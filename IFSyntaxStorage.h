//
//  IFSyntaxStorage.h
//  Inform
//
//  Created by Andrew Hunter on 17/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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
- (void) setSyntaxStorage: (IFSyntaxStorage*) storage;

// The highlighter itself
- (IFSyntaxState) stateForCharacter: (unichar) chr
						 afterState: (IFSyntaxState) lastState;
- (IFSyntaxStyle) styleForCharacter: (unichar) chr
						  nextState: (IFSyntaxState) nextState
						  lastState: (IFSyntaxState) lastState;
- (void) rehintLine: (NSString*) line
			 styles: (IFSyntaxStyle*) styles
	   initialState: (IFSyntaxState) state;

// Styles
- (NSDictionary*) attributesForStyle: (IFSyntaxStyle) style;

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
	
	NSRange needsHighlighting;			// Range that still needs highlighting
	int amountHighlighted;				// Amount highlighted this pass
	
	// Syntax state (dynamic)
	NSMutableArray*   syntaxStack;		// Current syntax stack
	int				  syntaxPos;		// Current highlighter position
	IFSyntaxState     syntaxState;		// Active state
	IFHighlighterMode syntaxMode;		// 'Mode' - possible extra state from the highlighter
	
	// The highlighter
	id<IFSyntaxHighlighter,NSObject> highlighter;
}

// Setting/retrieving the highlighter
- (void) setHighlighter: (id<IFSyntaxHighlighter>) highlighter;
- (id<IFSyntaxHighlighter>) highlighter;

// Communication from the highlighter
- (void) pushState;
- (IFSyntaxState) popState;

- (void) backtrackWithStyle: (IFSyntaxStyle) newStyle
					 length: (int) backtrackLength;

- (void) setHighlighterMode: (IFHighlighterMode) newMode;
- (IFHighlighterMode) highlighterMode;
- (BOOL) preceededByKeyword: (NSString*) keyword
					 offset: (int) offset;

// Actually performing highlighting
- (void) highlightRangeSoon: (NSRange) range;
- (void) highlightRange: (NSRange) rangeToHighlight;
- (BOOL) highlighterPass;
- (void) startBackgroundHighlighting;
- (void) stopBackgroundHighlighting;

@end
