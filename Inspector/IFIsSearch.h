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

//
// The search inspector allows searching the extensions, the current project and/or the documentation
//
@interface IFIsSearch : IFInspector {
	// Active window and project
	NSWindow* activeWin;						// Currently active window
	IFProject* activeProject;					// Currently active project
	IFProjectController* activeController;		// Currently active window controller
	
	// Search controls
	IBOutlet NSTextField* searchText;			// The text the user is search for
	IBOutlet NSButton* searchButton;			// Button to click when it's actually time to search
	
	IBOutlet NSPopUpButton* searchType;			// Whether to search whole words, start of words or parts of words

	IBOutlet NSButton* caseSensitive;			// Case sensitivity check box
	IBOutlet NSButton* searchDocs;				// Search docs check box
	IBOutlet NSButton* searchSources;			// Search sources check box
	IBOutlet NSButton* searchExtensions;		// Search extensions check box
	
	// Current options
	int willSearchType;							// Last known value of the searchType popup button
	BOOL willCaseSensitive;						// Last known value of the case sensitive checkbox
	BOOL willSearchSources;						// Last known value of the search sources checkbox
	BOOL willSearchExtensions;					// Last known value of the search extensions checkbox
	BOOL willSearchDocs;						// Last known value of the search docs checkbox
}

// The shared search inspector
+ (IFIsSearch*) sharedIFIsSearch;				// Retrieves the shared search inspector

// Dealing with the controls
- (void) setControlsFromSettings;				// Sets the settings of the controls from the 'last known' settings (which may have previously come from the user defaults)

// Search actions
- (IBAction) startSearch: (id) sender;			// Starts searching using the current settings
- (IBAction) changeSearchOption: (id) sender;	// Called when one of the various option buttons are changed

- (IBAction) makeSearchKey: (id) sender;		// (BROKEN) Makes the search inspector key. Unfortunately, making the inspector window key is a tough problem.

@end
