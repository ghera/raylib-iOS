# Xcode27 - iOS example project

`main.c` is the raylib input-gestures example; `raylib/bridge/IOSBridge.{h,mm}` exposes the safe-area insets and the documents path to C.

Open `raylib.xcodeproj` and run the `raylib` scheme. Deployment target: iOS 15.6. The project compiles raylib from `../../../src` and links ANGLE from `../../deps/ANGLE` (`libEGL`, `libGLESv2`), which are prebuilt and committed.

To use a prebuilt library instead, the stable releases of this repository (`6.0.2-iOS` and later, on the [releases page](https://github.com/ghera/raylib-iOS/releases)) attach a `raylib-ios-xcframeworks-<tag>.zip` with `raylib.xcframework`, `libEGL.xcframework` and `libGLESv2.xcframework`. Add them to the target and remove the raylib sources from the Sources build phase; the deployment target is the same.

## Platform requirements

- **Adopt the scene life cycle.** An app linked against the iOS 27 SDK that doesn't is killed at launch by a UIKit assert, and only when the runtime is iOS 27 as well - a binary built with an older SDK keeps running. `rcore_ios.c` creates the window in a `SceneDelegate`, without declaring `UIApplicationSceneManifest` in the plist. See [Transitioning to the UIKit scene-based life cycle](https://developer.apple.com/documentation/uikit/transitioning-to-the-uikit-scene-based-life-cycle).

`ios_ready()` runs once per app launch and `ios_destroy()` once at termination: nothing tears the window down in between, and no other callback should.
