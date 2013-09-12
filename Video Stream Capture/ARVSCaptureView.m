//
//  ARVSCaptureView.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 30/01/12.
//  Copyright, 2012, by Samuel G. D. Williams.
//

#import "ARVSCaptureView.h"
#import "ARVideoFrameController.h"
#import "ARVideoBackground.h"

@implementation ARVSCaptureView

@synthesize videoFrameController;

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame pixelFormat:GL_RGB565_OES depthFormat:GL_DEPTH_COMPONENT16_OES preserveBackbuffer:YES];
	
	if (self) {
		videoFrameController = [[ARVideoFrameController alloc] initWithRate:10];
		videoBackground = [[ARVideoBackground alloc] init];
		
		[videoFrameController start];
	}
	
	return self;
}

- (void) update {	
	if (videoFrameController) {
		ARVideoFrame * videoFrame = [videoFrameController videoFrame];
		
		if (videoFrame && videoFrame->data) {
			[videoBackground update:videoFrame];
			
			[videoBackground draw];
			
			// Only update if we need to redraw:
			[super update];
		}
	} else {
		glClear(GL_COLOR_BUFFER_BIT);
		
		[super update];
	}
}

- (void) stopRendering
{
	[videoFrameController stop];
	
	[super stopRendering];
}

- (void) startRendering
{
	[videoFrameController start];
	
	[super startRendering];
}

- (void)dealloc
{
	[videoFrameController stop];
	
	
}

@end
