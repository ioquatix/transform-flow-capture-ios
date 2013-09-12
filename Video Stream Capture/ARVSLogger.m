//
//  ARVSLogger.m
//  This file is part of the "transform-flow" project, and is released under the MIT license.
//
//  Created by Samuel Williams on 30/01/12.
//  Copyright, 2012, by Samuel G. D. Williams.
//

#import "ARVSLogger.h"
#import <ImageIO/ImageIO.h>

@interface ARVSLogger ()
@property(readwrite,strong) NSString * path;
@end

@implementation ARVSLogger

@synthesize path = _path;

+ loggerForDocumentName:(NSString*)name {
	NSError * error = nil;
	
	NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	
	NSDateFormatter * format = [NSDateFormatter new];
	[format setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
	
	NSString * top = [NSString stringWithFormat:@"%@-%@", name, [format stringFromDate:[NSDate date]]];
	NSString * directory = [[paths objectAtIndex:0] stringByAppendingPathComponent:top];
	
	NSFileManager * fileManager = [NSFileManager defaultManager];

	[fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
	
	if (error) {
		NSLog(@"Error creating directory at path %@: %@", directory, error);
		return nil;
	}
		
	return [[ARVSLogger alloc] initWithPath:directory];
}

- initWithPath:(NSString*)path {
	self = [super init];
	
	if (self) {
		self.startDate = [NSDate date];

		[self setPath:path];
		
		NSFileManager * fileManager = [NSFileManager defaultManager];
		
		NSString * logPath = [path stringByAppendingPathComponent:@"log.csv"];
		
		if (![fileManager fileExistsAtPath:logPath]) {
			[fileManager createFileAtPath:logPath contents:nil attributes:nil];
		}
		
		_fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
		[_fileHandle seekToEndOfFile];
		
		_syncTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(synchronizeFile:) userInfo:nil repeats:YES];
		
		NSLog(@"Opening log file: %@", logPath);
	}
	
	return self;
}

- (NSTimeInterval) timestamp
{
	return [[NSDate date] timeIntervalSinceDate:self.startDate];
}

- (void)close {
	NSLog(@"Closing log file: %@", _path);
	
	if (_syncTimer) {
		[_syncTimer invalidate];
		_syncTimer = nil;
	}
	
	if (_fileHandle) {
		[_fileHandle closeFile];
		_fileHandle = nil;
	}
}

- (void)dealloc
{
	[self close];
	
	
}

- (void) synchronizeFile: (id)sender {
	NSLog(@"Sync log file: %@", _path);
	[_fileHandle synchronizeFile];
}

- (void)logWithFormat:(NSString *)messageFormat, ... {
	va_list args;
	va_start(args, messageFormat);
	
	_logCounter++;
	
	NSString * message = [[NSString alloc] initWithFormat:messageFormat arguments:args];
	
	NSString * logMessage = [NSString stringWithFormat:@"%d, %@\n", _logCounter, message];
	[_fileHandle writeData:[logMessage dataUsingEncoding:NSUTF8StringEncoding]];	
	
}

-(void)saveImage:(CGImageRef)imageRef toPath:(NSString *)path {
    NSURL *outURL = [[NSURL alloc] initFileURLWithPath:path];
	
	// Save the image to a png file:
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)outURL, (CFStringRef)@"public.png" , 1, NULL);
    CGImageDestinationAddImage(destination, imageRef, NULL);
    CGImageDestinationFinalize(destination);
	
}

- (void)logImage:(CGImageRef)image withFormat:(NSString *)format, ... {
	va_list args;
	va_start(args, format);
	
	NSString * imageName = [[NSString alloc] initWithFormat:format arguments:args];
	NSString * path = [_path stringByAppendingPathComponent:[imageName stringByAppendingString:@".png"]];

	[self saveImage:image toPath:path];
}

@end
