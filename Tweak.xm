#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <substrate.h>

// --- Game Engine Hooks ---
extern "C" void SpawnItem(void *itemName, int quantity, float x, float y, float z, int colorHue, int colorSat);
extern "C" void* il2cpp_string_new(const char *str);

@interface MilesTMCController : UIViewController <WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *tmcButton;
@property (nonatomic, strong) UIButton *closeButton;
@end

@implementation MilesTMCController

// --- MODERN WINDOW FINDER (Stops iPhone 13-16 Crashes) ---
- (UIWindow *)getSafeWindow {
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

    // 1. TMC Button (Lowered for iPhone 13-16 Notch/Island)
    self.tmcButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tmcButton.frame = CGRectMake(50, 80, 80, 45); 
    self.tmcButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.5 blue:1.0 alpha:0.9];
    [self.tmcButton setTitle:@"TMC" forState:UIControlStateNormal];
    self.tmcButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.tmcButton.layer.cornerRadius = 12;
    self.tmcButton.layer.borderWidth = 2;
    self.tmcButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.tmcButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    
    // 2. X Close Button (Top Right)
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.frame = CGRectMake(sw - 80, 80, 50, 50);
    self.closeButton.backgroundColor = [UIColor redColor];
    [self.closeButton setTitle:@"X" forState:UIControlStateNormal];
    self.closeButton.layer.cornerRadius = 25;
    self.closeButton.hidden = YES;
    [self.closeButton addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];

    // Add buttons to the active window safely
    [[self getSafeWindow] addSubview:self.tmcButton];
    [[self getSafeWindow] addSubview:self.closeButton];

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

    // FULL FISHING UPDATE HTML
    NSString *html = @"<!DOCTYPE html><html><head><style>"
    "body { margin:0; display:flex; justify-content:center; align-items:center; background:rgba(35,0,55,0.95); font-family:sans-serif; height:100vh; }"
    ".panel { border:2px solid #1e90ff; padding:20px; border-radius:20px; text-align:center; color:white; width:330px; box-shadow:0 0 20px #1e90ff; }"
    ".tab { background:#1e90ff; border:none; color:white; padding:7px; margin:2px; border-radius:8px; cursor:pointer; font-size:12px; }"
    "select, input { width:90%; padding:10px; margin:8px 0; border-radius:8px; border:none; background:#222; color:white; }"
    ".res { max-height:90px; overflow-y:auto; background:rgba(0,0,0,0.3); margin-bottom:10px; }"
    ".item { padding:8px; cursor:pointer; border-bottom:1px solid #444; font-size:14px; }"
    ".spawn { background:#1e90ff; border:none; width:100%; padding:15px; border-radius:12px; color:white; font-weight:bold; cursor:pointer; }"
    "</style></head><body><div class='panel'><h3>Miles TMC Fishing</h3>"
    "<div class='tabs'><button class='tab' onclick='setCat(\"Fishing\")'>Fishing</button><button class='tab' onclick='setCat(\"Fish\")'>Fish</button><button class='tab' onclick='setCat(\"Special\")'>Special</button></div>"
    "<select id='loc'><option>Center</option><option>Lake</option><option>Megalodon Cave</option></select>"
    "<input type='text' id='search' placeholder='Search...' onkeyup='filter()'><div class='res' id='res'></div>"
    "<button class='spawn' onclick='doSpawn()'>SPAWN ITEM</button></div>"
    "<script>"
    "let sel=''; let items={Fishing:['Lava Fishing Rod','Radioactive Fishing Rod','Super Fishing Pole'],Fish:['Diamond Fish','Dragon Fish','Goldfish','Salmon'],Special:['Wicked Broom','Money Nut','Time Bomb','Clam Hook Shot']};"
    "function setCat(c){ window.cat=c; filter(); }"
    "function filter(){ const s=document.getElementById('search').value.toLowerCase(); const r=document.getElementById('res'); r.innerHTML=''; "
    "(items[window.cat]||[]).filter(i=>i.toLowerCase().includes(s)).forEach(i=>{ "
    "const d=document.createElement('div'); d.className='item'; d.textContent=i; "
    "d.onclick=()=>{sel=i; document.getElementById('search').value=i; r.innerHTML='';}; r.appendChild(d); }); }"
    "function doSpawn(){ if(!sel)return; window.webkit.messageHandlers.milesBridge.postMessage({item:sel, loc:document.getElementById('loc').value}); }"
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

// --- CRASH BYPASS HOOK (7-Second Stealth Delay) ---
%hook UnityAppController
- (void)applicationDidBecomeActive:(id)arg {
    %orig;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // WAIT 7 SECONDS: Lets all security checks pass before modding
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            MilesTMCController *menu = [[MilesTMCController alloc] init];
            UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
            if (win) {
                [win.rootViewController addChildViewController:menu];
                [win.rootViewController.view addSubview:menu.view];
            }
        });
    });
}
%end
