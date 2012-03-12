//
//  MapViewController.m
//  Traffic Sense(new)
//
//  Created by Alex Pereira on 3/11/12.
//  Copyright (c) 2012 UBC. All rights reserved.
//

#import "MapViewController.h"

#define ACCELUPDATEINTERVAL 0.5

@implementation MapViewController

@synthesize lastKnownLocation = _lastKnownLocation;
@synthesize statusLight = _statusLight;
@synthesize myMapView = _myMapView;
@synthesize userEnteredTransportType = _userEnteredTransportType;
@synthesize locationController = _locationController;
@synthesize locationTimer = _locationTimer;
@synthesize statusLightTimer = _statusLightTimer;
@synthesize statusLightState = _statusLightState;
@synthesize myMotionManager = _myMotionManager;
@synthesize latestAccelData = _latestAccelData;
@synthesize latestSpeedData = _latestSpeedData;
@synthesize currentInferredTransportType = _currentInferredTransportType;
@synthesize previousInferredTransportType = _previousInferredTransportType;
@synthesize latestAccelerometerVariance = _latestAccelerometerVariance;
@synthesize senseTechnicManager = _senseTechnicManager;
@synthesize database = _database;
@synthesize userEnteredTransportSegControl = _userEnteredTransportSegControl;
@synthesize inferredTransportSegControl = _inferredTransportSegControl;


/*
 *  Custom setters & getters
 */

- (CMMotionManager *)myMotionManager {
    
    if (!_myMotionManager) {
        _myMotionManager = [[CMMotionManager alloc ] init];
        _myMotionManager.accelerometerUpdateInterval = ACCELUPDATEINTERVAL;
        
        if (!_myMotionManager.accelerometerAvailable) {
            NSLog(@"No accelerometer available...");
        }
    }
    return _myMotionManager;
}

- (NSMutableArray *)latestAccelData {
    if (!_latestAccelData) {
        _latestAccelData = [[NSMutableArray alloc] init ];
    }
    return _latestAccelData;
}

- (NSMutableArray *)latestSpeedData {
    if (!_latestSpeedData) {
        _latestSpeedData = [[NSMutableArray alloc] init ];
    }
    return _latestSpeedData;
}

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

- (void)setCurrentInferredTransportType:(TransportType)currentInferredTransportType {
    _currentInferredTransportType = currentInferredTransportType;
    self.inferredTransportSegControl.selectedSegmentIndex = currentInferredTransportType;
    
    return;
}

- (void)setUserEnteredTransportType:(TransportType)userEnteredTransportType {
    _userEnteredTransportType = userEnteredTransportType;
    NSLog(@"User input transport type changed");
}

/*
 *  Helper functions
 */

- (double)getMagnitudeFromAccelerometerData:(CMAccelerometerData *)data {
    // returns 100*sqrt(x^2 + y^2 + z^2) where 100 is amplifying factor (strictly for ease of intepretation)
    
    double magtitude =  100*sqrt(pow(data.acceleration.x, 2) + pow(data.acceleration.y, 2) + pow(data.acceleration.z, 2) ); 
    
    return magtitude;
    
}

- (double)getMeanFromArray:(NSArray *)array {
    // this method assumes the array contains only NSNumbers
    
    if (array.count == 0) {
        return 0;
    }
    
    double total = 0;
    
    for (int i = 0; i < array.count; i++) {
        total = total + [[array objectAtIndex:i] doubleValue];
    }
    
    return total / array.count;
}

- (double)getVarianceFromArray:(NSArray *)array {
    
    if (array.count == 0)
        return 0;
    
    double mean = [self getMeanFromArray:array];
    
    double sumOfDifferencesSquared = 0;
    
    for (int i = 0; i < array.count; i++) {
        sumOfDifferencesSquared = sumOfDifferencesSquared + pow( ( [[array objectAtIndex:i] doubleValue] - mean), 2 );
    }
    
    return sumOfDifferencesSquared / array.count;
}

- (NSString *)getFormattedDate {
    
    NSDate *currentTime = [NSDate date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [dateFormatter stringFromDate:currentTime];
    
    return timeString;
}

- (NSString *)getFormattedTransportType:(TransportType)transportType {
    
    switch (transportType) {
        case 0:
            return @"Still";
        case 1:
            return @"Walk";
        case 2:
            return @"Run";
        case 3:
            return @"Bike";
        case 4:
            return @"Drive";
        case 5:
            return @"Bus";
        default:
            return @"Error: Invalid transport type.";
    }
}

/*
 *  Data analysis / transport algorithm
 */

- (void)analyzeData {
    
    NSArray *accelData = [self.latestAccelData copy];
    NSArray *speedData = [self.latestSpeedData copy];
    double speed = self.lastKnownLocation.speed;
    double avgSpeed = [self getMeanFromArray:self.latestSpeedData];
    double accelVariance = [self getVarianceFromArray:accelData];
    double speedVariance = [self getVarianceFromArray:speedData];
    TransportType newTransportMode;
    
    self.latestAccelerometerVariance = accelVariance;
    /*
    NSLog(@"The variance is: %.2f", accelVariance);
    self.speedVarLabel.text = [NSString stringWithFormat:@"%.2f", speedVariance];
    self.accelVarLabel.text = [NSString stringWithFormat:@"%.2f", accelVariance];
    self.speedMeanLabel.text = [NSString stringWithFormat:@"%.2f", avgSpeed];
    */
    
    //over 40 km/h : Drive or Bus
    if (speed > 11 && speedVariance < 5) {
        //assume drive, not smart enough yet
        newTransportMode = Drive;
    }
    
    //ensure no speed and very little acceloremeter
    else if (speed <= 0 && accelVariance < 150) {
        newTransportMode = Still;
    }
    
    //not still, but don't know new mode of transport
    //resort to last known mode
    else if (speed <= 0 && accelVariance >= 150) {
        if (self.currentInferredTransportType == Still) {
            newTransportMode = self.previousInferredTransportType;
        }
        else {
            newTransportMode = self.currentInferredTransportType;
        }
    }
    
    //speed is < 4.5 km/h and low speed variance
    else if (avgSpeed > 0 && avgSpeed < 1.5 && speedVariance < 0.5 ) {
        newTransportMode = Walk;
    }
    
    //no speed (no gps), therefore rely on subtle accelerometer movement
    else if (speed <= 0 && accelVariance >= 1 && avgSpeed < 1.5 ) {
        newTransportMode = Walk;
    }
    
    else if (avgSpeed > 1.25 && avgSpeed < 4 && accelVariance > 2000) {
        newTransportMode = Run;
    }
    
    else if (avgSpeed > 2 && avgSpeed < 15 && accelVariance > 5000 ) {
        newTransportMode = Bike;
    }
    
    else if (avgSpeed > 5 && speedVariance > 6 && accelVariance > 8) {
        newTransportMode = Bus;
    }
    
    else if (avgSpeed > 4 && speedVariance < 10) {
        newTransportMode = Drive;
        
    }
    
    //slow car
    else if (speed < 1.5 && avgSpeed >= 2) {
        newTransportMode = Drive;
    }
    
    if (newTransportMode != self.currentInferredTransportType) {
        self.previousInferredTransportType = self.currentInferredTransportType;
        self.currentInferredTransportType = newTransportMode;
    }
    
    return;
    
}


/*
 *  Location event handling
 */

- (void)locationUpdate:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    self.lastKnownLocation = newLocation;
    [self.locationTimer resetTimer];
    
    [self updateMap];
    
}

- (void)locationError:(NSError *)error {
    NSLog(@"Core Location error...");
}


/*
 *  Motion event handling
 */

- (void)startMyMotionDetect
{
    [self.myMotionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init] withHandler:^(CMAccelerometerData *data, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Collecting data
            
            double magnitude = [self getMagnitudeFromAccelerometerData:data];
            
            //add newest reading to front of array and remove oldest reading
            [self.latestAccelData insertObject:[NSNumber numberWithDouble:magnitude] atIndex:0];
            
            if (self.latestAccelData.count > 5) {
                [self.latestAccelData removeLastObject];
            }
            
            [self analyzeData];
            
        });
    }
     ];
}

/*
 *  Map-related methods
 */

- (void)updateMap {
    
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
 *  UI-event handling
 */

- (IBAction)userEnteredTransportTypeChanged:(UISegmentedControl *)sender {
    
    self.userEnteredTransportType = 1 + sender.selectedSegmentIndex;
}

/*
 *  Data handling
 */

- (void)sendDataToSenseTecnic {
    
    static int count = 0;
    count++;
    
    if (count < 6)
        return;
    else
        count = 0;
    
    NSString *latitude = [NSString stringWithFormat:@"%f", self.lastKnownLocation.coordinate.latitude];
    NSString *longitude = [NSString stringWithFormat:@"%f", self.lastKnownLocation.coordinate.longitude];
    NSString *speed = [NSString stringWithFormat:@"%f", self.lastKnownLocation.speed];
    NSString *accelVariance = [NSString stringWithFormat:@"%f", self.latestAccelerometerVariance];
    NSString *inferredTransportType = [self getFormattedTransportType:self.currentInferredTransportType];
    NSString *userInputTransportType = [self getFormattedTransportType:self.userEnteredTransportType];
    
    
    NSString *message = [NSString stringWithFormat:@"lat=%@&lng=%@&value=%@&accel=%@&inferred-mode=%@&actual-mode=%@&speed=%@", latitude, longitude, speed, accelVariance, inferredTransportType, userInputTransportType, speed];
    
    [self.senseTechnicManager sendDataToSenseTecnic:[message dataUsingEncoding:NSASCIIStringEncoding]];
    
}


- (void)recordToDatabase {
    
    if (!self.lastKnownLocation) {
        //ignore if location unknown
        return;
    }
    
    AppDelegate *appDelegate = [AppDelegate sharedAppdelegate];
    
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSManagedObject *newPoint;
    newPoint = [NSEntityDescription insertNewObjectForEntityForName:@"Point" inManagedObjectContext: context];
    
    [newPoint setValue:[self getFormattedTransportType:self.currentInferredTransportType] forKey:@"inferredTransportMode"];
    [newPoint setValue:[self getFormattedTransportType:self.userEnteredTransportType] forKey:@"actualTransportMode"];
    [newPoint setValue:[NSNumber numberWithDouble:self.lastKnownLocation.coordinate.longitude] forKey:@"longitude"];
    [newPoint setValue:[NSNumber numberWithDouble:self.lastKnownLocation.coordinate.latitude] forKey:@"latitude"];
    [newPoint setValue:[NSNumber numberWithDouble:self.lastKnownLocation.speed] forKey:@"speed"];
    [newPoint setValue:[NSNumber numberWithDouble:[self getMeanFromArray:self.latestSpeedData]] forKey:@"recentAvgSpeed"];
    [newPoint setValue:[NSNumber numberWithDouble:[self getVarianceFromArray:self.latestSpeedData]] forKey:@"recentSpeedVariance"];
    [newPoint setValue:[self getFormattedDate] forKey:@"time"];
    [newPoint setValue:[NSNumber numberWithDouble:self.latestAccelerometerVariance] forKey:@"accelVariance"];
    
    NSError *error;
    [context save:&error];
    
    NSLog(@"Data added to database..");
    
    [self sendDataToSenseTecnic];
    
}


/*
 *  Handle timer update
 */

- (void)locationTimerFired {
    [self forceLocationUpdate];
}

- (void)statusLightTimerFired {
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


/*
 *  System initializers and event handling
 */

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
    self.inferredTransportSegControl = nil;
    self.userEnteredTransportSegControl = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    NSLog(@"MapView did unload...");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end