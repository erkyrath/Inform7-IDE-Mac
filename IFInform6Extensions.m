//
//  IFInform6Extensions.m
//  Inform
//
//  Created by Andrew Hunter on 12/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFInform6Extensions.h"


@implementation IFInform6Extensions

- (id) init {
	return [self initWithNibName: @"Inform6Extensions"];
}

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Inform 6 Libraries"
												  value: @"Inform 6 Libraries"
												  table: nil];
}

// = Meta-information about what to look for =

- (NSArray*) directoriesToSearch {
	NSArray* libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSMutableArray* libraryDirectories = [NSMutableArray array];
	
	// Look for 'Inform 6 Extensions' directories in each library directory
	NSEnumerator* libEnum = [libraries objectEnumerator];
	NSString* libPath;
	
	while (libPath = [libEnum nextObject]) {
		NSString* extnPath = [[libPath stringByAppendingPathComponent: @"Inform"] stringByAppendingPathComponent: @"Inform 6 Extensions"];
		BOOL isDir;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: extnPath
												 isDirectory: &isDir]) {
			[libraryDirectories addObject: extnPath];
		}
	}
	
	return libraryDirectories;
}

// = Searching the extensions =

- (void) searchForExtensions {
	// Clear out the old extensions
	if (extensions) [extensions release];
	extensions = [[NSMutableArray alloc] init];
	
	// Get the list of extensions
	NSArray* directories = [self directoriesToSearch];
	
	// An extension lives in a directory in one of the directories specified above
	NSEnumerator* dirEnum = [directories objectEnumerator];
	NSString* dir;

	while (dir = [dirEnum nextObject]) {
		// Get the contents of this directory
		
		// Iterate through: add any directories found as an extension
	}
}

@end
