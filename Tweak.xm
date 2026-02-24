#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>

// --- Game Engine Hooks (Defined globally) ---
extern "C" void SpawnItem(void *itemName, int quantity, float x, float y, float z, int colorHue, int colorSat);
extern "C" void* il2cpp_string_new(const char *str);

@interface MilesTMCController : UIViewController <WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *tmcButton;
@property (nonatomic, strong) UIButton *closeButton;
@end

@implementation MilesTMCController

// Modern Window Finder for iPhone 13-16
- (UIWindow *)getSafeWindow {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                return scene.windows.firstObject;
            }
        }
    }
    return [UIApplication sharedApplication].keyWindow;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // 1. TMC Button (Lowered for Notch)
    self.tmcButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tmcButton.frame = CGRectMake(50, 80, 80, 45); 
    self.tmcButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.5 blue:1.0 alpha:0.9];
    [self.tmcButton setTitle:@"TMC" forState:UIControlStateNormal];
    self.tmcButton.layer.cornerRadius = 12;
    self.tmcButton.layer.borderWidth = 2;
    self.tmcButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.tmcButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    
    // 2. X Close Button
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.frame = CGRectMake(sw - 80, 80, 50, 50);
    self.closeButton.backgroundColor = [UIColor redColor];
    [self.closeButton setTitle:@"X" forState:UIControlStateNormal];
    self.closeButton.layer.cornerRadius = 25;
    self.closeButton.hidden = YES;
    [self.closeButton addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];

    // Inject buttons safely
    [[self getSafeWindow] addSubview:self.tmcButton];
    [[self getSafeWindow] addSubview:self.closeButton];

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

    // Your Ultimate HTML String here...
    NSString *html = @"<html><body style='background:rgba(30,0,50,0.9); color:white; font-family:sans-serif; display:flex; justify-content:center; align-items:center; height:100vh;'>"
    "<div style='border:2px solid #1e90ff; padding:20px; border-radius:15px; text-align:center;'>"
    "<h3>Miles TMC Stealth</h3>"
    "<button onclick='window.webkit.messageHandlers.milesBridge.postMessage({item:\"item_lava_fishing_rod\"})' style='padding:10px; background:#1e90ff; color:white; border:none; border-radius:8px;'>Spawn Lava Rod</button>"
    "</div></body></html>";

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

// --- THE "GENERAL LOAD" CONSTRUCTOR ---
// This replaces the %hook entirely. 
__attribute__((constructor)) static void initializeMilesMod() {
    // WAIT 10 SECONDS: This is the secret to stopping the crash!
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        MilesTMCController *menu = [[MilesTMCController alloc] init];
        UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
        if (win) {
            [win.rootViewController addChildViewController:menu];
            [win.rootViewController.view addSubview:menu.view];
        }
    });
}
