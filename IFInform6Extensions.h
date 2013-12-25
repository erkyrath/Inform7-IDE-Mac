//
//  IFInform6Extensions.h
//  Inform
//
//  Created by Andrew Hunter on 12/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFSetting.h"
#import "IFExtensionsManager.h"

//
// The installed Inform 6 extensions and which extensions to use in the current project
//
@interface IFInform6Extensions : IFSetting {
	// Data on what's available
	IFExtensionsManager* extnMgr;
	BOOL needRefresh;
	
	// Which extensions we're using
	NSMutableSet* activeExtensions;
	
	IBOutlet NSTableView* extensionTable;
}

// Used to determine what types of file we can drag and drop
- (BOOL) canAcceptFile: (NSString*) filename;
- (BOOL) canAcceptPasteboard: (NSPasteboard*) pasteboard;

// Adding new extensions
- (BOOL) importExtensionFile: (NSString*) file;

// Actions
- (IBAction) addExtension: (id) sender;
- (IBAction) deleteExtension: (id) sender;

@end
