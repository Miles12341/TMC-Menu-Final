#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <substrate.h>

// --- Game Functions ---
extern "C" void SpawnItem(void *itemName, int quantity, float x, float y, float z, int colorHue, int colorSat);
extern "C" void* il2cpp_string_new(const char *str);

@interface MilesTMCController : UIViewController <WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *tmcButton;
@property (nonatomic, strong) UIButton *closeButton;
@end

static const void *kInjected = &kInjected;

@implementation MilesTMCController

- (UIWindow *)findActiveWindow {
    for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            return scene.windows.firstObject;
        }
    }
    return [UIApplication sharedApplication].keyWindow;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tmcButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tmcButton.frame = CGRectMake(50, 80, 80, 45); 
    self.tmcButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.5 blue:1.0 alpha:0.9];
    [self.tmcButton setTitle:@"TMC" forState:UIControlStateNormal];
    self.tmcButton.layer.cornerRadius = 12;
    self.tmcButton.layer.borderWidth = 2;
    self.tmcButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.tmcButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.frame = CGRectMake(sw - 80, 80, 50, 50);
    self.closeButton.backgroundColor = [UIColor redColor];
    [self.closeButton setTitle:@"X" forState:UIControlStateNormal];
    self.closeButton.layer.cornerRadius = 25;
    self.closeButton.hidden = YES;
    [self.closeButton addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[self findActiveWindow] addSubview:self.tmcButton];
        [[self findActiveWindow] addSubview:self.closeButton];
    });

    WKUserContentController *ucc = [[WKUserContentController alloc] init];
    [ucc addScriptMessageHandler:self name:@"milesBridge"];
    WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
    cfg.userContentController = ucc;

    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:cfg];
    self.webView.hidden = YES;
    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.webView];

    // PASTE YOUR PREVIOUS "ULTIMATE HTML" CODE HERE AS THE htmlSource STRING
    [self.webView loadHTMLString:htmlSource baseURL:nil];
}

- (void)showMenu { self.webView.hidden = NO; self.closeButton.hidden = NO; }
- (void)hideMenu { self.webView.hidden = YES; self.closeButton.hidden = YES; }

- (void)userContentController:(id)ucc didReceiveScriptMessage:(WKScriptMessage *)msg {
    NSDictionary *data = msg.body;
    NSString *name = data[@"item"];
    NSString *loc = data[@"loc"];

    // --- 1. SMART ID FORMATTER (Ensures items actually spawn) ---
    NSString *fmt;
    if ([name isEqualToString:@"CEO Big Brain"]) { fmt = @"ceo_big_brain_sign"; }
    else if ([name isEqualToString:@"Wicked Broom"]) { fmt = @"dev_broom_wicked"; }
    else if ([name isEqualToString:@"Golden Grenade"]) { fmt = @"gold_grenade"; }
    else if ([name isEqualToString:@"Golden Bat"]) { fmt = @"pinata_bat_gold"; }
    else if ([name isEqualToString:@"Time Bomb"]) { fmt = @"time_bomb_item"; }
    else {
        // Formatter: "Lava Fishing Rod" -> "item_lava_fishing_rod"
        fmt = [NSString stringWithFormat:@"item_%@", [[name lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
    }
    
    // --- 2. UNIVERSAL COORDINATE SYSTEM ---
    float x=0, y=3.0, z=0;
    if([loc isEqualToString:@"sell"]) { x=12.5; y=2.0; z=-8.0; }
    else if([loc isEqualToString:@"lake"]) { x=-45.0; y=1.0; z=22.0; }
    else if([loc isEqualToString:@"cave"]) { x=200.0; y=-15.0; z=50.0; }
    else if([loc isEqualToString:@"moon"]) { x=500.0; y=100.0; z=500.0; }
    else if([loc isEqualToString:@"volcano"]) { x=85.0; y=5.0; z=-120.0; }
    else if([loc isEqualToString:@"mountains"]) { x=150.0; y=60.0; z=150.0; }
    else if([loc isEqualToString:@"dupe"]) { x=5.0; y=2.0; z=5.0; }

    void *uStr = il2cpp_string_new([fmt UTF8String]);
    SpawnItem(uStr, 1, x, y, z, 0, 0);
}
@end

// --- STABILITY HOOK (7-Second Stealth Delay) ---
%hook UnityAppController
- (void)applicationDidBecomeActive:(id)arg1 {
    %orig;
    if (objc_getAssociatedObject(self, kInjected)) return;
    objc_setAssociatedObject(self, kInjected, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        MilesTMCController *menu = [[MilesTMCController alloc] init];
        UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
        if (win) {
            [win.rootViewController addChildViewController:menu];
            [win.rootViewController.view addSubview:menu.view];
        }
    });
}
%end
