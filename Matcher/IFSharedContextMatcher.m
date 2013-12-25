//
//  IFSharedContextMatcher.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 01/07/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFSharedContextMatcher.h"


@implementation IFSharedContextMatcher

+ (IFSharedContextMatcher*) matcherForInform7 {
	static IFSharedContextMatcher* matcher = nil;
	
	if (matcher == nil) {
		// Initialise the shared context matcher
		matcher = [[IFSharedContextMatcher alloc] init];
		
		// Build it from the standard XML files
		[matcher build: YES];
	}
	
	return matcher;
}

+ (IFSharedContextMatcher*) matcherForInform6 {
	static IFSharedContextMatcher* matcher = nil;
	
	if (matcher == nil) {
		// Initialise the shared context matcher
		matcher = [[IFSharedContextMatcher alloc] init];
		
		// Build it from the standard XML files
		[matcher build: NO];
	}
	
	return matcher;
}

- (void) build: (BOOL) inform7 {
	// Clear this matcher
	[self clear];
	
	// Get the list of existing XML files
	NSMutableArray* xmlFiles = [NSMutableArray array];
	
	// Read the syntax from the library files
	NSString* libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
	libraryPath = [libraryPath stringByAppendingPathComponent: @"Inform"];
	libraryPath = [libraryPath stringByAppendingPathComponent: inform7?@"Syntax":@"Inform6Syntax"];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath: libraryPath]) {
		NSEnumerator* fileEnum = [[[NSFileManager defaultManager] directoryContentsAtPath: libraryPath] objectEnumerator];
		NSString* file;

		while (file = [fileEnum nextObject]) {
			if ([[[file pathExtension] lowercaseString] isEqualToString: @"xml"]) {
				[xmlFiles addObject: [libraryPath stringByAppendingPathComponent: file]];
			}
		}
	}
	
	[xmlFiles sortUsingSelector: @selector(caseInsensitiveCompare:)];
	
	// Read the syntax from the Inform package
	if (inform7) {
		[xmlFiles insertObject:	[[NSBundle mainBundle] pathForResource: @"Inform7Syntax"
																ofType: @"xml"]
					   atIndex: 0];
	} else {
		NSString* inform6SyntaxPath = [[NSBundle mainBundle] pathForResource: @"Inform6Syntax"
																	  ofType: @"xml"];
		
		if (inform6SyntaxPath) {
			[xmlFiles insertObject:	[[NSBundle mainBundle] pathForResource: @"Inform6Syntax"
																	ofType: @"xml"]
						   atIndex: 0];
		}
	}
	
	// Read each of the XML files in turn to build this matcher
	NSEnumerator* fileEnum = [xmlFiles objectEnumerator];
	NSString* path;
	while (path = [fileEnum nextObject]) {
		if (path == nil) continue;
		if (![[NSFileManager defaultManager] fileExistsAtPath: path]) continue;
		
		NSURL* fileUrl = [NSURL fileURLWithPath: path];
		NSXMLParser* xmlParser = [[NSXMLParser alloc] initWithContentsOfURL: fileUrl];
		
		[self readXml: xmlParser];
		[xmlParser release];
	}
}

@end
