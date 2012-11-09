//
//  AKPoint3D.h
//  AurasmaKit
//
//  Copyright 2012 Aurasma. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AKVector3D : NSObject 
{
    double x, y, z; 
}

@property (nonatomic) double x, y, z;

- (id) initWithX: (double) x_ y: (double) y_ z: (double) z;
+ (AKVector3D*) vector;
+ (AKVector3D*) vectorWithX:(double) x_ y:(double) y_ z: (double) z_;

- (double) norm;
- (void) normalize;

@end

@interface AKPoint3D : AKVector3D 
{
}

+ (AKPoint3D*) point;
+ (AKPoint3D*) pointWithX:(double) x_ y:(double) y_ z: (double) z_;

@end

@interface AKRay3D : NSObject
{
    AKPoint3D  *origin;
    AKVector3D *direction;
}

@property (nonatomic, copy) AKPoint3D *origin;
@property (nonatomic, copy) AKVector3D *direction;

- (id)initWithOrigin:(AKPoint3D*)origin direction:(AKVector3D*)direction;
+ (AKRay3D*) rayWithOrigin:(AKPoint3D*)origin direction:(AKVector3D*)direction;

- (AKPoint3D*) XYPlaneIntersection;

@end