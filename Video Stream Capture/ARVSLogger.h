//
//  ARVSLogger.h
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 30/01/12.
//  Copyright, 2012, by Samuel G. D. Williams.
//

#include <UIKit/UIKit.h>
#include <CoreGraphics/CoreGraphics.h>

@interface ARVSLogger : NSObject {
	NSString * _path;
	NSFileHandle * _fileHandle;
	NSTimer * _syncTimer;
	NSUInteger _logCounter;
}

@property(nonatomic,strong) NSDate * startDate;
@property(readonly,strong) NSString * path;

- (NSTimeInterval)timestamp;

+ loggerForDocumentName:(NSString*)name;

- initWithPath:(NSString*)path;
- (void)close;

- (void)logWithFormat:(NSString *)format, ...;

- (void)logImage:(CGImageRef)image withFormat:(NSString *)format, ...;

@end
