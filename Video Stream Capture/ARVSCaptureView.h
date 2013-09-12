//
//  ARVSCaptureView.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 30/01/12.
//  Copyright, 2012, by Samuel G. D. Williams.
//

#import <Foundation/Foundation.h>

#import "ARGLView.h"
#import "ARVSCaptureViewController.h"

@class ARVideoFrameController, ARVideoBackground, ARVSLocationController;

@interface ARVSCaptureView : ARGLView {
	ARVideoFrameController * videoFrameController;
	ARVideoBackground * videoBackground;
	
	UITextView * velocityTextView;
	
	ARVSLocationController * locationController;
}

@property(nonatomic,strong) ARVideoFrameController * videoFrameController;

@end
