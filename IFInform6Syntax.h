//
//  IFInform6Syntax.h
//  Inform
//
//  Created by Andrew Hunter on Sun Nov 30 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFSyntaxHighlighter.h"

typedef struct IFInform6State IFInform6State;
typedef struct IFInform6Line  IFInform6Line;

struct IFInform6State {
    int character;
    
    struct IFInform6Outer {
        int comment:1;
        int singleQuote:1;
        int doubleQuote:1;
        int statement:1;
        int afterMarker:1;
        int highlight:1;
        int highlightAll:1;
        int colourBacktrack:1;
        int afterRestart:1;
        int waitingForDirective:1;
        int dontKnowFlag:1;
    } outer;
    short unsigned int inner;
    
    enum IFSyntaxType backtrackColour;
};

struct IFInform6Line {
    BOOL invalid; // Needs rehighlighting
    BOOL needsDisplay; // Needs redisplaying
    IFInform6State initialState;
    
    int length;
    unsigned char* colour;
};

@interface IFInform6Syntax : IFSyntaxHighlighter {
    int nLines;
    IFInform6Line* lines;
    
    NSString* file;
    
    IFInform6State lastState;

    // Last colourForCharacter character
    int lastIndex;
    int lastLine;
    int lastPos;
}

// Running the state machine (see the inform techincal manual)
- (IFInform6State) nextState: (IFInform6State) state
               nextCharacter: (int) chr;
- (BOOL) innerStateMachine: (IFInform6State*) state
                 character: (int) chr;
- (enum IFSyntaxType) initialColourForState: (IFInform6State) state
                                  character: (int) chr;

// Some (maybe) useful functions. Mainly for internal use
- (int) lineForChar: (int) index
           position: (int*) posOut;
@end
