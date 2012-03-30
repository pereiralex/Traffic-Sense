//
//  PathLine.h
//  Traffic Sense
//
//  Created by Alex Pereira on 3/20/12.
//  Copyright (c) 2012 UBC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <pthread.h>

@interface PathLine : NSObject {
    CLLocationCoordinate2D *pointsInPath;
    int pointCount;
    int pointSpace;
    double distanceOfPath;
}

@property (nonatomic, strong) MKPolyline *currentPath;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coord;
- (void)addCoordinateToPathLine:(CLLocationCoordinate2D)coor;
- (MKPolyline *)currentPathConnectedToCurrentLocation:(CLLocation *)location;
- (double)getTotalDistanceOfPath;

@end
