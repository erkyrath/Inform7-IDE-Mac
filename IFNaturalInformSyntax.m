//
//  IFNaturalInformSyntax.m
//  Inform
//
//  Created by Andrew Hunter on Sun Dec 14 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFNaturalInformSyntax.h"


@implementation IFNaturalInformSyntax

// In need of implementing
- (void) colourForCharacterRange: (NSRange) range
                          buffer: (unsigned char*) buf {
    int x;
    
    for (x=0; x<range.length; x++) {
        buf[x] = IFSyntaxNone;
    }
}

@end
