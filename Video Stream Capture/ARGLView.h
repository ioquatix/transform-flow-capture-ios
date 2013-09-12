//
//  ARGLView.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 27/08/13.
//  Copyright, 2013, by Samuel G. D. Williams.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@class ARGLView;

/// The main EAGL delegate callbacks.
@protocol ARGLViewDelegate <NSObject>
@optional
/// Called whenever the EAGL surface has been resized.
- (void) didResizeSurfaceForView:(ARGLView*)view; 

- (void)touchesBegan: (NSSet *)touches withEvent: (UIEvent *)event inView: (ARGLView*)view;
- (void)touchesMoved: (NSSet *)touches withEvent: (UIEvent *)event inView: (ARGLView*)view;
- (void)touchesEnded: (NSSet *)touches withEvent: (UIEvent *)event inView: (ARGLView*)view;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event inView: (ARGLView*)view;

/// Update the view by drawing using OpenGL commands.
- (void)update: (ARGLView*)view;
@end

/// Wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
/// The view content is basically an EAGL surface you render your OpenGL scene into.
/// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface ARGLView : UIView

- (id) initWithFrame:(CGRect)frame;
- (id) initWithFrame:(CGRect)frame pixelFormat:(GLuint)format;
- (id) initWithFrame:(CGRect)frame pixelFormat:(GLuint)format depthFormat:(GLuint)depth preserveBackbuffer:(BOOL)retained;

@property(nonatomic,readonly) GLuint framebuffer;
@property(nonatomic,readonly) GLuint pixelFormat;
@property(nonatomic,readonly) GLuint depthFormat;
@property(nonatomic,readonly) EAGLContext *context;

/// Print out FPS and other related debugging information.
@property(nonatomic,assign) BOOL debug;

/// Controls whether the EAGL surface automatically resizes when the view bounds change. Otherwise, the EAGL surface contents are scaled to fix when rendered. NO by default.
@property(nonatomic) BOOL autoresize;
@property(nonatomic,readonly) CGSize surfaceSize;

@property(nonatomic,weak) id<ARGLViewDelegate> delegate;

- (void) startRendering;
- (void) stopRendering;

- (void) setCurrentContext;
- (BOOL) isCurrentContext;
- (void) clearCurrentContext;

/// Swap the back and front buffers so that the buffer than has been drawn is now visible.
/// This also checks the current OpenGL error and logs an error if needed.
- (void) swapBuffers; 

- (void) update;

- (void) logStatistics;

- (CGPoint) convertPointFromViewToSurface:(CGPoint)point;
- (CGRect) convertRectFromViewToSurface:(CGRect)rect;

@end
