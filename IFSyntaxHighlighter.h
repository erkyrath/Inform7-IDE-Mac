//
//  IFSyntaxHighlighter.h
//  Inform
//
//  Created by Andrew Hunter on Sun Nov 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

// Base class for building syntax highlighters for Inform code

#import <Foundation/Foundation.h>

enum IFSyntaxType {
    // Basic syntax types
    IFSyntaxNone,
    IFSyntaxString,
    IFSyntaxComment,
    
    // Inform 6 syntax types
    IFSyntaxDirective = 0x40,
    IFSyntaxProperty,
    IFSyntaxFunction,
    IFSyntaxCode,
    IFSyntaxCodeAlpha,
    IFSyntaxAssembly,
    IFSyntaxEscapeCharacter,
    
    // Natural inform syntax types
    IFSyntaxHeading = 0x80,
    
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
- (void) invalidateCharacter: (int) chr;

- (NSRange) invalidRange;

// Getting information about a character
- (enum IFSyntaxType) colourForCharacterAtIndex: (int) index;

@end
