//
//  IFIsSearch.h
//  Inform
//
//  Created by Andrew Hunter on 29/01/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFInspector.h"

#import "IFProject.h"
#import "IFProjectController.h"

extern NSString* IFIsSearchInspector;

@interface IFIsSearch : IFInspector {
	// Active window and project
	NSWindow* activeWin;
	IFProject* activeProject;
	IFProjectController* activeController;	
	
	// Search controls
	IBOutlet NSTextField* searchText;
	IBOutlet NSButton* searchButton;
	
	IBOutlet NSPopUpButton* searchType;

	IBOutlet NSButton* caseSensitive;
	IBOutlet NSButton* searchDocs;
	IBOutlet NSButton* searchSources;
	IBOutlet NSButton* searchExtensions;
	
	// Current options
	int willSearchType;
	BOOL willCaseSensitive;
	BOOL willSearchSources;
	BOOL willSearchExtensions;
	BOOL willSearchDocs;
}

// The shared search inspector
+ (IFIsSearch*) sharedIFIsSearch;

// Dealing with the controls
- (void) setControlsFromSettings;

// Search actions
- (IBAction) startSearch: (id) sender;
- (IBAction) changeSearchOption: (id) sender;

- (IBAction) makeSearchKey: (id) sender;

@end
