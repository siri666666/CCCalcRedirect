#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <os/lock.h>
#import "CCCalcPrefs.h"

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (BOOL)applicationIsInstalled:(NSString *)appIdentifier;
@end

@interface CCUIContentModuleContext : NSObject
@property (nonatomic, copy, readonly) NSString *moduleIdentifier;
- (void)openURL:(NSURL *)url completionHandler:(void (^)(BOOL success))completionHandler;
- (void)openApplication:(NSString *)bundleID completionHandler:(void (^)(BOOL success))completionHandler;
- (void)openApplication:(NSString *)bundleID withOptions:(id)options completionHandler:(void (^)(BOOL success))completionHandler;
@end

@interface CCUIAppLauncherModule : NSObject
@property (nonatomic, copy) NSString *applicationIdentifier;
@property (nonatomic, copy) NSString *launchApplicationIdentifier;
@property (nonatomic, retain) CCUIContentModuleContext *contentModuleContext;
- (NSURL *)launchURLForTouchType:(long long)touchType;
@end

static os_unfair_lock gPrefsLock = OS_UNFAIR_LOCK_INIT;
static BOOL gEnabled = YES;
static NSString *gTargetBundleID = @"";
static NSString *gCustomURLScheme = @"";
static BOOL gReplaceLongPress = NO;

static void loadPrefs(void) {
    CFPreferencesSynchronize(CCCALC_SUITE, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

    id enabledVal = cccalc_cf_get(@"enabled");
    id targetVal = cccalc_cf_get(@"targetBundleID");
    id urlVal = cccalc_cf_get(@"customURLScheme");
    id longPressVal = cccalc_cf_get(@"replaceLongPress");

    BOOL enabled = [enabledVal respondsToSelector:@selector(boolValue)] ? [enabledVal boolValue] : YES;
    NSString *target = [targetVal isKindOfClass:[NSString class]]
        ? [targetVal stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
        : @"";
    NSString *urlScheme = [urlVal isKindOfClass:[NSString class]]
        ? [urlVal stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
        : @"";
    BOOL replaceLongPress = [longPressVal respondsToSelector:@selector(boolValue)] ? [longPressVal boolValue] : NO;

    os_unfair_lock_lock(&gPrefsLock);
    gEnabled = enabled;
    gTargetBundleID = [target copy];
    gCustomURLScheme = [urlScheme copy];
    gReplaceLongPress = replaceLongPress;
    os_unfair_lock_unlock(&gPrefsLock);
}

static void reloadPrefsCallback(CFNotificationCenterRef center __unused,
                                void *observer __unused,
                                CFStringRef name __unused,
                                const void *object __unused,
                                CFDictionaryRef userInfo __unused) {
    loadPrefs();
}

static BOOL cccalc_is_calc_module(CCUIAppLauncherModule *mod) {
    if (!mod) return NO;
    if ([mod.contentModuleContext.moduleIdentifier isEqualToString:CCCALC_MODULE_ID]) {
        return YES;
    }
    @try {
        id bundle = [mod valueForKey:@"_bundle"];
        if ([bundle isKindOfClass:[NSBundle class]] &&
            [[(NSBundle *)bundle bundleIdentifier] isEqualToString:CCCALC_MODULE_ID]) {
            return YES;
        }
    } @catch (NSException *ignored) {}
    @try {
        id appID = [mod valueForKey:@"_applicationIdentifier"];
        if ([appID isKindOfClass:[NSString class]] && [appID isEqualToString:CCCALC_STOCK_ID]) {
            return YES;
        }
    } @catch (NSException *ignored) {}
    return NO;
}

static NSString *cccalc_resolved_target_bundle_id(void) {
    os_unfair_lock_lock(&gPrefsLock);
    BOOL enabled = gEnabled;
    NSString *target = gTargetBundleID;
    os_unfair_lock_unlock(&gPrefsLock);

    if (!enabled || target.length == 0 || [target isEqualToString:CCCALC_STOCK_ID]) {
        return nil;
    }
    Class wsCls = objc_getClass("LSApplicationWorkspace");
    if (wsCls) {
        LSApplicationWorkspace *ws = [wsCls defaultWorkspace];
        if (ws && ![ws applicationIsInstalled:target]) {
            return nil;
        }
    }
    return target;
}

static NSURL *cccalc_resolved_custom_url(void) {
    os_unfair_lock_lock(&gPrefsLock);
    BOOL enabled = gEnabled;
    NSString *urlStr = gCustomURLScheme;
    os_unfair_lock_unlock(&gPrefsLock);

    if (!enabled || urlStr.length == 0) {
        return nil;
    }
    NSURL *url = [NSURL URLWithString:urlStr];
    if (url && url.scheme.length > 0) {
        return url;
    }
    return nil;
}

static BOOL cccalc_should_replace_long_press(void) {
    os_unfair_lock_lock(&gPrefsLock);
    BOOL replace = gReplaceLongPress;
    os_unfair_lock_unlock(&gPrefsLock);
    return replace;
}

%hook CCUIAppLauncherModule

- (NSString *)launchApplicationIdentifier {
    if (cccalc_is_calc_module(self) && !cccalc_resolved_custom_url()) {
        NSString *target = cccalc_resolved_target_bundle_id();
        if (target) return target;
    }
    return %orig;
}

- (NSString *)applicationIdentifier {
    NSString *orig = %orig;
    if (cccalc_should_replace_long_press() &&
        [orig isEqualToString:CCCALC_STOCK_ID] &&
        !cccalc_resolved_custom_url()) {
        NSString *target = cccalc_resolved_target_bundle_id();
        if (target) return target;
    }
    return orig;
}

- (NSURL *)launchURLForTouchType:(long long)touchType {
    if (cccalc_is_calc_module(self)) {
        NSURL *url = cccalc_resolved_custom_url();
        if (url) return url;
    }
    return %orig;
}

%end

%hook CCUIContentModuleContext

- (void)openApplication:(NSString *)bundleID withOptions:(id)options completionHandler:(void (^)(BOOL))completion {
    if ([bundleID isEqualToString:CCCALC_STOCK_ID] &&
        [self.moduleIdentifier isEqualToString:CCCALC_MODULE_ID]) {
        NSURL *url = cccalc_resolved_custom_url();
        if (url) {
            [self openURL:url completionHandler:completion];
            return;
        }
        NSString *target = cccalc_resolved_target_bundle_id();
        if (target) {
            %orig(target, options, completion);
            return;
        }
    }
    %orig;
}

- (void)openApplication:(NSString *)bundleID completionHandler:(void (^)(BOOL))completion {
    if ([bundleID isEqualToString:CCCALC_STOCK_ID] &&
        [self.moduleIdentifier isEqualToString:CCCALC_MODULE_ID]) {
        NSURL *url = cccalc_resolved_custom_url();
        if (url) {
            [self openURL:url completionHandler:completion];
            return;
        }
        NSString *target = cccalc_resolved_target_bundle_id();
        if (target) {
            %orig(target, completion);
            return;
        }
    }
    %orig;
}

%end

%ctor {
    loadPrefs();
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        reloadPrefsCallback,
        CCCALC_NOTIF,
        NULL,
        CFNotificationSuspensionBehaviorCoalesce
    );
}
