//
//  IFExtensionsManager.h
//  Inform
//
//  Created by Andrew Hunter on 06/03/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString* IFExtensionsUpdatedNotification;				// Sent when the extensions are updated
																// (Note that there's also IFExtensionsChangedNotification, currently used with the extensions managers used for the settings. I suspect this will go)

//
// Class used to manage extensions: add/remove them, and deal with displaying them in table views
//
// There are two kinds of extensions: Natural Inform extensions (which are managed by NI itself, and
// are grouped by author name [directory] then extension name [file]) and Inform 6 extensions (which
// are directories containing files and managed by us)
//
// In the case of Inform 6 extensions, we just display the directories in a table view. Adding a new
// directory overwrites the old one.
//
// For NI extensions, directories are merged. Files have to be added to the extensions owned by a
// particular author.
//
@interface IFExtensionsManager : NSObject {
	// Places to look
	NSMutableArray* extensionDirectories;				// Standard set of extension directories (subdirectory is appended)
	NSMutableArray* customDirectories;					// Custom, user-added extension directories (subdirectory is NOT appended)

	// Settings
	BOOL mergesMultipleExtensions;						// Whether extension directories in multiple places override each other (NO) or merge with each other (YES)
	NSString* subdirectory;								// Subdirectory to append to directories in the extensionDirectories array
	
	// Temporary data
	NSDictionary* tempExtensions;						// Caches the extension dictionary until the autorelease pool is next flushed
	NSArray*      tempAvailableExtensions;				// Caches the available extensions array until the autorelease pool is next flushed
	
	// Table/outline view data
	BOOL updatingTableData;								// Set to YES if an update is pending
	BOOL updateOutlineData;								// Set to YES to also update the data necessary for an outline view (off by default, but switched on if necessary)
	
	NSArray* extensionNames;							// Cached version of the extension names, used for tables and outline views
	NSDictionary* extensionContents;					// Maps extension names to arrays of content, used for outline views only
	NSMutableArray* outlineViewData;					// Cached versions of the objects needed to display the outline view (annoyingly, we have to keep these around and can't generate them when asked)
}

// Shared managers
+ (IFExtensionsManager*) sharedInform6ExtensionManager;
+ (IFExtensionsManager*) sharedNaturalInformExtensionsManager;

// Setting up
- (void) setExtensionDirectories: (NSArray*) directories;				// If different from the defaults
- (void) addExtensionDirectory: (NSString*) directory;					// Complete path (ie, subdirectory not appended to this path)
- (void) setSubdirectory: (NSString*) extensionSubdirectory;			// Appended to the directories set using setExtensionDirectories, but not those added using addExtensionDirectory

- (NSArray*) extensionDirectories;
- (NSString*) subdirectory;

- (void) setMergesMultipleExtensions: (BOOL) mergeMultipleExtensions;	// If YES, then behave as for Natural Inform extensions: ie, if there is an extension with the same author name in multiple directories, functions like filesInExtensionWithName: iterate through all possible directories

// Retrieving the list of installed extensions
- (NSArray*) availableExtensions;
- (NSArray*) pathsForExtensionWithName: (NSString*) name;
- (NSString*) pathForExtensionWithName: (NSString*) name;

// ... and the list of files within a given extension (full paths)
- (NSArray*) filesInExtensionWithName: (NSString*) name;
- (NSArray*) sourceFilesInExtensionWithName: (NSString*) name;

@end
