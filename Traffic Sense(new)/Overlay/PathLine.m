//
//  PathLine.m
//  Traffic Sense
//
//  Created by Alex Pereira on 3/20/12.
//  Copyright (c) 2012 UBC. All rights reserved.
//

#import "PathLine.h"

#define INITIAL_POINT_SPACE 1000
#define MINIMUM_DELTA_METERS 20.0

@implementation PathLine

@synthesize currentPath = _currentPath;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coord {
    
    self = [super init];
    
    if (self) {
        pointsInPath = malloc(sizeof(CLLocationCoordinate2D)*INITIAL_POINT_SPACE);
        pointsInPath[0] = coord;
        pointCount = 1;
        pointSpace = INITIAL_POINT_SPACE;
        distanceOfPath = 0.0;
        
        self.currentPath = [MKPolyline polylineWithCoordinates:pointsInPath count:1];
    }
    return self;
}

- (void)addCoordinateToPathLine:(CLLocationCoordinate2D)coor {
    
    MKMapPoint newPoint = MKMapPointForCoordinate(coor);
    MKMapPoint prevPoint = MKMapPointForCoordinate(pointsInPath[pointCount - 1]);
    CLLocationDistance metersApart = MKMetersBetweenMapPoints(newPoint, prevPoint);
    
    NSLog(@"attempting to add coordinate to path with delta: %.f", metersApart);
    
    if (metersApart > MINIMUM_DELTA_METERS) {
        NSLog(@"point added to path with delta: %.f", metersApart);
        pointsInPath[pointCount] = coor;
        pointCount++;
        
        distanceOfPath += metersApart;
        
        self.currentPath = [MKPolyline polylineWithCoordinates:pointsInPath count:pointCount];
        
        
        
        //grow points array if necessary
        if (pointCount == pointSpace)
        {
            pointSpace *= 2;
            pointsInPath = realloc(pointsInPath, sizeof(CLLocationCoordinate2D) * pointSpace);
        } 
    }
}

- (MKPolyline *)currentPathConnectedToCurrentLocation:(CLLocation *)location {
    
    if (pointCount == 0) {
        return nil;
    }
    
    if (CLLocationCoordinate2DIsValid(location.coordinate)) {
        //add the location to the tail of the path for the purpose of creating an updated polyline
        //dont increase the count as we will want to overwrite it later.
        pointsInPath[pointCount] = location.coordinate;
        MKPolyline *pathWithCurrentLocation = [MKPolyline polylineWithCoordinates:pointsInPath count:(pointCount+1)];
        return pathWithCurrentLocation;
    }
    else {
        //if location is invalid, then return the most recent path.
        return self.currentPath;
    }
}

- (double)getTotalDistanceOfPath {
    return distanceOfPath;
}


- (void)dealloc
{
    free(pointsInPath);
}

@end
