//
//  ARVSGraph.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 9/02/12.
//  Copyright, 2012, by Samuel G. D. Williams.
//

#import <UIKit/UIKit.h>

@interface ARVSGraphView : UIView

@property(nonatomic,assign) CGFloat scale;

- (void)setPointCount:(NSUInteger)count;

- (void)setSequenceCount:(NSUInteger)count;
- (void)setColor:(UIColor*)color ofSequence:(NSUInteger)sequence;

- (void)addPoints:(CGFloat*)points;

@end
