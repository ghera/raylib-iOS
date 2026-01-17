/*******************************************************************************************
 *
 *   raylib [core] example - Input Gestures Detection
 *
 *   Example originally created with raylib 1.4, last time updated with raylib 4.2
 *
 *   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
 *   BSD-like license that allows static linking with closed source software
 *
 *   Copyright (c) 2016-2024 Ramon Santamaria (@raysan5)
 *
 *   This version has been adapted for iOS with safe area support
 *   as part of the raylib-iOS project (https://github.com/ghera/raylib-iOS)
 *
 ********************************************************************************************/
#ifndef RL_IOS_NO_EXAMPLE

#include "raylib.h"

#if defined(PLATFORM_IOS)
#include "IOSBridge.h"
#endif

#define LOG_AREA_WIDTH 160

int maxGestureStrings = 20;
int usableWidth = 0;
int usableHeight = 0;
SafeAreaInsets safeArea = (SafeAreaInsets){0, 0, 0, 0};
Vector2 touchPosition = (Vector2){0, 0};
Rectangle touchArea;
Rectangle logArea;
int gesturesCount = 0;
char gestureStrings[100][32];
int currentGesture = GESTURE_NONE;
int lastGesture = GESTURE_NONE;

static void add_log_text(const char* title) {
    if (gesturesCount >= maxGestureStrings) {
        for (int i = 0; i < maxGestureStrings; i++)
            TextCopy(gestureStrings[i], "\0");
        gesturesCount = 0;
    }
    TextCopy(gestureStrings[gesturesCount], title);
    gesturesCount++;
}

static void update_screen_layout() {
#if defined(PLATFORM_IOS)
    safeArea = GetIOSSafeAreaInsets();
    add_log_text(TextFormat("SafeAreaInsets %.0f, %.0f, %.0f, %.0f",
                            safeArea.top, safeArea.left, safeArea.bottom, safeArea.right));
#endif
    usableWidth = GetScreenWidth() - safeArea.left - safeArea.right;
    usableHeight = GetScreenHeight() - safeArea.top - safeArea.bottom;
    touchArea = (Rectangle){safeArea.left + LOG_AREA_WIDTH + 20, safeArea.top + 10, usableWidth - LOG_AREA_WIDTH - 30, usableHeight - 20};
    logArea = (Rectangle){safeArea.left + 10, safeArea.top + 30, LOG_AREA_WIDTH, usableHeight - 40};
    maxGestureStrings = logArea.height / 20;
}

static void ready() {
#if defined(PLATFORM_IOS)
    SetConfigFlags(FLAG_FULLSCREEN_MODE);
    InitWindow(0, 0, "raylib [core] example - input gestures");
#else
    InitWindow(800, 600, "raylib [core] example - input gestures");
#endif
    
    // SetGesturesEnabled(0b0000000000001001);   // Enable only some gestures to be detected
    SetTargetFPS(60);

    update_screen_layout();
}

static void update(bool viewSizeChanged) {
    if (viewSizeChanged) {
        update_screen_layout();
        add_log_text(TextFormat("ViewSizeChanged %d x %d", GetMonitorWidth(0), GetMonitorHeight(0)));
    }

    lastGesture = currentGesture;
    currentGesture = GetGestureDetected();
    touchPosition = GetTouchPosition(0);
    bool testAreaTouched = false;
    
    if (CheckCollisionPointRec(touchPosition, touchArea) && (currentGesture != GESTURE_NONE)) {
        testAreaTouched = true;
        if (currentGesture != lastGesture) {
            switch (currentGesture) {
                case GESTURE_TAP:
                    add_log_text("GESTURE TAP");
                    break;
                case GESTURE_DOUBLETAP:
                    add_log_text("GESTURE DOUBLE TAP");
                    break;
                case GESTURE_HOLD:
                    add_log_text("GESTURE HOLD");
                    break;
                case GESTURE_DRAG:
                    add_log_text("GESTURE DRAG");
                    break;
                case GESTURE_SWIPE_RIGHT:
                    add_log_text("GESTURE SWIPE RIGHT");
                    break;
                case GESTURE_SWIPE_LEFT:
                    add_log_text("GESTURE SWIPE LEFT");
                    break;
                case GESTURE_SWIPE_UP:
                    add_log_text("GESTURE SWIPE UP");
                    break;
                case GESTURE_SWIPE_DOWN:
                    add_log_text("GESTURE SWIPE DOWN");
                    break;
                case GESTURE_PINCH_IN:
                    add_log_text("GESTURE PINCH IN");
                    break;
                case GESTURE_PINCH_OUT:
                    add_log_text("GESTURE PINCH OUT");
                    break;
                default:
                    break;
            }
        }
    }
    
    BeginDrawing();

    ClearBackground(RAYWHITE);

    DrawRectangleRec(touchArea, GRAY);
    DrawRectangle(touchArea.x + 5, touchArea.y + 5, touchArea.width - 10, touchArea.height - 10, RAYWHITE);

    DrawText("GESTURES\nTEST AREA", touchArea.x + 15, safeArea.top + usableHeight - 65, 20, Fade(GRAY, 0.5f));

    for (int i = 0; i < gesturesCount; i++) {
        if (i % 2 == 0) {
            DrawRectangle(safeArea.left + 10, safeArea.top + 30 + 20 * i, LOG_AREA_WIDTH, 20, Fade(LIGHTGRAY, 0.5f));
        } else {
            DrawRectangle(safeArea.left + 10, safeArea.top + 30 + 20 * i, LOG_AREA_WIDTH, 20, Fade(LIGHTGRAY, 0.3f));
        }
        if (i < gesturesCount - 1) {
            DrawText(gestureStrings[i], logArea.x + 5, logArea.y + 6 + 20 * i, 10, DARKGRAY);
        } else {
            DrawText(gestureStrings[i], logArea.x + 5, logArea.y + 6 + 20 * i, 10, MAROON);
        }
    }

    DrawRectangleLinesEx(logArea, 1, GRAY);
    
    if (testAreaTouched) {
        DrawText(TextFormat("TOUCH COUNT: %d", GetTouchPointCount()), safeArea.left + 15, safeArea.top + 15, 10, GRAY);

        for (int i = 0; i < GetTouchPointCount(); i++) {
            DrawCircleV(GetTouchPosition(i), 30, MAROON);
        }
    }
        
    EndDrawing();
}

static void destroy() {
    CloseWindow();
}

#if defined(PLATFORM_IOS)
void ios_ready() {
    ready();
}

void ios_update(bool viewSizeChanged) {
    update(viewSizeChanged);
}

void ios_destroy() {
    destroy();
}
#else
int main() {
    ready();

    while (!WindowShouldClose()) {
        update(false);
    }

    destroy();
    return 0;
}
#endif

#endif
