#import "IOSBridge.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern "C" const char* GetIOSDocumentsPath() {
    static NSString *documentsPath = nil;
    static const char *cPath = nullptr;

    if (!documentsPath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsPath = [paths firstObject];
        cPath = [documentsPath UTF8String];
    }
    return cPath;
}

extern "C" const SafeAreaInsets GetIOSSafeAreaInsets() {
    UIWindow *window = nil;

    for (UIWindowScene* scene in UIApplication.sharedApplication.connectedScenes) {
        for (UIWindow* w in scene.windows) {
            if (w.isKeyWindow) {
                window = w;
                break;
            }
        }
        if (window) break;
    }

    SafeAreaInsets insets = { 0, 0, 0, 0 };
    
    if (window) {
        UIEdgeInsets saInsets = window.safeAreaInsets;        
        insets.top    = (float)(saInsets.top);
        insets.bottom = (float)(saInsets.bottom);
        insets.left   = (float)(saInsets.left);
        insets.right  = (float)(saInsets.right);
    }
    
    return insets;
}
