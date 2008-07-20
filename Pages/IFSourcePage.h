//
//  IFSourcePage.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFPage.h"
#import "IFIntelFile.h"
#import "IFIsFiles.h"
#import "IFSourceFileView.h"
#import "IFHeaderPage.h"
#import "IFRestrictedTextStorage.h"

//
// The 'source' page
//
@class IFCustomPopup;
@class IFHeadingsBrowser;
@interface IFSourcePage : IFPage {
	IBOutlet IFSourceFileView* sourceText;						// The text view containing the source text
	IBOutlet NSScrollView* sourceScroller;						// The scroll view containing the source file
	IBOutlet NSView* fileManager;								// The view containing the file manager
	
	IFRestrictedTextStorage* restrictedStorage;					// The restricted text storage object that was last used
	NSTextStorage* textStorage;									// The text storage object for this view
	NSString* openSourceFile;									// The name of the file that is open in this page
	
	// The file manager
	BOOL fileManagerShown;										// YES if the source pane is showing the file manager and not the source
	
	// The headings pop-up menu
	IFCustomPopup* headingsControl;								// The 'headings' drop-down control
	IFHeadingsBrowser* headingsBrowser;							// The headings browser control

	// The header page control
	BOOL headerPageShown;
	IFPageBarCell* sourcePageControl;							// The 'source page' toggle
	IFPageBarCell* headerPageControl;							// The 'header page' toggle
	IFHeaderPage* headerPage;									// The header page
}

// Source pane controls
- (void) prepareToCompile;										// Informs this pane that it's time to prepare to compile (or save) the document

- (NSRange) findLine: (int) line;								// Gets the range of characters that correspond to a specific line number
- (void) moveToLine: (int) line									// Scrolls the source view so that the given line/character to be visible
		  character: (int) chr;
- (void) moveToLine: (int) line;								// Scrolls the source view so that the given line to be visible
- (void) moveToLocation: (int) location;						// Scrolls the source view so that the given character index is visible
- (void) selectRange: (NSRange) range;							// Selects a range of characters in the source view

- (void) pasteSourceCode: (NSString*) sourceCode;				// Pastes in the given code at the current insertion position (replacing any selected code and updating the undo manager)

- (void) showSourceFile: (NSString*) file;						// Shows the source file with the given filename in the view
- (NSString*) openSourceFile;									// Returns the unprocessed name of the currently open file (currentFile is usually more appropriate than this)
- (NSString*) currentFile;										// Returns the currently displayed filename
- (int) currentLine;											// Returns the line the cursor is currently on

- (void) indicateRange: (NSRange) range;						// (10.5 only) shows an indicator for the specified range
- (void) indicateLine: (int) line;								// (10.5 only) shows an indicator for the specified line number
- (void) updateHighlightedLines;								// Updates the temporary highlights (which display breakpoints, etc)

- (IFIntelFile*) currentIntelligence;							// The active IntelFile object for the current view (ie, the object that's dealing with auto-tabs, the dynamic index, etc)

- (void) setSpellChecking: (BOOL) checkSpelling;				// Sets check-as-you-type on or off

// Breakpoints
- (IBAction) setBreakpoint: (id) sender;
- (IBAction) deleteBreakpoint: (id) sender;

// File manager controls
- (IBAction) showFileManager: (id) sender;
- (IBAction) hideFileManager: (id) sender;
- (IBAction) toggleFileManager: (id) sender;

// The header page
- (IBAction) showHeaderPage: (id) sender;
- (IBAction) hideHeaderPage: (id) sender;
- (IBAction) toggleHeaderPage: (id) sender;

@end

#import "IFCustomPopup.h"
#import "IFHeadingsBrowser.h"