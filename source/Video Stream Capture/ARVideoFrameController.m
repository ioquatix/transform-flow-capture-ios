//
//  ARVideoFrameController.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 5/04/11.
//  Copyright, 2011, by Samuel G. D. Williams.
//

#import "ARVideoFrameController.h"

@implementation ARVideoFrameController


- init {
	return [self initWithRate:30];
}

- initWithRate:(NSUInteger)rate
{
	self = [super init];

	if (self) {
		for (NSUInteger i = 0; i < ARVideoFrameBuffers; ++i) {
			videoFrames[i].data = NULL;
			videoFrames[i].index = 0;
		}

		AVCaptureDevice * captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		
		if (captureDevice == nil) {
			NSLog(@"Couldn't acquire AVCaptureDevice!");
			
			return nil;
		}

		// Without this setting, focus tends to be very slow and cause problems.
		AVCaptureFocusMode wantedFocusMode = AVCaptureFocusModeContinuousAutoFocus;
		if ([captureDevice isFocusModeSupported: wantedFocusMode]) {
			NSError * error = nil;
			
			if ([captureDevice lockForConfiguration:&error]) {
				[captureDevice setFocusMode:wantedFocusMode];
				[captureDevice unlockForConfiguration];
			} else {
				NSLog(@"lockForConfiguration error: %@", error);

				return nil;
			}
		}

		NSError * error = nil;
		AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
		
		if (error) {
			NSLog(@"Couldn't create AVCaptureDeviceInput: %@", error);
			
			return nil;
		}
		
		// Setup the video output
		AVCaptureVideoDataOutput * captureOutput = [[AVCaptureVideoDataOutput alloc] init];		
		captureOutput.alwaysDiscardsLateVideoFrames = YES;
		
		// (1) Setup the dispatch queue
		// [captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
		
		// (2) Create a serial queue to handle the processing of our frames in the background
		dispatch_queue_t cameraQueue;
		cameraQueue = dispatch_queue_create("cameraQueue", NULL);
		[captureOutput setSampleBufferDelegate:self queue:cameraQueue];
		
		// Set the video capture mode, 32BGRA is the only universally supported output format from camera.
		[captureOutput setVideoSettings:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
			kCVPixelBufferPixelFormatTypeKey,
			nil
		]];
		
		for (NSUInteger i = 0; i < ARVideoFrameBuffers; ++i) {
			videoFrames[i].internalFormat = GL_RGBA;
			videoFrames[i].pixelFormat = GL_BGRA;
			videoFrames[i].dataType = GL_UNSIGNED_BYTE;
		}
		
		captureSession = [AVCaptureSession new];
		
		[captureSession beginConfiguration];
		
		if ([captureSession canSetSessionPreset:AVCaptureSessionPresetMedium]) {
			[captureSession setSessionPreset:AVCaptureSessionPresetMedium];
		} else if ([captureSession canSetSessionPreset:AVCaptureSessionPresetLow]) {
			[captureSession setSessionPreset:AVCaptureSessionPresetLow];
		}
		
		[captureSession addInput:captureInput];
		[captureSession addOutput:captureOutput];
		
		// Set the frame rate of the camera capture
		CMTime secondsPerFrame = CMTimeMake(1, rate);

		// iOS5 changes
		AVCaptureConnection *captureConnection = [captureOutput connectionWithMediaType:AVMediaTypeVideo];

		if ([captureConnection isVideoMinFrameDurationSupported]) {
			NSLog(@"Setting minimum frame duration = %0.3f", (1.0 / rate));
			captureConnection.videoMinFrameDuration = secondsPerFrame;
		}
		
		if ([captureConnection isVideoMaxFrameDurationSupported]) {
			NSLog(@"Setting maximum frame duration = %0.3f", (1.0 / rate));
			captureConnection.videoMaxFrameDuration = secondsPerFrame;
		}
		
		[captureSession commitConfiguration];
		
		NSLog(@"Capture Session Initialised");
	}
	
	return self;
}

- (void) dealloc {
	NSLog(@"Capture Session Deallocated");
	
	[self stop];
	
	for (id input in captureSession.inputs) {
		[captureSession removeInput:input];
	}
	
	for (id output in captureSession.outputs) {
		[output setSampleBufferDelegate:nil queue:nil];
		[captureSession removeOutput:output];
	}	

	for (NSUInteger i = 0; i < ARVideoFrameBuffers; ++i) {
		free(videoFrames[i].data);
		videoFrames[i].data = NULL;
	}
}

- (void) start {
	[captureSession startRunning];
}

- (void) stop {
	[captureSession stopRunning];
}

- (ARVideoFrame*) videoFrame {
	return videoFrames + (index % 2);
}

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection 
{
	@autoreleasepool {
		NSUInteger nextIndex = index + 1;
		ARVideoFrame * videoFrame = videoFrames + (nextIndex % 2);
		
		// Get the current frame time:
		CMTime frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
		videoFrame->timestamp = CMTimeGetSeconds(frameTime);
		
		// Acquire the image buffer data:
		CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
		CVPixelBufferLockBaseAddress(imageBuffer, 0); 

		// Get information about the image:
		uint8_t * baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
		size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
		size_t width = CVPixelBufferGetWidth(imageBuffer);
		size_t height = CVPixelBufferGetHeight(imageBuffer);
		
		size_t count = bytesPerRow * height;
		
		if (index == 0) {
			NSLog(@"Image data dimensions = (%ld, %ld)", width, height);
		}
		
		// Setup the video frame:
		if (videoFrame->data == NULL) {
			videoFrame->data = (unsigned char*)malloc(count);
			
			videoFrame->size.width = width;
			videoFrame->size.height = height;
			videoFrame->bytesPerRow = bytesPerRow;
		}
		
		// Copy the pixel data to the video frame:
		memcpy(videoFrame->data, baseAddress, bytesPerRow * height);
		videoFrame->index = nextIndex;
		index = nextIndex;

		if (_delegate) {
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();	
			CGContextRef bitmapContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); 
			CGImageRef bitmap = CGBitmapContextCreateImage(bitmapContext); 
			
			// Call the delegate with the bitmap image:
			[_delegate videoFrameController:self didCaptureFrame:bitmap atTime:frameTime];
			
			CGContextRelease(bitmapContext); 
			CGColorSpaceRelease(colorSpace);
			CGImageRelease(bitmap);
		}
		
		// We unlock the pixel buffer
		CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
	}
}

@end