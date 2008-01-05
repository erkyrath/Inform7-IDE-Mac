//
//  IFRestrictedString.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 05/01/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


///
/// NSString object that provides a view onto a substring of another string.
///
/// This is intended for use with IFRestrictedTextStorage; note that it won't work in general
/// with mutable strings.
///
@interface IFRestrictedString : NSString {
	NSString* sourceString;								// The source for this string
	NSRange restriction;								// The range that this string should represent
}

// Initialisation

- (id) initWithString: (NSString*) source;				// Initialises this string object
- (void) setRestriction: (NSRange) restriction;			// Updates the restriction for this string

@end
