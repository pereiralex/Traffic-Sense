//
//  MapViewController.m
//  Traffic Sense(new)
//
//  Created by Alex Pereira on 3/11/12.
//  Copyright (c) 2012 UBC. All rights reserved.
//

#import "MapViewController.h"

#define ACCELUPDATEINTERVAL 0.5
#define NOTIFICATIONPERIOD 1800 //aprox. 15mins
#define FORCELOCATIONUPDATEPERIOD 20

@implementation MapViewController


@synthesize lastKnownLocation = _lastKnownLocation;
@synthesize lastKnownHeading = _lastKnownHeading;
@synthesize statusLight = _statusLight;
@synthesize myMapView = _myMapView;
@synthesize userEnteredTransportType = _userEnteredTransportType;
@synthesize locationController = _locationController;
@synthesize locationTimer = _locationTimer;
@synthesize oneSecondTimer = _oneSecondTimer;
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
@synthesize locateMeButton = _locateMeButton;
@synthesize statusToolbar = _statusToolbar;
@synthesize distanceLabel = _distanceLabel;
@synthesize inferredTransportSegControl = _inferredTransportSegControl;
@synthesize myUUID = _myUUID; 
@synthesize senseTecnicDataPoints = _senseTecnicDataPoints;
@synthesize currrentMapAnnotations = _currrentMapAnnotations;
@synthesize consecutiveStillCount = _consecutiveStillCount;
@synthesize myPathLine = _myPathLine;
@synthesize currentPolylineOverlay = _currentPolylineOverlay;
@synthesize backgroundMode = _backgroundMode;
@synthesize recentTransportTypeLog = _recentTransportTypeLog;

/*
 *  Custom setters & getters
 */

- (NSString *)myUUID {
    
    if (!_myUUID) {
        //retrieve UUID from user defaults
        _myUUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"UUID"];
        
        if (!_myUUID) {
            NSLog(@"UUID not found, creating one..");
            CFUUIDRef theUUID = CFUUIDCreate(NULL);
            CFStringRef UUIDstring = CFUUIDCreateString(NULL, theUUID);
            NSString *UUID = [NSString stringWithFormat:@"%@", UUIDstring];
            [[NSUserDefaults standardUserDefaults] setValue:UUID forKey:@"UUID"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            CFRelease(theUUID);
            _myUUID = UUID;
        }
    }
    //NSLog(@"UUID:%@", _myUUID);
    return _myUUID;
}

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

- (SenseTecnicManager *)senseTechnicManager {
    if (!_senseTechnicManager) {
        _senseTechnicManager = [SenseTecnicManager senseTechnicManagerWithSensorName:@"transportation_mode"];
    }
    return _senseTechnicManager;
}

- (CoreLocationController *)locationController {
    if (!_locationController) {
        _locationController = [[CoreLocationController alloc] init];
        if (!_locationController) {
            NSLog(@"Location services disabled by user...");
        }
        _locationController.delegate = self;
        _locationController.locManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationController.locManager.distanceFilter = 0;
    }
    return _locationController;
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

- (NSMutableArray *)recentTransportTypeLog {
    if (!_recentTransportTypeLog) {
        NSNumber *zero = [NSNumber numberWithInt:0];
        _recentTransportTypeLog = [[NSMutableArray alloc] initWithObjects:zero, zero, zero, zero, zero, zero, nil];
    }
    return _recentTransportTypeLog;
}

- (void)setCurrentInferredTransportType:(TransportType)currentInferredTransportType {
    _currentInferredTransportType = currentInferredTransportType;
    
    int i = 0;
    //disable all segments
    for (i = 0; i < self.inferredTransportSegControl.numberOfSegments; i++) {
        [self.inferredTransportSegControl setEnabled:NO forSegmentAtIndex:i];
    }
    //enable the selected segment (simply for ease of viewing)
    [self.inferredTransportSegControl setEnabled:YES forSegmentAtIndex:currentInferredTransportType];
    
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
    [dateFormatter setDateFormat:@"yy-MM-dd HH:mm:ss"];
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
            return @"Bus";
        case 5:
            return @"Drive";
        default:
            return @"Error: Invalid transport type.";
    }
}

- (void)printContentsOfArrayToConsole:(NSArray *)array {
    //array must comprise solely of NSNumber objects
    
    int i;
    
    for (i = 0; i < array.count; i++) {
        NSLog(@"Index %d: %d", i, [[array objectAtIndex:i] intValue]);
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
    TransportType newTransportMode = -1;
    
    self.latestAccelerometerVariance = accelVariance;
    
    NSLog(@"The variance is: %.2f", accelVariance);
    
    

    //over 40 km/h : Drive or Bus
    if (speed > 11 && speedVariance < 4) {
        //assume drive, not smart enough yet
        newTransportMode = Drive;
        NSLog(@"::1");
    }
    
    //ensure no speed and very little acceloremeter
    else if (speed == 0 && accelVariance < 150) {
        newTransportMode = Still;
        NSLog(@"::2");
        
    }
    
    //speed is < 4.5 km/h and low speed variance
    else if (avgSpeed > 0 && avgSpeed < 1.5 && speedVariance < 2 && accelVariance > 150 ) {
        newTransportMode = Walk;
        NSLog(@"::3");
    }
    
    else if (speed <= 0 && accelVariance > 150 && accelVariance < 3500 ) {
        newTransportMode = Walk;
        NSLog(@"::3");
    }
    
    else if (avgSpeed > 0 && avgSpeed < 3.5 && accelVariance > 2000 && speed > 1.5 && speed < 3.5) {
        newTransportMode = Run;
        NSLog(@"::4");
    }
    
    else if (speed <= 0  && accelVariance > 3500) {
        newTransportMode = Run;
        NSLog(@"::5");
    }
    
    //not still, but don't know new mode of transport
    //resort to last known mode
    else if (speed <= 0 && accelVariance >= 80) {
        if (self.currentInferredTransportType == Still) {
            newTransportMode = self.previousInferredTransportType;
            NSLog(@"::6");
        }
        else {
            newTransportMode = self.currentInferredTransportType;
            NSLog(@"::7");
        }
        
    }

    //no speed (no gps), therefore rely on subtle accelerometer movement
    else if (speed <= 0 && accelVariance >= 50 && avgSpeed < 1.5 ) {
        newTransportMode = Walk;
        NSLog(@"::8");
    }
    
    else if (avgSpeed > 2 && avgSpeed < 15 && accelVariance > 2000 ) {
        newTransportMode = Bike;
        NSLog(@"::9");
    }
    
    else if (avgSpeed > 5 && avgSpeed < 15 && speed > 1 && speedVariance > 15 && accelVariance > 8) {
        newTransportMode = Bus;
        NSLog(@"::10");
    }
    
    else if (avgSpeed > 6 && speedVariance < 70 && accelVariance > 1) {
        newTransportMode = Drive;
        NSLog(@"::11");
    }
    
    //slow car
    else if (speed < 1.5 && avgSpeed >= 2) {
        newTransportMode = Drive;
        NSLog(@"::12");
    }
    
    //error case (no accel)
    if (newTransportMode == -1 ) {
        newTransportMode = Still;
        NSLog(@"::13");
    }
    
    if (newTransportMode != self.currentInferredTransportType) {
        self.previousInferredTransportType = self.currentInferredTransportType;
        self.currentInferredTransportType = newTransportMode;
        NSLog(@"::14");
        
    }
    
    if (newTransportMode == Still) {
        
        self.consecutiveStillCount++;
        if (self.consecutiveStillCount > NOTIFICATIONPERIOD) {
            self.consecutiveStillCount = 0;
            UILocalNotification *prolongedInactivityNotification = [[UILocalNotification alloc] init];
            prolongedInactivityNotification.alertBody = @"Your trip is still recording. Consider stopping your trip to preserve battery life.";
            prolongedInactivityNotification.soundName = UILocalNotificationDefaultSoundName;
            prolongedInactivityNotification.alertAction = @"open Traffic Sense";
            [[UIApplication sharedApplication] presentLocalNotificationNow:prolongedInactivityNotification];
        }
    }
    
    else {
        self.consecutiveStillCount = self.consecutiveStillCount - 100;
        if (self.consecutiveStillCount < 0) {
            self.consecutiveStillCount = 0;
        }
    }
    
    NSLog(@"Inferred transport mode: %@", [self getFormattedTransportType:newTransportMode]);
    
    [self updateRecentTransportTypeLog:self.currentInferredTransportType];
    [self analyzeRecentTransportTypeLog];
    
    return;
}


- (void)updateRecentTransportTypeLog:(TransportType)currentTransportType {
    
    int currentTransportTypeCount = [[self.recentTransportTypeLog objectAtIndex:currentTransportType] intValue ];
    currentTransportTypeCount++;
    
    [self.recentTransportTypeLog removeObjectAtIndex:currentTransportType];
    [self.recentTransportTypeLog insertObject:[NSNumber numberWithInt:currentTransportTypeCount] atIndex:currentTransportType];
}

- (TransportType)analyzeRecentTransportTypeLog {
    
    NSArray *transportTypeLog = [self.recentTransportTypeLog copy];
    
    int stillCount = [[transportTypeLog objectAtIndex:Still] intValue];
    
    int i;
    int maxTypeCount = stillCount;
    TransportType mostFrequentType = Still;
    
    for (i = 1; i < 6; i++) {
        if (maxTypeCount <= [[transportTypeLog objectAtIndex:i] intValue]) {
            maxTypeCount = [[transportTypeLog objectAtIndex:i] intValue];
            mostFrequentType = i;
        }
    }
    
    //[self printContentsOfArrayToConsole:[self.recentTransportTypeLog copy]];
    //NSLog(@"Most frequent type: %d", mostFrequentType);
    
    return mostFrequentType;
}

- (void)resetRecentTransportTypeLog {
    
    [self.recentTransportTypeLog removeAllObjects];
    
    int i;
    for (i = 0; i < 6; i++) {
        [self.recentTransportTypeLog insertObject:[NSNumber numberWithInt:0] atIndex:i];
    }
}

/*
 *  Location manager event handling
 */

- (void)locationUpdate:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    if (!CLLocationCoordinate2DIsValid(newLocation.coordinate)) {
        return;
    }
    
    self.lastKnownLocation = newLocation;
    [self.locationTimer resetTimer];
    
    if (newLocation.horizontalAccuracy > 60) {
        //NSLog(@"New location with insufficent accuracy: %.f", newLocation.horizontalAccuracy);
        return;
    }

    //NSLog(@"New location with accuracy %.f", newLocation.horizontalAccuracy);

    if (newLocation.speed > 0 || (newLocation.speed == 0 && newLocation.horizontalAccuracy <= 20) ){
        
        [self.latestSpeedData insertObject:[NSNumber numberWithDouble:newLocation.speed] atIndex:0];
        if (self.latestSpeedData.count > 10) {
            [self.latestSpeedData removeLastObject];
        }
    }
    
    if (newLocation.horizontalAccuracy < 20) {
        //if sufficiently accurate, include point in path overlay
        NSLog(@"Adding high accuracy(%.f m) point to path", newLocation.horizontalAccuracy);
        [self addPointToPath];
    }
    else {
        static int consecutiveLowAccuracyLocations = 0;
        consecutiveLowAccuracyLocations++;
        if ( (consecutiveLowAccuracyLocations > 3 && newLocation.horizontalAccuracy < 40) || (consecutiveLowAccuracyLocations > 6 && newLocation.horizontalAccuracy <= 60 )) {
            
            consecutiveLowAccuracyLocations = 0;
             NSLog(@"Adding low accuracy(%.f m) point to path", newLocation.horizontalAccuracy);
            [self addPointToPath];
        }
    }
    
    /*  
     *  In this block we manage how to handle the new location:
     *  iteration 1 - 3 : ignore and return
     *  iteration 4 : request a heading update (this is to insure an updated heading is ready for the next iteration
     *  iteration 5 : record data in database, send data to sense tecnic, & retrieve data from sense tecnic
     */
    
    static int count = 4;
    
    if (count < 4) {
        count++;
        return;
    }
    else if (count == 4) {
        if ([CLLocationManager headingAvailable]) {
            [self.locationController.locManager startUpdatingHeading];
        }
        count++;
        return;
    }
    else {
        count = 1;
        [self.senseTechnicManager retrieveDataFromSenseTecnic];
        [self recordToDatabase];
        [self sendDataToSenseTecnic];
        //once the inferred transport type has been captured, we reset the log.
        [self resetRecentTransportTypeLog];
    }
    return;
}

- (void)headingUpdate:(CLHeading *)newHeading {
    NSLog(@"new heading: %.f", newHeading.trueHeading);
    self.lastKnownHeading = newHeading;
    [self.locationController.locManager stopUpdatingHeading];
}

- (void)locationError:(NSError *)error {
    NSLog(@"Core Location error...");
}

/*
 *  Motion (accelerometer) event handling
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
    span.longitudeDelta = 0.005;
    span.latitudeDelta = 0.005;
    MKCoordinateRegion region;
    region.span = span;
    region.center = self.lastKnownLocation.coordinate;
    [self.myMapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    [self.myMapView setRegion:region animated:YES];
    
}

- (MKAnnotationView *)mapView:(MKMapView *)mV viewForAnnotation:(id <MKAnnotation>)annotation {
    
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    DataPoint *myPoint = (DataPoint *) annotation;
    NSString *defaultPinID = myPoint.title;
    
    MKPinAnnotationView *pinView = [[MKPinAnnotationView alloc]
                                    initWithAnnotation:annotation reuseIdentifier:defaultPinID];
    
    pinView.pinColor = MKPinAnnotationColorRed; 
    pinView.canShowCallout = YES;
    pinView.animatesDrop = NO;
    
    return pinView;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id < MKOverlay >)overlay {
    
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineView *lineView = [[MKPolylineView alloc] initWithPolyline:overlay];
        
        lineView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.35];
               
        return lineView;
    }
    
    else {
        return nil;
    }
}

- (void)removeStalePath {
    
    if ([self.myMapView.overlays count] == 1) {
        //no stale overlays
        return;
    }
    
    int i;
    for (i = 0; i < [self.myMapView.overlays count] - 1; i++) {
        MKPolyline *stalePath = [self.myMapView.overlays objectAtIndex:0];
        [self.myMapView removeOverlay:stalePath];
    }
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
    
    NSString *latitude = [NSString stringWithFormat:@"%f", self.lastKnownLocation.coordinate.latitude];
    NSString *longitude = [NSString stringWithFormat:@"%f", self.lastKnownLocation.coordinate.longitude];
    NSString *speed = [NSString stringWithFormat:@"%.f", self.lastKnownLocation.speed];
    NSString *heading = [NSString stringWithFormat:@"%.f", self.lastKnownHeading.trueHeading];
    //NSString *accelVariance = [NSString stringWithFormat:@"%f", self.latestAccelerometerVariance];
    NSString *inferredTransportType = [self getFormattedTransportType:[self analyzeRecentTransportTypeLog]];
    
    //NSString *userInputTransportType = [self getFormattedTransportType:self.userEnteredTransportType];
    
    //send to alex's sensor
    //NSString *message = [NSString stringWithFormat:@"lat=%@&lng=%@&speed=%@&accel=%@&inferred-mode=%@&actual-mode=%@&speed=%@", latitude, longitude, speed, accelVariance, inferredTransportType, userInputTransportType, speed];
    
    //send to ian's sensor
    NSString *message = [NSString stringWithFormat:@"lat=%@&lng=%@&value=%@&transportation_mode=%@&pid=%@&direction=%@", latitude, longitude, speed, inferredTransportType, self.myUUID, heading];
    
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
    
    [newPoint setValue:self.myUUID forKey:@"userID"];
    [newPoint setValue:[self getFormattedTransportType:[self analyzeRecentTransportTypeLog]] forKey:@"inferredTransportMode"];
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
}

- (void)addPointToPath {
    
    if (!self.myPathLine) {
        self.myPathLine = [[PathLine alloc] initWithCoordinate:self.lastKnownLocation.coordinate];
    }
    
    else {
        [self.myPathLine addCoordinateToPathLine:self.lastKnownLocation.coordinate];
    }
    
    [self.myMapView addOverlay:[self.myPathLine currentPath]];
    [self removeStalePath];
}


/*
 *  Handle timer update
 */

- (void)locationTimerFired {
    [self forceLocationUpdate];
}

- (void)forceLocationUpdate {
    [self.locationController.locManager stopUpdatingLocation];
    [self.locationController.locManager startUpdatingLocation];
    [self.locationTimer resetTimer];
}


- (void)oneSecondTimerFired {
    //fires every second
    [self statusLightTimerFired];

    if (self.myPathLine && self.backgroundMode == NO) {
        MKPolyline *polyOverlay = [self.myPathLine currentPathConnectedToCurrentLocation:self.locationController.locManager.location];
        [self.myMapView addOverlay:polyOverlay];
        [self removeStalePath];
    }
    
    self.distanceLabel.text = [NSString stringWithFormat:@"%.f m", [self.myPathLine getTotalDistanceOfPath]];
}

- (void)statusLightTimerFired {
    if (self.statusLightState)
        self.statusLight.image = [UIImage imageNamed:@"lightOFF.png"];
    else
        self.statusLight.image = [UIImage imageNamed:@"lightON.png"];
    
    self.statusLightState = !self.statusLightState;
    
}


/*
 *  Asynchronous notification handling
 */


- (void)newPointsPulledFromST {
    
    NSLog(@"(%d) new point(s) received!", [self.senseTecnicDataPoints count]);
    
    //made and add annotations
    int i = 0;
    NSMutableArray *newAnnotations = [[NSMutableArray alloc] init ];
    
    for (i = 0; i < self.senseTecnicDataPoints.count; i++) {
        DataPoint *currPoint = [self.senseTecnicDataPoints objectAtIndex:i];
        [newAnnotations addObject:currPoint];
    }

    [self.myMapView removeAnnotations:self.currrentMapAnnotations];
    [self.myMapView addAnnotations:[newAnnotations copy]];
    self.currrentMapAnnotations = [newAnnotations copy];
    
}

/*
 *  UI initializers
 */

- (void)setupUI {
    
    //build toolbar
    UIBarButtonItem *locatebutton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:100 target:self action:@selector(updateMap)];
    locatebutton.style = UIBarButtonItemStyleDone;
    
    NSArray *segItems = [NSArray arrayWithObjects:@"Still", @"Walk", @"Run", @"Bike", @"Bus", @"Drive", nil];
    UISegmentedControl *mySeg = [[UISegmentedControl alloc] initWithItems:segItems];
    mySeg.frame = CGRectMake(0, 0, 235, 30);
    mySeg.segmentedControlStyle = UISegmentedControlStyleBar;
    mySeg.selectedSegmentIndex = 0;
    mySeg.tintColor = [UIColor darkGrayColor];
    mySeg.enabled = YES;
    
    UIBarButtonItem *segControl = [[UIBarButtonItem alloc] initWithCustomView:mySeg];
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] init];
    fixedSpace.width = 12.0;
    
    [self.statusToolbar setItems:[[NSArray alloc] initWithObjects:fixedSpace, segControl, locatebutton, nil] animated:YES];
    self.inferredTransportSegControl = mySeg;
    
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


- (void)viewDidAppear:(BOOL)animated {
    self.consecutiveStillCount = 0;
}

- (void)viewDidDisappear:(BOOL)animated {
    NSLog(@"view did disapear..");
    //[self.locationTimer invalidate];
    //need to manage when we want to release view and when we dont
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"MapView did load...");
    
    [self setupUI];
    
    //start sensor detection
    [self startMyMotionDetect];
    [self.locationController.locManager startUpdatingLocation];
    [self.locationController.locManager startUpdatingHeading];
    
    //set inital state
    self.userEnteredTransportType = Walk;
    self.currentInferredTransportType = Still;
    self.previousInferredTransportType = Walk;
    self.consecutiveStillCount = 0;

    //setup MapView
    self.myMapView.delegate = self;
    self.myMapView.userTrackingMode = MKUserTrackingModeFollow;
    
    //setup timers
    SetupViewController *setupVC = (SetupViewController *) [AppDelegate sharedAppdelegate].setupViewController;
    if (setupVC.tripActive) {
        self.oneSecondTimer = [Timer timerWithInterval:1 target:self selector:@selector(oneSecondTimerFired)];
    }

    self.locationTimer = [Timer timerWithInterval:FORCELOCATIONUPDATEPERIOD target:self selector:@selector(locationTimerFired)];
    self.statusLight.image = [UIImage imageNamed:@"lightOFF.png"];
    self.statusLightState = NO;
    
    //setup notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPointsPulledFromST) name:@"newPointsNotification" object:nil];
    
    //retrieve initial data from sense technic
    [self.senseTechnicManager retrieveDataFromSenseTecnic];
}

- (void)viewDidUnload
{
    [self.myMotionManager stopAccelerometerUpdates];
    self.myMotionManager = nil;
    [self.locationController.locManager stopUpdatingLocation];
    [self.locationController.locManager stopUpdatingHeading];
    self.myMapView.delegate = nil;
    self.myMapView = nil;
    self.locationController.delegate = nil;
    self.locationController = nil;
    [self.oneSecondTimer invalidate];
    self.oneSecondTimer = nil;
    [self.locationTimer invalidate];
    self.locationTimer = nil;
    [self setStatusLight:nil];
    self.inferredTransportSegControl = nil;
    self.userEnteredTransportSegControl = nil;
    [self setLocateMeButton:nil];
    [self setStatusToolbar:nil];
    
    [self setDistanceLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    NSLog(@"MapView did unload...");
}


@end