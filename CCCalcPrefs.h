#ifndef CCCALCPREFS_H
#define CCCALCPREFS_H

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#define CCCALC_SUITE CFSTR("com.siri666666.cccalcredirectprefs")
#define CCCALC_SUITE_NS @"com.siri666666.cccalcredirectprefs"
#define CCCALC_NOTIF CFSTR("com.siri666666.cccalcredirectprefs/saved")
#define CCCALC_MODULE_ID @"com.apple.control-center.CalculatorModule"
#define CCCALC_STOCK_ID @"com.apple.calculator"

static inline id cccalc_cf_get(NSString *key) {
    if (!key) return nil;
    CFPropertyListRef val = CFPreferencesCopyValue(
        (__bridge CFStringRef)key,
        CCCALC_SUITE,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost
    );
    return (__bridge_transfer id)val;
}

static inline void cccalc_cf_set(NSString *key, id value) {
    if (!key) return;
    CFPreferencesSetValue(
        (__bridge CFStringRef)key,
        (__bridge CFPropertyListRef)value,
        CCCALC_SUITE,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost
    );
    CFPreferencesSynchronize(CCCALC_SUITE, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}

static inline void cccalc_post_saved_notification(void) {
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CCCALC_NOTIF,
        NULL,
        NULL,
        YES
    );
}

#endif
