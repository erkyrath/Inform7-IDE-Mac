//
//  IFasProject.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 05/05/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFasProject.h"


@implementation IFProject(IFasProject)

// = Dealing with source files =

- (NSTextStorage*) asSourceFileWithName: (NSString*) name {
	// Retrieve the source file
	NSTextStorage* res = [self storageForFile: name];
	if (res == nil) return nil;
	
	// Fail if the result is temporary
	if ([self fileIsTemporary: name]) return nil;
	
	// Finish up
	return res;
}

- (NSTextStorage*) asPrimarySourceFile {
	return [self asSourceFileWithName: [self mainSourceFile]];
}

@end
