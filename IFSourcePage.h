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

//
// The 'source' page
//
@interface IFSourcePage : IFPage {
	IBOutlet NSTextView* sourceText;							// The text view containing the source text
	
	NSTextStorage* textStorage;									// The text storage object for this view
	NSString* openSourceFile;									// The name of the file that is open in this page
}

- (void) prepareToCompile;										// Informs this pane that it's time to prepare to compile (or save) the document

- (NSRange) findLine: (int) line;								// Gets the range of characters that correspond to a specific line number
- (void) moveToLine: (int) line									// Scrolls the source view so that the given line/character to be visible
		  character: (int) chr;
- (void) moveToLine: (int) line;								// Scrolls the source view so that the given line to be visible
- (void) moveToLocation: (int) location;						// Scrolls the source view so that the given character index is visible
- (void) selectRange: (NSRange) range;							// Selects a range of characters in the source view

- (void) pasteSourceCode: (NSString*) sourceCode;				// Pastes in the given code at the current insertion position (replacing any selected code and updating the undo manager)

- (void) showSourceFile: (NSString*) file;						// Shows the source file with the given filename in the view
- (NSString*) currentFile;										// Returns the currently displayed filename
- (int) currentLine;											// Returns the line the cursor is currently on

- (void) updateHighlightedLines;								// Updates the temporary highlights (which display breakpoints, etc)

- (IFIntelFile*) currentIntelligence;							// The active IntelFile object for the current view (ie, the object that's dealing with auto-tabs, the dynamic index, etc)

@end
