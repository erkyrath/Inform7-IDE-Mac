//
//  IFasProject.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 05/05/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFasProject.h"

#import "IFasSource.h"

@implementation IFProject(IFasProject)

// = Dealing with source files =

- (NSArray*) asSourceFiles {
	// Build the list of source files (using the IFasSource proxy object)
	NSMutableArray* res = [NSMutableArray array];
	NSEnumerator* srcEnum = [[self sourceFiles] keyEnumerator];
	NSString* srcName;
	
	while (srcName = [srcEnum nextObject]) {
		IFasSource* sourceFile = [[IFasSource alloc] initWithProject: self
																name: srcName];
		
		[res addObject: sourceFile];
		[sourceFile release];
	}
	
	return res;
}

- (NSTextStorage*) asPrimarySourceFile {
	return [[[IFasSource alloc] initWithProject: self
										   name: [self mainSourceFile]] autorelease];
	//return [self storageForFile: [self mainSourceFile]];
}

@end
