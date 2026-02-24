#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <substrate.h>

extern "C" void SpawnItem(void *itemName, int quantity, float x, float y, float z, int colorHue, int colorSat);
extern "C" void* il2cpp_string_new(const char *str);

@interface MilesStealthMenu : UIViewController <WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *webView;
@end

static const void *kInjected = &kInjected;

@implementation MilesStealthMenu

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup WebView with extreme memory safety
    WKUserContentController *ucc = [[WKUserContentController alloc] init];
    [ucc addScriptMessageHandler:self name:@"milesBridge"];
    WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
    cfg.userContentController = ucc;

    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:cfg];
    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.webView];

    // Your original Neon HTML design
    NSString *html = @"<!DOCTYPE html><html><body style='margin:0;display:flex;justify-content:center;align-items:center;background:rgba(30,0,50,0.9);height:100vh;'>"
    "<div style='border:2px solid #1e90ff;padding:20px;border-radius:15px;text-align:center;color:white;width:300px;font-family:sans-serif;'>"
    "<h3>Miles Stealth TMC</h3>"
    "<button onclick='spawn(\"item_lava_fishing_rod\")' style='width:100%;padding:10px;background:#1e90ff;color:white;border:none;border-radius:8px;'>Lava Rod</button>"
    "<button onclick='window.location.reload()' style='margin-top:10px;background:none;border:none;color:grey;'>[ Refresh ]</button>"
    "<p style='font-size:10px;'>3-Finger Double Tap to Hide</p></div>"
    "<script>function spawn(id){window.webkit.messageHandlers.milesBridge.postMessage({item:id});}</script></body></html>";

    [self.webView loadHTMLString:html baseURL:nil];
}

- (void)userContentController:(id)ucc didReceiveScriptMessage:(WKScriptMessage *)msg {
    NSDictionary *data = msg.body;
    void *uStr = il2cpp_string_new([data[@"item"] UTF8String]);
    SpawnItem(uStr, 1, 0, 3.5, 0, 0, 0);
}
@end

// --- STEALTH GESTURE HOOK ---
%hook UnityAppController
- (void)applicationDidBecomeActive:(id)arg1 {
    %orig;

    if (objc_getAssociatedObject(self, kInjected)) return;
    objc_setAssociatedObject(self, kInjected, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // Add a secret gesture listener to the main window
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
        
        // 3-Finger Double Tap to Toggle Menu
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMilesTap:)];
        tap.numberOfTapsRequired = 2;
        tap.numberOfTouchesRequired = 3;
        [win addGestureRecognizer:tap];
    });
}

%new
- (void)handleMilesTap:(UITapGestureRecognizer *)sender {
    static MilesStealthMenu *menu = nil;
    UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
    
    if (!menu) {
        menu = [[MilesStealthMenu alloc] init];
        [win.rootViewController addChildViewController:menu];
        [win.rootViewController.view addSubview:menu.view];
    } else {
        menu.view.hidden = !menu.view.hidden;
    }
}
%end
