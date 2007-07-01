//
//  IFSharedContextMatcher.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 01/07/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFSharedContextMatcher.h"


@implementation IFSharedContextMatcher

+ (IFSharedContextMatcher*) matcher {
	static IFSharedContextMatcher* matcher = nil;
	
	if (matcher == nil) {
		// Initialise the shared context matcher
		matcher = [[IFSharedContextMatcher alloc] init];
		
		// Build it from the standard XML files
		[matcher build];
	}
}

- (void) build {
	// Clear this matcher
	[self clear];
	
	// Get the list of existing XML files
	NSMutableArray* xmlFiles = [NSMutableArray array];
	
	[xmlFiles addObject: [[NSBundle mainBundle] pathForResource: @"Inform7Syntax"
														 ofType: @"xml"]];
	
	// Read each of the XML files in turn to build this matcher
	NSEnumerator* fileEnum = [xmlFiles objectEnumerator];
	NSString* path;
	while (path = [fileEnum nextObject]) {
		if (path == nil) continue;
		
		NSURL* fileUrl = [NSURL fileURLWithPath: path];
		NSXMLParser* xmlParser = [[NSXMLParser alloc] initWithContentsOfURL: fileUrl];
		
		[self readXml: xmlParser];
		[xmlParser release];
	}
}

@end
