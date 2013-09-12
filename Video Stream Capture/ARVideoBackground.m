//
//  ARVideoBackground.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 5/04/11.
//  Copyright, 2011, by Samuel G. D. Williams.
//

#import "ARVideoBackground.h"

// http://acius2.blogspot.com/2007/11/calculating-next-power-of-2.html
uint32_t nextHighestPowerOf2 (uint32_t n)
{
	if (n == 0) return 0;
	
	n--;
	n |= n >> 1;
	n |= n >> 2;
	n |= n >> 4;
	n |= n >> 8;
	n |= n >> 16;
	n++;
	
	return n;
}

@implementation ARVideoBackground

- (id)init {
    self = [super init];

    if (self) {
        glGenTextures(1, &texture);
		lastIndex = -1;
		size = CGSizeMake(0, 0);
    }

    return self;
}

- (void) update: (ARVideoFrame*) frame
{
	assert(frame != NULL && frame->data != NULL);
		
	// Don't update the data if the frame index has not changed.
	if (frame->index == lastIndex) {
		return;
	}
	
	glBindTexture(GL_TEXTURE_2D, texture);
		
	// Resize the texture if necessary.
	if (size.width == 0) {
		size.width = nextHighestPowerOf2(frame->size.width);
		size.height = nextHighestPowerOf2(frame->size.height);
		
		glTexImage2D(GL_TEXTURE_2D, 0, frame->internalFormat, size.width, size.height, 0, frame->pixelFormat, frame->dataType, NULL);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		
		scale.width = (float)frame->size.width / (float)size.width;
		scale.height = (float)frame->size.height / (float)size.height;
	}
	
	// Update the texture data.
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, frame->size.width, frame->size.height, frame->pixelFormat, frame->dataType, frame->data);
	lastIndex = frame->index;
}

- (void) draw
{
	glColor4f(1.0, 1.0, 1.0, 1.0);
	
	glDisable(GL_DEPTH_TEST);
	
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();
	
	glBindTexture(GL_TEXTURE_2D, texture);
	
	float vertices[] = {
		-1, -1,
		-1, 1,
		1, -1,
		1, 1
	};
	
	float texcoords[] = {
		scale.width, scale.height,
		0, scale.height,
		scale.width, 0,
		0, 0,
	};
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
	
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, texture);
	
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	glDisable(GL_TEXTURE_2D);
	
	// Debugging..
	//glDrawArrays(GL_LINE_STRIP, 0, 4);
	
	// Restore matrix state
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
	
	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();
	
	glEnable(GL_DEPTH_TEST);
}

@end
