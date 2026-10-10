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

#ifdef __cplusplus
}
#endif
