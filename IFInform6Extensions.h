//
//  IFInform6Extensions.h
//  Inform
//
//  Created by Andrew Hunter on 12/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFSetting.h"

@interface IFInform6Extensions : IFSetting {
	// Data on what's available
	NSMutableArray* extensions;
	NSMutableDictionary* extensionPath;
	BOOL needRefresh;
	
	// Which extensions we're using
	NSMutableSet* activeExtensions;
	
	IBOutlet NSTableView* extensionTable;
}

// Meta-information about what to look for
- (NSString*) extensionSubdirectory;
- (NSArray*) directoriesToSearch;

// Searching the extensions
- (void) searchForExtensions;

// Used to determine what types of file we can drag and drop
- (BOOL) canAcceptFile: (NSString*) filename;
- (BOOL) canAcceptPasteboard: (NSPasteboard*) pasteboard;
- (NSString*) directoryNameForExtension: (NSString*) extn;

// Adding new extensions
- (BOOL) importExtensionFile: (NSString*) file;
- (void) notifyThatExtensionsHaveChanged;

// Actions
- (IBAction) addExtension: (id) sender;
- (IBAction) deleteExtension: (id) sender;

@end
