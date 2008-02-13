//
//  IFFindController.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 05/02/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	// The main types of find that can be performed
	IFFindContains,
	IFFindBeginsWith,
	IFFindCompleteWord,
	IFFindRegexp,
	
	// Flags that can be applied to the find types
	IFFindCaseInsensitive = 0x100,
} IFFindType;

///
/// Controller for the find window
///
@interface IFFindController : NSWindowController {
	// The components of the find dialog
	IBOutlet NSComboBox*	findPhrase;									// The phrase to search for
	IBOutlet NSComboBox*	replacePhrase;								// The phrase to replace it with
	
	IBOutlet NSButton*		ignoreCase;									// The 'ignore case' checkbox
	IBOutlet NSPopUpButton* searchType;									// The 'contains/begins with/complete word/regexp' pop-up button
	
	IBOutlet NSMenuItem*	containsItem;								// Choices for the type of object to find
	IBOutlet NSMenuItem*	beginsWithItem;
	IBOutlet NSMenuItem*	completeWordItem;
	IBOutlet NSMenuItem*	regexpItem;
	
	IBOutlet NSButton*		next;
	IBOutlet NSButton*		previous;
	IBOutlet NSButton*		replaceAndFind;
	IBOutlet NSButton*		replace;
	IBOutlet NSButton*		findAll;
	
	IBOutlet NSView*		findAllResults;								// The 'find all' results view
	IBOutlet NSButton*		includeDocumentation;						// The 'include documentation' check box
	IBOutlet NSTableView*	findAllTable;								// The 'find all' results table
	
	// The regular expression help view
	IBOutlet NSView*		regexpHelpView;								// The view containing information about regexps
	IBOutlet NSView*		regexpTextView;								// The view containing the text for the regexp help
	IBOutlet NSButton*		showRegexpHelp;								// The button specifying whether or not to show the regexp help
	NSRect textViewSize;												// The original size of the text view
	
	// The 'find all' view
	IBOutlet NSView*		findAllView;								// The main 'find all' view
	
	// Auxiliary views
	NSView* auxView;													// The auxiliary view that is being displayed
	NSRect winFrame;													// The default window frame
	NSRect contentFrame;												// The default size of the content frame
	
	// The delegate
	id activeDelegate;													// The delegate that we've chosen to work with
}

// Initialisation

+ (IFFindController*) sharedFindController;								// The shared find window controller

// Actions
- (IBAction) findNext: (id) sender;										// 'Next' clicked
- (IBAction) findPrevious: (id) sender;									// 'Previous' clicked
- (IBAction) replaceAndFind: (id) sender;								// 'Replace and find' clicked
- (IBAction) replace: (id) sender;										// 'Replace' clicked
- (IBAction) findAll: (id) sender;										// 'Find all' clicked
- (IBAction) useSelectionForFind: (id) sender;							// 'Use selection for find' chosen from the menu
- (IBAction) findTypeChanged: (id) sender;								// The user has selected a new type of find (from contains, etc)
- (IBAction) toggleRegexpHelp: (id) sender;								// The user has toggled the regexp help button

// Menu actions
- (BOOL) canFindAgain: (id) sender;										// YES if find next/previous can be sensibly repeated
- (BOOL) canUseSelectionForFind: (id) sender;							// YES if 'useSelectionForFind' will work

// Updating the find window
- (void) updateFromFirstResponder;										// Updates the status of the find window from the first responder
- (void) willFindMore: (id) identifier;									// The 'Find All' process with the specified identifier will find more matches
- (void) finishedSearching: (id) identifier;							// The 'Find All' process with the specified identifier has completed
- (void) foundItems: (NSArray*) items;									// Found new items for the 'find more' window

- (void) showAuxiliaryView: (NSView*) auxView;							// Shows the specified auxiliary view in the find window

@end

///
/// Delegate methods that can be used to enhance the find dialog (or provide it for new views or controllers)
///
@interface NSObject(IFFindDelegate)

// Basic interface (all searchable objects must implement this)
- (BOOL) findNextMatch:	(NSString*) match
				ofType: (IFFindType) type;
- (BOOL) findPreviousMatch: (NSString*) match
					ofType: (IFFindType) type;

- (BOOL) canUseFindType: (IFFindType) find;

- (NSString*) currentSelectionForFind;

// 'Find all'
- (NSArray*) findAllMatches: (NSString*) match
		   inFindController: (IFFindController*) controller
			 withIdentifier: (id) identifier;

// Search as you type
- (id) beginSearchAsYouType;
- (void) findAsYouType: (NSString*) phrase
				ofType: (IFFindType) type
			withObject: (id) object;
- (void) endSearchAsYouType: (id) object;

// Replace
- (void) replaceFoundWith: (NSString*) match;
- (void) replaceAllForPhrase: (NSString*) phrase
				  withString: (NSString*) string
						type: (IFFindType) type;

@end
