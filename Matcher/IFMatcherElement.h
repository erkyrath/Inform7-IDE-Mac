//
//  IFMatcherElement.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 27/06/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFMatcherStructure.h"

///
/// Context matcher structure that 
///
@interface IFMatcherElement : IFMatcherStructure {
	NSString* description;										// The description for this element
	NSString* link;												// The URL of the link for this element
}

// Setting the values in this element
- (NSString*) elementDescription;								// The description for this element
- (void) setElementDescription: (NSString*) description;
- (NSString*) elementLink;										// A string giving a URL for the link for this element
- (void) setElementLink: (NSString*) link;

@end
