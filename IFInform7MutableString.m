//
//  IFInform7MutableString.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 04/10/2009.
//  Copyright 2009 Andrew Hunter. All rights reserved.
//

#import "IFInform7MutableString.h"

///
/// I7 parser method that gives the string/comment depth at a given position
///
static void I7Parse(NSString* string, int pos, int* commentDepthOut, int* stringDepthOut, int* commentStartOut) {
	int commentDepth	= 0;
	int stringDepth		= 0;
	int commentStart	= -1;
	
	if (pos < [string length]) {
		// Iterate through the string
		int charPos;
		for (charPos = 0; charPos < pos; charPos++) {
			int chr = [string characterAtIndex: charPos];
			
			if (stringDepth == 0 && commentDepth == 0) {
				if (chr == '"') {
					// Quote characters begin a new string
					stringDepth++;
				} else if (chr == '[') {
					// '[' begins a new comment
					commentDepth++;
					commentStart = pos;
				}
			} else if (stringDepth != 0) {
				// Strings are ended by '"' characters
				if (chr == '"') {
					stringDepth--;
				}
			} else if (commentDepth != 0) {
				// Comments nest and are ended by ']' characters
				if (chr == '[') {
					commentDepth++;
				} else if (chr == ']') {
					commentDepth--;
					if (commentDepth == 0) commentStart = -1;
				}
			}
		}
	}
	
	// Update the output variables
	if (commentDepthOut)	*commentDepthOut	= commentDepth;
	if (stringDepthOut)		*stringDepthOut		= stringDepth;
	if (commentStartOut)	*commentStartOut	= commentStart;
}

@implementation NSMutableString(IFInform7MutableString)

///
/// Undoes a commenting action initiated by either
///
- (void) undoInform7Commenting: (NSUndoManager*)	manager
			withOriginalString: (NSString*)			original
				  replaceRange: (NSRange)			range {
	// Get the original string
	NSString* replacing = [self substringWithRange: range];
	
	// Undo the action
	[self replaceCharactersInRange: range
						withString: original];
	
	// Create a new undo action
	[[manager prepareWithInvocationTarget: self] undoInform7Commenting: manager
													withOriginalString: replacing
														  replaceRange: NSMakeRange(range.location, [original length])];
}

///
/// Comments out a region in the string using Inform 7 syntax
///
- (void) commentOutInform7: (NSRange)			range
			   undoManager: (NSUndoManager*)	manager {
	// Restrict the range to the length of the string
	if (range.location < 0 || range.location >= [self length]) {
		return;
	}
	
	if (range.length <= 0) {
		return;
	}
	
	int end = range.location + range.length;
	if (end > [self length]) {
		end				= [self length];
		range.length	= end - range.location;
	}
	
	// Get the original string
	NSString*	original	= [self substringWithRange: range];
	int			finalLength = range.length;
	
	// Parse the string to the beginning of the range
	int pos = range.location;
	int stringDepth;
	int commentDepth;
	I7Parse(self, pos, &commentDepth, &stringDepth, NULL);

	// We also need to know the string depth where the close comment marker will go
	int finalStringDepth;
	I7Parse(self, pos + range.length, NULL, &finalStringDepth, NULL);
	
	if (stringDepth > 0) {
		// The user wants to comment out from the middle of a string; terminate the string
		// and comment out the remainder (this won't always result in valid syntax)
		[self insertString: @"\"[\"" 
				   atIndex: pos];
		finalLength += 3;
		pos			+= 3;
	} else if (commentDepth == 0) {
		// Starting to comment out code from outside a comment
		[self insertString: @"["
				   atIndex: pos];
		finalLength++;
		pos++;
	} else {
		// Trying to comment out from within a comment! Skip to the end of the comment.
		int x;
		for (x=0; x<range.length; x++) {
			if (commentDepth == 0) break;
			
			int chr = [self characterAtIndex: pos];
			pos++;
			if (chr == ']')	commentDepth--;
			if (chr == '[') commentDepth++;
		}
		range.length -= x;
		if (range.length <= 0) return;

		// Insert the comment start character
		[self insertString: @"["
				   atIndex: pos];
		finalLength++;
		pos++;
	}
	
	// Add the close comment marker
	if (finalStringDepth > 0) {
		// Restart any strings that may have got commented out
		[self insertString: @"\"] \""
				   atIndex: pos + range.length];
		finalLength += 4;
	} else {
		// Just finish the comment (nesting should sort itself out if the code was valid originally)
		[self insertString: @"]"
				   atIndex: pos + range.length];
		finalLength++;
	}
	
	// Create the undo action
	if (manager) {
		[[manager prepareWithInvocationTarget: self] undoInform7Commenting: manager
														withOriginalString: (NSString*) original
															  replaceRange: NSMakeRange(range.location, finalLength)];
	}
}

///
/// Removes I7 comments from the specified range
///
- (void) removeCommentsInform7: (NSRange) range
				   undoManager: (NSUndoManager*) manager {
	// Restrict the range to the length of the string
	if (range.location < 0 || range.location >= [self length]) {
		return;
	}
	
	if (range.length <= 0) {
		return;
	}
	
	int end = range.location + range.length;
	if (end > [self length]) {
		end				= [self length];
		range.length	= end - range.location;
	}
}

@end
