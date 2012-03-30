//
//  DataPoint.h
//  Traffic Sense
//
//  Created by Alex Pereira on 3/13/12.
//  Copyright (c) 2012 UBC. All rights reserved.
//

#import "MapKit/Mapkit.h"

typedef enum {
    Still,
    Walk,
    Run,
    Bike,
    Bus,
    Drive,
    ERROR
} TransportType;

@interface DataPoint : NSObject <MKAnnotation> {
    CLLocationCoordinate2D coordinate;
    NSString *title;
    NSString *subtitle;
}

@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSString *timeStamp;
@property (nonatomic) double speed;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) TransportType transportMode;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;


+ (DataPoint *)dataPointWithID:(NSString *)userID latitude:(double)lat longitude:(double)lng speed:(double)sp timeStamp:(NSString *)time transportMode:(NSString *)mode;

- (void)printToConsole;


@end
