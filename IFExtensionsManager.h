//
//  IFExtensionsManager.h
//  Inform
//
//  Created by Andrew Hunter on 06/03/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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
	NSMutableArray* extensionDirectories;
	NSMutableArray* customDirectories;
	
	NSString* subdirectory;
	
	NSDictionary* tempExtensions;
}

// Setting up
- (void) setExtensionDirectories: (NSArray*) directories;			// If different from the defaults
- (void) addExtensionDirectory: (NSString*) directory;				// Complete path (ie, subdirectory not appended to this path)
- (void) setSubdirectory: (NSString*) extensionSubdirectory;

- (NSArray*) extensionDirectories;
- (NSString*) subdirectory;

// Retrieving the list of installed extensions
- (NSArray*) availableExtensions;
- (NSString*) pathForExtensionWithName: (NSString*) name;

// ... and the list of files within a given extension (full paths)
- (NSArray*) filesInExtensionWithName: (NSString*) name;
- (NSArray*) sourceFilesInExtensionWithName: (NSString*) name;

@end
