#import "IOSBridge.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern "C" const char* GetIOSDocumentsPath() {
    static NSString *documentsPath = nil;
    static const char *cPath = nullptr;

    if (!documentsPath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsPath = [[paths firstObject] copy];
        cPath = [documentsPath UTF8String];
    }
    return cPath;
}

extern "C" void InstallBackgroundHook(void (*callback)(bool focused))
{
    static bool installed = false;
    if (installed) {
        return;
    }
    installed = true;

    /* Works with scenes too: UIKit still posts the app-level notifications, and
       raylib's SceneDelegate consumes the first edge by simply not calling the
       game any more -- which is exactly why the game cannot see it. One callback
       with a boolean, the same shape as the engine's own focus handling. */
    [NSNotificationCenter.defaultCenter
        addObserverForName:UIApplicationWillResignActiveNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *notification) { callback(false); }];
    [NSNotificationCenter.defaultCenter
        addObserverForName:UIApplicationDidBecomeActiveNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *notification) { callback(true); }];
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
