//
//  DataPoint.m
//  Traffic Sense
//
//  Created by Alex Pereira on 3/13/12.
//  Copyright (c) 2012 UBC. All rights reserved.
//

#import "DataPoint.h"

@implementation DataPoint

@synthesize userID = _userID;
@synthesize speed = _speed;
@synthesize coordinate = _coordinate;
@synthesize transportMode = _transportMode;
@synthesize timeStamp = _timeStamp;
@synthesize title = _title;
@synthesize subtitle = _subtitle;



+ (DataPoint *)dataPointWithID:(NSString *)userID latitude:(double)lat longitude:(double)lng speed:(double)sp timeStamp:(NSString *)time transportMode:(NSString *)mode {
    
    DataPoint *point = [[DataPoint alloc] init];
    point.userID = userID;
    point.coordinate = CLLocationCoordinate2DMake(lat, lng);
    point.speed = sp;
    point.timeStamp = time;
    point.title = mode;
    point.subtitle = [NSString stringWithFormat:@"%.f km/h", sp*3.6];
    
    if ([mode isEqualToString:@"Still"])
        point.transportMode = Still;
    else if ([mode isEqualToString:@"Walk"])
        point.transportMode = Walk;
    else if ([mode isEqualToString:@"Run"])
    point.transportMode = Run;
    else if ([mode isEqualToString:@"Bike"])
        point.transportMode = Bike;
    else if ([mode isEqualToString:@"Bus"])
        point.transportMode = Bus;
    else if ([mode isEqualToString:@"Drive"])
        point.transportMode = Drive;
    
    return point;
}

- (void)printToConsole {
    
    NSLog(@"UserID: %@", self.userID);
    NSLog(@"Speed: %.3f", self.speed);
    NSLog(@"Lat: %.3f", self.coordinate.latitude);
    NSLog(@"Long: %.3f", self.coordinate.longitude);
    NSLog(@"Time: %@", self.timeStamp);
    
}

@end
