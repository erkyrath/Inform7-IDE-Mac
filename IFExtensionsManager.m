//
//  IFExtensionsManager.m
//  Inform
//
//  Created by Andrew Hunter on 06/03/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFExtensionsManager.h"

#import "IFTempObject.h"

@implementation IFExtensionsManager

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
		extensionDirectories = [[NSMutableArray alloc] init];
		customDirectories = [[NSMutableArray alloc] init];
		subdirectory = [@"Extensions" retain];
		
		tempExtensions = nil;
		
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

// = Temporary objects =

- (void) temporaryObjectHasDeallocated: (NSObject*) obj {
	if (obj == tempExtensions) tempExtensions = nil;
	else if (obj == tempAvailableExtensions) tempAvailableExtensions = nil;
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

- (void) setMergesMultipleExtensions: (BOOL) newMergeMultipleExtensions {
	mergesMultipleExtensions = newMergeMultipleExtensions;
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
	if (tempExtensions) return tempExtensions;
	
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
				// Add to the list of paths for this name
				NSString* dirKey = [filename lowercaseString];
				NSMutableArray* dirsWithName = [resultSet objectForKey: dirKey];
					
				if (dirsWithName == nil) dirsWithName = [NSMutableArray array];
				
				[dirsWithName addObject: fullPath];
				
				// Add to the result
				[resultSet setObject: dirsWithName
							  forKey: dirKey];
			}
		}
	}
	
	// Cache the results: this will ensure future calls to this function will be faster (at least until the
	// autorelease pool is destroyed)
	[[[IFTempObject alloc] initWithObject: tempExtensions=resultSet
								 delegate: self] autorelease];
	
	// Return the result
	return resultSet;
}

- (NSArray*) availableExtensions {
	// Use the cached versions if they're around
	if (tempAvailableExtensions) return [[tempAvailableExtensions retain] autorelease];
	
	// Produce a list of extensions
	// We use the 'last' (highest priority) extension name in the array of extensions as the 'actual' name of the extension
	NSDictionary* extensionDictionary = [self extensionDictionary];
	NSMutableArray* result = [NSMutableArray array];
	
	NSEnumerator* extnEnum = [extensionDictionary keyEnumerator];
	NSString* dirKey;
	while (dirKey = [extnEnum nextObject]) {
		NSArray* extnDetails = [extensionDictionary objectForKey: dirKey];
		
		[result addObject: [[extnDetails objectAtIndex: [extnDetails count]-1] lastPathComponent]];
	}
	
	[[[IFTempObject alloc] initWithObject: tempAvailableExtensions=result
								 delegate: self]
		autorelease];
	
	return tempAvailableExtensions;
}

- (NSString*) pathForExtensionWithName: (NSString*) name {
	return [[[self extensionDictionary] objectForKey: [name lowercaseString]] lastObject];
}

- (NSArray*) pathsForExtensionWithName: (NSString*) name {
	return [[self extensionDictionary] objectForKey: [name lowercaseString]];
}

// = The list of files within a given extension (full paths) =

- (NSArray*) filesInExtensionWithName: (NSString*) name {
	// Returns all the files in a particular extension (as full path names)
	NSFileManager* manager = [NSFileManager defaultManager];
	NSArray* pathsToSearch;
	
	// Work out which paths to search (just one if we're not merging)
	if (mergesMultipleExtensions) {
		pathsToSearch = [self pathsForExtensionWithName: name];
	} else {
		pathsToSearch = [NSArray arrayWithObject: [[self pathsForExtensionWithName: name] lastObject]];
	}
	
	// Search all the paths to generate the list of files
	// If a file with the same name exists in multiple places, then only the last one is used
	NSMutableDictionary* resultDict = [NSMutableDictionary dictionary];
	
	NSEnumerator* pathEnum = [pathsToSearch objectEnumerator];
	NSString* path;
	while (path = [pathEnum nextObject]) {
		// Search this path
		NSArray* files = [manager directoryContentsAtPath: path];
		
		NSEnumerator* fileEnum = [files objectEnumerator];
		NSString* file;
		
		while (file = [fileEnum nextObject]) {
			// Add to the result
			[resultDict setObject: [path stringByAppendingPathComponent: file]
						   forKey: [file lowercaseString]];
		}
	}
	
	return [resultDict allValues];
}

- (NSArray*) sourceFilesInExtensionWithName: (NSString*) name {
	// Returns all the files that are probably source files in the extension with the given name
	// (Also returns other files we can edit: .txt and .rtf files in particular)
	NSFileManager* manager = [NSFileManager defaultManager];

	// Use filesInExtensionWithName: to get all the files
	NSArray* files = [self filesInExtensionWithName: name];
	
	// Filter for valid source files
	NSMutableArray* result = [NSMutableArray array];
	
	NSEnumerator* fileEnum = [files objectEnumerator];
	NSString* file;
	
	while (file = [fileEnum nextObject]) {
		// File must exist and not be a directory
		BOOL exists, isDir;
		
		exists = [manager fileExistsAtPath: file
							   isDirectory: &isDir];
		
		if (!exists || isDir) continue;
		
		// File must not begin with a '.'
		if ([[file lastPathComponent] characterAtIndex: 0] == '.') continue;
		
		// File must have a suitable extension
		NSString* extn = [[file pathExtension] lowercaseString];
		if (extn == nil || [extn isEqualToString: @""] || 
			[extn isEqualToString: @"txt"] || [extn isEqualToString: @"rtf"] ||
			[extn isEqualToString: @"inf"] || [extn isEqualToString: @"h"] || [extn isEqualToString: @"i6"])  {
			// Add to the result
			[result addObject: file];
		}
	}
	
	return result;
}

@end
