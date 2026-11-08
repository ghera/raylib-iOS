#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef struct SafeAreaInsets {
    float top;
    float bottom;
    float left;
    float right;
} SafeAreaInsets;

const char* GetIOSDocumentsPath();
const SafeAreaInsets GetIOSSafeAreaInsets();

/**
 * @brief Calls `callback` with `focused` = false when the app resigns active
 *        (background, control centre, incoming call) and `true` when it becomes
 *        active again, so a game can freeze, pause and paint one last frame.
 *
 *        UIKit is the only way to get these edges: `rcore_ios.c` reads the first
 *        one only to stop calling the game (`-[GameViewController update]` gates
 *        `ios_update()` on `IsWindowFocused()`), so inside the game loop that flag
 *        is always true and the transition is invisible. Installs once; later
 *        calls are ignored.
 */
void InstallBackgroundHook(void (*callback)(bool focused));

#ifdef __cplusplus
}
#endif
