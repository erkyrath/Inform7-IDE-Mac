//
//  IFInform6Syntax.m
//  Inform
//
//  Created by Andrew Hunter on Sun Nov 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "IFInform6Syntax.h"


@implementation IFInform6Syntax

static const IFInform6State initialState = {
    0,
    { 0,0,0,0,0,0,0,0,0,1,0 },
    0,
    IFSyntaxNone
};

- (id) init {
    self = [super init];
    
    if (self) {
        nLines = 0;
        lines = NULL;
        
        lastIndex = 0;
        lastState = initialState;
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
}

// = Noting that things have changed in the file =
- (void) clearLine: (int) lineNo {
    if (lineNo < 0 || lineNo >= nLines) return;
    
    if (lines[lineNo].colour) free(lines[lineNo].colour);
    lines[lineNo].colour = NULL;
    lines[lineNo].invalid = YES;
}

- (void) clearAllLines {
    int x;
    
    for (x=0; x<nLines; x++) {
        [self clearLine: x];
    }
    
    nLines = 0;
    free(lines);
    lines = NULL;
}

- (void) invalidateAll {
    lastIndex = 0;
    lastState = initialState;
    
    [self clearAllLines];
}

- (void) invalidateCharacter: (int) chr {
    lastIndex = 0;
    lastState = initialState;
    
    [self clearAllLines]; // FIXME: just the line with this character on
}

static BOOL cmpStates(IFInform6State a, IFInform6State b) {
    if (a.inner != b.inner) return NO;
    if (a.backtrackColour != b.backtrackColour) return NO;
    if (a.outer.comment != b.outer.comment ||
        a.outer.singleQuote != b.outer.singleQuote ||
        a.outer.doubleQuote != b.outer.doubleQuote ||
        a.outer.statement != b.outer.statement ||
        a.outer.afterMarker != b.outer.afterMarker ||
        a.outer.highlight != b.outer.highlight ||
        a.outer.highlightAll != b.outer.highlightAll ||
        a.outer.colourBacktrack != b.outer.colourBacktrack ||
        a.outer.afterRestart != b.outer.afterRestart ||
        a.outer.waitingForDirective != b.outer.waitingForDirective ||
        a.outer.dontKnowFlag != b.outer.dontKnowFlag) {
        return NO;
    }
    
    return YES;
}

- (void) highlightLine: (int) line {
    int x, pos;
    int len = [file length];
    
    // Highlight any preceeding lines that need highlighting
    pos = 0;
    for (x=0; x<line; x++) {
        if (x >= nLines || lines[x].invalid) {
            [self highlightLine: x];
        }
        
        if (x >= nLines) {
            NSLog(@"BUG: tripped over the end of the lines");
            return;
        }
        
        pos += lines[x].length;
    }
    
    if (pos >= len) {
        NSLog(@"BUG: tripped over the end of the file");
        return;
    }
    
    if (line == 0 && lines == NULL) {
        // Create an initial line
        lines = malloc(sizeof(IFInform6Line));
        lines[0].invalid = YES;
        lines[0].initialState = initialState;
        lines[0].length = 0;
        lines[0].colour = NULL;
        nLines = 1;
    }
    
    if (line >= nLines) {
        NSLog(@"BUG: tripped over the end of the lines");
        return;
    }
    
    int chr;
    IFInform6State state = lines[line].initialState;
    
    lines[line].length = 0;
    
    do {
        chr = [file characterAtIndex: pos];
        
        IFInform6State newState = [self nextState: state 
                                    nextCharacter: chr];
        
        lines[line].length++;
        lines[line].colour = realloc(lines[line].colour, lines[line].length);
        lines[line].colour[lines[line].length-1] = [self initialColourForState:newState character:chr];
        
        if (newState.outer.colourBacktrack) {
            int backLen = state.inner >> 8;
            int z;
            
            newState.outer.colourBacktrack = 0;
                
            for (z=0; z<(backLen+2); z++) {
                if (z < lines[line].length)
                    lines[line].colour[lines[line].length-z-1] = newState.backtrackColour;
            }
        }

        state = newState;
        pos++;
    } while (pos < len && chr != '\n' && chr != '\r');
    
    lines[line].invalid = NO;
    
#if 0
    NSMutableString* highlights = [NSMutableString string];
    
    NSLog(@"Line: %@", [file substringWithRange: NSMakeRange(pos - lines[line].length, lines[line].length)]);
    
    int q;
    for (q=0; q<lines[line].length; q++) {
        int c = '?';
        
        switch (lines[line].colour[q]) {
            case IFSyntaxNone: c = 'N'; break;
            case IFSyntaxString: c = 'Q'; break;
            case IFSyntaxComment: c = '!'; break;
            
            // Inform 6 syntax types
            case IFSyntaxDirective: c = 'D'; break;
            case IFSyntaxProperty: c = 'P'; break;
            case IFSyntaxFunction: c = 'F'; break;
            case IFSyntaxCode: c = 'C'; break;
            case IFSyntaxCodeAlpha: c = 'c'; break;
            case IFSyntaxAssembly: c = '@'; break;
            case IFSyntaxEscapeCharacter: c = 'E'; break;
        }
        
        [highlights appendFormat: @"%c", c];
    }
    
    NSLog(@"Attr: %@", highlights);
#endif
    
    if (nLines <= line+1) {
        // Add the following line
        nLines++;
        lines = realloc(lines, sizeof(IFInform6Line)*nLines);
        lines[line+1].invalid = YES;
        lines[line+1].initialState = state;
        lines[line+1].length = 0;
        lines[line+1].colour = NULL;
    } else {
        if (!cmpStates(state, lines[line+1].initialState)) {
            // Following line has become invalidated
            [self clearLine: line+1];
        }
    }
}

- (int) lineForChar: (int) index
           position: (int*) posOut {
    int x, pos;
    
    if (nLines == 0) [self highlightLine: 0];

    pos = 0;
    
    for (x=0; x<nLines; x++) {
        if (lines[x].invalid) {
            [self highlightLine: x];
        }
        
        if (posOut) *posOut = pos;
        pos += lines[x].length;
        if (pos > index) return x;
    }
    
    NSLog(@"??? Ran over end of file ???");
    
    *posOut = pos;
    return nLines;
}

- (int) lineForChar: (int) index {
    return [self lineForChar: index position: NULL];
}

// = Getting information about a character = 
- (enum IFSyntaxType) colourForCharacterAtIndex: (int) index {    
    // Get the colour
    int pos;
    int line = [self lineForChar: index
                        position: &pos];
    
    index -= pos;
    if (index >= lines[line].length) {
        NSLog(@"BUG: ran over end of line");
        return IFSyntaxNone;
    }
    
    return lines[line].colour[index];
}

// = The statemachine itself =
- (IFInform6State) nextState: (IFInform6State) state
               nextCharacter: (int) chr {
    IFInform6State newState = state;
    
    // 1.  Is the comment bit set?
    //        Is the character a new-line?
    //           If so, clear the comment bit.
    //           Stop.

    if (state.outer.comment) {
        if (chr == '\n' || chr == '\r') {
            newState.outer.comment = 0;
        }
        return newState;
    }
    
    // 2.  Is the double-quote bit set?
    //        Is the character a double-quote?
    //           If so, clear the double-quote bit.
    //           Stop.
    
    if (state.outer.doubleQuote) {
        if (chr == '"') {
            newState.outer.doubleQuote = 0;
        }
        return newState;
    }
    
    // 3.  Is the single-quote bit set?
    //        Is the character a single-quote?
    //           If so, clear the single-quote bit.
    //           Stop.
    
    if (state.outer.singleQuote) {
        if (chr == '\'') {
            newState.outer.singleQuote = 0;
        }
        return newState;
    }
    
    // 4.  Is the character a single quote?
    //        If so, set the single-quote bit and stop.
    
    if (chr == '\'') {
        newState.outer.singleQuote = 1;
        return newState;
    }
    
    // 5.  Is the character a double quote?
    //        If so, set the double-quote bit and stop.
    
    if (chr == '"') {
        newState.outer.doubleQuote = 1;
        return newState;
    }
    
    // 6.  Is the character an exclamation mark?
    //        If so, set the comment bit and stop.
    
    if (chr == '!') {
        newState.outer.comment = 1;
        return newState;
    }
    
    // 7.  Is the statement bit set?
    if (state.outer.statement) {
        //        If so:
        //           Is the character "]"?
        //              If so:
        //                 Clear the statement bit.
        //                 Stop.
        
        if (chr == ']') {
            newState.outer.statement = 0;
            return newState;
        }
        
        //           If the after-restart bit is clear, stop.
        
        if (state.outer.afterRestart) {
            return newState;
        }
        
        //           Run the inner finite state machine.
        
        BOOL terminalFlag = [self innerStateMachine: &newState
                                          character: chr];
        
        //           If it results in a keyword terminal (that is, a terminal
        //           which has inner state 0x100 or above):
        //              Set colour-backtrack (and record the backtrack colour
        //              as "function" colour).
        //              Clear after-restart.
        
        if (terminalFlag && newState.inner >= 0x100) {
            newState.outer.colourBacktrack = 1;
            newState.backtrackColour = IFSyntaxFunction;
            newState.outer.afterRestart = 0;
        }
        
        //           Stop.

        return newState;
    } else {
        //        If not:
        //           Is the character "["?
        //              If so:
        //                 Set the statement bit.
        //                 If the after-marker bit is clear, set after-restart.
        //                 Stop.
        
        if (chr == '[') {
            newState.outer.statement = 1;
            if (newState.outer.afterMarker)
                newState.outer.afterRestart = 1;
            return newState;
        }
        
        //           Run the inner finite state machine.
        
        BOOL terminalFlag = [self innerStateMachine: &newState
                                          character: chr];
        
        //           If it results in a terminal:
        if (terminalFlag) {
            //              Is the inner state 2 [after "->"] or 3 [after "*"]?
            //                 If so:
            //                    Set after-marker.
            //                    Set colour-backtrack (and record the backtrack
            //                    colour as "directive" colour).
            //                    Zero the inner state.
            
            if (newState.inner == 2) {
                newState.outer.afterMarker = 1;
                newState.outer.colourBacktrack = 1;
                newState.backtrackColour = IFSyntaxDirective;
                newState.inner = 0;
            }
            
            //              [If not, the terminal must be from a keyword.]
            //              Is the inner state 0x404 [after "with"]?
            //                 If so:
            //                    Set colour-backtrack (and record the backtrack
            //                    colour as "directive" colour).
            //                    Set after-marker.
            //                    Set highlight.
            //                    Clear highlight-all.
            
            else if (newState.inner == 0x404) {
                newState.outer.colourBacktrack = 1;
                newState.backtrackColour = IFSyntaxDirective;
                newState.outer.afterMarker = 1;
                newState.outer.highlight = 1;
                newState.outer.highlightAll = 0;
            }
            
            //              Is the inner state 0x313 ["has"] or 0x525 ["class"]?
            //                 If so:
            //                    Set colour-backtrack (and record the backtrack
            //                    colour as "directive" colour).
            //                    Set after-marker.
            //                    Clear highlight.
            //                    Set highlight-all.
            
            else if (newState.inner == 0x313 || newState.inner == 0x525) {
                newState.outer.colourBacktrack = 1;
                newState.backtrackColour = IFSyntaxDirective;
                newState.outer.afterMarker = 1;
                newState.outer.highlight = 0;
                newState.outer.highlightAll = 1;
            }
            
            //              If the inner state isn't one of these: [so that recent
            //              text has formed some alphanumeric token which might or
            //              might not be a reserved word of some kind]
            //                 If waiting-for-directive is set:
            //                       Set colour-backtrack (and record the backtrack
            //                       colour as "directive" colour)
            //                       Clear waiting-for-directive.
            //                 If not, but highlight-all is set:
            //                       Set colour-backtrack (and record the backtrack
            //                       colour as "property" colour)
            //                 If not, but highlight is set:
            //                       Clear highlight.
            //                       Set colour-backtrack (and record the backtrack
            //                       colour as "property" colour).

            else {
                if (newState.outer.waitingForDirective) {
                    newState.outer.colourBacktrack = 1;
                    newState.backtrackColour = IFSyntaxDirective;
                    newState.outer.waitingForDirective = 0;
                } else if (newState.outer.highlightAll) {
                    newState.outer.colourBacktrack = 1;
                    newState.backtrackColour = IFSyntaxProperty;
                } else if (newState.outer.highlight) {
                    newState.outer.highlight = 0;
                    newState.outer.colourBacktrack = 1;
                    newState.backtrackColour = IFSyntaxProperty;
                }
            }
            
            //              Is the character ";"?
            //                 If so:
            //                    Set wait-direct.
            //                    Clear after-marker.
            //                    Clear after-restart.
            //                    Clear highlight.
            //                    Clear highlight-all.
            
            if (chr == ';') {
                newState.outer.waitingForDirective = 1;
                newState.outer.afterMarker = 0;
                newState.outer.afterRestart = 0;
                newState.outer.highlight = 0;
                newState.outer.highlightAll = 0;
            }
            
            //              Is the character ","?
            //                 If so:
            //                    Set after-marker.
            //                    Set highlight.
            
            if (chr == ',') {
                newState.outer.afterMarker = 1;
                newState.outer.highlight = 1;
            }
        }

        //           Stop.
        
        return newState;
    }
    
    return newState;
}

- (BOOL) innerStateMachine: (IFInform6State*) state
                 character: (int) chr {
    BOOL terminalFlag = NO;
    
    chr = tolower(chr);
    
    if (state->inner == 0) {
        switch (chr) {
            case '-':
                state->inner = 1;
                break;
            case '*':
                state->inner = 3;
                terminalFlag = YES;
                break;
            case ' ': case '#': case '\n': case '\r':
                state->inner = 0;
                break;
            case '_':
                state->inner = 0x100;
                break;
            case 'w':
                state->inner = 0x101;
                break;
            case 'h':
                state->inner = 0x111;
                break;
            case 'c':
                state->inner = 0x121;
                break;
            default:
                if (isalpha(chr)) state->inner = 0x100; else state->inner = 0xff;
        }
    } else if (state->inner == 1) {
        if (chr == '>') {
            state->inner = 2;
            terminalFlag = YES;
        } else {
            state->inner = 0xff;
        }
    } else if (state->inner == 2) {
        state->inner = 0;
    } else if (state->inner == 3) {
        state->inner = 0;
    } else if (state->inner == 0xff) {
        if (chr == ' ' || chr == '\n' || chr == '\r') {
            state->inner = 0;
        } else {
            state->inner = 0xff;
        }
    } else if (state->inner >= 0x100) {
        if (!(isalpha(chr) || isdigit(chr))) {
            state->inner += 0x8000;
            terminalFlag = YES;
        }        

        switch (state->inner) {
            case 0x101:
                if (chr == 'i')
                    state->inner = 0x202;
                else
                    state->inner = 0x200;
                break;
            case 0x202:
                if (chr == 't')
                    state->inner = 0x303;
                else
                    state->inner = 0x300;
                break;
            case 0x303:
                if (chr == 'h')
                    state->inner = 0x404;
                else
                    state->inner = 0x400;
                break;
            case 0x111:
                if (chr == 'a')
                    state->inner = 0x212;
                else
                    state->inner = 0x200;
                break;
            case 0x212:
                if (chr == 's')
                    state->inner = 0x313;
                else
                    state->inner = 0x300;
                break;
            case 0x121:
                if (chr == 'l')
                    state->inner = 0x222;
                else
                    state->inner = 0x200;
                break;
            case 0x222:
                if (chr == 'a')
                    state->inner = 0x323;
                else
                    state->inner = 0x300;
                break;
            case 0x323:
                if (chr == 's')
                    state->inner = 0x424;
                else
                    state->inner = 0x400;
                break;
            case 0x424:
                if (chr == 's')
                    state->inner = 0x525;
                else
                    state->inner = 0x500;
                break;
                
            default:
                if (state->inner < 0x8000) {
                    if (isalpha(chr) || isdigit(chr)) {
                        state->inner += 0x100;
                    }
                } else {
                    state->inner = 0;
                }
        }
    }
        
    return terminalFlag;
}

- (enum IFSyntaxType) initialColourForState: (IFInform6State) state 
                             character: (int) chr {
    if (state.outer.singleQuote || state.outer.doubleQuote) return IFSyntaxString;
    if (state.outer.comment) return IFSyntaxComment;
    if (state.outer.statement) {
        if (chr == '[' || chr == ']') return IFSyntaxFunction;
        if (chr == '\'' || chr == '"') return IFSyntaxString;
        return IFSyntaxCode;
    }
    
    if (chr == ',' || chr == ';' || chr == '*' || chr == '>') return IFSyntaxDirective;
    if (chr == '[' || chr == ']') return IFSyntaxFunction;
    if (chr == '\'' || chr == '"') return IFSyntaxString;
    
    // IMPLEMENT ME: colour backtracking
    return IFSyntaxNone;
}

@end
