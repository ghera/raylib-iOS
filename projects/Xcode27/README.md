# Xcode27 - iOS example project

`main.c` is the raylib input-gestures example; `raylib/bridge/IOSBridge.{h,mm}` exposes the safe-area insets and the documents path to C.

Open `raylib.xcodeproj` and run the `raylib` scheme. Deployment target: iOS 15.6. The project compiles raylib from `../../../src` and links ANGLE from `../../deps/ANGLE` (`libEGL`, `libGLESv2`), which are prebuilt and committed.

To use a prebuilt library instead, the stable releases of this repository (`6.0.2-iOS` and later, on the [releases page](https://github.com/ghera/raylib-iOS/releases)) attach a `raylib-ios-xcframeworks-<tag>.zip` with `raylib.xcframework`, `libEGL.xcframework` and `libGLESv2.xcframework`. Add them to the target and remove the raylib sources from the Sources build phase; the deployment target is the same.

## Platform requirements

- **Declare a launch screen.** Every iOS app must declare one - `UILaunchStoryboardName`, `UILaunchStoryboards`, `UILaunchScreen` or `UILaunchScreens` in `Info.plist` - and since iOS 27 App Store Connect rejects uploads built with the iOS 27 SDK that declare none, with `ITMS-90870: Missing launch screen`. See [Specifying your app's launch screen](https://developer.apple.com/documentation/xcode/specifying-your-apps-launch-screen) and [TN3208](https://developer.apple.com/documentation/technotes/tn3208-preparing-your-apps-launch-screen-to-meet-app-store-requirements).

  This project ships no storyboard, so it declares the modern build setting `INFOPLIST_KEY_UILaunchScreen_Generation = YES`, which generates an empty `UILaunchScreen` dictionary. Don't go back to `INFOPLIST_KEY_UILaunchStoryboardName = ""`: an empty value looks like a declaration but is dropped when the plist is generated, so the built app carries no launch screen key at all and UIKit logs `Update the Info.plist: ... Launch screens will soon be required`.

  Don't remove the key: on iOS 26 and earlier an app that declares no launch screen at all falls back to a reduced compatibility window instead of the full screen. iOS 27 doesn't apply that fallback, so the damage is invisible there.

- **Support every orientation.** The iPad list is `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad` (all four), which generates `UISupportedInterfaceOrientations~ipad`; the shared `INFOPLIST_KEY_UISupportedInterfaceOrientations` keeps the iPhone list at three. Rotating an iPad to an orientation the app doesn't declare makes UIKit log `Conversion error!` for a degenerate rect conversion while the rotation is refused, and iOS announces that all orientations will soon be required. That requirement is about the resizable scene, not about iPhone: the three-orientation list is fine there, and in a resizable environment the declared orientations are only a preference (an iPhone app in iPhone Mirroring stays in portrait), so a layout follows size classes, not the orientation.

- **Adopt the scene life cycle.** An app linked against the iOS 27 SDK that doesn't is killed at launch by a UIKit assert, and only when the runtime is iOS 27 as well - a binary built with an older SDK keeps running. `rcore_ios.c` creates the window in a `SceneDelegate`, without declaring `UIApplicationSceneManifest` in the plist. See [Transitioning to the UIKit scene-based life cycle](https://developer.apple.com/documentation/uikit/transitioning-to-the-uikit-scene-based-life-cycle).

- **Handle a resizable scene.** `UIRequiresFullScreen` is deprecated and logged a "will soon be ignored" warning at launch, so it is gone. During an interactive drag nothing is recomputed, as Apple recommends for games: `RecreatePlatformSurface()` keeps the surface size and stretches the presentation, while the scene delegate reports the interaction state and the new size is applied when the interaction ends.

`ios_ready()` runs once per app launch and `ios_destroy()` once at termination: nothing tears the window down in between, and no other callback should.
