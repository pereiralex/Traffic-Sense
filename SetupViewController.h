//
//  SetupViewController.h
//  Traffic Sense(new)
//
//  Created by Alex Pereira on 3/11/12.
//  Copyright (c) 2012 UBC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface SetupViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *tripToggleButton;
@property (weak, nonatomic) IBOutlet UIButton *mapButton;
@property (nonatomic) BOOL tripActive;

@end
