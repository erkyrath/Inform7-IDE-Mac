//
//  IFNaturalInformSyntax.m
//  Inform
//
//  Created by Andrew Hunter on Sun Dec 14 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFNaturalInformSyntax.h"

#define SANITY_CHECKS

@implementation IFNaturalInformSyntax

static inline IFNaturalInformState StateMachine(IFNaturalInformState startState, int chr) {
	switch (startState) {
		case IFStateText:
			if (chr == '[') 
				return IFStateComment;
			if (chr == '"')
				return IFStateQuote;
			return IFStateText;
			
		case IFStateComment:
			if (chr == ']')
				return IFStateText;
			return IFStateComment;
			
		case IFStateQuote:
			if (chr == '"')
				return IFStateText;
			return IFStateQuote;
			
		default:
			// Unknown state
			return IFStateText;
	}
}

static inline unsigned char Colour(IFNaturalInformState state, int chr) {
	switch (state) {
		case IFStateText:
			if (chr == '[') return IFSyntaxComment;
			if (chr == '"') return IFSyntaxString;
			return IFSyntaxPlain;
		case IFStateQuote:
			return IFSyntaxString;
		case IFStateComment:
			return IFSyntaxComment;
		default:
			return IFSyntaxPlain;
	}
}

- (id) init {
	self = [super init];
	
	if (self) {
		nLines = -1;
		lines = NULL;
		file = nil;
	}
	
	return self;
}

- (void) dealloc {
	if (file) [file release];
	
	[super dealloc];
}

- (void) setFile: (NSString*) newFile {
	if (file) [file release];
	file = [newFile retain];
	
	[self invalidateAll];
}

- (void) invalidateAll {
	// Clear out the old lines
	nLines = 0;
	if (lines) free(lines);
	lines = NULL;
	
	// Create placeholders for the lines
	int x;
	int startPos = 0;
	
	for (x=0; x<[file length]; x++) {
		int chr = [file characterAtIndex: x];
		
		if (chr == 10 || chr == 13) {
			// End of line
			lines = realloc(lines, sizeof(IFNaturalInformLine)*(nLines+1));
			
			lines[nLines].invalid    = YES;
			lines[nLines].length     = x - startPos + 1;
			lines[nLines].startState = IFStateText;
			
			startPos = x+1;
			nLines++;
		}
	}
	
	// Line 0 is actually always valid (as we don't store any more state than that at the start
	// of each line)
	lines[0].invalid = NO;
}

- (void) invalidateRange: (NSRange) range {
	int endPos = range.location + range.length;
	
	// Find the first invalidated line
	int x;
	int lineStart = 0;
	for (x=0; x<nLines; x++) {
		if (range.location > lineStart &&
			range.location < lineStart + lines[x].length) {
			break;
		}
		
		lineStart += lines[x].length;
	}
	
	if (x >= nLines) {
		NSLog(@"BUG: tried to invalidate a range that starts beyond the end of the file");
		return;
	}
	
	// While we still have invalid lines...
	int firstLine = x;
	int firstLineStart = lineStart;
	int invalidLine = x;

	while (lineStart < endPos && invalidLine < nLines) {
		// Mark this line as invalid
		lines[invalidLine].invalid = YES;
		
		// Move to the next line
		lineStart += lines[invalidLine].length;
		invalidLine++;
	}
	
	// Line 0 is always valid
	lines[0].invalid = NO;
	
	int lastLine = invalidLine;
	
	// Recalculate all line endings in the (firstLine - lastLine) range
	// Add any new lines at lastLine (or delete lines there, too)
	int line = firstLine;
	lineStart = firstLineStart;
	int pos = lineStart;
	
	while (lineStart < endPos) {
		int chr = [file characterAtIndex: pos];
		
		if (chr == 10 || chr == 13) {
			// End of line
			int length = pos - lineStart + 1;
			
			// Insert line if necessary
			if (line >= lastLine) {
				// Extra line
				lines = realloc(lines, sizeof(IFNaturalInformLine)*(nLines+1));
				
				memmove(lines + line + 1, lines + line, sizeof(IFNaturalInformLine)*(nLines - line));
				
				lines[line].length = length;
				lines[line].startState = IFStateText;
				lines[line].invalid = YES;
				
				lastLine = line + 1;
				
				nLines++;
			}
			
			// Set the length of this line
			lines[line].length = length;
			
			lineStart = pos+1;
			line++;
		}
		
		pos++;
	}
	
	// Delete lines if necessary
	if (line < lastLine) {
		int linesToDelete = lastLine - line;
		
		memmove(lines + line, lines + lastLine,
				sizeof(IFNaturalInformLine)*(nLines - lastLine));
		
		nLines -= linesToDelete;
	}
	
#ifdef SANITY_CHECKS
	// Perform sanity checks
	int startPos = 0;
	line = 0;
	
	for (x=0; x<[file length]; x++) {
		int chr = [file characterAtIndex: x];
		
		if (chr == 10 || chr == 13) {
			// End of line
			if (lines[line].length != (x - startPos + 1)) {
				NSLog(@"Programmer is a spoon: line %i does not match", line);
			}
			
			line++;
		}
	}	
#endif
}

- (NSRange) invalidRange {
	// Everything's invalid if we haven't calculated any lines yet
	if (nLines == -1) {
		return NSMakeRange(0, [file length]);
	}
	
	// Work out which lines are invalid
	int x;
	int lineStart = 0;
	BOOL startRange = NO;
	NSRange invalid = NSMakeRange(NSNotFound, NSNotFound);
	
	for (x=0; x<nLines; x++) {
		if (lines[x].invalid) {
			NSRange lineRange = NSMakeRange(lineStart, lines[x].length);
			
			if (startRange)
				invalid = NSUnionRange(invalid, lineRange);
			else
				invalid = lineRange;
			
			startRange = YES;
		}
		
		lineStart += lines[x].length;
	}
	
	if (lineStart < [file length]) {
		// Extra data at the end of the file?
		NSLog(@"BUG? Extra data at end of file");
		
		// Technically, this shouldn't happen, as the invalidate* functions should
		// handle this. It could happen if an edit is made, and invalidateRange:
		// is not called before this function
		int oldEnd = lineStart;
		NSRange lineRange = NSMakeRange(oldEnd, [file length] - oldEnd);
		
		if (startRange)
			invalid = NSUnionRange(invalid, lineRange);
		else
			invalid = lineRange;
	}
	
	return invalid;
}

- (void) colourForCharacterRange: (NSRange) range
                          buffer: (unsigned char*) buf {
    int x;
    
	// Clear the buffer
    for (x=0; x<range.length; x++) {
        buf[x] = IFSyntaxPlain;
    }
	
	if (nLines <= 0) return; // Nothing to do
	
	// Run the state machine to get the start state of any invalid lines
	int line;
	int lineStart = lines[0].length;
	
	for (line = 1; line < nLines; line++) {
		if (lines[line].invalid) {
			// Run the state machine over the preceding line to get the starting state for this line
			int pos = lineStart - lines[line-1].length;
			IFNaturalInformState state = lines[line-1].startState;
			
			int y;
			
			for (y=0; y<lines[line-1].length; y++) {
				state = StateMachine(state, [file characterAtIndex: pos+y]);
			}
			
			lines[line].invalid = NO;
			lines[line].startState = state;
			
			if (line+1 < nLines && lines[line+1].invalid == NO) {
				// Run the state machine some more to see if the next line has become invalid
				pos = lineStart;
				
				for (y=0; y<lines[line].length; y++) {
					state = StateMachine(state, [file characterAtIndex: pos+y]);
				}
				
				// If the states don't match up, then this line is invalid
				if (state != lines[line+1].startState) {
					lines[line+1].invalid = YES;
					// FIXME: this needs to be reported via invalidRange
				}
			}
		}
		
		lineStart += lines[line].length;
	}
	
	// Run the state machine to fill in the colours
	line = 0;
	lineStart = 0;
	
	for (line = 0; line<nLines; line++) {
		if (lineStart > range.location + range.length) break;
		
		if ((lineStart + lines[line].length) > range.location) {
			IFNaturalInformState state = lines[line].startState;
			int y;
			int offset = lineStart - range.location;
			
			for (y=0; y<lines[line].length; y++, offset++) {
				int chr = [file characterAtIndex: lineStart+y];
				if (offset >= 0) {
					buf[offset] = Colour(state, chr);
				}
				
				state = StateMachine(state, chr);
			}
		}
		
		lineStart += lines[line].length;
	}
}

@end
