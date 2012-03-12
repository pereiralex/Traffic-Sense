//
//  AppDelegate.h
//  Traffic Sense(new)
//
//  Created by Alex Pereira on 3/11/12.
//  Copyright (c) 2012 UBC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SetupViewController.h"
#import "MapViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) UIViewController *setupViewController;
@property (strong, nonatomic) UIViewController *mapViewController;

+(AppDelegate*)sharedAppdelegate;

@end
