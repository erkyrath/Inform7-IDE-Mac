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
			if (chr == '"') return IFSyntaxGameText;
			return IFSyntaxNone;
		case IFStateQuote:
			return IFSyntaxGameText;
		case IFStateComment:
			return IFSyntaxComment;
		default:
			return IFSyntaxNone;
	}
}

- (id) init {
	self = [super init];
	
	if (self) {
		nLines = -1;
		lines = NULL;
		file = nil;
		invalidRange = NSMakeRange(NSNotFound, 0);
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
	
	// Last line
	lines = realloc(lines, sizeof(IFNaturalInformLine)*(nLines+1));
	
	lines[nLines].invalid    = YES;
	lines[nLines].length     = x - startPos;
	lines[nLines].startState = IFStateText;
	
	startPos = x+1;
	nLines++;	
}

#ifdef SANITY_CHECKS
- (void) sanityCheck {
	// Perform sanity checks
	int startPos = 0;
	int x;
	int line = 0;
	
	for (x=0; x<[file length]; x++) {
		int chr = [file characterAtIndex: x];
		
		if (chr == 10 || chr == 13) {
			// End of line
			if (line >= nLines) {
				NSLog(@"Programmer is a spoon: too many lines (%i/%i)", line, nLines);
			} else if (lines[line].length != (x - startPos + 1)) {
				NSLog(@"Programmer is a spoon: line %i does not match (length = %i, should be %i)", line, lines[line].length, (x - startPos + 1));
			}
			
			line++;
			startPos = x + 1;
		}
	}
	
	// Last line
	if (line < nLines && lines[line].length != (x - startPos)) {
		NSLog(@"Programmer is a spoon: line %i does not match (length = %i, should be %i)", line, lines[line].length, (x - startPos));
	}
	
	if (line+1 < nLines) {
		NSLog(@"Programmer is a spoon: too few lines (%i/%i)", line, nLines);
	}
	
	int length = 0;
	for (x=0; x<nLines; x++) {
		length += lines[x].length;
	}
	
	if (length != [file length]) {
		NSLog(@"File size does not match up (%i/%i)", length, [file length]);
	}
}	
#endif

- (void) invalidateRange: (NSRange) range {
	// It's a bit annoying trying to work out what has changed while disturbing as little as possible
	// of the file.
	
	// Syntax highlighting itself is fast, but NSTextView takes an _ETERNITY_ to reformat text,
	// especially when fonts change a lot in a line. There's not a lot that can be done about this.
	// Mac OS X's font system is basically slow, and NSLayoutManager works to hide this from the user.
	// (*WHY* it is still so slow is a mystery to me. Font metrics aren't that hard to do).
	
	// range gives the range of changed characters in the new, edited file.
	// We have line positions and states marking the old, unedited file.
	// Text may have been added
	// Text may have been deleted
	// Text length may not have changed
	// More lines may be added
	// Lines may be deleted
	// The last line does not end with a \n
	
	// Presumably, nothing has changed before range.location. If something has, then we're stuffed anyway.
	// This allows us to get the line preceding the change.
	int firstLine = 0;
	int lineStart = 0;
	
	for (firstLine = 0; firstLine < nLines; firstLine++) {
		if (lineStart + lines[firstLine].length > range.location) {
			// This is the first line that has changed
			break;
		}
		
		lineStart += lines[firstLine].length;
	}
	
	if (firstLine >= nLines) {
		firstLine = nLines-1;
		lineStart -= lines[firstLine].length;
	}

	lines[firstLine].invalid = YES;
	
	// Work out any changes to line endings
	// Unfortunately, as there is no way to tell the range of text that has been deleted,
	// we have to scan the entire file. A possible optimisation is to scan only from the
	// first line we found previously, but probably isn't worth the implementation effort.
	int oldnLines = nLines;
	int startPos = 0;
	
	int x;
	nLines = 0;
	
	for (x=0; x<[file length]; x++) {
		int chr = [file characterAtIndex: x];
		
		if (chr == 10 || chr == 13) {
			// End of line
			if (nLines >= oldnLines)
				lines = realloc(lines, sizeof(IFNaturalInformLine)*(nLines+1));
			
			lines[nLines].length     = x - startPos + 1;
			
			startPos = x+1;
			nLines++;
		}
	}
	
	// Last line
	lines = realloc(lines, sizeof(IFNaturalInformLine)*(nLines+1));
	
	lines[nLines].length     = x - startPos;
	
	startPos = x+1;
	nLines++;
	
	// Work out where the last changed line is
	int lastLine;
	for (lastLine = firstLine; lastLine < nLines; lastLine++) {
		if (lineStart < range.location + range.length) {
			break;
		}
		
		lineStart += lines[lastLine].length;
	}
	
	if (lastLine > nLines) {
		lastLine--;
		lineStart -= lines[lastLine].length;
	}
	
	// Move states around:
	//   newly added lines go after lastLine
	//   deleted lines are removed before lastLine
	if (nLines > oldnLines) {
		int diff = nLines - oldnLines;
        
        for (x = nLines-1; x > (firstLine+diff); x--) {
            lines[x].startState = lines[x-diff].startState;
            lines[x].invalid = lines[x-diff].invalid;
        }		
	} else if (nLines < oldnLines) {
        int diff = oldnLines - nLines;
        
        for (x = firstLine; x < nLines; x++) {
			lines[x].startState = lines[x+diff].startState;
			lines[x].invalid = lines[x+diff].invalid;
        }
	}
	
	// Mark lines as invalid
	for (x=firstLine; x<=lastLine; x++) {
		lines[x].invalid = YES;
	}
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
	NSRange invalid = NSMakeRange(NSNotFound, 0);
	
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
		
		return NSMakeRange(NSNotFound, 0);
		
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
	
	if (invalidRange.location != NSNotFound) {
		if (invalid.location == NSNotFound)
			invalid = invalidRange;
		else
			invalid = NSUnionRange(invalid, invalidRange);
	}
	
	return invalid;
}

- (void) colourForCharacterRange: (NSRange) range
                          buffer: (unsigned char*) buf {
    int x;
    
	// Clear the buffer
    for (x=0; x<range.length; x++) {
        buf[x] = IFSyntaxNone;
    }
	
	if (nLines <= 0) return; // Nothing to do
	
	// Run the state machine to get the start state of any invalid lines
	int line;
	int lineStart = lines[0].length;
	
	invalidRange = NSMakeRange(NSNotFound,0);
	
	lines[0].invalid = NO;
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
				if (lines[line+1].invalid == NO && state != lines[line+1].startState) {
					lines[line+1].invalid = YES;
					lines[line+1].startState = state;
					
					NSRange lineRange = NSMakeRange(lineStart + lines[line].length, lines[line+1].length);
					if (invalidRange.location == NSNotFound) {
						invalidRange = lineRange;
					} else {
						invalidRange = NSUnionRange(invalidRange, lineRange);
					}
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
				if (offset >= 0 && offset < range.length) {
					buf[offset] = Colour(state, chr);
				}
				
				state = StateMachine(state, chr);
			}
		}
		
		lineStart += lines[line].length;
	}
}

@end
