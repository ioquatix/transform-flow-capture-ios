//
//  ARGLView.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 27/08/13.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "ARGLView.h"

@interface ARGLView () {
	GLuint _format, _depthFormat;
	BOOL _autoresize;
	EAGLContext * _context;
	GLuint _framebuffer, _renderbuffer, _depthBuffer;
	
	CGSize _size;

	unsigned long _count;
	NSDate * _lastDate;
	
    CADisplayLink * _displayLink;
}

@property(nonatomic,strong) dispatch_queue_t frameRendererQueue;
@property(nonatomic,strong) dispatch_semaphore_t frameRendererSemaphore;

@end

@implementation ARGLView

+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (BOOL) _createSurface
{
	CAEAGLLayer*			eaglLayer = (CAEAGLLayer*)[self layer];
	CGSize					newSize;
	GLuint					oldRenderbuffer;
	GLuint					oldFramebuffer;
	
	if(![EAGLContext setCurrentContext:_context]) {
		return NO;
	}
	
	// Check the resolution of the main screen to support high resolution devices.
    if([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
		CGFloat scale = [[UIScreen mainScreen] scale];

		[self setContentScaleFactor:scale];
	}
     
	glGetIntegerv(GL_RENDERBUFFER_BINDING_OES, (GLint *) &oldRenderbuffer);
	glGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, (GLint *) &oldFramebuffer);
	
	glGenRenderbuffersOES(1, &_renderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderbuffer);
	
	if(![_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)eaglLayer]) {
		glDeleteRenderbuffersOES(1, &_renderbuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_BINDING_OES, oldRenderbuffer);
		return NO;
	}
	
	// Get the renderbuffer size.
	GLint width, height;
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &width);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &height);
	
	newSize.width = width;
	newSize.height = height;
	
	glGenFramebuffersOES(1, &_framebuffer);
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _renderbuffer);
	if (_depthFormat) {
		glGenRenderbuffersOES(1, &_depthBuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, _depthBuffer);
		glRenderbufferStorageOES(GL_RENDERBUFFER_OES, _depthFormat, newSize.width, newSize.height);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, _depthBuffer);
	}
	
	NSLog(@"ARGLView: Creating surface (size = %@; framebuffer = %d; depth buffer = %d; render buffer = %d).", NSStringFromCGSize(newSize), _framebuffer, _depthBuffer, _renderbuffer);

	_size = newSize;

	glViewport(0, 0, newSize.width, newSize.height);
	glScissor(0, 0, newSize.width, newSize.height);

	glBindFramebufferOES(GL_FRAMEBUFFER_OES, oldFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, oldRenderbuffer);
	
	// Error handling here
	[_delegate didResizeSurfaceForView:self];

	self.frameRendererQueue = dispatch_queue_create("ARGLView Renderer", 0);
	self.frameRendererSemaphore = dispatch_semaphore_create(1);
	
	return YES;
}

- (void) _destroySurface
{
	NSLog(@"ARGLView: Destroying surface (framebuffer = %d; depth buffer = %d; render buffer = %d).", _framebuffer, _depthBuffer, _renderbuffer);
	
	EAGLContext *oldContext = [EAGLContext currentContext];
	
	if (oldContext != _context)
		[EAGLContext setCurrentContext:_context];
	
	if(_depthFormat) {
		glDeleteRenderbuffersOES(1, &_depthBuffer);
		_depthBuffer = 0;
	}
	
	glDeleteRenderbuffersOES(1, &_renderbuffer);
	_renderbuffer = 0;

	glDeleteFramebuffersOES(1, &_framebuffer);
	_framebuffer = 0;

	self.frameRendererQueue = nil;
	self.frameRendererSemaphore = nil;

	if (oldContext != _context)
		[EAGLContext setCurrentContext:oldContext];
}

- (id) initWithFrame:(CGRect)frame
{
	return [self initWithFrame:frame pixelFormat:GL_RGB565_OES depthFormat:0 preserveBackbuffer:NO];
}

- (id) initWithFrame:(CGRect)frame pixelFormat:(GLuint)format 
{
	return [self initWithFrame:frame pixelFormat:format depthFormat:0 preserveBackbuffer:NO];
}

- (id) initWithFrame:(CGRect)frame pixelFormat:(GLuint)format depthFormat:(GLuint)depth preserveBackbuffer:(BOOL)retained
{
	self = [super initWithFrame:frame];

	if (self)
	{
		_autoresize = YES;
		
		CAEAGLLayer * eaglLayer = (CAEAGLLayer*)[self layer];
		
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:retained], kEAGLDrawablePropertyRetainedBacking,
			(format == GL_RGB565_OES) ? kEAGLColorFormatRGB565 : kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, 
			nil];

		_format = format;
		_depthFormat = depth;
		
		_context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		
		if (_context == nil) {
			return nil;
		}
		
		if (![self _createSurface]) {
			return nil;
		}

		// This line displays resized content at the correct aspect ratio,
		// but it doesn't solve the underlying problem of setting _autoresize = YES.
		//eaglLayer.contentsGravity = kCAGravityResizeAspectFill;
		//self.autoresize = YES;

		//_frameTimer = nil;
	}

	return self;
}

- (void) dealloc
{
    [self stopRendering];
    
	//[_frameTimer invalidate];
	//_frameTimer = nil;
	
	[self _destroySurface];


}

- (void) renderFrameAsynchronously
{
	dispatch_async(_frameRendererQueue, ^{
		[self setCurrentContext];
		[self update];
		[self swapBuffers];

		dispatch_semaphore_signal(_frameRendererSemaphore);
	});
}

- (void) renderFrame:(CADisplayLink *)sender
{
	if ([self isHidden]) return;

	if (dispatch_semaphore_wait(_frameRendererSemaphore, DISPATCH_TIME_NOW) != 0)
		return;

	[self renderFrameAsynchronously];

	if (_debug) {
		_count += 1;

		if (_count > 150) {
			[self logStatistics];
		}
	}
}

- (void) startRendering {
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderFrame:)];
    //_displayLink.frameInterval = 4.0;
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
	_lastDate = [NSDate date];
	_count = 0;
}

- (void) stopRendering {
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
}

- (void) logStatistics
{
	NSTimeInterval interval = -[_lastDate timeIntervalSinceNow];
	
	NSLog(@"FPS: %0.2f", (double)(_count) / interval);

	_lastDate = [NSDate date];
	_count = 0;
}

- (void) update
{
	if ([_delegate respondsToSelector:@selector(update:)])
		[_delegate update:self];	
}

- (void)layoutSubviews
{
	CGRect bounds = [self bounds];
	
	if(_autoresize && ((roundf(bounds.size.width) != _size.width) || (roundf(bounds.size.height) != _size.height))) {
		[self _destroySurface];
		[self _createSurface];
	}
}

- (void) setAutoresize:(BOOL)autoresize
{
	_autoresize = autoresize;
	
	if(_autoresize)
		[self layoutSubviews];
}

- (void) setCurrentContext
{
	if(![EAGLContext setCurrentContext:_context]) {
		NSLog(@"Failed to set current context %@", _context);
	}
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, _framebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderbuffer);
}

- (BOOL) isCurrentContext
{
	return ([EAGLContext currentContext] == _context ? YES : NO);
}

- (void) clearCurrentContext
{
	if(![EAGLContext setCurrentContext:nil]) {
		NSLog(@"Failed to clear current context");
	}
}

- (void) swapBuffers
{
	EAGLContext *oldContext = [EAGLContext currentContext];
	GLuint oldRenderbuffer;
	
	if (oldContext != _context) {
		[EAGLContext setCurrentContext:_context];
	}
	
	GLint error = glGetError();
	if (error != GL_NO_ERROR) {
		NSLog(@"OpenGL Error #%d", error);
	}
	
	glGetIntegerv(GL_RENDERBUFFER_BINDING_OES, (GLint *) &oldRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderbuffer);

	if (![_context presentRenderbuffer:GL_RENDERBUFFER_OES])
        NSLog(@"Failed to swap renderbuffer!");

	if (oldContext != _context)
		[EAGLContext setCurrentContext:oldContext];
}

- (CGPoint) convertPointFromViewToSurface:(CGPoint)point
{
	CGRect bounds = [self bounds];
	
	return CGPointMake((point.x - bounds.origin.x) / bounds.size.width * _size.width, (point.y - bounds.origin.y) / bounds.size.height * _size.height);
}

- (CGRect) convertRectFromViewToSurface:(CGRect)rect
{
	CGRect bounds = [self bounds];
	
	return CGRectMake((rect.origin.x - bounds.origin.x) / bounds.size.width * _size.width, (rect.origin.y - bounds.origin.y) / bounds.size.height * _size.height, rect.size.width / bounds.size.width * _size.width, rect.size.height / bounds.size.height * _size.height);
}

- (void)touchesBegan: (NSSet *)touches withEvent: (UIEvent *)event
{
	if ([_delegate respondsToSelector:@selector(touchesBegan:withEvent:inView:)])
		[_delegate touchesBegan:touches withEvent:event inView:self];
}

- (void)touchesMoved: (NSSet *)touches withEvent: (UIEvent *)event
{
	if ([_delegate respondsToSelector:@selector(touchesMoved:withEvent:inView:)])
		[_delegate touchesMoved:touches withEvent:event inView:self];
}

- (void)touchesEnded: (NSSet *)touches withEvent: (UIEvent *)event
{
	if ([_delegate respondsToSelector:@selector(touchesEnded:withEvent:inView:)])
		[_delegate touchesEnded:touches withEvent:event inView:self];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	/* This can happen if the user puts more than 5 touches on the screen at once, or perhaps in other circumstances.  Usually (it seems) all active touches are
	 canceled. We forward this on to touchesEnded, which will hopefully provide adequate behaviour. */
	if ([_delegate respondsToSelector:@selector(touchesCancelled:withEvent:inView:)])
		[_delegate touchesCancelled:touches withEvent:event inView:self];
}

@end
