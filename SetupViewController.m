//
//  SetupViewController.m
//  Traffic Sense(new)
//
//  Created by Alex Pereira on 3/11/12.
//  Copyright (c) 2012 UBC. All rights reserved.
//

#import "SetupViewController.h"

@interface SetupViewController ()

@end

@implementation SetupViewController

@synthesize tripToggleButton = _tripToggleButton;
@synthesize mapButton = _mapButton;
@synthesize tripActive = _tripActive;


/*
 *  Handle IBAction events
 */

- (IBAction)tripToggleButtonPressed {

AppDelegate *myAppDelegate = [AppDelegate sharedAppdelegate];

if (!self.tripActive) {
    [self.tripToggleButton setTitle:@"Stop Trip" forState:UIControlStateNormal];
    self.tripActive = YES;
    
    [self.navigationController pushViewController:myAppDelegate.mapViewController animated:YES];
    
    self.mapButton.enabled = YES;
    [self.mapButton setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
}

else {
    
    [myAppDelegate.mapViewController viewDidUnload];
    [myAppDelegate setMapViewController:nil];
    
    [self.tripToggleButton setTitle:@"Start Trip" forState:UIControlStateNormal];
    self.tripActive = NO;
    [self.mapButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    self.mapButton.enabled = NO;
}
}

- (IBAction)mapButtonPressed {

AppDelegate *myAppDelegate = [AppDelegate sharedAppdelegate];

[self.navigationController pushViewController:myAppDelegate.mapViewController animated:YES];
}




/*
 *  Handle system events
 */

- (void)viewDidLoad
{
[super viewDidLoad];
// Do any additional setup after loading the view, typically from a nib.
NSLog(@"setup view did load");

//the state will be intentially false until the map view is instantiated
self.tripActive = NO;

}

- (void)viewDidDisappear:(BOOL)animated {

NSLog(@"setupview did dissapear");
}


- (void)viewDidUnload
{
self.tripToggleButton = nil; 
[self setMapButton:nil];
[super viewDidUnload];
// Release any retained subviews of the main view.

NSLog(@"setup view did unload");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
