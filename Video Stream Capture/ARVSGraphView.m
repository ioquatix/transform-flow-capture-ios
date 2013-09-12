//
//  ARVSGraph.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 9/02/12.
//  Copyright, 2012, by Samuel G. D. Williams.
//

#import "ARVSGraphView.h"

@interface ARVSGraphView () {
	// The number of sequences to display:
	NSUInteger _sequences;
	
	// The count of points in a sequence
	NSUInteger _count;
	CGFloat * _points;
	
	NSUInteger _current;
		
	CGFloat _scale;
}

@property(nonatomic,strong) NSMutableArray * colors;

@end

@implementation ARVSGraphView

static NSUInteger indexOfPointInSequence(NSUInteger sequence, NSUInteger point, NSUInteger count) {
	return (sequence * count) + point;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		_scale = 100.0;
		
		_sequences = 0;

		self.colors = [[NSMutableArray alloc] initWithCapacity:4];
		
		[self setSequenceCount:1];
		[self setColor:[UIColor redColor] ofSequence:0];
		
		[self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

-(void)dealloc {
	[self setSequenceCount:0];

}

- (void)setSequenceCount:(NSUInteger)count {
	if (count != _sequences) {
		// This array is invariably foobar:
		if (_points) {
			free(_points);
		}
		
		// Allocate new data structures if required:
		if (count) {
			while (self.colors.count < count) {
				[self.colors addObject:[UIColor grayColor]];
			}

			[self setPointCount:_count];
		}
	}
	
	_sequences = count;
}

- (void)setColor:(UIColor *)color ofSequence:(NSUInteger)sequence {
	NSAssert(sequence < _sequences, @"Invalid sequence number specified");
	
	self.colors[sequence] = color;
}

- (void)setPointCount:(NSUInteger)count {
	if (_points) {
		free(_points);
	}
	
	if (count) {
		_points = (CGFloat *)calloc(count * _sequences, sizeof(CGFloat));
	} else {
		_points = NULL;
	}
	
	_count = count;
	_current = 0;
}

- (void)addPoints:(CGFloat*)points {
	if (_count == 0)
		return;
	
	_current = (_current + 1) % _count;
	
	NSUInteger s = 0;
	for (; s < _sequences; s += 1) {
		_points[indexOfPointInSequence(s, _current, _count)] = points[s];
	}
	
	[self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
	if (_count == 0)
		return;
	
	CGRect bounds = self.bounds;
	CGPoint origin = {
		bounds.origin.x,
		bounds.origin.y + bounds.size.height / 2.0
	};
	
	CGFloat scale = bounds.size.width / _count;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Clear the background:
	CGContextSetRGBFillColor(context, 0.0f, 0.0f, 0.0f, 0.0f);
	CGContextFillRect(context, self.bounds);
	
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, origin.x, origin.y);
	CGContextAddLineToPoint(context, origin.x + bounds.size.width, origin.y);
	CGContextSetStrokeColorWithColor(context, [[UIColor blueColor] CGColor]);
	CGContextStrokePath(context);
	
	NSUInteger s = 0;
	for (; s < _sequences; s += 1) {
		// Draw the graph line:
		CGContextBeginPath(context);
		CGContextMoveToPoint(context, origin.x, origin.y);
		
		NSUInteger i = 0;
		for (; i < _count; i += 1) {
			CGFloat point = _points[indexOfPointInSequence(s, i, _count)];
			CGContextAddLineToPoint(context, origin.x + (scale * i), origin.y + (point * _scale));
		}
		
		CGContextSetLineWidth(context, 1);

		CGContextSetStrokeColorWithColor(context, [self.colors[s] CGColor]);
		
		CGContextStrokePath(context);
	}
	
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, bounds.origin.x + (_current * scale), bounds.origin.y);
	CGContextAddLineToPoint(context, bounds.origin.x + (_current * scale), bounds.origin.y + bounds.size.height);
	CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] CGColor]);
	CGContextStrokePath(context);
}

@end
