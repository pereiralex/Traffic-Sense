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

//custom transport type
typedef enum {
    Still,
    Walk,
    Run,
    Bike,
    Bus,
    Drive
} TransportType;

//state
@property (nonatomic, strong) CLLocation *lastKnownLocation;
@property (nonatomic) BOOL statusLightState;
@property (nonatomic, strong) NSMutableArray *latestAccelData;
@property (nonatomic, strong) NSMutableArray *latestSpeedData;
@property (nonatomic) double latestAccelerometerVariance;
@property (nonatomic) TransportType currentInferredTransportType;
@property (nonatomic) TransportType previousInferredTransportType;
@property (nonatomic) TransportType userEnteredTransportType;

//timers
@property (nonatomic, strong) Timer *locationTimer;
@property (nonatomic, strong) Timer *statusLightTimer;

//sensor managers
@property (nonatomic, strong) CoreLocationController *locationController;
@property (nonatomic, strong) CMMotionManager *myMotionManager;

//data managers
@property (nonatomic, strong) UIManagedDocument *database;
@property (nonatomic, strong) SenseTecnicManager *senseTechnicManager; 

//UI outlets
@property (weak, nonatomic) IBOutlet UIImageView *statusLight;
@property (nonatomic, strong) IBOutlet MKMapView *myMapView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *inferredTransportSegControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *userEnteredTransportSegControl;


@end