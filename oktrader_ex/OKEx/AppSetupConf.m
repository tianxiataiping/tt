//
//  AppSetupConf.m
//  OKEx
//
//  Created by 金小白 on 2018/6/28.
//  Copyright © 2018年 OKEx. All rights reserved.
//

#import "AppSetupConf.h"
#import "AppDelegate.h"
#import <OKBusiness/OKBAgent.h>
#import <OKBusiness/OKBusiness.h>
#import <OKBusiness/OKBFuturesManager.h>
#import <OKBusiness/OKBAccountManager.h>
#import <OKBusiness/OKBExchangeRateManager.h>
#import <OKFoundation/OKFAPIRequestGenerator.h>
#import <OKFoundation/OKFSocketSubscriptionCenter.h>
#import <OKFoundation/OKFDebugAPIConfiguration.h>
#import <OKFoundation/OKFBundle.h>
#import <OKBusiness/OKBShare.h>
#import <OKBusiness/OKBETFManager.h>
#import <OKBusiness/OKBEXConfigurationManager.h>
#import <OKFoundation/OKFAnalytics.h>
#import <Bugly/Bugly.h>

extern NSString *const OKExBuglyAppID;
extern NSString *const OKExUmengAppKey;
extern NSString *const OKExUmengSecret;

@implementation AppSetupConf

+ (void)setupAllConf {
    [UIApplication sharedApplication].delegate.window.backgroundColor = [UIColor whiteColor];
    [OKBAgent registerCurrentAgent:OKBAgentTypeOKEx];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[OKFAPIRequestGenerator sharedInstance].appUserAgent, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];

    //初始化 Bugly
    [self setupBugly];
    
#ifdef DEBUG
    [AppSetupConf configEnvironment];
#else
    [AppSetupConf setupRootVC];
    [AppSetupConf setupNecessaryReq];
#endif
    
    //数据上报初始化
    [self setupAnalytics];
    
    [OKBAccountManager prepareGesture];
    //分享注册平台
    [OKBShare registerPlatforms];
    // 监听语言设置的变动
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLanguageDidChanged) name:AppLanguageDidChangedNotification object:nil];
}

+ (void)setupNecessaryReq {
    [[OKBEXConfigurationManager sharedEXConfigurationManager] forbidApp];
    [[OKBSpotVendor sharedVendor] sendProductsReq];
    [[OKBSpotVendor sharedVendor] sendCurrenciesReq];
    [[OKBSpotVendor sharedVendor] sendContractQuoteReq];
    //Request Futures Data
    [[OKBFuturesManager sharedFuturesManager] requestAllSymbol];
    [OKBETFManager sharedETFManager];
    if ([OKBAccountManager shareInstance].isLogin) {
        [[OKFAPIRequestGenerator sharedInstance] updateToken:[OKBAccountManager shareInstance].userInfo.token];
        [[OKFSocketSubscriptionCenter defaultCenter] loginEvent];
        [[OKBFuturesManager sharedFuturesManager] requestUserInfo];
        [[OKBFuturesManager sharedFuturesManager] requestFuturesCoin:[OKBFuturesManager sharedFuturesManager].futuresUserInfo.nativeCurrency.length > 0 ? [OKBFuturesManager sharedFuturesManager].futuresUserInfo.nativeCurrency : @"usd"];
    }else{
        [[OKBFuturesManager sharedFuturesManager] requestFuturesCoin:[OKBFuturesManager sharedFuturesManager].futuresUserInfo.nativeCurrency.length > 0 ? [OKBFuturesManager sharedFuturesManager].futuresUserInfo.nativeCurrency : @"usd"];
    }
}

+ (void)setupBugly {
    BuglyConfig *config = [BuglyConfig new];
    config.blockMonitorTimeout = 0.3;
    config.blockMonitorEnable = YES;
    
#if DEBUG
    [Bugly startWithAppId:@"846feaf59a" config:config];
#else
    [Bugly startWithAppId:OKExBuglyAppID config:config];
#endif
}

+ (void)setupAnalytics {
    NSMutableArray *analyticsConfigArray = [NSMutableArray array];
    
//    //OKEx HTTP
//    OKFAnalyticsConfig *httpConfig = [OKFAnalyticsConfig new];
//    httpConfig.type = OKFAnalyticsType_HTTP;
//    httpConfig.channel = @"OKEx";
//    [analyticsConfigArray addObject:httpConfig];
    
    //友盟
    OKFAnalyticsConfig *umengConfig = [OKFAnalyticsConfig new];
    umengConfig.type = OKFAnalyticsType_UMeng;
    umengConfig.channel = @"OKEx";
    umengConfig.appKey = OKExUmengAppKey;
    [analyticsConfigArray addObject:umengConfig];
    
    //初始化
    [OKFAnalytics setupWithConfigs:analyticsConfigArray];
}

+ (void)setupRootVC {
    OKBTabbarModel *homeModel = [OKBTabbarModel new];
    homeModel.title = [OKFBundle localizedStringForKey:@"TabbarHome" value:@"首页"];
    homeModel.vcName = @"OKGHomeVC";
    homeModel.normalImage = [UIImage imageNamed:@"tabbar_okex"];
    homeModel.selectImage = [UIImage imageNamed:@"tabbar_okex_s"];
    
    OKBTabbarModel *marketModel = [OKBTabbarModel new];
    marketModel.title = [OKFBundle localizedStringForKey:@"TabbarMarket" value:@"行情"];
    marketModel.vcName = @"OKGMarketVC";
    marketModel.normalImage = [UIImage imageNamed:@"tabbar_charts"];
    marketModel.selectImage = [UIImage imageNamed:@"tabbar_charts_s"];
    
    OKBTabbarModel *currencyModel = [OKBTabbarModel new];
    currencyModel.vcName = @"OKGCurrencyVC";
    currencyModel.title = [OKFBundle localizedStringForKey:@"TabbarFiat" value:@"法币"];
    currencyModel.normalImage = [UIImage imageNamed:@"tabbar_token"];
    currencyModel.selectImage = [UIImage imageNamed:@"tabbar_token_s"];
    
    OKBTabbarModel *spotModel = [OKBTabbarModel new];
    spotModel.title = [OKFBundle localizedStringForKey:@"TabbarSpot" value:@"币币"];
    spotModel.vcName = @"OKGSpotVC";
    spotModel.normalImage = [UIImage imageNamed:@"tabbar_spot"];
    spotModel.selectImage = [UIImage imageNamed:@"tabbar_spot_s"];
    
    OKBTabbarModel *futuresModel = [OKBTabbarModel new];
    futuresModel.title = [OKFBundle localizedStringForKey:@"TabbarFutures" value:@"合约"];
    futuresModel.vcName = @"OKGFuturesVC";
    futuresModel.normalImage = [UIImage imageNamed:@"tabbar_futures"];
    futuresModel.selectImage = [UIImage imageNamed:@"tabbar_futures_s"];
    
    OKBTabBarController *tabbar = [[OKBTabBarController alloc] initTabbarArray:@[homeModel, marketModel, currencyModel, spotModel, futuresModel]];
    tabbar.needForceLoginArray = @[@"OKGCurrencyVC"];
    [UIApplication sharedApplication].delegate.window.rootViewController = tabbar;
    [[UIApplication sharedApplication].delegate.window makeKeyAndVisible];
}

+ (void)onLanguageDidChanged {
    [self setupRootVC];
}

+ (void)configEnvironment {
    UIWindow *alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    alertWindow.rootViewController = [[UIViewController alloc] init];
    alertWindow.windowLevel = UIWindowLevelAlert + 1;
    [alertWindow makeKeyAndVisible];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"请选择配置环境" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [[OKFDebugAPIConfiguration defaultConfiguration].configItems enumerateObjectsUsingBlock:^(OKFDebugAPIConfigItem *item, NSUInteger idx, BOOL * _Nonnull stop) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:item.name style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[OKFDebugAPIConfiguration defaultConfiguration] setCurrentItem:item];
            [OKFSocketSubscriptionCenter defaultCenter];
            [self setupRootVC];
            [self setupNecessaryReq];
        }];
        [alertController addAction:action];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"不选了" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [OKFSocketSubscriptionCenter defaultCenter];
        [self setupRootVC];
        [self setupNecessaryReq];
    }];
    [alertController addAction:cancelAction];
    [alertWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - System Method Proxy

+ (void)applicationDidBecomeActive:(UIApplication *)application {
    [[OKBExchangeRateManager shareInstance] requesExchangeRate];
}

+ (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return NO;
}

+ (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return NO;
}

@end
