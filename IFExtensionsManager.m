//
//  IFExtensionsManager.m
//  Inform
//
//  Created by Andrew Hunter on 06/03/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFExtensionsManager.h"


@implementation IFExtensionsManager

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
		extensionDirectories = [[NSMutableArray alloc] init];
		customDirectories = [[NSMutableArray alloc] init];
		subdirectory = [@"Extensions" retain];
		
		// Get the list of directories where extensions might live
		NSArray* libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
		
		NSEnumerator* libEnum = [libraries objectEnumerator];
		NSString* libDirectory;
		
		while (libDirectory = [libEnum nextObject]) {
			// FIXME: should really go in 'Application Data/Inform'
			[extensionDirectories addObject: [libDirectory stringByAppendingPathComponent: @"Inform"]];
		}
	}
	
	return self;
}

- (void) dealloc {
	[extensionDirectories release]; extensionDirectories = nil;
	[customDirectories release]; customDirectories = nil;
	[subdirectory release]; subdirectory = nil;
	
	[super dealloc];
}

// = Setting up =

- (void) setExtensionDirectories: (NSArray*) directories {
	// Directories must be an array of strings
	[extensionDirectories release]; extensionDirectories = nil;
	[customDirectories release]; customDirectories = [[NSMutableArray alloc] init];
	
	extensionDirectories = [[NSMutableArray alloc] initWithArray: directories 
													   copyItems: YES];
}

- (void) addExtensionDirectory: (NSString*) directory {
	// customDirectories contains directories that do not have the subdirectory auto-appended
	[customDirectories addObject: [[directory copy] autorelease]];
}

- (void) setSubdirectory: (NSString*) extensionSubdirectory {
	[subdirectory release]; subdirectory = nil;
	
	subdirectory = [extensionSubdirectory copy];
}

- (NSArray*) extensionDirectories {
	return [[extensionDirectories copy] autorelease];
}

- (NSString*) subdirectory {
	return [[subdirectory copy] autorelease];
}

// = Retrieving the list of installed extensions =

- (NSArray*) directoriesToSearch {
	NSFileManager* manager = [NSFileManager defaultManager];
	
	// First, we work out the list of directories to search
	NSMutableArray* directoriesToSearch = [NSMutableArray array];
	
	NSEnumerator* extnEnum = [extensionDirectories objectEnumerator];
	NSString* extnDir;
	
	while (extnDir = [extnEnum nextObject]) {
		// Append the subdirectory
		NSString* dir = [extnDir stringByAppendingPathComponent: subdirectory];
		
		// Only add to the list to search if it exists and it's a directory
		BOOL exists;
		BOOL isDir;
		
		exists = [manager fileExistsAtPath: dir
							   isDirectory: &isDir];
		
		if (exists && isDir) {
			[directoriesToSearch addObject: dir];
		}
	}
	
	// Append the custom directories
	extnEnum = [customDirectories objectEnumerator];
	while (extnDir = [extnEnum nextObject]) {
		// Only add to the list to search if it exists and it's a directory
		BOOL exists;
		BOOL isDir;
		
		exists = [manager fileExistsAtPath: extnDir
							   isDirectory: &isDir];
		
		if (exists && isDir) {
			[directoriesToSearch addObject: extnDir];
		}
	}
	
	return directoriesToSearch;
}

- (NSDictionary*) extensionDictionary {
	NSFileManager* manager = [NSFileManager defaultManager];
	
	// First, we work out the list of directories to search
	NSArray* directoriesToSearch = [self directoriesToSearch];
	
	// Retrieve the extensions that exist in the directory
	NSMutableDictionary* resultSet = [NSMutableDictionary dictionary];
	
	// We go through the directories backwards, as the directory added first has the highest priority
	NSEnumerator* extnEnum = [directoriesToSearch reverseObjectEnumerator];
	NSString* extnDir;
	
	while (extnDir = [extnEnum nextObject]) {
		NSArray* extnFiles = [manager directoryContentsAtPath: extnDir];
		
		NSEnumerator* contentEnum = [extnFiles objectEnumerator];
		NSString* filename;
		while (filename = [contentEnum nextObject]) {
			NSString* fullPath = [extnDir stringByAppendingPathComponent: filename];
			
			// Must not be hidden from the finder
			if ([fullPath characterAtIndex: 0] == '.') continue;
			
			// Must exist and be a directory
			BOOL exists;
			BOOL isDir;
			
			exists = [manager fileExistsAtPath: fullPath
								   isDirectory: &isDir];
			
			if (exists && isDir) {
				// Add to the result
				[resultSet setObject: fullPath
							  forKey: [filename lowercaseString]];
			}
		}
	}
	
	// IMPLEMENT ME: cache the results temporarily so that we can re-use it again
	//		Could do this with a tempcache class of some variety that notifies it's delegate when it (and
	//		thus its data) gets destroyed.
	
	// Return the result
	return resultSet;
}

- (NSArray*) availableExtensions {
	return [[self extensionDictionary] allValues];
}

- (NSString*) pathForExtensionWithName: (NSString*) name {
	return [[self extensionDictionary] objectForKey: [name lowercaseString]];
}

// = The list of files within a given extension (full paths) =

- (NSArray*) filesInExtensionWithName: (NSString*) name {
	// Returns all the files in a particular extension (as full path names)
}

- (NSArray*) sourceFilesInExtensionWithName: (NSString*) name {
	// Returns all the files that are probably source files in the extension with the given name
	// (Also returns other files we can edit: .txt and .rtf files in particular)
}

@end
