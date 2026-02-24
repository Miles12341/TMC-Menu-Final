#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <substrate.h>

// --- Game Engine Hooks ---
extern "C" void SpawnItem(void *itemName, int quantity, float x, float y, float z, int colorHue, int colorSat);
extern "C" void* il2cpp_string_new(const char *str);

@interface MilesTMCController : UIViewController <WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *tmcButton;
@property (nonatomic, strong) UIButton *closeButton;
@end

// XD-STYLE STABILITY MARKER
static const void *kInjected = &kInjected;

@implementation MilesTMCController

// Modern Window Finder (Safe for iPhone 13/14/15)
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

    // 1. TMC Button (Top Left)
    self.tmcButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tmcButton.frame = CGRectMake(50, 70, 80, 45); 
    self.tmcButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.5 blue:1.0 alpha:0.9];
    [self.tmcButton setTitle:@"TMC" forState:UIControlStateNormal];
    self.tmcButton.layer.cornerRadius = 12;
    self.tmcButton.layer.borderWidth = 2;
    self.tmcButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.tmcButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    
    // 2. X Button (Top Right)
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.frame = CGRectMake(sw - 80, 70, 50, 50);
    self.closeButton.backgroundColor = [UIColor redColor];
    [self.closeButton setTitle:@"X" forState:UIControlStateNormal];
    self.closeButton.layer.cornerRadius = 25;
    self.closeButton.hidden = YES;
    [self.closeButton addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];

    // Add buttons to window (Using the Main Queue like XD)
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self findActiveWindow] addSubview:self.tmcButton];
        [[self findActiveWindow] addSubview:self.closeButton];
    });

    // 3. Setup WebView
    WKUserContentController *ucc = [[WKUserContentController alloc] init];
    [ucc addScriptMessageHandler:self name:@"milesBridge"];
    WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
    cfg.userContentController = ucc;

    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:cfg];
    self.webView.hidden = YES;
    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.webView];

    // YOUR NEON HTML
    NSString *html = @"<!DOCTYPE html><html><head><style>"
    "body{margin:0;display:flex;justify-content:center;align-items:center;background:rgba(30,0,50,0.95);font-family:sans-serif;height:100vh;}"
    ".panel{border:2px solid #1e90ff;padding:20px;border-radius:20px;text-align:center;color:white;width:320px;box-shadow:0 0 20px #1e90ff;}"
    "button{width:100%;padding:12px;background:#1e90ff;color:white;border:none;border-radius:10px;margin:5px 0;font-weight:bold;}"
    "</style></head><body><div class='panel'><h3>Miles TMC Fishing</h3>"
    "<button onclick='spawn(\"item_lava_fishing_rod\")'>Spawn Lava Rod</button>"
    "<button onclick='spawn(\"item_diamond_fish\")'>Spawn Diamond Fish</button></div>"
    "<script>function spawn(id){window.webkit.messageHandlers.milesBridge.postMessage({item:id});}</script></body></html>";

    [self.webView loadHTMLString:html baseURL:nil];
}

- (void)showMenu { self.webView.hidden = NO; self.closeButton.hidden = NO; }
- (void)hideMenu { self.webView.hidden = YES; self.closeButton.hidden = YES; }

- (void)userContentController:(id)ucc didReceiveScriptMessage:(WKScriptMessage *)msg {
    NSDictionary *data = msg.body;
    void *uStr = il2cpp_string_new([data[@"item"] UTF8String]);
    SpawnItem(uStr, 1, 0, 3.5, 0, 0, 0);
}
@end

// --- XD-STYLE STABILITY HOOK ---
%hook UnityAppController

- (void)applicationDidBecomeActive:(id)arg1 {
    %orig;

    // XD FIX: Check if already injected to stop instant-crash
    if (objc_getAssociatedObject(self, kInjected)) return;
    objc_setAssociatedObject(self, kInjected, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // XD FIX: Delayed Main Queue Injection
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        MilesTMCController *menu = [[MilesTMCController alloc] init];
        UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
        if (win) {
            [win.rootViewController addChildViewController:menu];
            [win.rootViewController.view addSubview:menu.view];
        }
    });
}
%end
