//
//  ARVSCaptureViewController.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 22/12/11.
//  Copyright, 2011, by Samuel G. D. Williams.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import "ARVideoFrameController.h"
#import "ARVSGraphView.h"

@class ARVSLogger;

double length(CMAcceleration vector);

typedef CMAcceleration ARVSVelocity;

@interface ARVSCaptureViewController : UIViewController <ARVideoFrameControllerDelegate, CLLocationManagerDelegate> {
	ARVSLogger * _logger;
	
	NSUInteger _frameOffset;
	
	NSOperationQueue * _motionQueue;
	CMMotionManager * _motionManager;
	
	UITextView * _velocityTextView;
	ARVSGraphView * _graphView;

	NSTimeInterval _timestampOffset;
}

@property(nonatomic,retain) CLLocationManager * locationManager;
@property(nonatomic,retain) ARVSLogger * logger;

@end
