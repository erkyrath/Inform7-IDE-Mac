//
//  IFInform6Syntax.m
//  Inform
//
//  Created by Andrew Hunter on Sun Nov 30 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFInform6Syntax.h"

#undef logInvalidates

@implementation IFInform6Syntax

static const IFInform6State initialState = {
    0,
    { 0,0,0,0,0,0,0,0,0,1,0 },
    0,
    IFSyntaxNone
};

static NSSet* codeKwSet;
static NSSet* otherKwSet;

// We use cStrings instead for speed reasons (NSSets are very slow for the amount of
// lookups we need to do)
static int    numCodeKeywords = 0;
static char** codeKeywords = NULL;
static int    numOtherKeywords = 0;
static char** otherKeywords = NULL;

static inline BOOL FindKeyword(char** keywordList, int nKeywords, const char* keyword) {	
    int bottom = 0;
    int top = nKeywords-1;
    
    int pos;
    
    while (top > bottom) {
        pos = (top+bottom)>>1;
        
        int cmp = strcmp(keywordList[pos], keyword);
        
        if (cmp == 0) return YES;
        if (cmp < 0) bottom = pos+1;
        if (cmp > 0) top = pos-1;
    }
    
    if (top == bottom && strcmp(keywordList[top], keyword) == 0) return YES;
    
    return NO;
}

static int compare(const void* a, const void* b) {
    return strcmp(*((const char**)a),*((const char**)b));
}

+ (void) initialize {
    codeKwSet = [[NSSet setWithObjects:
        @"box", @"break", @"child", @"children", @"continue", @"default",
        @"do", @"elder", @"eldest", @"else", @"false", @"font", @"for", @"give",
        @"has", @"hasnt", @"if", @"in", @"indirect", @"inversion", @"jump",
        @"metaclass", @"move", @"new_line", @"nothing", @"notin", @"objectloop",
        @"ofclass", @"or", @"parent", @"print", @"print_ret", @"provides", @"quit",
        @"random", @"read", @"remove", @"restore", @"return", @"rfalse", @"rtrue",
        @"save", @"sibling", @"spaces", @"string", @"style", @"switch", @"to",
        @"true", @"until", @"while", @"younger", @"youngest", nil]
        retain];
    
    otherKwSet = [[NSSet setWithObjects: 
        @"first", @"last", @"meta", @"only", @"private", @"replace", @"reverse",
        @"string", @"table", nil]
        retain];
    
    NSEnumerator* enumerator = [codeKwSet objectEnumerator];
    NSString* key;
    
    while (key = [enumerator nextObject]) {
        const char* str = [[key lowercaseString] cString];
        
        numCodeKeywords++;
        
        codeKeywords = realloc(codeKeywords, sizeof(char*) * (numCodeKeywords+1));
        codeKeywords[numCodeKeywords-1] = malloc(strlen(str)+1);
        strcpy(codeKeywords[numCodeKeywords-1], str);
    }
    
    enumerator = [otherKwSet objectEnumerator];
    
    while (key = [enumerator nextObject]) {
        const char* str = [[key lowercaseString] cString];
        
        numOtherKeywords++;
        
        otherKeywords = realloc(otherKeywords, sizeof(char*) * (numOtherKeywords+1));
        otherKeywords[numOtherKeywords-1] = malloc(strlen(str)+1);
        strcpy(otherKeywords[numOtherKeywords-1], str);
    }
    
    qsort(codeKeywords, numCodeKeywords, sizeof(char*), compare);
    qsort(otherKeywords, numOtherKeywords, sizeof(char*), compare);
}

- (id) init {
    self = [super init];
    
    if (self) {
        nLines = 0;
        lines = NULL;
        
        lastIndex = 0;
        lastLine = 0;
        lastPos = 0;
        
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
    lines[lineNo].needsDisplay = YES;
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
    lastLine = 0;
    lastPos = 0;
    
    lastState = initialState;
    
    [self clearAllLines];
}

- (void) _invalidateRange: (NSRange) range {
    int line;
    int pos = 0;

    lastIndex = lastPos = lastLine = 0;

    for (line = 0; line < nLines; line++) {
        NSRange lineRange = NSMakeRange(pos, lines[line].length);
        
        if (NSIntersectionRange(lineRange, range).length != 0) {
            lines[line].invalid = YES;
            lines[line].needsDisplay = YES;

#ifdef logInvalidates
            NSLog(@"Line %i invalidated: editing", line);
#endif
        }
        
        pos += lines[line].length;
    }
}

- (void) invalidateRange: (NSRange) range {
    int line, pos;
    int lineLength;
    int len;
    
    if (range.location > 0) {
        range.location -= 1;
        range.length += 2;
    }
    
    // First, invalidate as the line list currently stands
    // (This deals with deletions)
    [self _invalidateRange: range];
    
    // Next, recalculate the line endings, and delete/add any lines that
    // have appeared/been removed (extra lines go just after the f
    line = 0;
    pos = 0;
    len = [file length];
    lineLength = 0;
    
    if (lines == NULL) {
        nLines = 1;
        lines = realloc(lines, sizeof(IFInform6Line)*nLines);
        lines[line].invalid = YES;
        lines[line].needsDisplay = YES;
        lines[line].length = 0;
        lines[line].colour = NULL;
    }
    
    int oldnLines = nLines;
    
    while (pos < len) {
        lineLength++;
        int chr = [file characterAtIndex: pos];
        
        if (chr == '\n' || chr == '\r' || pos == (len-1)) {
            // Line ending reached
            if (lines[line].length != lineLength) {
                lines[line].length = lineLength;
                //lines[line].invalid = YES; (EXPERIMENTAL)
                //lines[line].needsDisplay = YES;
                
#ifdef logInvalidates
                //NSLog(@"Line %i invalidated: length different", line);
#endif
            }

            // Next line
            line++;
            lineLength = 0;
            
            if (line >= nLines) {
                // Add extra lines at the end
                nLines++;
                lines = realloc(lines, sizeof(IFInform6Line)*nLines);
                lines[line].invalid = YES;
                lines[line].needsDisplay = YES;
                lines[line].length = 0;
                lines[line].colour = NULL;                

#ifdef logInvalidates
                NSLog(@"Line %i invalidated: # lines in file different", line);
#endif
            }
        }
        
        pos++;
    }
    
    // Any new lines should actually be inserted just after the first line in the
    // range
    int x;
    int firstLine, firstPos;
    firstLine = [self lineForChar: range.location
                         position: &firstPos];
    
    if (nLines > oldnLines) {
        int diff = nLines - oldnLines;
        
        // extra lines go after firstLine
        //firstLine++;
        
        for (x = nLines-1; x > (firstLine+diff); x--) {
            if (lines[x].colour) free(lines[x].colour);
            
            lines[x].colour = lines[x-diff].colour;
            lines[x].initialState = lines[x-diff].initialState;
            lines[x].invalid = lines[x-diff].invalid;
            lines[x].needsDisplay = lines[x-diff].needsDisplay;
            
            lines[x-diff].colour = NULL;
            lines[x-diff].invalid = YES;
        }
        
        // These lines are now invalid
        for (x=firstLine; x<firstLine+diff; x++) {
            lines[x].colour = NULL;
            lines[x].invalid = YES;
        }

        lines[firstLine].invalid = YES;
    } else if (nLines < oldnLines) {
        // Deleted lines are after firstLine
        int diff = oldnLines - nLines;
        
        //firstLine++;
        for (x = firstLine; x < nLines; x++) {
            if (lines[x].colour) free(lines[x].colour);
            
            lines[x].colour = lines[x+diff].colour;
            lines[x+diff].colour = NULL;
            lines[x].invalid = NO;
            lines[x].needsDisplay = NO;
        }
        
        lines[firstLine].invalid = YES;
    }
        
    
    // Delete lines from the beginning
    
    for (x=line; x<nLines; x++) {
        [self clearLine: x];
    }
     
    // Final line allocation
    nLines = (line+1);
    lines = realloc(lines, sizeof(IFInform6Line)*nLines);
    lines[line].invalid = YES;
    lines[line].needsDisplay = YES;
    lines[line].length = 0;
    lines[line].colour = NULL;                
    
#ifdef logInvalidates
    NSLog(@"Line %i invalidated: end of file", line);
#endif
    
    // Now, invalidate against the new line list
    [self _invalidateRange: range];
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
        if ((lines[line].invalid || lines[line].needsDisplay) && lines[line].length > 0) {
            if (res.location == NSNotFound) {
                res = NSMakeRange(pos, lines[line].length);
            } else {
                res = NSUnionRange(res, NSMakeRange(pos, lines[line].length));
            }
        }
        
        pos += lines[line].length;
    }
    
    if (res.location != NSNotFound && res.length != 0) {
        if (res.location + res.length > [file length]) {
            res.length = [file length] - res.location;
        }
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
         characters: (const char*) str {
    int x;
    int chr;
    
    // Firstly, any characters with colour Q (quoted-text) which have special
    // meanings are given "escape-character colour" instead.  This applies
    // to "~", "^", "\" and "@" followed by (possibly) another "@" and a
    // number of digits.
    
    for (x=0; x<lines[line].length; x++) {
        if (lines[line].colour[x] == IFSyntaxString) {
            chr = str[x];
            
            switch (chr) {
                case '~': case '^': case '\\':
                    lines[line].colour[x] = IFSyntaxEscapeCharacter;
                    break;
                    
                case '@':
                    lines[line].colour[x] = IFSyntaxEscapeCharacter;
                    
                    if ((x+1) < lines[line].length) {
                        chr = str[x+1];
                        
                        if (chr == '@') {
                            x++;
                            lines[line].colour[x] = IFSyntaxEscapeCharacter;
                        }
                    }
                    
                    do {
                        x++;
                        if (x >= lines[line].length) break;
                        
                        chr = str[x];
                        
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
        
        chr = str[x];
        
        if (colour != IFSyntaxCodeAlpha &&
            colour != IFSyntaxNone) {
            // No further highlighting will be required
            continue;
        }
        
        while (IsIdentifier(chr)) {
            identifierLen++;
            
            x++;
            if (x >= lines[line].length) break;
            
            chr = str[x];
        }
        
        if (identifierLen == 0) continue;
		if (identifierLen > 10) continue;

        // The initial colouring of an identifier tells us its context.  We're
        // only interested in those in foreground colour (these must be used
        // in the body of a directive) or code colour (used in statements).
        
        unsigned char newColour = 0xff;

        if (colour == IFSyntaxCodeAlpha) {
            // If an identifier is in code colour, then:

            if (identifierStart > 0 && str[identifierStart-1] == '@') {
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
                char* identifier = malloc(identifierLen+1);
                identifier = strncpy(identifier, str + identifierStart, identifierLen);
                identifier[identifierLen] = 0;
                
                if (FindKeyword(codeKeywords, numCodeKeywords, identifier)) newColour = IFSyntaxCode;
                
                free(identifier);
            }
        } else if (colour == IFSyntaxNone) {
            // On the other hand, if an identifier is in foreground colour, then we
            // check it to see if it's one of the following interesting keywords:
        
            //       "first"  "last"  "meta"  "only"  "private"  "replace"  "reverse"
            //       "string"  "table"
        
            // If it is, we recolour it in directive colour.

            char* identifier = malloc(identifierLen+1);
            identifier = strncpy(identifier, str + identifierStart, identifierLen);
            identifier[identifierLen] = 0;
            
            if (FindKeyword(otherKeywords, numOtherKeywords, identifier)) newColour = IFSyntaxDirective;
            
            free(identifier);
        }
        
        if (newColour != 0xff) {
            register int y;
			register char* col = lines[line].colour + identifierStart;
			
            for (y=0; y<identifierLen; y++) {
                *(col++) = newColour;
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
        lines[0].needsDisplay = YES;
        lines[0].initialState = initialState;
        lines[0].length = 0;
        lines[0].colour = NULL;
        nLines = 1;

#ifdef logInvalidates
        NSLog(@"Line %i invalidated: start of file", line);
#endif
    }
    
    if (line >= nLines) {
#ifdef logInvalidates
        NSLog(@"BUG: tripped over the end of the lines");
#endif
        return;
    }
    
    int chr;
    IFInform6State state = lines[line].initialState;
    
    lineStart = pos;
    lines[line].length = 0;
    lines[line].needsDisplay = YES;
    
    // Actually perform the highlighting
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
          characters: [[file substringWithRange: NSMakeRange(lineStart, lines[line].length)] cString]];
    
    lines[line].invalid = NO;
   
    if (nLines <= line+1) {
        // Add the following line
        nLines++;
        lines = realloc(lines, sizeof(IFInform6Line)*nLines);
        lines[line+1].invalid = YES;
        lines[line+1].needsDisplay = YES;
        lines[line+1].length = 0;
        lines[line+1].colour = NULL;

#ifdef logInvalidates
        NSLog(@"Line %i invalidated: newly added", line);
#endif
    } else {
        if (!cmpStates(state, lines[line+1].initialState)) {
            // Following line has become invalidated
            [self clearLine: line+1];

#ifdef logInvalidates
            NSLog(@"Line %i invalidated: state different", line+1);
#endif
        }
    }

    lines[line+1].initialState = state;
    
    // Delete any lines that fall off the end of the file
    if (pos >= len) {
        int x;
        
        for (x = (line+1); x < nLines; x++) {
            [self clearLine: x];
            lines[x].length = 0;
        }
        
        if (nLines > line+1) {
            nLines = line+1;
            
            lines = realloc(lines, sizeof(IFInform6Line)*nLines);
        }
    }
}

- (int) lineForChar: (int) index
           position: (int*) posOut {
    int x, pos;
    
    if (nLines == 0) [self highlightLine: 0];
    
    if (index < lastIndex) {
        // Reset if we move backwards
        lastIndex = lastPos = lastLine = 0;
    }

    // Otherwise move forward from where we were
    pos = 0;
    
    for (x=0; x<nLines; x++) {
        if (lines[x].invalid) {
            [self highlightLine: x];
        }
        
        if (posOut) *posOut = pos;
        pos += lines[x].length;

        if (pos > index) {
            lastPos = *posOut;
            lastLine = x;
            
            return x;
        }
    }
    
    NSLog(@"??? Ran over end of file ???");
    
    *posOut = pos;
    return nLines;
}

- (int) lineForChar: (int) index {
    return [self lineForChar: index position: NULL];
}

// = Getting information about a character = 
- (void) colourForCharacterRange: (NSRange) range
                          buffer: (unsigned char*) buf {
    int x;
    int index = range.location;
    int line, pos;
    
    // Get the start of the line
    line = [self lineForChar: index
                    position: &pos];
    
    index -= pos;    
    
    lines[line].needsDisplay = NO;
    
    // Fill the buffer
    for (x=0; x<range.length; x++) {
        buf[x] = lines[line].colour[index];
        
        if (x<range.length-1) {
            index++;
            if (index >= lines[line].length) {
                pos += lines[line].length;
                line++;
                if (pos < [file length]) [self highlightLine: line];
                index = 0;
            
                lines[line].needsDisplay = NO;
            }
        }
    }
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
        return IFSyntaxCodeAlpha;
    }
    
    if (chr == ',' || chr == ';' || chr == '*' || chr == '>') return IFSyntaxDirective;
    if (chr == '[' || chr == ']') return IFSyntaxFunction;
    if (chr == '\'' || chr == '"') return IFSyntaxString;
    
    // IMPLEMENT ME: colour backtracking
    return IFSyntaxNone;
}

@end
