# Proposal: Native-aligned gesture recognition pipeline

## Summary

Rework `rgestures.h` so gesture recognition follows the model used by native
mobile SDKs:

- `GESTURE_TAP` is emitted on `TOUCH_ACTION_UP`, after a valid press/release
  sequence.
- `GESTURE_HOLD` is emitted only after a hold timeout while the pointer is still
  down.
- `GESTURE_DRAG` is detected from movement while pressed, independently from
  `GESTURE_HOLD`.

This avoids using `GESTURE_TAP` as an internal "pointer is down" state. A tap
should be a confirmed completed gesture, not a provisional state that can later
turn into hold or drag.

## Current behavior

`ProcessGestureEvent()` sets `GESTURE_TAP` immediately on `TOUCH_ACTION_DOWN`.
Then `UpdateGestures()` converts `GESTURE_TAP` or `GESTURE_DOUBLETAP` to
`GESTURE_HOLD` on a later frame.

That makes `GESTURE_TAP` serve two roles:

- Public gesture reported to applications.
- Internal pressed/pending state used to later detect hold.

This is the root cause of short taps reporting both `GESTURE_TAP` and
`GESTURE_HOLD`: the gesture is reported as tap before it is known whether the
finger or mouse button will be released quickly.

## Native SDK model

Native mobile SDKs generally recognize tap on release:

- iOS `UITapGestureRecognizer` recognizes after a valid touch-up.
- iOS `UILongPressGestureRecognizer` begins after `minimumPressDuration` while
  the touch is still down.
- Android tap/click callbacks are produced after the down/up sequence, while
  long press is produced after the long-press timeout if the pointer remains
  down.
- Pan/drag recognition is movement-driven and does not require long press first.

The equivalent raylib gesture flow would be:

```text
TOUCH_ACTION_DOWN:
    store pointer id, position and time
    set internal pending state
    do not emit GESTURE_TAP

TOUCH_ACTION_MOVE:
    if movement passes drag threshold:
        emit GESTURE_DRAG
    otherwise keep waiting

UpdateGestures():
    if pointer is still down and hold timeout elapsed:
        emit GESTURE_HOLD

TOUCH_ACTION_UP:
    if no hold, drag, pinch or swipe was recognized:
        emit GESTURE_TAP or GESTURE_DOUBLETAP
```

## Proposed implementation direction

Add internal state separate from the public `GESTURES.current` value. For
example:

- `Touch.isDown`
- `Touch.pendingTap`
- `Touch.downTime`
- `Touch.downPositionA`
- `Touch.lastTapTime`
- `Touch.lastTapPosition`
- `Touch.dragging`
- `Touch.holding`

Then update recognition rules:

1. On `TOUCH_ACTION_DOWN`, record position/time and set the internal pending
   state. Do not set `GESTURE_TAP`.
2. In `UpdateGestures()`, if the pointer is still down, no drag/pinch has been
   recognized, and `HOLD_TIMEOUT` has elapsed, set `GESTURE_HOLD`.
3. On `TOUCH_ACTION_MOVE`, start `GESTURE_DRAG` when movement passes
   `MINIMUM_DRAG`, without requiring the current gesture to be `GESTURE_HOLD`.
4. On `TOUCH_ACTION_UP`, emit `GESTURE_TAP` only if the press was not converted
   to hold, drag, pinch or swipe.
5. Detect `GESTURE_DOUBLETAP` from two completed taps within `TAP_TIMEOUT` and
   `DOUBLETAP_RANGE`.
6. Keep swipe detection based on the completed movement and exclude already
   recognized hold/drag gestures where appropriate.

## Expected behavior

| Scenario | Current behavior | Proposed behavior |
|----------|------------------|-------------------|
| Quick tap | `TAP` on down, possible `HOLD` on next frame | `TAP` on up only |
| Long press | `TAP` on down, then `HOLD` | `HOLD` after timeout, no `TAP` |
| Double tap | `DOUBLETAP` on second down, possible `HOLD` | `DOUBLETAP` after second tap completes |
| Drag | Requires the flow through `HOLD` before `DRAG` | Starts from movement threshold while pressed |
| Swipe | Calculated on release | Calculated on release, excluding hold/drag cases |
| Pinch | Two-finger path mostly unchanged | Two-finger path mostly unchanged |

## Compatibility impact

This is a behavioral change and should not be presented as a minimal bug fix.

- Applications polling `IsGestureDetected(GESTURE_TAP)` immediately after
  pointer down will no longer see tap until pointer up.
- Applications relying on `GESTURE_HOLD` being emitted shortly after
  `GESTURE_TAP` will see hold only after the configured hold timeout.
- Desktop applications using mouse gestures through `SUPPORT_MOUSE_GESTURES`
  are affected in the same way as touch applications.
- Raw mouse APIs such as `IsMouseButtonPressed()`, `IsMouseButtonDown()`,
  `IsMouseButtonReleased()` and `GetMousePosition()` are not affected.

## Why this is preferable

The current design leaks an internal pending state through the public gesture
API. Delaying tap until release makes each public gesture represent a completed
or clearly recognized user action:

- `TAP`: completed press/release.
- `HOLD`: timeout reached while still pressed.
- `DRAG`: movement threshold reached while pressed.
- `SWIPE`: release after fast movement.

This matches native mobile behavior and removes the need for special fixes that
try to prevent `GESTURE_TAP` from turning into `GESTURE_HOLD` after it has
already been reported to the application.
