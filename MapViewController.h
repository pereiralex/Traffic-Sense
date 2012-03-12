//
//  MapViewController.h
//  Traffic Sense(new)
//
//  Created by Alex Pereira on 3/11/12.
//  Copyright (c) 2012 UBC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "Mapkit/MapKit.h"
#import "CoreLocationController.h"
#import "SenseTecnicManager.h"
#import "SetupViewController.h"
#import "Timer.h"
#import "AppDelegate.h"

@interface MapViewController : UIViewController <CoreLocationControllerDelegate, MKMapViewDelegate >


@property (nonatomic, strong) IBOutlet MKMapView *myMapView;
@property (nonatomic, strong) CoreLocationController *locationController;
@property (nonatomic, strong) Timer *locationTimer;
@property (nonatomic, strong) Timer *statusLightTimer;
@property (nonatomic, strong) CLLocation *lastKnownLocation;
@property (nonatomic) BOOL statusLightState;
@property (weak, nonatomic) IBOutlet UIImageView *statusLight;

typedef enum {
    Still,
    Walk,
    Run,
    Bike,
    Bus,
    Drive
} TransportType;

@end