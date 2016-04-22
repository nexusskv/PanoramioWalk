//
//  AppDelegate.m
//  PanoramioWalk
//
//  Created by rost on 21.04.16.
//  Copyright © 2016 Rost Gress. All rights reserved.
//

#import "AppDelegate.h"


@interface AppDelegate ()
@property (atomic) UIBackgroundTaskIdentifier bgTask;
@property (weak, nonatomic) NSTimer *taskTimer;
@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    self.photosVC = [[PhotosViewController alloc] init];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.photosVC];
    self.window.rootViewController = self.navigationController;

    self.bgTask = UIBackgroundTaskInvalid;
        
    [self.window makeKeyAndVisible];
    return YES;
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {    
    self.bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"com.PanoramioWalk" expirationHandler:^{
        if (self.bgTask != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
            self.bgTask = UIBackgroundTaskInvalid;
        }
    }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    if (self.bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:@"updateLocationWasStarted"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
