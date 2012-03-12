//
//  MapViewController.m
//  Traffic Sense(new)
//
//  Created by Alex Pereira on 3/11/12.
//  Copyright (c) 2012 UBC. All rights reserved.
//

#import "MapViewController.h"

@interface MapViewController ()

@end

@implementation MapViewController

@synthesize lastKnownLocation = _lastKnownLocation;
@synthesize statusLight = _statusLight;
@synthesize myMapView = _myMapView;
@synthesize locationController = _locationController;
@synthesize locationTimer = _locationTimer;
@synthesize statusLightTimer = _statusLightTimer;
@synthesize statusLightState = _statusLightState;


/*
 *  Custom setters & getters
 */

- (CoreLocationController *)locationController {
    if (!_locationController) {
        _locationController = [[CoreLocationController alloc] init];
        if (!_locationController) {
            NSLog(@"Location services disabled by user...");
        }
        _locationController.delegate = self;
        _locationController.locManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationController.locManager.distanceFilter = kCLLocationAccuracyHundredMeters;
    }
    return _locationController;
}


/*
 *  Handle location events
 */

- (void)locationUpdate:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    //[self.timer resetTimer];
    
    //self.myTimer = [NSTimer timerWithTimeInterval:10 target:self selector:@selector(forceLocationUpdate) userInfo:nil repeats:YES];
    
    self.lastKnownLocation = newLocation;
    [self.locationTimer resetTimer];
    
    [self updateMap];
    
}

- (void)locationError:(NSError *)error {
    NSLog(@"Core Location error...");
}

/*
 *  Map-related methods
 */

- (void)updateMap {
    
    /*
     if ( !CLLocationCoordinate2DIsValid(self.lastKnownLocation.coordinate) ) {
     return;
     }
     */
    
    if (!self.lastKnownLocation) {
        return;
    }
    
    NSLog(@"updating map location..");
    
    MKCoordinateSpan span;
    span.longitudeDelta = 0.01;
    span.latitudeDelta = 0.01;
    MKCoordinateRegion region;
    region.span = span;
    region.center = self.lastKnownLocation.coordinate;
    [self.myMapView setRegion:region animated:YES];
}


/*
 *  Handle timer update
 */

- (void)locationTimerFired {
    [self forceLocationUpdate];
}

- (void)statusLightTimerFired {
    NSLog(@"light timerfired");
    
    if (self.statusLightState)
        self.statusLight.image = [UIImage imageNamed:@"lightOFF.png"];
    else
        self.statusLight.image = [UIImage imageNamed:@"lightON.png"];
    
    self.statusLightState = !self.statusLightState;
    
}

- (void)forceLocationUpdate {
    [self.locationController.locManager stopUpdatingLocation];
    [self.locationController.locManager startUpdatingLocation];
    [self.locationTimer resetTimer];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidDisappear:(BOOL)animated {
    NSLog(@"view did disapear..");
    [self.locationTimer invalidate];
    //need to manage when we want to release view and when we dont
    
    /*
     AppDelegate *delegate = [AppDelegate sharedAppdelegate];
     [delegate setMapViewController:nil];
     */
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"MapView did load...");
    
    
    SetupViewController *setupVC = (SetupViewController *) [AppDelegate sharedAppdelegate].setupViewController;
    if (setupVC.tripActive) {
        self.statusLightTimer = [Timer timerWithInterval:1 target:self selector:@selector(statusLightTimerFired)];
    }
    
    self.locationTimer = [Timer timerWithInterval:15 target:self selector:@selector(locationTimerFired)];
    
    
    self.statusLight.image = [UIImage imageNamed:@"lightOFF.png"];
    self.statusLightState = NO;
    
    if (!self.lastKnownLocation) {
        NSLog(@"Last location is NIL");
    }
    
    //setup MapView
    self.myMapView.userTrackingMode = MKUserTrackingModeFollow;
    self.title = @"Trip";
    
    
}

- (void)viewDidUnload
{
    self.myMapView.delegate = nil;
    self.myMapView = nil;
    self.locationController.delegate = nil;
    self.locationController = nil;
    [self.statusLightTimer invalidate];
    self.statusLightTimer = nil;
    [self.locationTimer invalidate];
    self.locationTimer = nil;
    
    [self setStatusLight:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    NSLog(@"MapView did unload...");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end