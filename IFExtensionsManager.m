//
//  IFExtensionsManager.m
//  Inform
//
//  Created by Andrew Hunter on 06/03/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFExtensionsManager.h"
#import "IFMaintenanceTask.h"

#import "IFTempObject.h"

NSString* IFExtensionsUpdatedNotification = @"IFExtensionsUpdatedNotification";

@implementation IFExtensionsManager

// = Shared extension managers =

+ (IFExtensionsManager*) sharedInform6ExtensionManager {
	static IFExtensionsManager* mgr = nil;
	
	if (!mgr) {
		mgr = [[IFExtensionsManager alloc] init];
		
		[mgr setSubdirectory: @"Inform 6 Extensions"];
		[mgr setMergesMultipleExtensions: NO];
		[mgr setExtensionsDefineName: NO];
	}
	
	return mgr;
}

+ (IFExtensionsManager*) sharedNaturalInformExtensionsManager {
	static IFExtensionsManager* mgr = nil;
	
	if (!mgr) {
		mgr = [[IFExtensionsManager alloc] init];
		
		[mgr setSubdirectory: @"Extensions"];
		[mgr setMergesMultipleExtensions: YES];
		[mgr setExtensionsDefineName: YES];
		
		[mgr addExtensionDirectory: [[NSBundle mainBundle] pathForResource: @"Extensions"
																	ofType: @""
															   inDirectory: @"Inform7"]];
	}
	
	return mgr;
}

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
		extensionDirectories = [[NSMutableArray alloc] init];
		customDirectories = [[NSMutableArray alloc] init];
		subdirectory = [@"Extensions" retain];
		
		tempExtensions = nil;
		
		updateOutlineData = NO;
		
		// Get the list of directories where extensions might live
		NSArray* libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
		
		NSEnumerator* libEnum = [libraries objectEnumerator];
		NSString* libDirectory;
		
		while (libDirectory = [libEnum nextObject]) {
			// FIXME: should really go in 'Application Data/Inform'
			[extensionDirectories addObject: [libDirectory stringByAppendingPathComponent: @"Inform"]];
		}
		
		// We check for updates every time the application becomes active
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(updateTableData)
													 name: NSApplicationWillBecomeActiveNotification
												   object: nil];
	}
	
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[extensionDirectories release]; extensionDirectories = nil;
	[customDirectories release]; customDirectories = nil;
	[subdirectory release]; subdirectory = nil;
	
	[extensionNames release]; extensionNames = nil;
	[extensionContents release]; extensionContents = nil;
	
	[outlineViewData release]; outlineViewData = nil;
	
	[super dealloc];
}

// = Temporary objects =

- (void) tempObjectHasDeallocated: (NSObject*) obj {
	if (obj == tempExtensions) 
		tempExtensions = nil;
	else if (obj == tempAvailableExtensions) 
		tempAvailableExtensions = nil;
}

// = Setting up =

- (void) setExtensionDirectories: (NSArray*) directories {
	// Directories must be an array of strings
	[extensionDirectories release]; extensionDirectories = nil;
	[customDirectories release]; customDirectories = [[NSMutableArray alloc] init];
	
	extensionDirectories = [[NSMutableArray alloc] initWithArray: directories 
													   copyItems: YES];
}

- (void) setExtensionsDefineName: (BOOL) defines {
	extensionsDefineName = defines;
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
	if (tempExtensions) return [[tempExtensions retain] autorelease];
	
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
			
			// 'reserved' is a special case and never shows up in the list
			if ([[filename lowercaseString] isEqualToString: @"reserved"]) exists = NO;
			
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
	
	BOOL isGrahamNelson = [[name lowercaseString] isEqualToString: @"graham nelson"];
	
	while (file = [fileEnum nextObject]) {
		// File must exist and not be a directory
		BOOL exists, isDir;
		
		exists = [manager fileExistsAtPath: file
							   isDirectory: &isDir];
		
		if (!exists || isDir) continue;
		
		// File must not begin with a '.'
		if ([[file lastPathComponent] characterAtIndex: 0] == '.') continue;
		
		// 'Standard Rules' in 'Graham Nelson' is a special case and is never returned (even though it's a source file, and will always be present in the natural inform extensions)
		if (isGrahamNelson && [[[file lastPathComponent] lowercaseString] isEqualToString: @"standard rules"]) {
			continue;
		}
		
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

// = Editing the installed extensions =

- (void) createRecursiveDir: (NSString*) dir {
	if (dir == nil || [dir isEqualToString: @""] || [dir isEqualToString: @"/"]) return;
	
	BOOL exists, isDir;
	
	exists = [[NSFileManager defaultManager] fileExistsAtPath: dir
												  isDirectory: &isDir];
	if (exists) return;

	[self createRecursiveDir: [dir stringByDeletingLastPathComponent]];
	
	[[NSFileManager defaultManager] createDirectoryAtPath: dir
											   attributes: nil];
}

- (void) createDefaultExtnDir {
	// Create the directory that will contain the extensions (if necessary)
	NSString* directory = [[extensionDirectories objectAtIndex: 0] stringByAppendingPathComponent: subdirectory];
	
	if (directory == nil) return;
	
	// Do nothing if the directory already exists
	BOOL exists, isDir;
	
	exists = [[NSFileManager defaultManager] fileExistsAtPath: directory
												  isDirectory: &isDir];
	if (exists) return;
	
	// Otherwise, create the directory (and the hierarchy)
	[self createRecursiveDir: directory];
}

- (NSString*) authorForNaturalInformExtension: (NSString*) file
										title: (NSString**) title {
	// Work out the author and title from a Natural Inform extension file
	NSFileManager* mgr = [NSFileManager defaultManager];
	
	if (title != nil) *title = nil;

	// Can't do anything with a non-existant file
	BOOL isDir;
	BOOL exists = [mgr fileExistsAtPath: file
							isDirectory: &isDir];
	
	if (!exists || isDir) return nil;
	
	// Read the first 1k of the extension
	NSFileHandle* extensionFile = [NSFileHandle fileHandleForReadingAtPath: file];
	NSData* extensionInitialData = [extensionFile readDataOfLength: 1024];
	
	// Get up to the first newline
	const unsigned char* bytes = [extensionInitialData bytes];
	
	int x;
	for (x=0; x<[extensionInitialData length] && bytes[x] != '\n' && bytes[x] != '\r'; x++);
	
	// No newline means this is not an extension
	if (x >= [extensionInitialData length]) return nil;
	
	// Initial line should be "<foo> by <bar> begins here." or "Version <x> of <foo> by <bar> begins here."
	NSString* extensionString = [[[NSString alloc] initWithBytes: bytes
														  length: x
														encoding: NSUTF8StringEncoding]
		autorelease];
	if (extensionString == nil) return nil;
	
	// Check that the ending is 'begins here'
	if ([extensionString length] < [@" begins here." length]
		|| ![[[extensionString substringFromIndex: 
				[extensionString length]-[@" begins here." length]] lowercaseString] isEqualToString: @" begins here."])
		return nil;
	
	// Get the indexes of ' by ', and ' of '
	NSRange byPosition = [extensionString rangeOfString: @" by "
												options: NSCaseInsensitiveSearch];
	NSRange ofPosition = [extensionString rangeOfString: @" of "
												options: NSCaseInsensitiveSearch];
	NSRange versionPosition = [extensionString rangeOfString: @"version "
													 options: NSCaseInsensitiveSearch];
	
	// Must be a ' by '
	if (byPosition.location == NSNotFound) return nil;
	
	if (ofPosition.location != NSNotFound && versionPosition.location == 0) {
		// Must be version <x> of <foo> by ..., not version <x> by <foo> of ...
		if (ofPosition.location > byPosition.location) return nil;
		
		// Set ofPosition.location to be the start of the name
		ofPosition.location += ofPosition.length;
	} else {
		// No 'of', or at least, no 'of' indicating a version
		ofPosition.location = 0;
	}
	
	// Now we have enough information to work out the author and suggested extension name
	NSString* titleName = [extensionString substringWithRange: NSMakeRange(ofPosition.location, byPosition.location-ofPosition.location)];
	NSString* authorName = [extensionString substringWithRange: NSMakeRange(byPosition.location+byPosition.length, [extensionString length]-(byPosition.location+byPosition.length)-[@" begins here." length])];
	
	authorName = [authorName stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
	titleName = [titleName stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
	
	if (title) *title = titleName;
	return authorName;
}

- (BOOL) addExtension: (NSString*) extensionPath {
	// We can add directories (of all sorts, but with no subdirectories, and no larger than 1Mb total)
	// We can also add .h, .inf and .i6 files on their own, creating a directory to do so
	NSFileManager* mgr = [NSFileManager defaultManager];
	
	extensionPath = [extensionPath stringByStandardizingPath];

	[self createDefaultExtnDir];

	// Check that we can add this file
	BOOL exists, isDir;
	
	exists = [mgr fileExistsAtPath: extensionPath
					   isDirectory: &isDir];
	if (!exists) return NO;										// Can't add something that does not exist
	
	NSString* author = nil;
	NSString* title = nil;
	
	if (!isDir) {
		NSString* extn = [[extensionPath pathExtension] lowercaseString];
		
		if (extensionsDefineName) {
			// Try to read out the author and title name
			author = [self authorForNaturalInformExtension: extensionPath
													 title: &title];
			
			if (author == nil || title == nil || [author length] <= 0 || [title length] <= 0) return NO;
		} else if (!([extn isEqualToString: @"h"] || [extn isEqualToString: @"inf"] || [extn isEqualToString: @"i6"])) {
			// File is probably not an Inform source file
			return NO;
		}
	} else {
		// The directory must not contain any subdirectories or be larger than 1Mb
		NSDirectoryEnumerator* dirEnum = [mgr enumeratorAtPath: extensionPath];
		int size = 0;
		
		NSString* file;
		while (file = [dirEnum nextObject]) {
			NSString* path = [extensionPath stringByAppendingPathComponent: file];
			
			BOOL fExists, fIsDir;
			
			fExists = [mgr fileExistsAtPath: path
								isDirectory: &fIsDir];
			
			if (!fExists || fIsDir) return NO;				// Subdirectories are not allowed
				
			size += [[[mgr fileAttributesAtPath: path
								   traverseLink: NO] objectForKey: NSFileSize]
				intValue];
			
			if (size > 1048576) return NO;					// Not valid if >1Mb
		}
	}
	
	// We should be able to add the file/directory
	
	// Try to create the destination. First extensionDirectory should be the writable one
	NSString* directory = [[extensionDirectories objectAtIndex: 0] stringByAppendingPathComponent: subdirectory];
	NSString* destDir;
	
	if (directory == nil) return NO;
	
	if (isDir) {
		destDir = [directory stringByAppendingPathComponent: [extensionPath lastPathComponent]];
	} else {
		if (author) {
			destDir = [directory stringByAppendingPathComponent: author];
		} else {
			destDir = [directory stringByAppendingPathComponent: [[extensionPath lastPathComponent] stringByDeletingPathExtension]];
		}
	}
	
	destDir = [destDir stringByStandardizingPath];
	
	if ([[destDir lowercaseString] isEqualToString: [extensionPath lowercaseString]]) return NO;		// Trying to re-add an extension that already exists
	
	// If the old directory exists and we're not merging, then move the old directory to the trash
	BOOL oldExists = [mgr fileExistsAtPath: destDir];
	
	if (!mergesMultipleExtensions && oldExists) {
		if (![[NSWorkspace sharedWorkspace] performFileOperation: NSWorkspaceRecycleOperation
														  source: [destDir stringByDeletingLastPathComponent]
													 destination: @""
														   files: [NSArray arrayWithObject: [destDir lastPathComponent]]
															 tag: 0]) {
			// Failed to move to the trash
			return NO;
		}
		
		oldExists = [mgr fileExistsAtPath: destDir];
		if (oldExists) return NO;								// Er, should probably never happen
	}

	// The list of extensions may have changed
	[self updateTableData];

	// If the directory does not exist, create it
	if (!oldExists) {
		if (![mgr createDirectoryAtPath: destDir
							 attributes: nil]) {
			// Can't create the extension directory
			return NO;
		}
	}
	
	// Copy the files into the extension
	if (isDir) {
		NSDirectoryEnumerator* extnEnum = [mgr enumeratorAtPath: extensionPath];
		
		NSString* file;
		while (file = [extnEnum nextObject]) {
			NSString* path = [extensionPath stringByAppendingPathComponent: file];
			
			// (Silently fail if we can't copy for some reason here)
			[mgr copyPath: path
				   toPath: [destDir stringByAppendingPathComponent: file]
				  handler: nil];
		}
	} else {
		NSString* destFile;
		if (title != nil)
			destFile = title;
		else
			destFile = [extensionPath lastPathComponent];
		
		if (extensionsDefineName && [destFile length] > 0 && [destFile characterAtIndex: [destFile length]-1] == ')') {
			// The name of the extension may be followed by a proviso: remove it
			int index;
			
			for (index = [destFile length] - 1; 
				 index >= 0 && [destFile characterAtIndex: index] != '('; 
				 index--);
			
			if (index > 1) {
				if ([destFile characterAtIndex: index-1] == ' ') {
					destFile = [destFile substringToIndex: index-1];
				}
			}
		}
		
		if (extensionsDefineName && [destFile length] > 31) {
			// Extension filenames must be at most 31 characters
			destFile = [destFile substringToIndex: 30];
		}
		
		NSString* dest = [destDir stringByAppendingPathComponent: destFile];
		if ([mgr fileExistsAtPath: dest]) {
			[mgr removeFileAtPath: dest
						  handler: nil];
		}
		
		if (![mgr copyPath: extensionPath
					toPath: dest
				   handler: nil]) {
			// Couldn't finish installing the extension
			return NO;
		}
	}
	
	// Success
	[self updateTableData];
	[[NSWorkspace sharedWorkspace] noteFileSystemChanged: [destDir stringByDeletingLastPathComponent]];
	return YES;
}

- (BOOL) addFile: (NSString*) filePath
	 toExtension: (NSString*) extensionName {
	// We can add .h, .inf, .i6 or extensionless files
	NSFileManager* mgr = [NSFileManager defaultManager];
	
	filePath = [filePath stringByStandardizingPath];
	
	[self createDefaultExtnDir];
	
	NSString* directory = [[extensionDirectories objectAtIndex: 0] stringByAppendingPathComponent: subdirectory];
	
	// Check the extension
	NSString* extn = [[filePath pathExtension] lowercaseString];
	
	if (!(extn == nil || [extn isEqualToString: @""] || [extn isEqualToString: @"h"] || [extn isEqualToString: @"inf"] || [extn isEqualToString: @"i6"])) {
		// Invalid file extension
		return NO;
	}
	
	BOOL exists, isDir;
	
	exists = [mgr fileExistsAtPath: filePath
					   isDirectory: &isDir];
	if (!exists || isDir) return NO;

	// Create the extension directory if necessary
	NSString* extnDir = [directory stringByAppendingPathComponent: extensionName];
		
	exists = [mgr fileExistsAtPath: extnDir
					   isDirectory: &isDir];
	
	if (exists && !isDir) return NO;						// Is not a directory
	if (!exists) {
		// Does not exist: attempt to create the extension directory
		if (![mgr createDirectoryAtPath: extnDir
							 attributes: nil]) {
			return NO;
		}
		
		[self updateTableData];
	}
	
	// Copy the extension into the directory
	if (![mgr copyPath: filePath
				toPath: [extnDir stringByAppendingPathComponent: [filePath lastPathComponent]]
			   handler: nil])
		return NO;
	
	[self updateTableData];
	
	return YES;
}

- (BOOL) deleteExtension: (NSString*) extensionName {
	// Get the location of the extension (as it would be if installed in the user's directory)
 	NSString* extn = [[[extensionDirectories objectAtIndex: 0] stringByAppendingPathComponent: subdirectory] stringByAppendingPathComponent: extensionName];
	extn = [extn stringByStandardizingPath];
	
	// Check that it exists and is a directory
	BOOL exists, isDir;
	exists = [[NSFileManager defaultManager] fileExistsAtPath: extn
												  isDirectory: &isDir];
	
	if (!exists || !isDir) return NO;
	
	// Try to move it to the trash
	if (![[NSWorkspace sharedWorkspace] performFileOperation: NSWorkspaceRecycleOperation
													  source: [extn stringByDeletingLastPathComponent]
												 destination: @""
													   files: [NSArray arrayWithObject: [extn lastPathComponent]]
														 tag: 0]) {
		return NO;
	}
	
	[self updateTableData];
	
	// Success
	return YES;
}

- (BOOL) deleteFile: (NSString*) file
		inExtension: (NSString*) extensionName {
	// Get the location of the extension file (as it would be if installed in the user's directory)
	NSString* extn = [[[extensionDirectories objectAtIndex: 0] stringByAppendingPathComponent: subdirectory] stringByAppendingPathComponent: extensionName];
	extn = [extn stringByStandardizingPath];
	
	NSString* extnFile = [extn stringByAppendingPathComponent: file];
	extnFile = [extnFile stringByStandardizingPath];
	
	// Check that the extension file and the extension directory exist
	BOOL exists, isDir;
	exists = [[NSFileManager defaultManager] fileExistsAtPath: extn
												  isDirectory: &isDir];
	
	if (!exists || !isDir) return NO;
	
	exists = [[NSFileManager defaultManager] fileExistsAtPath: extnFile];
	if (!exists) return NO;
	
	// Try to move the file to trash
	if (![[NSWorkspace sharedWorkspace] performFileOperation: NSWorkspaceRecycleOperation
													  source: extn
												 destination: @""
													   files: [NSArray arrayWithObject: file]
														 tag: 0]) {
		return NO;
	}
	
	[self updateTableData];
	
	// Success
	return YES;
}

// = Data source support functions =

static const float updateFrequency = 0.75;				// Maximum frequency

//
// Occasionally we might need to update the data associated with the table or the outline view.
// We can't update immediately (as a data source, we have no means of informing the table of the
// update), so instead we use the runloop mechanism to delay the update until later.
//
// Change the 'updateFrequency' constant above to change how often updates occur.
//

- (void) updateTableData {
	// Queues a request to update the table data, if one is not already pending
	if (!updatingTableData) {
		[self performSelector: @selector(reallyUpdateTableData)
				   withObject: nil
				   afterDelay: updateFrequency];
		
		updatingTableData = YES;
	}
}

static int compare_insensitive(id a, id b, void* context) {
	return [a caseInsensitiveCompare: b];
}

- (void) reallyUpdateTableData: (BOOL) notify {
	BOOL hasChanged = NO;
	
	// Actually performs the update, and notifies if anything has changed
	updatingTableData = NO;
	
	NSArray* newTableData = [self availableExtensions];
	newTableData = [newTableData sortedArrayUsingFunction: compare_insensitive
												  context: nil];
	
	if (![newTableData isEqualToArray: extensionNames]) {
		// Table data has updated
		[extensionNames release]; extensionNames = nil;
		
		extensionNames = [newTableData copy];
		
		hasChanged = YES;
	}
	
	if (updateOutlineData) {
		// Also update the data for the outline view
		NSMutableDictionary* newContentData = [NSMutableDictionary dictionary];
		
		NSEnumerator* extnEnum = [extensionNames objectEnumerator];
		NSString* extn;
		
		while (extn = [extnEnum nextObject]) {
			NSArray* contents = [[self sourceFilesInExtensionWithName: extn] sortedArrayUsingFunction: compare_insensitive
																							  context: nil];
			
			if (contents != nil) {
				[newContentData setObject: contents
								   forKey: extn];
			}
		}
		
		if (![newContentData isEqualToDictionary: extensionContents]) {
			[extensionContents release];
			extensionContents = [newContentData retain];
			
			hasChanged = YES;
		}
	}
	
	if (hasChanged && updateOutlineData) {
		// Build the data that forms the final outline view
		// (Annoyingly, we have to keep the objects around, hence this seemingly pointless bit)
		[outlineViewData release]; outlineViewData = nil;
		
		outlineViewData = [[NSMutableArray alloc] init];
		
		NSEnumerator* extnEnum = [extensionNames objectEnumerator];
		NSString* extn;
		
		while (extn = [extnEnum nextObject]) {
			// Build the details for the contents of this extension
			NSMutableArray* extnContents = [NSMutableArray array];
			
			NSArray* contents = [extensionContents objectForKey: extn];
			NSEnumerator* contentEnum = [contents objectEnumerator];
			NSString* extnContent;

			while (extnContent = [contentEnum nextObject]) {
				// view items are arrays of type (type, name, data)
				// type is 'Source' or 'Directory'
				[extnContents addObject: [NSArray arrayWithObjects: @"Source", [extnContent lastPathComponent], extnContent, extn, nil]];
			}
			
			// Store this extension
			// view items are arrays of type (type, name, data)
			// type is 'Source' or 'Directory'
			[outlineViewData addObject: [NSArray arrayWithObjects: @"Directory", extn, extnContents, nil]];
		}
	}

	if (hasChanged && notify) {
		// Tell anything that wants to know that the data has been updated
		[[NSNotificationCenter defaultCenter] postNotificationName: IFExtensionsUpdatedNotification
															object: self];

		// Re-run the maintenance tasks
		NSString* compilerPath = [[NSBundle mainBundle] pathForResource: @"ni"
																 ofType: @""
															inDirectory: @"Compilers"];
		if (compilerPath != nil) {
			[[IFMaintenanceTask sharedMaintenanceTask] queueTask: compilerPath
												   withArguments: [NSArray arrayWithObjects: 
													   @"-census",
													   @"-rules",
													   [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"Inform7"] stringByAppendingPathComponent: @"Extensions"],
													   nil]];
		}
	}
}

- (void) reallyUpdateTableData {
	[self reallyUpdateTableData: YES];
}

- (void) retrieveDataForItem: (id) item
			   extensionName: (NSString**) extension
					fileName: (NSString**) filename {
	if (!extensionContents) {
		updateOutlineData = YES;
		[self reallyUpdateTableData: NO];
	}

	// Clear out the items
	if (extension) *extension = nil;
	if (filename) *filename = nil;
	
	if ([item isKindOfClass: [NSString class]]) {
		// Will be a table view item (not sure of the circumstances these can arrive here, but deal with them anyway)
		if (extension) *extension = item;
		return;
	} else if ([item isKindOfClass: [NSArray class]]) {
		// Will be an outline view item
		NSString* type = [item objectAtIndex: 0];
		
		if (![type isKindOfClass: [NSString class]]) return;					// Uh... Wasn't an item
		
		if ([type isEqualToString: @"Directory"]) {
			if (extension) *extension = [item objectAtIndex: 1];
		} else if ([type isEqualToString: @"Source"]) {
			if (extension) *extension = [item objectAtIndex: 3];
			if (filename) *filename = [item objectAtIndex: 1];
		}
	}
}

- (NSString*) extensionForRow: (int) rowIndex {
	if (!extensionNames)
		[self reallyUpdateTableData: NO];		// Need update now

	// Return nil if the row does not exist
	if (rowIndex < 0) return nil;
	if (rowIndex >= [extensionNames count]) return nil;

	return [extensionNames objectAtIndex: rowIndex];
}

// = Table view datasource =

//
// When acting as a table view datasource, we display the list of installed 'master' extension names only.
// The setting for mergesMultipleExtensions doesn't matter in this mode.
//
// Recognised table column names:
//		'extension'		- the name of the extension
//

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	if (!extensionNames)
		[self reallyUpdateTableData: NO];		// Need update now
	
	return [extensionNames count];
}


- (id)				tableView: (NSTableView *) aTableView 
	objectValueForTableColumn: (NSTableColumn *) aTableColumn
						  row: (int)rowIndex {
	if (!extensionNames)
		[self reallyUpdateTableData: NO];		// Need update now

	NSString* identifier = [aTableColumn identifier];
	
	if ([identifier isEqualToString: @"extension"]) {
		if (rowIndex < 0 || rowIndex >= [extensionNames count]) return @"== BAD ROW INDEX ==";
		
		return [extensionNames objectAtIndex: rowIndex];
	}
	
	return nil;		// Unknown column type
}

- (NSDragOperation) tableView: (NSTableView*) tableView 
				 validateDrop: (id<NSDraggingInfo>) info 
				  proposedRow: (int)row
		proposedDropOperation: (NSTableViewDropOperation)operation {
	// Outline view drops follow NI semantics (which is different from Inform 6 in many ways)
	if (!extensionNames)
		[self reallyUpdateTableData: NO];		// Need update now
	
	// We can accept files dropped on the outline view
	NSArray* pbFiles = [[info draggingPasteboard] propertyListForType: NSFilenamesPboardType];
	
	if (pbFiles == nil || ![pbFiles isKindOfClass: [NSArray class]]) {
		return NSDragOperationNone;
	}
	
	// We accept directories or files of the right type
	NSEnumerator* fileEnum = [pbFiles objectEnumerator];
	NSString* file;
	
	while (file = [fileEnum nextObject]) {
		BOOL exists, isDir;
		
		exists = [[NSFileManager defaultManager] fileExistsAtPath: file
													  isDirectory: &isDir];
		
		if (!exists) return NSDragOperationNone;
		
		if (!isDir) {
			// File type must be right
			NSString* extn = [file pathExtension];
			if (![extn isEqualToString: @"h"] && ![extn isEqualToString: @"inf"] && ![extn isEqualToString: @"i6"]) return NSDragOperationNone;
		}
	}
	
	return NSDragOperationCopy;
}

- (BOOL) tableView: (NSTableView*) tableView 
		acceptDrop: (id<NSDraggingInfo>) info 
			   row: (int) row 
	 dropOperation: (NSTableViewDropOperation) operation {	
	if ([self tableView: tableView
			 validateDrop: info
			proposedRow: row
  proposedDropOperation: operation] == NSDragOperationNone) {
		// Can't accept if we can't validate the drop
		return NO;
	}
	
	// Get the files associated with this drop
	NSArray* pbFiles = [[info draggingPasteboard] propertyListForType: NSFilenamesPboardType];
	
	if (pbFiles == nil || ![pbFiles isKindOfClass: [NSArray class]]) {
		return NO;
	}
	
	// Add the new item(s) as a new extension
	NSEnumerator* fileEnum = [pbFiles objectEnumerator];
	NSString* file;
	
	while (file = [fileEnum nextObject]) {
		if (![self addExtension: file]) 
			return NO;
	}
	
	return YES;
}

// = Outline view datasource =

//
// When acting as an outline view datasource, we show the extensions and all source files.
// The setting for mergesMultipleExtensions determines whether or not we get the files from all the
// extension directories with a given name or just one.
//
// Recognised table column names:
//		'extension'		- the name of the extension (or the name of the file within the extension)
//

- (id) outlineView: (NSOutlineView*) outlineView 
			 child: (int) index 
			ofItem: (id) item {
	// Make sure we've got all the info we need
	if (!extensionContents) {
		updateOutlineData = YES;
		[self reallyUpdateTableData: NO];
	}
	
	if (item == nil) {
		// Root item
		return [outlineViewData objectAtIndex: index];
	} else if ([item isKindOfClass: [NSArray class]]) {
		// Extension item (Directory or Source)
		if ([[item objectAtIndex: 0] isEqualToString: @"Directory"]) {
			// Source item
			return [[item objectAtIndex: 2] objectAtIndex: index];
		} else {
			// Extensions don't go down any further
			return nil;
		}
	}
	
	return nil;
}

- (BOOL) outlineView: (NSOutlineView*) outlineView
	isItemExpandable: (id) item {
	// Make sure we've got all the info we need
	if (!extensionContents) {
		updateOutlineData = YES;
		[self reallyUpdateTableData: NO];
	}
	
	if ([item isKindOfClass: [NSArray class]]) {
		if ([[item objectAtIndex: 0] isEqualToString: @"Directory"]) {
			return YES;
		} else {
			return NO;
		}
	}

	return NO;
}

- (int)		outlineView: (NSOutlineView*) outlineView 
 numberOfChildrenOfItem: (id) item {
	// Make sure we've got all the info we need
	if (!extensionContents) {
		updateOutlineData = YES;
		[self reallyUpdateTableData: NO];
	}
	
	if (item == nil) {
		// Root item
		return [outlineViewData count];
	} else if ([item isKindOfClass: [NSArray class]]) {
		// Either a source or a directory item
		if ([[item objectAtIndex: 0] isEqualToString: @"Directory"]) {
			// Directory item
			return [[item objectAtIndex: 2] count];
		} else {
			// Source item (ie no children)
			return 0;
		}
	}

	return 0;
}

- (id)			outlineView: (NSOutlineView*) outlineView
  objectValueForTableColumn: (NSTableColumn*) tableColumn 
					 byItem: (id)item {
	// Make sure we've got all the info we need
	if (!extensionContents) {
		updateOutlineData = YES;
		[self reallyUpdateTableData: NO];
	}
	
	if ([item isKindOfClass: [NSString class]]) {
		// Strings are returned as is
		return item;
	} else if ([item isKindOfClass: [NSArray class]]) {
		// Arrays are of the (kind, description) variety
		return [item objectAtIndex: 1];
	}

	return nil;
}

- (NSDragOperation) outlineView: (NSOutlineView*) outlineView
				   validateDrop: (id<NSDraggingInfo>) info 
				   proposedItem: (id) item 
			 proposedChildIndex: (int) index {
	// Outline view drops follow NI semantics (which is different from Inform 6 in many ways)
	
	// We can accept files dropped on the outline view
	NSArray* pbFiles = [[info draggingPasteboard] propertyListForType: NSFilenamesPboardType];
	
	if (pbFiles == nil || ![pbFiles isKindOfClass: [NSArray class]]) {
		return NSDragOperationNone;
	}
	
	if (item == NULL) {
		// We accept directories (only) dropped on the parent item
		NSEnumerator* fileEnum = [pbFiles objectEnumerator];
		NSString* file;
		
		while (file = [fileEnum nextObject]) {
			BOOL exists, isDir;
			
			exists = [[NSFileManager defaultManager] fileExistsAtPath: file
														  isDirectory: &isDir];
			
			if (!exists || !isDir) return NSDragOperationNone;
		}
		
		return NSDragOperationCopy;
	} else {
		NSString* type = [item objectAtIndex: 0];
		
		if (![type isEqualToString: @"Directory"]) return NSDragOperationNone;

		// We accept files with no extension to put in the extension directories themselves
		NSEnumerator* fileEnum = [pbFiles objectEnumerator];
		NSString* file;
		
		while (file = [fileEnum nextObject]) {
			BOOL exists, isDir;
			
			exists = [[NSFileManager defaultManager] fileExistsAtPath: file
														  isDirectory: &isDir];
			
			if (!exists || isDir) return NSDragOperationNone;
			
			NSString* extn = [file pathExtension];
			if (extn != nil && ![extn isEqualToString: @""]) return NSDragOperationNone;
		}
		
		return NSDragOperationCopy;
	}
	
	return NSDragOperationNone;
}

- (BOOL) outlineView: (NSOutlineView*) outlineView
		  acceptDrop: (id<NSDraggingInfo>) info 
				item: (id) item 
		  childIndex: (int) index {	
	if ([self outlineView: outlineView
			 validateDrop: info
			 proposedItem: item
	   proposedChildIndex: index] == NSDragOperationNone) {
		// Can't accept if we can't validate the drop
		return NO;
	}
	
	// Get the files associated with this drop
	NSArray* pbFiles = [[info draggingPasteboard] propertyListForType: NSFilenamesPboardType];
	
	if (pbFiles == nil || ![pbFiles isKindOfClass: [NSArray class]]) {
		return NO;
	}
	
	if (item == nil || extensionsDefineName) {
		// Add the new item(s) as a new extension
		NSEnumerator* fileEnum = [pbFiles objectEnumerator];
		NSString* file;
		
		while (file = [fileEnum nextObject]) {
			if (![self addExtension: file]) 
				return NO;
		}
		
		return YES;
	} else {
		// Add to a specific extension
		NSString* type = [item objectAtIndex: 0];
		
		if (![type isEqualToString: @"Directory"]) return NO;
		
		// Get the extension to add to
		NSString* extensionName = [item objectAtIndex: 1];
		
		// Add the files
		NSEnumerator* fileEnum = [pbFiles objectEnumerator];
		NSString* file;

		while (file = [fileEnum nextObject]) {
			if (![self addFile: file
				   toExtension: extensionName]) 
				return NO;
		}
		
		return YES;
	}
	
	return NO;
}

// = NSSavePanel delegate methods =

- (BOOL)           panel:(id)sender 
	  shouldShowFilename:(NSString *)filename {
	BOOL isDir;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: filename
													   isDirectory: &isDir];
	
	if (!exists) return NO;
	if (isDir) return YES;
	
	NSString* extn = [[filename pathExtension] lowercaseString];
	
	if (extensionsDefineName) {
		// Try to read out the author and title name
		NSString* author;
		NSString* title;
		
		author = [self authorForNaturalInformExtension: filename
												 title: &title];
		
		if (author == nil || title == nil || [author length] <= 0 || [title length] <= 0) return NO;
	} else if (!([extn isEqualToString: @"h"] || [extn isEqualToString: @"inf"] || [extn isEqualToString: @"i6"])) {
		// File is probably not an Inform source file
		return NO;
	}
	
	return YES;
}

@end
