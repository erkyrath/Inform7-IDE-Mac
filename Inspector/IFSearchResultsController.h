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

//
// Window controller for the window that lists the results we found while searching
//
// Usually used for searching a project or the documentation, but adaptable to search
// other things too.
//
@interface IFSearchResultsController : NSWindowController {
	// Interface elements
	IBOutlet NSTableView* tableView;				// Table of search results
	IBOutlet NSProgressIndicator* progress;			// Current search progress
	IBOutlet NSTextField* searchLabel;				// Label that details what we were searching for
	
	// Interface data
	NSString* searchLabelText;						// Text that will go in the search label
	
	// Thread communication
	NSPort* port1;									// Assorted detritus associated with communicating with the thread that actually performs the search
	NSPort* port2;
	NSConnection* mainThread;
	NSConnection* subThread;
	
	// Search status data
	BOOL searching;									// YES if we're actually searching, NO if we haven't started yet or have finished
	NSString* searchPhrase;							// The phrase we're searching for
	int searchType;									// The type of search to perform (starts with, contains, etc)
	BOOL caseSensitive;								// YES if we should compare in a case-sensitive manner
	NSMutableArray* searchItems;					// (Array of dictionaries) The files or NSTextStorages left to search
	
	NSMutableSet* searchTypes;						// A set of all the search types: used to determine if the 'Type' column should appear
	
	// Search results
	BOOL waitingForReload;							// YES if a table reload is pending
	NSMutableArray* searchResults;					// (Array of dictionaries) The matches for the search phrase
	
	// Delegate
	id delegate;									// The delegate (usually a ProjectController or similar)
}

// Controlling the display
- (void) setSearchLabelText: (NSString*) searchLabel;		// Sets the text that will appear as the label at the top of the window

// Controlling what to search
- (void) setSearchPhrase: (NSString*) searchPhrase;			// Sets the phrase to search for
- (void) setSearchType: (int) searchType;					// Sets the type of search to perform
- (void) setCaseSensitive: (BOOL) caseSensitive;			// Sets whether or not the search should be case-sensitive

- (void) addSearchStorage: (NSString*) storage				// Adds a string to the collection of things to search (matches will appear as being from the given filename)
			 withFileName: (NSString*) filename
					 type: (NSString*) type;
- (void) addSearchFile: (NSString*) filename				// Adds a file to the collection of things to search (file will be loaded before searching)
				  type: (NSString*) type
		  useSearchKit: (BOOL) useSearchKit;

- (void) addDocumentation;									// Adds all of the documentation files to the collection of things to search
- (void) addExtensions;										// Adds all of the extension files to the list of things to search
- (void) addFilesFromProject: (IFProject*) project;			// Adds all of the files loaded as part of a project to the list of things to search

// Controlling the search itself
- (void) startSearch;										// Starts searching
- (void) stopSearch;										// Requests that searching be aborted (won't be honoured immediately)
- (BOOL) searchRunning;										// Returns YES if the search thread is running

// The search delegate
- (void) setDelegate: (id) delegate;						// Sets the delegate object. Delegate is retained.

// Functions that the search thread uses to communicate with the main thread
- (void) threadHasFinishedSearching;						// Called when the thread starts to finish up
- (void) foundMatchInFile: (NSString*) filename				// Called when the thread finds a match
				 location: (int) location
			  displayName: (NSString*) displayname
					 type: (NSString*) type
				  context: (NSAttributedString*) context;

// Functions that the main thread uses to communicate with the search thread
- (void) abortSearch;										// Called by the main thread when the subthread should abort its search early

@end

// Delegate methods

@interface NSObject(IFSearchDelegate)

// Selected a file in the search window
- (void) searchSelectedItemAtLocation: (int) location		// Called when the user selects an item in the list of results
							   inFile: (NSString*) filename
								 type: (NSString*) type;

@end
