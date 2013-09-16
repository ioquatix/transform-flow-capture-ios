//
//  ARVideoBackground.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 5/04/11.
//  Copyright, 2011, by Samuel G. D. Williams.
//

#import <Foundation/Foundation.h>

#import "ARVideoFrameController.h"

/// Provides an OpenGL based video background which can display ARVideoFrame data.
@interface ARVideoBackground : NSObject {
	GLuint texture;
	CGSize size, scale;
		
	int lastIndex;
		
	GLenum pixelFormat, internalFormat, dataType;
}

/// Update the video background with a given video frame.
/// The frame data will only be updated if the index has changed.
- (void) update: (ARVideoFrame*) frame;

/// Render the video background to cover the entire screen (e.g. x,y coordinates -1 to +1)
- (void) draw;

@end
