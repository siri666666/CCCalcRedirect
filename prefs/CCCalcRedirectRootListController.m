#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <spawn.h>
#import <dlfcn.h>
#import "../CCCalcPrefs.h"

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (BOOL)openApplicationWithBundleID:(NSString *)bundleID;
- (BOOL)applicationIsInstalled:(NSString *)bundleID;
@end

static NSString *cccalc_root_path(NSString *path) {
    typedef const char *(*jbroot_fn)(const char *);
    jbroot_fn fn = (jbroot_fn)dlsym(RTLD_DEFAULT, "jbroot");
    if (fn) {
        const char *resolved = fn(path.UTF8String);
        if (resolved) return [NSString stringWithUTF8String:resolved];
    }
    NSString *jbPath = [@"/var/jb" stringByAppendingString:path];
    if ([[NSFileManager defaultManager] fileExistsAtPath:jbPath]) return jbPath;
    return path;
}

@interface CCCalcRedirectRootListController : PSListController
@end

@implementation CCCalcRedirectRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *respringBtn = [[UIBarButtonItem alloc]
        initWithTitle:@"Respring"
                style:UIBarButtonItemStyleDone
               target:self
               action:@selector(confirmRespring)];
    self.navigationItem.rightBarButtonItem = respringBtn;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadSpecifiers];
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (!key) return [super readPreferenceValue:specifier];
    id val = cccalc_cf_get(key);
    if (val != nil) return val;
    return [specifier propertyForKey:@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (key) {
        cccalc_cf_set(key, value);
        cccalc_post_saved_notification();
    } else {
        [super setPreferenceValue:value specifier:specifier];
    }
}

- (void)testOpenTarget {
    id urlVal = cccalc_cf_get(@"customURLScheme");
    NSString *urlStr = [urlVal isKindOfClass:[NSString class]]
        ? [urlVal stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
        : @"";
    if (urlStr.length > 0) {
        NSURL *url = [NSURL URLWithString:urlStr];
        if (url && url.scheme.length > 0) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            return;
        }
    }

    id targetVal = cccalc_cf_get(@"targetBundleID");
    NSString *target = [targetVal isKindOfClass:[NSString class]]
        ? [targetVal stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
        : @"";
    if (target.length > 0) {
        Class wsCls = objc_getClass("LSApplicationWorkspace");
        LSApplicationWorkspace *ws = wsCls ? [wsCls defaultWorkspace] : nil;
        if (ws && [ws openApplicationWithBundleID:target]) {
            return;
        }
    }

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"未选择目标"
                       message:@"请先在「选择目标 App」中挑选计算器，或填写自定义 URL Scheme。"
                preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)resetToDefault {
    cccalc_cf_set(@"targetBundleID", nil);
    cccalc_cf_set(@"customURLScheme", @"");
    cccalc_post_saved_notification();
    self->_specifiers = nil;
    [self reloadSpecifiers];
}

- (void)confirmRespring {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Respring 注销"
                       message:@"首次安装或修改「接管长按菜单」后需注销桌面生效；日常切换目标 App 即时生效无需注销。"
                preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"立即 Respring"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(__unused UIAlertAction *action) {
        pid_t pid;
        NSString *sbreload = cccalc_root_path(@"/usr/bin/sbreload");
        if ([[NSFileManager defaultManager] isExecutableFileAtPath:sbreload]) {
            const char *args[] = { "sbreload", NULL };
            if (posix_spawn(&pid, sbreload.UTF8String, NULL, NULL, (char * const *)args, NULL) == 0) {
                return;
            }
        }
        NSString *killall = cccalc_root_path(@"/usr/bin/killall");
        const char *args[] = { "killall", "backboardd", NULL };
        posix_spawn(&pid, killall.UTF8String, NULL, NULL, (char * const *)args, NULL);
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openGitHub {
    NSURL *url = [NSURL URLWithString:@"https://github.com/siri666666/CCCalcRedirect"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

@end
