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

// --- MODERN KEYWINDOW FIX (Fixes the build error) ---
- (UIWindow *)findActiveWindow {
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

    // 1. Setup the TMC Button (Top Left)
    self.tmcButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tmcButton.frame = CGRectMake(20, 50, 80, 45);
    self.tmcButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.5 blue:1.0 alpha:0.9];
    [self.tmcButton setTitle:@"TMC" forState:UIControlStateNormal];
    self.tmcButton.layer.cornerRadius = 12;
    self.tmcButton.layer.borderWidth = 2;
    self.tmcButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.tmcButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    
    // 2. Setup the X Close Button (Top Right)
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.frame = CGRectMake(sw - 70, 50, 50, 50);
    self.closeButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.9];
    [self.closeButton setTitle:@"X" forState:UIControlStateNormal];
    self.closeButton.layer.cornerRadius = 25;
    self.closeButton.hidden = YES;
    [self.closeButton addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];

    // Add buttons to the window safely
    [[self findActiveWindow] addSubview:self.tmcButton];
    [[self findActiveWindow] addSubview:self.closeButton];

    // 3. Setup the WebView (The Menu)
    WKUserContentController *ucc = [[WKUserContentController alloc] init];
    [ucc addScriptMessageHandler:self name:@"milesBridge"];
    WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
    cfg.userContentController = ucc;

    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:cfg];
    self.webView.hidden = YES;
    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.webView];

    // --- YOUR HTML DESIGN ---
    NSString *html = @"<!DOCTYPE html><html><head><style>"
    "body { margin:0; display:flex; justify-content:center; align-items:center; background:rgba(0,0,0,0.7); font-family:sans-serif; height:100vh; }"
    ".panel { background:rgba(40,0,60,0.95); padding:20px; border-radius:20px; width:320px; color:white; text-align:center; border:2px solid #1e90ff; box-shadow:0 0 20px #1e90ff; }"
    ".tab { background:#1e90ff; border:none; color:white; padding:8px; margin:3px; border-radius:8px; cursor:pointer; font-size:12px; }"
    "select, input { width:90%; padding:10px; margin:8px 0; border-radius:8px; border:none; background:#222; color:white; }"
    ".res { max-height:80px; overflow-y:auto; background:rgba(0,0,0,0.3); margin-bottom:10px; }"
    ".item { padding:8px; cursor:pointer; border-bottom:1px solid #444; }"
    ".spawn { background:#1e90ff; border:none; width:100%; padding:14px; border-radius:12px; color:white; font-weight:bold; cursor:pointer; }"
    "</style></head><body><div class='panel'><h3>Miles TMC Menu</h3>"
    "<div class='tabs'><button class='tab' onclick='setCat(\"Melee\")'>Melee</button><button class='tab' onclick='setCat(\"Firearms\")'>Firearms</button><button class='tab' onclick='setCat(\"Special\")'>Special</button></div>"
    "<select id='loc'><option>Center</option><option>Sell Machine</option><option>Lake</option></select>"
    "<input type='text' id='search' placeholder='Search...' onkeyup='filter()'><div class='res' id='res'></div>"
    "<button class='spawn' onclick='doSpawn()'>SPAWN ITEM</button></div>"
    "<script>"
    "let sel=''; let items={Melee:['Alpha Blade','Great Sword','Stellar Swords'],Firearms:['Revolver','Shotgun','Golden Revolver'],Special:['Wicked Broom','Money Nut','Time Bomb']};"
    "function setCat(c){ window.cat=c; filter(); }"
    "function filter(){ const s=document.getElementById('search').value.toLowerCase(); const r=document.getElementById('res'); r.innerHTML=''; "
    "(items[window.cat]||[]).filter(i=>i.toLowerCase().includes(s)).forEach(i=>{ "
    "const d=document.createElement('div'); d.className='item'; d.textContent=i; "
    "d.onclick=()=>{sel=i; document.getElementById('search').value=i; r.innerHTML='';}; r.appendChild(d); }); }"
    "function doSpawn(){ if(!sel)return; window.webkit.messageHandlers.milesBridge.postMessage({item:sel, loc:document.getElementById('loc').value}); }"
    "setCat('Melee');</script></body></html>";

    [self.webView loadHTMLString:html baseURL:nil];
}

- (void)showMenu { self.webView.hidden = NO; self.closeButton.hidden = NO; }
- (void)hideMenu { self.webView.hidden = YES; self.closeButton.hidden = YES; }

- (void)userContentController:(id)ucc didReceiveScriptMessage:(WKScriptMessage *)msg {
    NSDictionary *data = msg.body;
    NSString *name = data[@"item"];
    NSString *loc = data[@"loc"];
    
    NSString *fmt = [NSString stringWithFormat:@"item_%@", [[name lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
    
    float x=0, y=2.5, z=0;
    if([loc isEqualToString:@"Sell Machine"]) { x=12.0; z=-8.0; }

    void *uStr = il2cpp_string_new([fmt UTF8String]);
    SpawnItem(uStr, 1, x, y, z, 0, 0);
}
@end

// --- Injection Hook ---
%hook UnityAppController
- (void)applicationDidBecomeActive:(id)arg {
    %orig;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        MilesTMCController *menu = [[MilesTMCController alloc] init];
        UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
        [win.rootViewController addChildViewController:menu];
        [win.rootViewController.view addSubview:menu.view];
    });
}
%end
