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

- (void) invalidateRange: (NSRange) range {
}

- (NSRange) invalidRange {
    return NSMakeRange(NSNotFound, 0);
}

// Getting information about a character
- (void) colourForCharacterRange: (NSRange) range
                          buffer: (unsigned char*) buf {
    int x;
    
    for (x=0; x<range.length; x++) {
        buf[x] = IFSyntaxNone;
    }
}

@end
