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
#import "PathLine.h"

@interface MapViewController : UIViewController <CoreLocationControllerDelegate, MKMapViewDelegate >


//UUID
@property (nonatomic, strong) NSString *myUUID;

//state
@property (nonatomic) BOOL backgroundMode;
@property (nonatomic, strong) CLLocation *lastKnownLocation;
@property (nonatomic, strong) CLHeading *lastKnownHeading;
@property (nonatomic) BOOL statusLightState;
@property (nonatomic, strong) NSMutableArray *latestAccelData;
@property (nonatomic, strong) NSMutableArray *latestSpeedData;
@property (nonatomic) double latestAccelerometerVariance;
@property (nonatomic) TransportType currentInferredTransportType;
@property (nonatomic) TransportType previousInferredTransportType;
@property (nonatomic) TransportType userEnteredTransportType;
@property (nonatomic, strong) NSArray *senseTecnicDataPoints;
@property (nonatomic, strong) NSArray *currrentMapAnnotations;
@property (nonatomic) int consecutiveStillCount;
@property (nonatomic, strong) NSMutableArray *recentTransportTypeLog;

//map overlays
@property (nonatomic, strong) PathLine *myPathLine;
@property (nonatomic, strong) MKPolyline *currentPolylineOverlay;

//timers
@property (nonatomic, strong) Timer *locationTimer;
@property (nonatomic, strong) Timer *oneSecondTimer;

//sensor managers
@property (nonatomic, strong) CoreLocationController *locationController;
@property (nonatomic, strong) CMMotionManager *myMotionManager;

//data managers
@property (nonatomic, strong) UIManagedDocument *database;
@property (nonatomic, strong) SenseTecnicManager *senseTechnicManager; 

//UI outlets
@property (weak, nonatomic) IBOutlet UIImageView *statusLight;
@property (nonatomic, weak) IBOutlet MKMapView *myMapView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *inferredTransportSegControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *userEnteredTransportSegControl;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *locateMeButton;
@property (weak, nonatomic) IBOutlet UIToolbar *statusToolbar;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;


@end