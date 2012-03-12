//
//  AppDelegate.m
//  Traffic Sense(new)
//
//  Created by Alex Pereira on 3/11/12.
//  Copyright (c) 2012 UBC. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize setupViewController = _setupViewController;
@synthesize mapViewController = _mapViewController;
@synthesize navigationController = _navigationController;


- (UIViewController *)mapViewController {
    if (!_mapViewController) {
        _mapViewController = [[MapViewController alloc]initWithNibName:@"MapViewController" bundle:[NSBundle mainBundle]];
    }
    return _mapViewController;
}
 

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch
    
    self.setupViewController = [[SetupViewController alloc] initWithNibName:@"SetupViewController" bundle:[NSBundle mainBundle]];
    
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.setupViewController];
    
    //[[UIToolbar appearance ] setBackgroundImage:[UIImage imageNamed:@"NavigationBar.png"] forBarMetrics:UIBarMetricsDefault];
    
    //self.setupViewController.navigationItem.title = @"Traffic Sense";
    
    //UIBarButtonItem *setupButton = [[UIBarButtonItem alloc] initWithTitle:@"Setup"style:UIBarButtonItemStylePlain target:self action:@selector(handleSetup)];
    
    //self.setupViewController.navigationItem.backBarButtonItem.title = @"Setup";
    
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)handleSetup {
    
    //[self.navigationController pushViewController:self.setupViewController animated:YES];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

+(AppDelegate*)sharedAppdelegate
{
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

@end
