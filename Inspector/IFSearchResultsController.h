//
//  IFSearchResultsController.h
//  Inform
//
//  Created by Andrew Hunter on 29/01/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFProject.h"

enum IFSearchType {
	IFSearchContains = 1,
	IFSearchStartsWith = 2,
	IFSearchWholeWord = 3
};

@interface IFSearchResultsController : NSWindowController {
	// Interface elements
	IBOutlet NSTableView* tableView;
	IBOutlet NSProgressIndicator* progress;
	IBOutlet NSTextField* searchLabel;
	
	// Interface data
	NSString* searchLabelText;
	
	// Thread communication
	NSPort* port1;
	NSPort* port2;
	NSConnection* mainThread;
	NSConnection* subThread;
	
	// Search status data
	BOOL searching;
	NSString* searchPhrase;
	int searchType;
	BOOL caseSensitive;
	NSMutableArray* searchItems;	// Array of dictionaries
	
	// Search results
	BOOL waitingForReload;
	NSMutableArray* searchResults;	// Array of dictionaries
	
	// Delegate
	id delegate;
}

// Controlling the display
- (void) setSearchLabelText: (NSString*) searchLabel;

// Controlling what to search
- (void) setSearchPhrase: (NSString*) searchPhrase;
- (void) setSearchType: (int) searchType;
- (void) setCaseSensitive: (BOOL) caseSensitive;

- (void) addSearchStorage: (NSString*) storage
			 withFileName: (NSString*) filename
					 type: (NSString*) type;
- (void) addSearchFile: (NSString*) filename
				  type: (NSString*) type;

- (void) addDocumentation;
- (void) addExtensions;
- (void) addFilesFromProject: (IFProject*) project;

// Controlling the search itself
- (void) startSearch;
- (void) stopSearch;
- (BOOL) searchRunning;

// The search delegate
- (void) setDelegate: (id) delegate;

// Functions that the search thread uses to communicate with the main thread
- (void) threadHasFinishedSearching;
- (void) foundMatchInFile: (NSString*) filename
				 location: (int) location
			  displayName: (NSString*) displayname
					 type: (NSString*) type
				  context: (NSAttributedString*) context;

// Functions that the main thread uses to communicate with the search thread
- (void) abortSearch;

@end

// Delegate methods

@interface NSObject(IFSearchDelegate)

// Selected a file in the search window
- (void) searchSelectedItemAtLocation: (int) location
							   inFile: (NSString*) filename
								 type: (NSString*) type;

@end
