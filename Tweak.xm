#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>

// --- 1. IL2CPP FUNCTION SIGNATURES ---
// These must match the game's internal addresses. 
// If you have the offsets, you would use MSHookFunction instead.
extern void *il2cpp_string_new(const char* str);
extern void SpawnItem(void *name, int amount, float x, float y, float z, float rX, float rY);

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
            for (UIWindow *window in scene.windows) {
                if (window.isKeyWindow) return window;
            }
        }
    }
    return [UIApplication sharedApplication].windows.firstObject;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // 1. TMC Button Setup
    self.tmcButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.tmcButton.frame = CGRectMake(50, 70, 80, 45); 
    self.tmcButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.5 blue:1.0 alpha:0.9];
    self.tmcButton.layer.cornerRadius = 12;
    [self.tmcButton setTitle:@"MILES" forState:UIControlStateNormal];
    self.tmcButton.layer.borderWidth = 2;
    self.tmcButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.tmcButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];

    // 2. Close Button Setup
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.frame = CGRectMake(sw - 80, 70, 50, 50);
    [self.closeButton setTitle:@"✕" forState:UIControlStateNormal];
    self.closeButton.backgroundColor = [UIColor redColor];
    self.closeButton.layer.cornerRadius = 25;
    self.closeButton.hidden = YES;
    [self.closeButton addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [self findActiveWindow];
        [win addSubview:self.tmcButton];
        [win addSubview:self.closeButton];
    });

    // 3. Setup WebView
    WKUserContentController *ucc = [[WKUserContentController alloc] init];
    [ucc addScriptMessageHandler:self name:@"milesBridge"];
    
    WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
    cfg.userContentController = ucc;
    cfg.allowsInlineMediaPlayback = YES;

    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:cfg];
    self.webView.hidden = YES;
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.opaque = NO;
    [self.view addSubview:self.webView];

    NSString *html = @"<!DOCTYPE html><html><head><style>"
        "body{margin:0;display:flex;justify-content:center;align-items:center;background:rgba(30,0,50,0.96);font-family:sans-serif;height:100vh;}"
        ".panel{border:2px solid #1e90ff;padding:15px;border-radius:20px;text-align:center;color:white;width:350px;box-shadow:0 0 25px #1e90ff;}"
        ".tab{background:#1e90ff;border:none;color:white;padding:5px;margin:2px;border-radius:6px;font-size:10px;font-weight:bold;}"
        "select,input{width:90%;padding:10px;margin:5px 0;border-radius:8px;background:#222;color:white;border:none;}"
        ".res{max-height:120px;overflow-y:auto;background:rgba(0,0,0,0.4);margin-bottom:10px;}"
        ".item{padding:8px;border-bottom:1px solid #444;font-size:13px;text-align:left;}"
        ".spawn{background:#1e90ff;border:none;width:100%;padding:15px;border-radius:12px;color:white;font-weight:bold;font-size:16px;}"
        "</style></head><body><div class='panel'><h3>Miles TMC: Spawner</h3>"
        "<div class='tabs'>"
        "<button class='tab' onclick='setCat(\"Melee\")'>Melee</button>"
        "<button class='tab' onclick='setCat(\"Guns\")'>Guns</button>"
        "<button class='tab' onclick='setCat(\"Fishing\")'>Fishing</button></div>"
        "<select id='loc'><option>Center</option><option>Lake</option><option>Megalodon Cave</option></select>"
        "<input type='text' id='search' placeholder='Search...' onkeyup='filter()'><div class='res' id='res'></div>"
        "<button class='spawn' onclick='doSpawn()'>SPAWN ITEM</button></div>"
        "<script>"
        "let sel=''; let items={Melee:['Alpha Blade','Great Sword','Yeetblade'],Guns:['Revolver','AK47','Rocket Launcher'],Fishing:['Lava Fishing Rod','Diamond Fish']};"
        "function setCat(c){ window.cat=c; filter(); }"
        "function filter(){ const s=document.getElementById('search').value.toLowerCase(); const r=document.getElementById('res'); r.innerHTML=''; "
        "(items[window.cat]||[]).forEach(i=>{ if(i.toLowerCase().includes(s)){ const d=document.createElement('div'); d.className='item'; d.textContent=i; "
        "d.onclick=()=>{sel=i; document.getElementById('search').value=i; r.innerHTML='';}; r.appendChild(d); } }); }"
        "function doSpawn(){ if(!sel)return; window.webkit.messageHandlers.milesBridge.postMessage({item:sel, loc:document.getElementById('loc').value}); }"
        "setCat('Melee');</script></body></html>";

    [self.webView loadHTMLString:html baseURL:nil];
}

- (void)showMenu {
    self.webView.hidden = NO;
    self.closeButton.hidden = NO;
    self.tmcButton.hidden = YES;
}

- (void)hideMenu {
    self.webView.hidden = YES;
    self.closeButton.hidden = YES;
    self.tmcButton.hidden = NO;
}

- (void)userContentController:(id)ucc didReceiveScriptMessage:(WKScriptMessage *)msg {
    NSDictionary *data = msg.body;
    NSString *name = data[@"item"];
    NSString *loc = data[@"loc"];

    // ID Auto-Corrector
    NSString *fmt;
    if ([name isEqualToString:@"CEO Big Brain"]) { fmt = @"ceo_big_brain_prop"; }
    else if ([name isEqualToString:@"Wicked Broom"]) { fmt = @"dev_broom_wicked"; }
    else {
        fmt = [NSString stringWithFormat:@"item_%@", [[name lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
    }

    float x=0, y=3.5, z=0;
    if([loc isEqualToString:@"Lake"]) { x=-45.0; z=20.0; }
    if([loc isEqualToString:@"Megalodon Cave"]) { x=200.0; y=-15.0; z=50.0; }

    // Use Main Queue for Unity interactions to avoid threading crashes
    dispatch_async(dispatch_get_main_queue(), ^{
        void *uStr = il2cpp_string_new([fmt UTF8String]);
        if (uStr != NULL) {
            SpawnItem(uStr, 1, x, y, z, 0, 0);
        }
    });
}
@end

// --- 2. HOOKS ---
%hook UnityAppController
- (void)applicationDidBecomeActive:(id)arg1 {
    %orig;
    if (objc_getAssociatedObject(self, kInjected)) return;
    objc_setAssociatedObject(self, kInjected, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        MilesTMCController *menu = [[MilesTMCController alloc] init];
        UIWindow *win = [UIApplication sharedApplication].windows.firstObject;
        [win.rootViewController addChildViewController:menu];
        [win.rootViewController.view addSubview:menu.view];
    });
}
%end
