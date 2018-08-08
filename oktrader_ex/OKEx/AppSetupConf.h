//
//  AppSetupConf.h
//  OKEx
//
//  Created by 金小白 on 2018/6/28.
//  Copyright © 2018年 OKEx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AppSetupConf : NSObject

/**
 * Setup All Config
 */
+ (void)setupAllConf;

+ (void)setupNecessaryReq;
+ (void)setupRootVC;
+ (void)configEnvironment;

//System Method Proxy
+ (void)applicationDidBecomeActive:(UIApplication *)application;
+ (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;
+ (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options;

@end
