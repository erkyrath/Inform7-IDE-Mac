//
//  IFSyntaxHighlighter.h
//  Inform
//
//  Created by Andrew Hunter on Sun Nov 30 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

// Base class for building syntax highlighters for Inform code

#import <Foundation/Foundation.h>

/*
 * Subclasses of this class can be used to perform syntax highlighting on a file
 *
 * NOTE: fun adventures in profiling have revealed that most of the time spent syntax
 * highlighting is actually spent in NSTextView updating colours, line heights, etc.
 * I've done a few things to help alleviate the problems. Importantly, things are a lot
 * faster if you try to reduce the number of changes to the colour that you make.
 *
 * I've avoided using temporary attributes, mainly because they don't interact quite
 * right with NSLayoutManager and sometimes produce interesting results. This
 * implementation seems pretty usable on a G4 when editing a huge file such as
 * parserm.h, plus it allows for cute font changes that you can't do with temporary
 * attributes.
 *
 * The assumption is that the highlighter will be stateful; usually it will remember
 * its state at the start of a line, and syntax changes apply only forward. This basically
 * means no highlighting context sensitive languages, but pretty much anything else is
 * possible. If you're really nice to me, I might someday get around to implementing my
 * highlighter based around a LALR parser (I do actually have the parser generator all
 * ready) or a push-down automata.
 *
 * Anyway, initially, no text is highlighted, so the highlighter should have no state.
 * When IFProjectPane wants to get the colour of an area of text, it will call
 * colourForCharacterRange:buffer: with a range of characters from the source text,
 * and it's the highlighters job to fill the buffer (which is of range.length bytes)
 * with highlight items (values from the IFSyntaxType enumeration). IFProjectPane
 * avoids calling this. The highlighter should work out what has changed, and fill
 * the buffer appropriately. IFProjectPane will mark up the text appropriately.
 *
 * When the user edits the text, IFProjectPane will call invalidateRange: or in
 * extreme cases, invalidateAll. The highlighter should make note of the range of
 * text that IFProjectPane thinks is invalid (in the case where an insertion is
 * made in the middle of a file, you will get a range indicating the insertion,
 * NOT the entire file) and update it's internal state appropriately. IFProjectPane
 * will later call invalidRange to see which text needs highlighting.
 *
 * Note that it's not necessary to calculate the entire new invalidRange immediately.
 * If something noticed while running colourForCharacterRange: means the range expands,
 * then IFProjectPane should pick it up.
 *
 * When a new file is loaded into the view, setFile: is called to let the highlighter
 * know where it is stored. This is usually followed by a call to invalidateAll, so
 * there is no need to flush caches in this particular call.
 */

enum IFSyntaxType {
    // Basic syntax types
    IFSyntaxNone,
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

typedef enum IFSyntaxType IFSyntaxType;

@interface IFSyntaxHighlighter : NSObject {
}

// Changes the file we're using; does not invalidate any state information, though
- (void) setFile: (NSString*) newFile;

// Noting that things have changed in the file
- (void) invalidateAll;
- (void) invalidateRange: (NSRange) range;

- (NSRange) invalidRange;

// Getting information about a character
- (void) colourForCharacterRange: (NSRange) range
                          buffer: (unsigned char*) buf;

@end
