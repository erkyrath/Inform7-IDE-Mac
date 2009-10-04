//
//  IFInform7MutableString.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 04/10/2009.
//  Copyright 2009 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


///
/// Extensions to the NSMutableString class that allow manipulating I7 code
///
@interface NSMutableString(IFInform7MutableString)

///
/// Comments out a region in the string using Inform 7 syntax
///
- (void) commentOutInform7: (NSRange) range;

///
/// Removes I7 comments from the specified range
///
- (void) removeCommentsInform7: (NSRange) range;

@end
