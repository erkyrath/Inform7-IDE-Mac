//
//  IFTranscriptStorage.m
//  Inform
//
//  Created by Andrew Hunter on 19/09/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFTranscriptStorage.h"

#import "IFTranscriptString.h"

@implementation IFTranscriptStorage

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
	}
	
	return self;
}

- (void) dealloc {
	[transcriptItems release];
	[itemPositionData release];
	[finalItem release];
	
	[super dealloc];
}

// = Standard NSTextStorage methods =

- (NSString*) string {
	if (!string) string = [[IFTranscriptString alloc] initWithTranscriptStorage: self];
	return string;
}

- (NSDictionary*) attributesAtIndex: (unsigned) index
					 effectiveRange: (NSRangePointer) range {
	static NSDictionary* dict = nil;
	
	if (!dict) dict = [[NSDictionary alloc] init];
	
	if (range) {
		range->location = 0;
		range->length = [[[itemPositionData lastObject] objectForKey: @"FinalPosition"] intValue];
		
		if (index >= range->length) {
			range->location = index;
			range->length = 1;
		}
	}
	
	return dict;
}

- (void) replaceCharactersInRange: (NSRange) range
					   withString: (NSString*) string {
	// Not implemented yet
}

- (void) setAttributes: (NSDictionary*) attributes
				 range: (NSRange) range {
	// Attributes can't be changed
}

// = Setting up what to display/edit =

- (void) calculatePositionForItemAtIndex: (unsigned) itemIndex {
	// Recalculate the position data for a particular item
	
	if (itemIndex > [itemPositionData count]) {
		// Oops, can't insert this item!
		[NSException raise: @"IFCantInsertItemException"
					format: @"Attempted to calculate the position of a transcript item with an index outside the range of items currently in the transcript"];
		return;
	}
	
	if (itemIndex >= [transcriptItems count]) {
		[NSException raise: @"IFCantInsertItemException"
					format: @"Attempted to calculate the position of a transcript item outside the range of items being displayed by the transcript"];
		return;
	}
	
	ZoomSkeinItem* item = [transcriptItems objectAtIndex: itemIndex];
	
	// An item has four pieces of positional information relative to the storage object:
	//	 The 'actual' text position
	//	 The 'expected' text position
	//   The list of possible following command positions
	//	 The final position (the start of the next item)
	int lastItemEnd = 0;
	
	if (itemIndex > 0) {
		// Get the information for the previous item
		lastItemEnd = [[[itemPositionData objectAtIndex: itemIndex-1] objectForKey: @"FinalPosition"] intValue];
	}
	
	// Calculate the information for this item
	int actualText = lastItemEnd;
	int expectedText;
	int commands;
	int itemEnd;
	
	int commandLength = 0;
	
	// Length of the list of commands
	NSEnumerator* childEnum = [[item children] objectEnumerator];
	ZoomSkeinItem* itemChild;
	
	while (itemChild = [childEnum nextObject]) {
		commandLength += [[itemChild command] length] + 1;
	}
	
	if (commandLength > 0) commandLength--; // Last command has no space following it
	
	// Actual values
	expectedText = actualText + [[item result] length];
	commands = expectedText + 0; // FIXME: no support for this in the skeins yet
	itemEnd = commands + commandLength;
	
	// Store the result
	NSDictionary* newItem = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt: actualText],   @"ActualTextPosition",
		[NSNumber numberWithInt: expectedText], @"ExpectedTextPosition",
		[NSNumber numberWithInt: commands],		@"CommandsPosition",
		[NSNumber numberWithInt: itemEnd],		@"FinalPosition",
		nil];
	
	if (itemIndex >= [itemPositionData count]) {
		[itemPositionData addObject: newItem];
	} else {
		[itemPositionData replaceObjectAtIndex: itemIndex
									withObject: newItem];
	}
	
	// Done.
}

- (void) calculatePositionForItem: (ZoomSkeinItem*) item {
	unsigned index = [transcriptItems indexOfObjectIdenticalTo: item];
	
	if (index != NSNotFound) {
		[self calculatePositionForItemAtIndex: index];
	}
}

- (void) recalculateAllItemPositions {
	unsigned int x;
	unsigned int oldLength = [self length];

	if (itemPositionData) {
		oldLength = [[[itemPositionData lastObject] objectForKey: @"FinalPosition"] intValue];
		
		[itemPositionData release];
		itemPositionData = nil;
	}
	
	itemPositionData = [[NSMutableArray alloc] init];
	
	for (x=0; x<[transcriptItems count]; x++) {
		[self calculatePositionForItemAtIndex: x];
	}
	
	// Mark ourselves as updated
	unsigned int newLength = [[[itemPositionData lastObject] objectForKey: @"FinalPosition"] intValue];
	
	[self edited: NSTextStorageEditedCharacters
		   range: NSMakeRange(0, newLength)
  changeInLength: 0];
}

- (void) setTranscriptToPoint: (ZoomSkeinItem*) fI {
	// Clear up any old items that might be lying around
	
	// IMPLEMENT ME: detect when this item joins the existing items, and only update as appropriate
	if (transcriptItems) {
		[transcriptItems release];
		transcriptItems = nil;
	}
	if (finalItem) {
		[finalItem autorelease];
		finalItem = nil;
	}
	if (itemPositionData) {
		[itemPositionData release];
		itemPositionData = nil;
	}
	
	// Store the new set of items
	transcriptItems = [[NSMutableArray alloc] init];
	finalItem = [fI retain];
	
	ZoomSkeinItem* item = finalItem;
	
	while (item != nil) {
		[transcriptItems insertObject: item
							  atIndex: 0];
		
		item = [item parent];
	}
	
	// Calculate the positions of items within the string
	[self recalculateAllItemPositions];
}

- (NSArray*) itemPositionData {
	return itemPositionData;
}

- (NSArray*) transcriptItems {
	return transcriptItems;
}

- (unsigned) indexOfItemAtCharacterPosition: (unsigned) pos {
	// Binary search!
	int top, bottom, middle;
	
	top = 0;
	bottom = [itemPositionData count]-1;
	
	while (top <= bottom) {
		middle = (top + bottom) >> 1;
		
		NSDictionary* item = [itemPositionData objectAtIndex: middle];
		
		int startChar = [[item objectForKey: @"ActualTextPosition"] intValue];
		int endChar = [[item objectForKey: @"FinalPosition"] intValue];
		
		if (pos < startChar) {
			bottom = middle - 1;
		} else if (pos > endChar) {
			top = middle + 1;
		} else {
			return middle;
		}
	}
	
	return NSNotFound;
}

@end
