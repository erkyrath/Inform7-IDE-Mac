//
//  IFRestrictedTextStorage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 04/01/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFRestrictedTextStorage.h"


@implementation IFRestrictedTextStorage

// Initialisation

- (id) init {
	return [self initWithTextStorage: [[[NSTextStorage alloc] init] autorelease]];
}

- (id) initWithTextStorage: (NSTextStorage*) newStorage {
	self = [super init];
	
	if (self) {
		// Set up the storage object
		storage		= [newStorage retain];
		restriction = NSMakeRange(0, [storage length]);
		
		// Register for notifications from the storage object
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(didEdit:)
													 name: NSTextStorageDidProcessEditingNotification
												   object: storage];
	}
	
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[storage release];			storage = nil;
	
	[super dealloc];
}

- (NSTextStorage*) restrictedStorage {
	return storage;
}

// = Mandatory NSTextStorage function implementations =

- (NSString*) string {
	if (![self isRestricted]) {
		return [storage string];
	} else {
		return [[storage string] substringWithRange: restriction];
	}
}

- (NSDictionary*) attributesAtIndex: (unsigned) index
					 effectiveRange: (NSRangePointer) range {
	if (index < 0 || index >= restriction.length) return nil;
	
	NSRange effectiveRange;
	NSDictionary* result;
	
	result = [storage attributesAtIndex: index + restriction.location
						 effectiveRange: &effectiveRange];
	
	effectiveRange.location -= restriction.location;
	
	if (range) {
		*range = effectiveRange;
	}
	
	return result;
}

- (void) replaceCharactersInRange: (NSRange) range
					   withString: (NSString*) newString {
	range.location += restriction.location;
	
	[storage replaceCharactersInRange: range
						   withString: newString];
}

- (void) setAttributes: (NSDictionary*) attributes
				 range: (NSRange) range {
	range.location += restriction.location;

	[storage setAttributes: attributes
					 range: range]; 
}

// = Handling NSTextStorage notification events =

- (void) didEdit: (NSNotification*) not {
	if ([not object] != storage) return;
	
	// Get the details about the edit that has occurred
	NSRange editRange	= [storage editedRange];
	int changeInLength	= [storage changeInLength];
	int mask			= [storage editedMask];
	
	// If the edit is before the start of the restriction, then do nothing
	if (editRange.location + editRange.length < restriction.location) {
		restriction.location += changeInLength;
		return;
	}
	
	// If this edit is beyond the end of the restriction, then do nothing
	if (editRange.location >= restriction.location + restriction.length) {
		return;
	}
	
	NSRange restrictedEditRange = editRange;
	
	// If the edited range extends below the restriction location, restrict it
	if (restrictedEditRange.location < restriction.location) {
		restrictedEditRange.length -= (restriction.location - restrictedEditRange.location);
		restrictedEditRange.location = restriction.location;
	}
	
	// Move the range according to where the restriction is
	restrictedEditRange.location -= restriction.location;
	
	// Report the edit
	[self edited: mask
		   range: restrictedEditRange
  changeInLength: changeInLength];
}

// = Restricting the range that is being displayed by the storage object =

- (BOOL) isRestricted {
	if (restriction.location != 0 || restriction.length != [storage length]) {
		return YES;
	} else {
		return NO;
	}
}

- (void) setRestriction: (NSRange) range {
	// Do nothing if the restriction is the same as before
	if (NSEqualRanges(range, restriction)) {
		return;
	}
	
	if (range.location < 0) range.location = 0;
	if (range.location > [storage length]) {
		range.location = [storage length];
		range.length = 0;
	}
	
	if (range.location + range.length > [storage length]) {
		range.length = [storage length] - range.location;
	}
	
	// Update the range that this text storage is displaying
	NSRange oldRange = restriction;
	restriction = range;

	// Send an edited event marking the change
	[self edited: NSTextStorageEditedAttributes | NSTextStorageEditedCharacters
		   range: NSMakeRange(0, oldRange.length)
  changeInLength: oldRange.length - restriction.length];
}

- (void) removeRestriction {
	[self setRestriction: NSMakeRange(0, [storage length])];
}

- (NSRange) restrictionRange {
	return restriction;
}

@end
