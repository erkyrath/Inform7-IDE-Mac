//
//  IFSyntaxHighlighter.m
//  Inform
//
//  Created by Andrew Hunter on Sun Nov 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "IFSyntaxHighlighter.h"


@implementation IFSyntaxHighlighter

// Changes the file we're using; does not invalidate any state information, though
- (void) setFile: (NSString*) newFile {
}

// Noting that things have changed in the file
- (void) invalidateAll {
}

- (void) invalidateCharacter: (int) chr {
}

- (NSRange) invalidRange {
    return NSMakeRange(NSNotFound, 0);
}

// Getting information about a character
- (enum IFSyntaxType) colourForCharacterAtIndex: (int) index {
    return IFSyntaxNone;
}

@end
