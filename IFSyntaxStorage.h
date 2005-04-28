//
//  IFSyntaxStorage.h
//  Inform
//
//  Created by Andrew Hunter on 17/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFIntelFile.h"

//
// Predefined states
//

enum {
	IFSyntaxStateNotHighlighted = 0xffffffff,
	IFSyntaxStateDefault = 0
};

// Syntax styles
enum {
    // Basic syntax types
    IFSyntaxNone = 0,
    IFSyntaxString,
    IFSyntaxComment,
    IFSyntaxMonospace,
    
    // Inform 6 syntax types
    IFSyntaxDirective,
    IFSyntaxProperty,
    IFSyntaxFunction,
    IFSyntaxCode,
    IFSyntaxCodeAlpha,
    IFSyntaxAssembly,
    IFSyntaxEscapeCharacter,
	
	// Styles between 0x20-0x40 are the same as above but with a flag set
    
    // Natural inform syntax types
    IFSyntaxHeading = 0x80,				// Heading style
	IFSyntaxPlain,						// 'No highlighting' style - lets user defined styles show through
	IFSyntaxGameText,					// Text that appears in the game
	IFSyntaxSubstitution,				// Substitution instructions
	IFSyntaxNaturalInform,				// Natural inform standard text
	
	IFSyntaxStyleNotHighlighted = 0xf0,	// Used internally by the highlighter to indicate that the highlights are invalid for a particular range
    
    // Debugging syntax types
    IFSyntaxDebugHighlight = 0xa0
};

typedef unsigned int  IFHighlighterMode;
typedef unsigned int  IFSyntaxState;
typedef unsigned char IFSyntaxStyle;

@class IFSyntaxStorage;

//
// Classes must implement this to create a new syntax highlighter
//
@protocol IFSyntaxHighlighter

// Notifying of the highlighter currently in use
- (void) setSyntaxStorage: (IFSyntaxStorage*) storage;				// Sets the storage that the highlighter is (currently) dealing with

// The highlighter itself
- (IFSyntaxState) stateForCharacter: (unichar) chr					// Retrieves the syntax state for a given character
						 afterState: (IFSyntaxState) lastState;
- (IFSyntaxStyle) styleForCharacter: (unichar) chr					// Retrieves the style for a given character with the specified state transition
						  nextState: (IFSyntaxState) nextState
						  lastState: (IFSyntaxState) lastState;
- (void) rehintLine: (NSString*) line								// Opportunity to highlight keywords, etc missed by the first syntax highlighting pass. styles has one entry per character in the line specified, and can be rewritten as required
			 styles: (IFSyntaxStyle*) styles
	   initialState: (IFSyntaxState) state;

// Styles
- (NSDictionary*) attributesForStyle: (IFSyntaxStyle) style;		// Retrieves the text attributes a specific style should use
- (float) tabStopWidth;												// Retrieves the width of a tab stop

@end

//
// Classes must implement this to provide syntax intelligence (real-time indexing and autocomplete)
//
@protocol IFSyntaxIntelligence

// Notifying of the highlighter currently in use
- (void) setSyntaxStorage: (IFSyntaxStorage*) storage;		// Sets the syntax storage that the intelligence object should use

// Gathering information (works like rehint)
- (void) gatherIntelForLine: (NSString*) line				// Gathers intelligence data for the given line (with the given syntax highlighting styles, initial state and line number), and places the resulting data into the given IntelFile object
					 styles: (IFSyntaxStyle*) styles
			   initialState: (IFSyntaxState) state
				 lineNumber: (int) lineNumber
				   intoData: (IFIntelFile*) data;

// Autotyping (occurs when inserting single characters, and allows us to turn '\n' into '\n\t' for example
- (NSString*) rewriteInput: (NSString*) input;				// Opportunity to automatically insert data (for instance to implement auto-tabbing)

@end

//
// An NSTextStorage object that performs syntax highlighting
//
@interface IFSyntaxStorage : NSTextStorage {
	// The string
	NSMutableAttributedString* string;
	
	// Syntax state (static)
	int				nLines;				// Number of lines
	unsigned*		lineStarts;			// Start positions of each line
	NSMutableArray* lineStates;			// Syntax stack at the start of lines
	
	IFSyntaxStyle*  charStyles;			// Syntax state for each character
	NSMutableArray* lineStyles;			// NSParagraphStyles for each line
	
	NSRange needsHighlighting;			// Range that still needs highlighting
	int amountHighlighted;				// Amount highlighted this pass
	
	// Syntax state (dynamic)
	NSMutableArray*   syntaxStack;		// Current syntax stack
	int				  syntaxPos;		// Current highlighter position
	IFSyntaxState     syntaxState;		// Active state
	IFHighlighterMode syntaxMode;		// 'Mode' - possible extra state from the highlighter
	
	// The highlighter
	id<IFSyntaxHighlighter,NSObject> highlighter;
	
	// Paragraph styles
	NSMutableArray* tabStops;			// Tab stop array
	NSMutableArray* paragraphStyles;	// Maps number of tabs at the start of a line to the appropriate paragraph style
	BOOL enableWrapIndent;
	
	// 'Intelligence'
	id<IFSyntaxIntelligence,NSObject> intelSource;
	IFIntelFile* intelData;				// 'Intelligence' data
	
	NSRange editingRange;				// Used while rewriting
}

// Setting/retrieving the highlighter
- (void) setHighlighter: (id<IFSyntaxHighlighter>) highlighter;	// Sets the syntax highlighter to use
- (id<IFSyntaxHighlighter>) highlighter;						// Retrieves the active syntax highlighter

- (BOOL) highlighting;											// YES if highlighting is/may be going on

// Communication from the highlighter
- (void) pushState;												// Pushes the current state onto the stack
- (IFSyntaxState) popState;										// Pops a state from the stack (which is returned)

- (void) backtrackWithStyle: (IFSyntaxStyle) newStyle			// Overwrites the styles backwards from the current position
					 length: (int) backtrackLength;

- (void) setHighlighterMode: (IFHighlighterMode) newMode;		// Allows the highlighter to run in different 'modes' (basically, extends the state data to 64 bits)
- (IFHighlighterMode) highlighterMode;							// Retrieves the current highlighter mode
- (BOOL) preceededByKeyword: (NSString*) keyword				// If the given keyword occurs offset characters behind the current position, returns YES (ie, if the given keyword occurs and ends offset characters previously)
					 offset: (int) offset;

// Actually performing highlighting
- (void) highlightRangeSoon: (NSRange) range;					// The given range will be highlighted later (queues a request)
- (void) highlightRange: (NSRange) rangeToHighlight;			// Highlights a piece of string
- (BOOL) highlighterPass;										// Performs a highlighter pass (highlights only part of the file if there's a lot to do and queues another request)
- (void) startBackgroundHighlighting;							// Queues up anything that needs highlighting in the background
- (void) stopBackgroundHighlighting;							// Abandons the current highlighter queue

- (void) preferencesChanged: (NSNotification*) not;				// Forces a rehighlight (to take account of new preferences)

- (NSDictionary*) paragraphStyleForTabStops: (int) numberOfTabstops;	// Gets a paragraph style for the given number of tab stops

// Gathering/retrieving intelligence data
- (void) setIntelligence: (id<IFSyntaxIntelligence>) intel;		// Sets the intelligence object for this highlighter
- (id<IFSyntaxIntelligence>) intelligence;						// Retrieves the current intelligence object
- (IFIntelFile*) intelligenceData;								// Retrieves the intel data for the current intelligence object

// Intelligence callbacks (rewriting lines)
- (int) editingLineNumber;										// (To be called from rewriteInput) the number of the line being rewritten
- (int) numberOfTabStopsForLine: (int) lineNumber;				// (To be called from rewriteInput) the number of tab stops on the given line
- (NSString*) textForLine: (int) lineNumber;					// (To be called from rewriteInput) the text for a specific line number (which must be lower than the current line number)

- (IFSyntaxStyle) styleAtStartOfLine: (int) lineNumber;			// (To be called from rewriteInput) the syntax highlighting style at the start of a specific line
- (IFSyntaxStyle) styleAtEndOfLine: (int) lineNumber;			// (To be called from rewriteInput) the style at the end of a specific line

- (unichar) characterAtEndOfLine: (int) lineNumber;				// (To be called from rewriteInput) the character at the end of a specific line

- (void) callbackForEditing: (SEL) selector						// (To be called from rewriteInput) callback allows editing outside the current line
				  withValue: (id) parameter;
- (void) replaceLine: (int) lineNumber							// (To be called from the callbackForEditing) replaces a line with another line
			withLine: (NSString*) newLine;			// DANGEROUS! May change styles, invoke the highlighter, etc

@end

//
// Extra delegate methods for the IFSyntaxStorage object
// Enables other objects to ensure that undo works as intended
//
@interface NSObject(IFSyntaxStorageDelegate)

// Called when the syntax storage replaces some text automatically. A delegate can use this to ensure that the
// undo manager is up to date
- (void) rewroteCharactersInStorage: (IFSyntaxStorage*) storage
							  range: (NSRange) range
					 originalString: (NSString*) originalString
				  replacementString: (NSString*) replacementString;

@end
