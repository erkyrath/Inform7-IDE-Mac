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
	IFSyntaxStateNotHighlighted = 0xff,
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
    IFSyntaxDirective = 0x40,
    IFSyntaxProperty,
    IFSyntaxFunction,
    IFSyntaxCode,
    IFSyntaxCodeAlpha,
    IFSyntaxAssembly,
    IFSyntaxEscapeCharacter,
    
    // Natural inform syntax types
    IFSyntaxHeading = 0x80,		// Heading style
	IFSyntaxPlain,				// 'No highlighting' style - lets user defined styles show through
	IFSyntaxGameText,			// Text that appears in the game
    
    // Debugging syntax types
    IFSyntaxDebugHighlight = 0xa0
};

typedef unsigned char IFSyntaxState;
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
							  state: (IFSyntaxState) state;
- (void) rehintLine: (NSString*) line
			 styles: (IFSyntaxStyle*) styles;

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
	NSMutableArray* linePositions;	// Locations of the start of lines
	NSMutableArray* lineStates;		// Syntax stack at the start of lines
	
	IFSyntaxStyle*  charStyles;		// Syntax state for each character
	
	// Syntax state (dynamic)
	NSMutableArray* syntaxStack;	// Current syntax stack
	int				syntaxPos;		// Current highlighter position
	IFSyntaxState   syntaxState;	// Active state
	
	// The highlighter
	id<IFSyntaxHighlighter,NSObject> highlighter;
}

// Setting/retrieving the highlighter
- (void) setHighlighter: (id<IFSyntaxHighlighter>) highlighter;
- (id<IFSyntaxHighlighter>) highlighter;

// Communication from the highlighter
- (void) pushState;
- (void) popState;

// Actually performing highlighting
- (void) highlightRange: (NSRange) rangeToHighlight;
- (void) startBackgroundHighlighting;
- (void) stopBackgroundHighlighting;

@end
