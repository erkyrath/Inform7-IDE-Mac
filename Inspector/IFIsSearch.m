//
//  IFIsSearch.m
//  Inform
//
//  Created by Andrew Hunter on 29/01/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFIsSearch.h"
#import "IFSearchResultsController.h"

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
	
	// Find the files and data to search
	if (willSearchDocs) {
		// Find the documents to search
		NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
		
		// Get all .htm and .html documents from the resources
		NSDirectoryEnumerator* dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: resourcePath];
		NSString* path;
		
		while (path = [dirEnum nextObject]) {
			NSString* extension = [path pathExtension];
			
			if ([extension isEqualToString: @"html"] ||
				[extension isEqualToString: @"htm"]) {
				[ctrl addSearchFile: [resourcePath stringByAppendingPathComponent: path]
							   type: @"Documentation"];
			}
		}
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

@end
