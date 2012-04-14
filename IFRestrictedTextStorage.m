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
		string		= [[IFRestrictedString alloc] initWithString: [storage string]];
		
		[string setRestriction: restriction];
		
		// Register for notifications from the storage object
		if ([newStorage isKindOfClass: [IFSyntaxStorage class]]) {
			[(IFSyntaxStorage*)newStorage addDerivativeStorage: self];
		} else {
			[[NSNotificationCenter defaultCenter] addObserver: self
													 selector: @selector(didEdit:)
														 name: NSTextStorageDidProcessEditingNotification
													   object: storage];
		}
	}
	
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	if ([storage isKindOfClass: [IFSyntaxStorage class]]) {
		[(IFSyntaxStorage*)storage removeDerivativeStorage: self];
	}
	
	[storage release];			storage = nil;
	[string release];			string = nil;
	
	[super dealloc];
}

- (NSTextStorage*) restrictedStorage {
	return storage;
}

// = Mandatory NSTextStorage function implementations =

- (NSString*) string {
	return string;
}

- (int) length {
	return restriction.length;
}

- (NSDictionary*) attributesAtIndex: (NSUInteger) index
					 effectiveRange: (NSRangePointer) range {
	if (index < 0 || index >= restriction.length) {
		[NSException raise: NSRangeException
					format: @"Index outside the bounds of the restricted string"];
		if (range) {
			range->location = restriction.length;
			range->length = 0;
		}
		return [NSDictionary dictionary];
	}
	
	NSRange effectiveRange;
	NSDictionary* result;
	
	result = [storage attributesAtIndex: index + restriction.location
						 effectiveRange: &effectiveRange];
	
	if (effectiveRange.location < restriction.location) {
		effectiveRange.length -= restriction.location - effectiveRange.location;
		effectiveRange.location = restriction.location;
	}
	effectiveRange.location -= restriction.location;
	if (effectiveRange.location + effectiveRange.length > restriction.length) {
		effectiveRange.length = restriction.length - effectiveRange.location;
	}
	
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

- (void) didBeginEditing: (NSTextStorage*) storage {
	[self beginEditing];
}

- (void) didEdit: (NSTextStorage*) storage
			mask: (unsigned int) mask
  changeInLength: (int) changeInLength
		   range: (NSRange) editRange {
	// If the edit is before the start of the restriction, then do nothing
	if (editRange.location + editRange.length < restriction.location) {
		restriction.location += changeInLength;
		[string setRestriction: restriction];
		return;
	}
	
	// If this edit is beyond the end of the restriction, then do nothing
	if (editRange.length != 0 || editRange.location != restriction.location + restriction.length)
	{
		if (editRange.location >= restriction.location + restriction.length) {
			return;
		}
	}
	
	NSRange restrictedEditRange = editRange;
	
	// If the change in length is non-zero and the edited range extends below the restriction location,
	// perform the update by changing the restriction range
	if (editRange.location < restriction.location) {
		int extraCharacters = restriction.location - editRange.location;
		NSRange newRestriction = restriction;
		
		newRestriction.location -= extraCharacters;
		newRestriction.length	+= extraCharacters + changeInLength;

		if (editRange.location + editRange.length > restriction.location + restriction.length) {
			newRestriction.length += (editRange.location + editRange.length) - (restriction.location + restriction.length);
		}
		
		[self setRestriction: newRestriction];
		
		return;
	}
	
	// If the change in length is non-zero and the edited range extends beyonds the restriction location, perform the update by changing the restriction range
	if (changeInLength != 0 && editRange.location + editRange.length > restriction.location + restriction.length) {
		NSRange newRestriction = restriction;
		
		newRestriction.length	+= (editRange.location + editRange.length) - (restriction.location + restriction.length);
		
		[self setRestriction: newRestriction];
		
		return;
	}	
	
	// If the edited range extends below the restriction location, restrict it
	if (restrictedEditRange.location < restriction.location) {
		restrictedEditRange.length -= (restriction.location - restrictedEditRange.location);
		restrictedEditRange.location = restriction.location;
	}
	
	// Move the range according to where the restriction is
	restrictedEditRange.location -= restriction.location;
	
	// If the edited range extends above the current restriction, then reduce it
	if (restrictedEditRange.location + restrictedEditRange.length > restriction.length) {
		restrictedEditRange.length = restriction.length - restrictedEditRange.location;
	}
	
	// Change the size of the restriction
	restriction.length += changeInLength;
	[string setRestriction: restriction];
	
	// Report the edit
	[self edited: mask
		   range: restrictedEditRange
  changeInLength: changeInLength];
}

- (void) didEndEditing: (NSTextStorage*) storage {
	[self endEditing];
}

- (void) didEdit: (NSNotification*) not {
	// NSNotification (this is less than ideal as we can get confused more easily)
	if ([not object] != storage) return;
	
	// Get the details about the edit that has occurred
	NSRange editRange	= [storage editedRange];
	int changeInLength	= [storage changeInLength];
	int mask			= [storage editedMask];
	
	// Pass to the didEdit: method
	[self didEdit: storage
			 mask: mask
   changeInLength: changeInLength
			range: editRange];
	
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
	[string setRestriction: restriction];

	// Send an edited event marking the change
	[self edited: NSTextStorageEditedAttributes | NSTextStorageEditedCharacters
		   range: NSMakeRange(0, oldRange.length)
  changeInLength: (int)restriction.length - (int)oldRange.length];
}

- (void) removeRestriction {
	[self setRestriction: NSMakeRange(0, [storage length])];
}

- (NSRange) restrictionRange {
	return restriction;
}

@end
