//
//  IFIsSearch.m
//  Inform
//
//  Created by Andrew Hunter on 29/01/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFIsSearch.h"
#import "IFSearchResultsController.h"

#import "IFAppDelegate.h"

// Inspector key
NSString* IFIsSearchInspector = @"IFIsSearchInspector";

// Defaults keys
NSString* IFIsSearchCaseSensitive	= @"IFIsSearchCaseSensitive";
NSString* IFIsSearchDocs			= @"IFIsSearchSearchDocs";
NSString* IFIsSearchSource			= @"IFIsSearchSource";
NSString* IFIsSearchExtensions		= @"IFIsSearchExtensions";
NSString* IFIsSearchType			= @"IFIsSearchType";

@implementation IFIsSearch

// = Initialisation =

+ (void) initialize {
	// Set up the user defaults
	[[NSUserDefaults standardUserDefaults] registerDefaults: 
		[NSDictionary dictionaryWithObjectsAndKeys: 
			[NSNumber numberWithBool: NO], IFIsSearchCaseSensitive,
			[NSNumber numberWithBool: YES], IFIsSearchDocs, 
			[NSNumber numberWithBool: YES], IFIsSearchSource, 
			[NSNumber numberWithBool: NO], IFIsSearchExtensions, 
			[NSNumber numberWithInt: 1], IFIsSearchType, 
			nil]];
}

+ (IFIsSearch*) sharedIFIsSearch {
	IFIsSearch* sharedSearch = nil;
	
	if (!sharedSearch) {
		sharedSearch = [[[self class] alloc] init];
	}
	
	return sharedSearch;
}

- (id) init {
	self = [super init];
	
	if (self) {
		[NSBundle loadNibNamed: @"SearchInspector"
						 owner: self];
		[self setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Inspector Search"
															   value: @"Search"
															   table: nil]];
		
		// Read the settings from the defaults
		NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
		
		willSearchType = [[defaults objectForKey: IFIsSearchType] intValue];
		willCaseSensitive = [[defaults objectForKey: IFIsSearchCaseSensitive] boolValue];
		willSearchSources = [[defaults objectForKey: IFIsSearchSource] boolValue];
		willSearchExtensions = [[defaults objectForKey: IFIsSearchExtensions] boolValue];
		willSearchDocs = [[defaults objectForKey: IFIsSearchDocs] boolValue];
		
		[self setControlsFromSettings];
	}
	
	return self;
}

// = Inspectory stuff =

- (NSString*) key {
	return IFIsSearchInspector;
}

- (void) inspectWindow: (NSWindow*) newWindow {
	activeWin = newWindow;
	
	if (activeProject) {
		// Need to remove the layout manager to prevent potential weirdness
		[activeProject release];
	}
	activeController = nil;
	activeProject = nil;
	
	// Get the active project, if applicable
	NSWindowController* control = [newWindow windowController];
	
	if (control != nil && [control isKindOfClass: [IFProjectController class]]) {
		activeController = (IFProjectController*)control;
		activeProject = [[control document] retain];
	}
}

- (BOOL) available {
	return activeProject==nil?NO:YES;
}

// = Running the search inspector =

- (void) setControlsFromSettings {
	if (willSearchType < 1 || willSearchType > 3) willSearchType = 1;
	
	// Set up the controls
	[searchType selectItem: [[searchType menu] itemWithTag: willSearchType]];
	[caseSensitive setState: willCaseSensitive?NSOnState:NSOffState];
	
	[searchSources setState: willSearchSources?NSOnState:NSOffState];
	[searchExtensions setState: willSearchExtensions?NSOnState:NSOffState];
	[searchDocs setState: willSearchDocs?NSOnState:NSOffState];
}

- (void) saveSettingsToDefaults {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	[defaults setObject: [NSNumber numberWithInt: willSearchType]
				 forKey: IFIsSearchType];
	[defaults setObject: [NSNumber numberWithBool: willCaseSensitive]
				 forKey: IFIsSearchCaseSensitive];

	[defaults setObject: [NSNumber numberWithBool: willSearchDocs]
				 forKey: IFIsSearchDocs];
	[defaults setObject: [NSNumber numberWithBool: willSearchSources]
				 forKey: IFIsSearchSource];
	[defaults setObject: [NSNumber numberWithBool: willSearchExtensions]
				 forKey: IFIsSearchExtensions];
}

- (IBAction) startSearch: (id) sender {
	// Create a new SearchResultsController to handle the search
	IFSearchResultsController* ctrl = [[IFSearchResultsController alloc] init];
	
	// Set up the controller
	[ctrl setSearchLabelText: [NSString stringWithFormat: @"\"%@\" in %@", 
		[searchText stringValue], 
		[[activeController document] displayName]]];
	[ctrl setSearchPhrase: [searchText stringValue]];
	[ctrl setSearchType: willSearchType];
	[ctrl setCaseSensitive: willCaseSensitive];
	
	[ctrl setDelegate: activeController];
	
	// Find the files and data to search
	
	// Note that files are searched in the reverse order they are added
	
	// Documents (we search these last)
	if (willSearchDocs) {
		[ctrl addDocumentation];
	}
	
	// Extensions
	if (willSearchExtensions) {
		[ctrl addExtensions];
	}
	
	// Source files (searched first)
	if (willSearchSources) {
		[ctrl addFilesFromProject: activeProject];
	}
	
	// Display the window
	[ctrl showWindow: self];
	// ctrl will autorelease itself when done
	
	// Start the search
	[ctrl startSearch];
}

- (IBAction) changeSearchOption: (id) sender {
	// Read the controls
	willSearchType = [[searchType selectedItem] tag];
	willCaseSensitive = [caseSensitive state]==NSOnState;
	
	willSearchSources = [searchSources state]==NSOnState;
	willSearchExtensions = [searchExtensions state]==NSOnState;
	willSearchDocs = [searchDocs state]==NSOnState;
	
	// Save into the user defaults
	[self saveSettingsToDefaults];
	
	// Update to the 'real' settings
	[self setControlsFromSettings];
}

- (IBAction) makeSearchKey: (id) sender {
	// Make ourselves key
	[[IFInspectorWindow sharedInspectorWindow] showInspector: self];
		
	// Hrm, not sure if there's a better way to do this. Spent hours looking though the docs, and can't find
	// anything. Simulate a click in the search control in order to force it to become key

	// performClick: fails to work if the window is not key. The window won't become key unless 
	// setBecomesKeyOnlyIfNeeded is NO. Changing this would make the inspectors annoying to use, so
	// this isn't going to happen. Temporarily turning this off fails. Permanently turning it off
	// fails also. I've no idea how to make this work.
	
	// (makeFirstResponder fails too. Trying to manually set up the field editor fails. Even
	// fabricating a mouseDown/mouseUp event pair fails. ARRRGH)
	
	// If you're reading this and you know a better way, email me.
	
	//[(NSPanel*)[inspectorView window] setBecomesKeyOnlyIfNeeded: NO];	// HACK! (doesn't work)
	[[inspectorView window] makeKeyWindow];	// FAILS
	[searchText performClick: self];		// Does nothing
	//[(NSPanel*)[inspectorView window] setBecomesKeyOnlyIfNeeded: YES];	// HACK! (doesn't work)
}

@end
