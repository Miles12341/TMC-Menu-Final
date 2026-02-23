#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>

// --- Game Engine Hooks ---
extern "C" void SpawnItem(void *itemName, int quantity, float x, float y, float z, int colorHue, int colorSat);
extern "C" void* il2cpp_string_new(const char *str);

@interface MilesTMCController : UIViewController <WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *tmcButton;
@property (nonatomic, strong) UIButton *closeButton;
@end

// Memory marker from your first script to stop double-loading crashes
static const void *kInjected = &kInjected;

@implementation MilesTMCController

// Modern Window Finder for iPhone 13/14/15
- (UIWindow *)findActiveWindow {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) return window;
                }
            }
        }
    }
    return [UIApplication sharedApplication].keyWindow;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // 1. TMC Button (Top Left)
    self.tmcButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tmcButton.frame = CGRectMake(40, 70, 80, 45); 
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

    // Inject buttons into the main window
    [[self findActiveWindow] addSubview:self.tmcButton];
    [[self findActiveWindow] addSubview:self.closeButton];

    // 3. Setup the Menu WebView
    WKUserContentController *ucc = [[WKUserContentController alloc] init];
    [ucc addScriptMessageHandler:self name:@"milesBridge"];
    WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
    cfg.userContentController = ucc;

    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:cfg];
    self.webView.hidden = YES;
    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.webView];

    // FULL FISHING UPDATE HTML DESIGN
    NSString *html = @"<!DOCTYPE html><html><head><style>"
    "body{margin:0;display:flex;justify-content:center;align-items:center;background:rgba(35,0,55,0.95);font-family:sans-serif;height:100vh;}"
    ".panel{border:2px solid #1e90ff;padding:20px;border-radius:20px;text-align:center;color:white;width:320px;box-shadow:0 0 20px #1e90ff;}"
    ".tab{background:#1e90ff;border:none;color:white;padding:7px;margin:2px;border-radius:8px;cursor:pointer;font-size:12px;}"
    "select, input{width:90%;padding:10px;margin:8px 0;border-radius:8px;border:none;background:#222;color:white;}"
    ".res{max-height:80px;overflow-y:auto;background:rgba(0,0,0,0.3);margin-bottom:10px;}"
    ".item{padding:8px;cursor:pointer;border-bottom:1px solid #444;font-size:14px;}"
    ".spawn{background:#1e90ff;border:none;width:100%;padding:15px;border-radius:12px;color:white;font-weight:bold;cursor:pointer;}"
    "</style></head><body><div class='panel'><h3>Miles TMC Fishing</h3>"
    "<div class='tabs'><button class='tab' onclick='setCat(\"Fishing\")'>Fishing</button><button class='tab' onclick='setCat(\"Fish\")'>Fish</button><button class='tab' onclick='setCat(\"Melee\")'>Melee</button></div>"
    "<select id='loc'><option>Center</option><option>Lake</option><option>Megalodon Cave</option></select>"
    "<input type='text' id='search' placeholder='Search...' onkeyup='filter()'><div class='res' id='res'></div>"
    "<button class='spawn' onclick='doSpawn()'>SPAWN ITEM</button></div>"
    "<script>"
    "let sel=''; let items={Fishing:['Lava Fishing Rod','Radioactive Fishing Rod','Super Fishing Pole'],Fish:['Diamond Fish','Dragon Fish','Goldfish','Salmon'],Melee:['Alpha Blade','Great Sword','Fish Sword']};"
    "function setCat(c){window.cat=c; filter();}"
    "function filter(){const s=document.getElementById('search').value.toLowerCase(); const r=document.getElementById('res'); r.innerHTML=''; "
    "(items[window.cat]||[]).filter(i=>i.toLowerCase().includes(s)).forEach(i=>{ "
    "const d=document.createElement('div'); d.className='item'; d.textContent=i; "
    "d.onclick=()=>{sel=i; document.getElementById('search').value=i; r.innerHTML='';}; r.appendChild(d); }); }"
    "function doSpawn(){if(!sel)return; window.webkit.messageHandlers.milesBridge.postMessage({item:sel, loc:document.getElementById('loc').value}); }"
    "setCat('Fishing');</script></body></html>";

    [self.webView loadHTMLString:html baseURL:nil];
}

- (void)showMenu { self.webView.hidden = NO; self.closeButton.hidden = NO; }
- (void)hideMenu { self.webView.hidden = YES; self.closeButton.hidden = YES; }

- (void)userContentController:(id)ucc didReceiveScriptMessage:(WKScriptMessage *)msg {
    NSDictionary *data = msg.body;
    NSString *name = data[@"item"];
    NSString *loc = data[@"loc"];
    NSString *fmt = [NSString stringWithFormat:@"item_%@", [[name lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
    
    float x=0, y=3.5, z=0;
    if([loc isEqualToString:@"Lake"]) { x=-45.0; z=20.0; }
    if([loc isEqualToString:@"Megalodon Cave"]) { x=200.0; y=-15.0; z=50.0; }

    void *uStr = il2cpp_string_new([fmt UTF8String]);
    SpawnItem(uStr, 1, x, y, z, 0, 0);
}
@end

// --- STABILITY HOOK (Stops Animal Company Companion from Crashing) ---
#import <substrate.h>

%hook UnityAppController
- (void)applicationDidBecomeActive:(id)arg1 {
    %orig;

    // The "kInjected" check from your first script - stops double-loading crashes
    if (objc_getAssociatedObject(self, kInjected)) return;
    objc_setAssociatedObject(self, kInjected, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // Wait 5 seconds for the app to finish its security checks
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
