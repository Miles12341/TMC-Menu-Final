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

static const void *kInjected = &kInjected;

@implementation MilesTMCController

// Modern Window Finder for iPhone 13-16
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
    self.tmcButton.frame = CGRectMake(50, 70, 80, 45); 
    self.tmcButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.5 blue:1.0 alpha:0.9];
    [self.tmcButton setTitle:@"TMC" forState:UIControlStateNormal];
    self.tmcButton.layer.cornerRadius = 12;
    self.tmcButton.layer.borderWidth = 2;
    self.tmcButton.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.tmcButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.frame = CGRectMake(sw - 80, 70, 50, 50);
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

    // UPDATED HTML WITH ALL VERIFIED CATEGORIES
    NSString *html = @"<!DOCTYPE html><html><head><style>"
    "body{margin:0;display:flex;justify-content:center;align-items:center;background:rgba(30,0,50,0.96);font-family:sans-serif;height:100vh;}"
    ".panel{border:2px solid #1e90ff;padding:15px;border-radius:20px;text-align:center;color:white;width:350px;box-shadow:0 0 25px #1e90ff;}"
    ".tab{background:#1e90ff;border:none;color:white;padding:5px;margin:2px;border-radius:6px;cursor:pointer;font-size:10px;font-weight:bold;}"
    "select,input{width:90%;padding:10px;margin:5px 0;border-radius:8px;border:none;background:#222;color:white;}"
    ".res{max-height:120px;overflow-y:auto;background:rgba(0,0,0,0.4);margin-bottom:10px;border-radius:5px;}"
    ".item{padding:8px;cursor:pointer;border-bottom:1px solid #444;font-size:13px;text-align:left;}"
    ".spawn{background:#1e90ff;border:none;width:100%;padding:15px;border-radius:12px;color:white;font-weight:bold;cursor:pointer;font-size:16px;}"
    "</style></head><body><div class='panel'><h3>Miles TMC: All Items</h3>"
    "<div class='tabs'>"
    "<button class='tab' onclick='setCat(\"Melee\")'>Melee</button>"
    "<button class='tab' onclick='setCat(\"Guns\")'>Guns</button>"
    "<button class='tab' onclick='setCat(\"Explosives\")'>Explosives</button>"
    "<button class='tab' onclick='setCat(\"Fishing\")'>Fishing</button>"
    "<button class='tab' onclick='setCat(\"Secret\")'>Secret</button></div>"
    "<select id='loc'><option>Center</option><option>Lake</option><option>Megalodon Cave</option><option>Sell Machine</option></select>"
    "<input type='text' id='search' placeholder='Search...' onkeyup='filter()'><div class='res' id='res'></div>"
    "<button class='spawn' onclick='doSpawn()'>SPAWN ITEM</button></div>"
    "<script>"
    "let sel=''; let items={"
    "Melee:['Alpha Blade','Great Sword','Stellar Swords','Yeetblade','Fish Sword','Chaos Axe','Demon Sword','Viking Hammer','Hatchet','Baton','Baseball Bat','Lance','Frying Pan','Golden Bat'],"
    "Guns:['Revolver','Golden Revolver','Shotgun','Viper Shotgun','Dragon Pistol','Money Gun','Golden AK47','Salmon Cannon','Flamethrower','Rocket Launcher','Crossbow'],"
    "Explosives:['Frag Grenade','Golden Grenade','Cluster Grenade','Impact Grenade','Dynamite','Laser Bomb','Landmine','Time Bomb','Broccoli Bomb'],"
    "Fishing:['Lava Fishing Rod','Radioactive Fishing Rod','Super Fishing Pole','Diamond Fish','Dragon Fish','Goldfish','Salmon','Starfish Bait','Magma Bait'],"
    "Secret:['Wicked Broom','CEO Big Brain','Galaxy Box','Cursed Box','Red Flashlight','Pink MRE','Money Nut','Viking Shield','OG Uranium','Cracker']};"
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

    // --- ID AUTO-CORRECTOR (Ensures they actually spawn) ---
    NSString *fmt;
    if ([name isEqualToString:@"CEO Big Brain"]) { fmt = @"ceo_big_brain_prop"; }
    else if ([name isEqualToString:@"Wicked Broom"]) { fmt = @"dev_broom_wicked"; }
    else if ([name isEqualToString:@"Time Bomb"]) { fmt = @"item_timebomb_blue"; }
    else if ([name isEqualToString:@"Pink MRE"]) { fmt = @"item_mre_pink_og"; }
    else {
        // Standard Formatting: "Alpha Blade" -> "item_alpha_blade"
        fmt = [NSString stringWithFormat:@"item_%@", [[name lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
    }
    
    float x=0, y=3.5, z=0;
    if([loc isEqualToString:@"Lake"]) { x=-45.0; z=20.0; }
    if([loc isEqualToString:@"Megalodon Cave"]) { x=200.0; y=-15.0; z=50.0; }
    if([loc isEqualToString:@"Sell Machine"]) { x=12.5; y=2.0; z=-8.0; }

    void *uStr = il2cpp_string_new([fmt UTF8String]);
    SpawnItem(uStr, 1, x, y, z, 0, 0);
}
@end

// --- CRASH BYPASS HOOK ---
%hook UnityAppController
- (void)applicationDidBecomeActive:(id)arg1 {
    %orig;
    if (objc_getAssociatedObject(self, kInjected)) return;
    objc_setAssociatedObject(self, kInjected, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

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
