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

static NSSet* codeKeywords;
static NSSet* otherKeywords;

+ (void) initialize {
    codeKeywords = [[NSSet setWithObjects:
        @"box", @"break", @"child", @"children", @"continue", @"default",
        @"do", @"elder", @"eldest", @"else", @"false", @"font", @"for", @"give",
        @"has", @"hasnt", @"if", @"in", @"indirect", @"inversion", @"jump",
        @"metaclass", @"move", @"new_line", @"nothing", @"notin", @"objectloop",
        @"ofclass", @"or", @"parent", @"print", @"print_ret", @"provides", @"quit",
        @"random", @"read", @"remove", @"restore", @"return", @"rfalse", @"rtrue",
        @"save", @"sibling", @"spaces", @"string", @"style", @"switch", @"to",
        @"true", @"until", @"while", @"younger", @"youngest"]
        retain];
    
    otherKeywords = [[NSSet setWithObjects: 
        @"first", @"last", @"meta", @"only", @"private", @"replace", @"reverse",
        @"string", @"table"]
        retain];
}

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
    // Get the colour
    int pos;
    int line = [self lineForChar: chr
                        position: &pos];
    
    lines[line].invalid = YES;
    
    // Recalculate the length of the line
    lines[line].length = 1;
    while (pos < [file length] && [file characterAtIndex: pos] != '\n' && [file characterAtIndex: pos] != '\r') {
        lines[line].length++;
        pos++;
    }
}

- (NSRange) invalidRange {
    int pos = 0;
    int line;
    
    if (nLines == 0) {
        // Whole file has been invalidated
        return NSMakeRange(0, [file length]);
    }
    
    // Range is all the invalid lines
    NSRange res = NSMakeRange(NSNotFound, 0);
    
    for (line=0; line<nLines; line++) {
        if (lines[line].invalid && lines[line].length > 0) {
            if (res.location == NSNotFound) {
                res = NSMakeRange(pos, lines[line].length);
            } else {
                res = NSUnionRange(res, NSMakeRange(pos, lines[line].length));
            }
        }
        
        pos += lines[line].length;
    }
    
    return res;
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

- (NSString*) stateToString: (IFInform6State) state {
    return [NSString stringWithFormat: @"Com: %i sQ: %i dQ: %i S: %i aM: %i hl: %i hlA: %i cB: %i aR: %i wfD: %i dkF: %i. Inner: %x",
        state.outer.comment, state.outer.singleQuote, state.outer.doubleQuote, state.outer.statement, state.outer.afterMarker,
        state.outer.highlight, state.outer.highlightAll, state.outer.colourBacktrack, state.outer.afterRestart,
        state.outer.waitingForDirective, state.outer.dontKnowFlag,
        state.inner];
}

static inline BOOL IsIdentifier(int chr) {
    if (isalpha(chr) || isdigit(chr) || chr == '$' || chr == '#' || chr == '_') {
        return YES;
    } else {
        return NO;
    }
}

- (void) refineLine: (int) line 
         characters: (NSString*) str {
    int x;
    int chr;
    
    // Firstly, any characters with colour Q (quoted-text) which have special
    // meanings are given "escape-character colour" instead.  This applies
    // to "~", "^", "\" and "@" followed by (possibly) another "@" and a
    // number of digits.
    
    for (x=0; x<lines[line].length; x++) {
        if (lines[line].colour[x] == IFSyntaxString) {
            chr = [str characterAtIndex: x];
            
            switch (chr) {
                case '~': case '^': case '\\':
                    lines[line].colour[x] = IFSyntaxEscapeCharacter;
                    break;
                    
                case '@':
                    lines[line].colour[x] = IFSyntaxEscapeCharacter;
                    
                    if ((x+1) < lines[line].length) {
                        chr = [str characterAtIndex: x+1];
                        
                        if (chr == '@') {
                            x++;
                            lines[line].colour[x] = IFSyntaxEscapeCharacter;
                        }
                    }
                    
                    do {
                        x++;
                        if (x >= lines[line].length) break;
                        
                        chr = [str characterAtIndex: x];
                        
                        if (isdigit(chr)) lines[line].colour[x] = IFSyntaxEscapeCharacter;
                    } while (isdigit(chr));
                    break;
            }
        }
    }

    // Next we look for identifiers.  An identifier for these purposes includes
    // a number, for it is just a sequence of:
    
    //      "_" or "$" or "#" or "0" to "9" or "a" to "z" or "A" to "Z".

    for (x=0; x<lines[line].length; x++) {
        int identifierLen = 0;
        int identifierStart = x;
        unsigned char colour = lines[line].colour[identifierStart];
        
        chr = [str characterAtIndex: x];
        
        if (colour != IFSyntaxCode &&
            colour != IFSyntaxNone) {
            // No further highlighting will be required
            continue;
        }
        
        while (IsIdentifier(chr)) {
            identifierLen++;
            
            x++;
            if (x >= lines[line].length) break;
            
            chr = [str characterAtIndex: x];
        }
        
        if (identifierLen == 0) continue;

        // The initial colouring of an identifier tells us its context.  We're
        // only interested in those in foreground colour (these must be used
        // in the body of a directive) or code colour (used in statements).
        
        unsigned char newColour = 0xff;

        if (colour == IFSyntaxCode) {
            // If an identifier is in code colour, then:

            if (identifierStart > 0 && [str characterAtIndex: identifierStart-1] == '@') {
                //     If it follows an "@", recolour the "@" and the identifier in
                //        assembly-language colour.
                identifierStart--;
                identifierLen++;
                newColour = IFSyntaxAssembly;
            } else {
                //     Otherwise, unless it is one of the following:
            
                //       "box"  "break"  "child"  "children"  "continue"  "default"
                //       "do"  "elder"  "eldest"  "else"  "false"  "font"  "for"  "give"
                //       "has"  "hasnt"  "if"  "in"  "indirect"  "inversion"  "jump"
                //       "metaclass"  "move"  "new_line"  "nothing"  "notin"  "objectloop"
                //       "ofclass"  "or"  "parent"  "print"  "print_ret"  "provides"  "quit"
                //       "random"  "read"  "remove"  "restore"  "return"  "rfalse"  "rtrue"
                //       "save"  "sibling"  "spaces"  "string"  "style"  "switch"  "to"
                //       "true"  "until"  "while"  "younger"  "youngest"
        
                //     we recolour the identifier to "codealpha colour".
                
                NSString* idString = [str substringWithRange: NSMakeRange(identifierStart, identifierLen)];
                idString = [idString lowercaseString];
                if (![codeKeywords containsObject: idString]) newColour = IFSyntaxCodeAlpha;
            }
        } else if (colour == IFSyntaxNone) {
            // On the other hand, if an identifier is in foreground colour, then we
            // check it to see if it's one of the following interesting keywords:
        
            //       "first"  "last"  "meta"  "only"  "private"  "replace"  "reverse"
            //       "string"  "table"
        
            // If it is, we recolour it in directive colour.

            NSString* idString = [str substringWithRange: NSMakeRange(identifierStart, identifierLen)];
            idString = [idString lowercaseString];
            if ([otherKeywords containsObject: idString]) newColour = IFSyntaxDirective;
        }
        
        if (newColour != 0xff) {
            int y;
            
            for (y=0; y<identifierLen; y++) {
                lines[line].colour[identifierStart+y] = newColour;
            }
        }
    }
}

- (void) highlightLine: (int) line {
    int x, pos, lineStart;
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
    
    lineStart = pos;
    lines[line].length = 0;
    
    do {
        chr = [file characterAtIndex: pos];
        
        IFInform6State newState = [self nextState: state 
                                    nextCharacter: chr];
        
        lines[line].length++;
        lines[line].colour = realloc(lines[line].colour, lines[line].length);
        lines[line].colour[lines[line].length-1] = [self initialColourForState:newState character:chr];
        
        if (newState.outer.colourBacktrack) {
            int backLen = newState.inner;
            int z;
            
            backLen &= ~0x8000;
            backLen >>= 8;
            backLen++;
            
            newState.outer.colourBacktrack = 0;
            
            if (backLen == 0) { backLen = 1; printf("-- 0 --\n"); }
                
            for (z=0; z<backLen; z++) {
                if (z < lines[line].length)
                    lines[line].colour[lines[line].length-z-1] = newState.backtrackColour;
                    //lines[line].colour[lines[line].length-z-1] = newState.backtrackColour;
            }
        }

        state = newState;
        pos++;
    } while (pos < len && chr != '\n' && chr != '\r');
    
    [self refineLine: line
          characters: [file substringWithRange: NSMakeRange(lineStart, lines[line].length)]];
    
    lines[line].invalid = NO;
    
#if 0
    NSMutableString* highlights = [NSMutableString string];
    
    NSLog(@"Pos: %i Length: %i End: %i Start state: %@", pos-lines[line].length, lines[line].length, pos, [self stateToString: lines[line].initialState]);
    NSLog(@"Line: '%@'", [file substringWithRange: NSMakeRange(pos - lines[line].length, lines[line].length)]);
    
    int q;
    for (q=0; q<lines[line].length; q++) {
        int c = '?';
        
        switch (lines[line].colour[q]) {
            case IFSyntaxNone: c = 'F'; break;
            case IFSyntaxString: c = 'Q'; break;
            case IFSyntaxComment: c = 'C'; break;
            
            // Inform 6 syntax types
            case IFSyntaxDirective: c = 'D'; break;
            case IFSyntaxProperty: c = 'P'; break;
            case IFSyntaxFunction: c = 'f'; break;
            case IFSyntaxCode: c = 'S'; break;
            case IFSyntaxCodeAlpha: c = 'c'; break;
            case IFSyntaxAssembly: c = '@'; break;
            case IFSyntaxEscapeCharacter: c = 'E'; break;
        }
        
        [highlights appendFormat: @"%c", c];
    }
    
    NSLog(@"Attr: '%@'", highlights);
#endif
    
    if (nLines <= line+1) {
        // Add the following line
        nLines++;
        lines = realloc(lines, sizeof(IFInform6Line)*nLines);
        lines[line+1].invalid = YES;
        lines[line+1].length = 0;
        lines[line+1].colour = NULL;
    } else {
        if (!cmpStates(state, lines[line+1].initialState)) {
            // Following line has become invalidated
            [self clearLine: line+1];
        }
    }

    lines[line+1].initialState = state;
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
    
    return (IFSyntaxType)(lines[line].colour[index]);
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
        
        if (state.outer.afterRestart == 0) {
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
            if (newState.outer.afterMarker == 0)
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
            
            else if (newState.inner == 0x8404) {
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
            
            else if (newState.inner == 0x8313 || newState.inner == 0x8525) {
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

        //           Stop.
        
        return newState;
    }
    
    return newState;
}

- (BOOL) innerStateMachine: (IFInform6State*) state
                 character: (int) chr {
    BOOL terminalFlag = NO;
    
    //chr = tolower(chr);
    if (state->inner >= 0x8000) {
        state->inner = 0;
    }
    
    if (state->inner == 0) {
        switch (chr) {
            case '-':
                state->inner = 1;
                break;
            case '*':
                state->inner = 3;
                terminalFlag = YES;
                break;
            case ' ': case '\t': case '#': case '\n': case '\r':
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
        if (chr == ' ' || chr == '\t' || chr == '\n' || chr == '\r') {
            state->inner = 0;
        } else {
            state->inner = 0xff;
        }
    } else if (state->inner >= 0x100 && state->inner < 0x8000) {
        if (!(isalpha(chr) || isdigit(chr))) {
            state->inner += 0x8000;
            return terminalFlag = YES;
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
                if (isalpha(chr) || isdigit(chr)) {
                    state->inner += 0x100;
                }
                break;
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
