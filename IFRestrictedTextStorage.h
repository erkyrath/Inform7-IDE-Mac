//
//  IFRestrictedTextStorage.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 04/01/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


///
/// Text storage object that represents a restricted range of another text storage object
///
@interface IFRestrictedTextStorage : NSTextStorage {
	NSTextStorage* storage;										// The text storage which being restricted
	NSRange restriction;										// The restriction that is in effect for this object
}

// Initialisation

- (id) initWithTextStorage: (NSTextStorage*) storage;			// Creates a new restricted text storage object

- (NSTextStorage*) restrictedStorage;							// The text storage object that this object is restricting

// Restricting the range that is being displayed by the storage object

- (BOOL) isRestricted;											// YES if this storage object is not showing the entire range of available text
- (void) setRestriction: (NSRange) range;						// Restricts the range that this storage object will display
- (void) removeRestriction;										// Removes the restriction in effect for this object
- (NSRange) restrictionRange;									// The restriction range for this object

@end
