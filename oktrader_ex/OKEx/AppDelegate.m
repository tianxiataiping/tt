//
//  AppDelegate.m
//  OKEx
//
//  Created by 金小白 on 2018/6/4.
//  Copyright © 2018年 OKEx. All rights reserved.
//

#import "AppDelegate.h"
#import "AppSetupConf.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [AppSetupConf setupAllConf];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {}

- (void)applicationDidEnterBackground:(UIApplication *)application {}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [AppSetupConf setupNecessaryReq];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [AppSetupConf applicationDidBecomeActive:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [AppSetupConf application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return [AppSetupConf application:app openURL:url options:options];
}

@end
