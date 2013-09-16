//
//  ARVSCaptureViewController.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 22/12/11.
//  Copyright, 2011, by Samuel G. D. Williams.
//

#import "ARVSCaptureViewController.h"
#import "ARVSCaptureView.h"
#import "ARVSLogger.h"

#include <sys/sysctl.h>

double length(CMAcceleration vector) {
	return sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z);
}

@implementation ARVSCaptureViewController

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Logging callbacks

- (void)videoFrameController:(ARVideoFrameController *)controller didCaptureFrame:(CGImageRef)buffer atTime:(CMTime)time {	
	if (self.logger) {
		NSLog(@"Saving frame %d", _frameOffset);
		
		[self.logger logWithFormat:@"Frame, %0.4f, %d", CMTimeGetSeconds(time), _frameOffset];
		[self.logger logImage:buffer withFormat:@"%d", _frameOffset];
		
		_frameOffset += 1;
	}
}

#pragma mark - View lifecycle

- (void)loadView {	
	// Standard view size for iOS UIWindow:
	CGRect frame = CGRectMake(0, 0, 320, 480);
	
	// Initialize the OpenGL view:
	ARVSCaptureView * captureView = [[ARVSCaptureView alloc] initWithFrame:frame];
	[captureView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
	
	[captureView.videoFrameController setDelegate:self];
	
	// A switch to control logging:
	UISwitch * toggleLogging = [[UISwitch alloc] initWithFrame:CGRectMake(10, 10, 100, 40)];
	[toggleLogging setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin];
	[toggleLogging addTarget:self action:@selector(toggleLogging:) forControlEvents:UIControlEventValueChanged];
	[captureView addSubview:toggleLogging];

	_graphView = [[ARVSGraphView alloc] initWithFrame:CGRectMake(10, 50, frame.size.width - 20, 80)];
	[_graphView setSequenceCount:3];
	
	[_graphView setColor:[UIColor redColor] ofSequence:0];
	[_graphView setColor:[UIColor greenColor] ofSequence:1];
	[_graphView setColor:[UIColor blueColor] ofSequence:2];
	
	[_graphView setPointCount:(frame.size.width - 20) / 3];
	_graphView.scale = 100.0;
	
	[captureView addSubview:_graphView];
	
	[self setView:captureView];
}

- (NSString *)machineName
{
	size_t nameLength = 1024;
	char name[nameLength];

	int request[] = {CTL_HW,HW_MACHINE};
	sysctl(request, 2, name, &nameLength, NULL, 0);
	
	return [NSString stringWithUTF8String:name];
}

- (void)toggleLogging:(UISwitch*)sender {
	if ([sender isOn]) {
		_frameOffset = 0;

		self.logger = [ARVSLogger loggerForDocumentName:@"VideoStream"];

		UIDevice * device = [UIDevice currentDevice];

		// Log device specific details:
		[self.logger logWithFormat:@"Device, %@, %@", device.name, self.machineName];
		[self.logger logWithFormat:@"Motion Rate, %0.4f", _motionManager.deviceMotionUpdateInterval];
	} else {
		[self.logger close];
		[self setLogger:nil];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	NSLog(@"ARBrowserViewController: Resuming Rendering.");
	
	ARVSCaptureView * captureView = (ARVSCaptureView*)[self view];
	
	[captureView startRendering];
	
	[super viewDidAppear:animated];
	
	if (!_motionQueue) {
		_motionQueue = [NSOperationQueue mainQueue];
		//_motionQueue = [[NSOperationQueue alloc] init];
	}
	
	if (!_motionManager) {
		_motionManager = [[CMMotionManager alloc] init];

		// Device sensor frame rate:
		NSTimeInterval rate = 1.0 / 30.0;
		
		[_motionManager setAccelerometerUpdateInterval:rate];
		[_motionManager setDeviceMotionUpdateInterval:rate];
		_previousTime = -1;
	}
	
	[_motionManager startAccelerometerUpdatesToQueue:_motionQueue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
		CMAcceleration acceleration = accelerometerData.acceleration;
		
		CGFloat points[3] = {acceleration.x, acceleration.y, acceleration.z};
		//CGFloat points[3] = {rotation.x, rotation.y, rotation.z};
		[_graphView addPoints:points];
	}];
	
	[_motionManager startDeviceMotionUpdatesToQueue:_motionQueue withHandler:^(CMDeviceMotion *motion, NSError *error) {
		CMAcceleration acceleration = motion.userAcceleration;
		CMAcceleration gravity = motion.gravity;
		CMRotationRate rotation = motion.rotationRate;
				
		[self.logger logWithFormat:@"Gyroscope, %0.4f, %0.6f, %0.6f, %0.6f", motion.timestamp, rotation.x, rotation.y, rotation.z];
		[self.logger logWithFormat:@"Accelerometer, %0.4f, %0.6f, %0.6f, %0.6f", motion.timestamp, acceleration.x, acceleration.y, acceleration.z];
		[self.logger logWithFormat:@"Gravity, %0.4f, %0.6f, %0.6f, %0.6f", motion.timestamp, gravity.x, gravity.y, gravity.z];
		
		if (_previousTime == -1) {
			_previousTime = motion.timestamp;
			return;
		}
		
		NSTimeInterval delta = motion.timestamp - _previousTime;
		ARVSVelocity velocity = _currentVelocity;
		
		if (length(acceleration) > 0.1) {
			velocity.x += acceleration.x * delta;
			velocity.y += acceleration.y * delta;
			velocity.z += acceleration.z * delta;
		}
		
		_currentVelocity = velocity;
		
		[self.logger logWithFormat:@"Velocity, %0.4f, %0.6f, %0.6f, %0.6f, %0.6f", motion.timestamp, delta, velocity.x, velocity.y, velocity.z];
	}];

	NSTimeInterval uptime = [NSProcessInfo processInfo].systemUptime;
	NSTimeInterval nowTimeIntervalSince1970 = [[NSDate date] timeIntervalSince1970];
	_timestampOffset = nowTimeIntervalSince1970 - uptime;

	self.locationManager = [[CLLocationManager alloc] init];
	[self.locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
	[self.locationManager setDelegate:self];
	
	[self.locationManager setHeadingOrientation:CLDeviceOrientationPortrait];
	
	[self.locationManager startUpdatingLocation];
	[self.locationManager startUpdatingHeading];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	CLLocationCoordinate2D coordinate = newLocation.coordinate;

	NSTimeInterval timestamp = newLocation.timestamp.timeIntervalSince1970 - _timestampOffset;

	[self.logger logWithFormat:@"Location, %0.4f, %0.6f, %0.6f, %0.4f, %0.4f", timestamp, coordinate.latitude, coordinate.longitude, newLocation.horizontalAccuracy, newLocation.verticalAccuracy];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	NSTimeInterval timestamp = newHeading.timestamp.timeIntervalSince1970 - _timestampOffset;

	[self.logger logWithFormat:@"Heading, %0.4f, %0.4f, %0.4f", timestamp, newHeading.magneticHeading, newHeading.trueHeading];
}

- (void)viewWillDisappear:(BOOL)animated {
	NSLog(@"ARBrowserViewController: Pausing Rendering.");
	
	ARVSCaptureView * captureView = (ARVSCaptureView*)[self view];
	
	[captureView stopRendering];
	
	[_motionManager stopDeviceMotionUpdates];
	[_motionManager stopAccelerometerUpdates];
	
	[super viewWillDisappear:animated];
}

@end
