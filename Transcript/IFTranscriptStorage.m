//
//  IFTranscriptStorage.m
//  Inform
//
//  Created by Andrew Hunter on 19/09/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFTranscriptStorage.h"

// Positional dictionary entries
static NSString* firstCommandText = @"FirstCommandText";
static NSString* actualTextPosition = @"ActualTextPosition";
static NSString* expectedTextPosition = @"ExpectedTextPosition";
static NSString* commandsPosition = @"CommandsPosition";
static NSString* finalPosition = @"FinalPosition";

static NSString* itemStartPosition = @"FirstCommandText";

// Order of sections as they appear in the string
static NSArray* sectionOrder = nil;
static unsigned sectionOrderCount;

@implementation IFTranscriptStorage

// = Standard attributes =

static NSDictionary* defaultAttributes = nil;
static NSDictionary* command1Attributes = nil;
static NSDictionary* command2Attributes = nil;
static NSDictionary* activeCommandAttributes = nil;
static NSDictionary* resultAttributes = nil;
static NSDictionary* expectedAttributes = nil;

+ (void) initialize {
	NSFont* gillSans = [NSFont fontWithName: @"GillSans" size: 11.0];
	if (!gillSans) gillSans = [NSFont systemFontOfSize: 11.0];
	
	// Default attributes
	defaultAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		NSBaselineOffsetAttributeName, [NSNumber numberWithFloat: 0.0],
		NSFontAttributeName, gillSans,
		NSForegroundColorAttributeName, [NSColor blackColor],
		NSKernAttributeName, [NSNumber numberWithFloat: 0.0],
		NSLigatureAttributeName, [NSNumber numberWithInt: 1],
		NSParagraphStyleAttributeName, [NSParagraphStyle defaultParagraphStyle],
		NSSuperscriptAttributeName, [NSNumber numberWithInt: 0],
		NSStrokeWidthAttributeName, [NSNumber numberWithInt: 0],
		NSStrikethroughStyleAttributeName, [NSNumber numberWithInt: 0],
		NSObliquenessAttributeName, [NSNumber numberWithFloat: 0.0],
		NSExpansionAttributeName, [NSNumber numberWithFloat: 0.0],
		nil];
	
	NSMutableDictionary* attr; // Used to build new attributes
	NSMutableParagraphStyle* pStyle;
	
	// Command result attributes
	attr = [defaultAttributes mutableCopy];
	
	//[attr setObject: [NSColor colorWithDeviceRed: 0.6 green: 1.0 blue: 0.6 alpha: 1.0]
	//		 forKey: NSBackgroundColorAttributeName];
	[attr setObject: [NSColor whiteColor]
			 forKey: NSBackgroundColorAttributeName];
	
	resultAttributes = [attr copy];
	[attr release]; attr = nil;
	
	// Active command attributes
	attr = [defaultAttributes mutableCopy];
	
	[attr setObject: [NSFont boldSystemFontOfSize: 11.0]
			 forKey: NSFontAttributeName];
	[attr setObject: [NSColor colorWithDeviceRed: 0.6 green: 0.6 blue: 1.0 alpha: 1.0]
			 forKey: NSBackgroundColorAttributeName];
		
	activeCommandAttributes = [attr copy];
	[attr release]; attr = nil;
	
	// 'Command 1' attributes
	attr = [defaultAttributes mutableCopy];
	
	[attr setObject: [NSFont boldSystemFontOfSize: 10.0]
			 forKey: NSFontAttributeName];
	[attr setObject: [NSColor colorWithDeviceRed: 1.0 green: 0.7 blue: 0.7 alpha: 1.0]
			 forKey: NSBackgroundColorAttributeName];

	pStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[pStyle setAlignment: NSCenterTextAlignment];
	[pStyle setParagraphSpacing: 6.0];
	
	[attr setObject: pStyle
			 forKey: NSParagraphStyleAttributeName];
	[pStyle release];
	
	command1Attributes = [attr copy];
	[attr release]; attr = nil;

	// 'Command 2' attributes
	attr = [defaultAttributes mutableCopy];
	
	[attr setObject: [NSFont boldSystemFontOfSize: 10.0]
			 forKey: NSFontAttributeName];
	[attr setObject: [NSColor colorWithDeviceRed: 1.0 green: 0.5 blue: 0.5 alpha: 1.0]
			 forKey: NSBackgroundColorAttributeName];
	
	pStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[pStyle setAlignment: NSCenterTextAlignment];
	[pStyle setParagraphSpacing: 12.0];

	[attr setObject: pStyle
			 forKey: NSParagraphStyleAttributeName];
	[pStyle release];
	
	command2Attributes = [attr copy];
	[attr release]; attr = nil;
	
	// 'Expected text' attributes
	attr = [defaultAttributes mutableCopy];
	
	[attr setObject: [NSColor colorWithDeviceRed: 0.8 green: 0.8 blue: 0.8 alpha: 1.0]
			 forKey: NSBackgroundColorAttributeName];	
	
	expectedAttributes = [attr copy];
	[attr release]; attr = nil;

	// Order of items as they appear in the string
	if (!sectionOrder) {
		sectionOrder = [[NSArray arrayWithObjects: firstCommandText, actualTextPosition, expectedTextPosition, commandsPosition, finalPosition, nil] retain];
		sectionOrderCount = [sectionOrder count];
	}
	
}

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
		theString = [[NSMutableString alloc] init];
	}
	
	return self;
}

- (void) dealloc {
	[transcriptItems release];
	[itemPositionData release];
	[finalItem release];
	[theString release];
	
	[super dealloc];
}

// = Item info =

- (NSString*) itemSectionAtIndex: (unsigned) index
						itemData: (NSDictionary*) itemData {	
	// Retrieve the section of the item that exists at the given index
	unsigned foundIndex = NSNotFound; // Location in sectionOrder
	unsigned x;
	
	for (x=0; x<sectionOrderCount; x++) {
		NSNumber* pos = [itemData objectForKey: [sectionOrder objectAtIndex: x]];
		
		if (index < [pos intValue]) {
			foundIndex = x;
			break;
		}
	}
	
	if (foundIndex == 0 || foundIndex == NSNotFound) {
		// Index is outside this item
		return nil;
	}
	
	// Otherwise, index is in the section preceding the one marked by foundIndex
	return [sectionOrder objectAtIndex: foundIndex-1];
}

// = Standard NSTextStorage methods =

- (NSString*) string {
	return theString;
}

- (NSDictionary*) attributesAtIndex: (unsigned) index
					 effectiveRange: (NSRangePointer) range {
	NSDictionary* attr = defaultAttributes;
	
	// Find the item
	unsigned item = [self indexOfItemAtCharacterPosition: index];
	NSDictionary* itemData = nil;
	
	if (item != NSNotFound) itemData = [itemPositionData objectAtIndex: item];
		
	// Work out which set of attributes to use
	NSString* attribute = [self itemSectionAtIndex: index
										  itemData: itemData];
	
	if (attribute == firstCommandText) {
		attr = activeCommandAttributes;
	} else if (attribute == actualTextPosition) {
		attr = resultAttributes;
	} else if (attribute == expectedTextPosition) {
		attr = expectedAttributes;
	} else if (attribute == commandsPosition) {
		attr = command1Attributes;
	}
	
	if (range) {
		if (attribute) {
			NSString* nextAttribute = [sectionOrder objectAtIndex: [sectionOrder indexOfObjectIdenticalTo: attribute] + 1];
		
			range->location = [[itemData objectForKey: attribute] intValue];
			range->length = [[itemData objectForKey: nextAttribute] intValue] - range->location;
		} else {
			range->location = index;
			range->length = 1;
		}
	}
	
	return attr;
}

- (void) replaceCharactersInRange: (NSRange) range
					   withString: (NSString*) string {
	// Not implemented yet
	NSLog(@"replaceCharacters: %@", string);
}

- (void) setAttributes: (NSDictionary*) attributes
				 range: (NSRange) range {
	// We have to support attribute changing, as otherwise nothing gets displayed!
	// Not sure why: I think certain attributes must be present or the layout manager keels over.
	// I suspect this behaviour will change, so just providing the required attributes will be
	// a recipe for disaster after future OS updates. 
	
	// Work out which attribute to use
	// Assume the range does not cross a boundary, which would be annoying, and wouldn't work
	// properly, anyway

	// Find the item
	unsigned item = [self indexOfItemAtCharacterPosition: range.location];
	NSDictionary* itemData = nil;
	
	if (item != NSNotFound) itemData = [itemPositionData objectAtIndex: item];
	
	// Work out which set of attributes to update
	NSString* attribute = [self itemSectionAtIndex: range.location
										  itemData: itemData];
	
	if (attribute == firstCommandText) {
		[activeCommandAttributes release];
		activeCommandAttributes = [attributes copy];
	} else if (attribute == actualTextPosition) {
		[resultAttributes release];
		resultAttributes = [attributes copy];
	} else if (attribute == expectedTextPosition) {
		[expectedAttributes release];
		expectedAttributes = [attributes copy];
	} else if (attribute == commandsPosition) {
		[command1Attributes release];
		command1Attributes = [attributes copy];
	} else {
		[defaultAttributes release];
		defaultAttributes = [attributes copy];
	}
	
	
	[self edited: NSTextStorageEditedCharacters
		   range: range
  changeInLength: 0];
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
	
	NSMutableString* itemString = [[NSMutableString alloc] init];	
	
	ZoomSkeinItem* item = [transcriptItems objectAtIndex: itemIndex];
	NSDictionary* oldItem = nil;
	
	// An item has four pieces of positional information relative to the storage object:
	//	 The 'actual' text position
	//	 The 'expected' text position
	//   The list of possible following command positions
	//	 The final position (the start of the next item)
	int lastItemEnd = 0;
	
	if (itemIndex > 0) {
		// Get the information for the previous item
		lastItemEnd = [[[itemPositionData objectAtIndex: itemIndex-1] objectForKey: finalPosition] intValue];
	}
	
	if (itemIndex+1 < [itemPositionData count]) {
		// Get the old item data
		oldItem = [itemPositionData objectAtIndex: itemIndex];
	}
	
	// Calculate the information for this item
	int itemStart = lastItemEnd;
	int firstCommandText = lastItemEnd;
	int actualText;
	int expectedText;
	int commands;
	int itemEnd;
	
	// 'Input' command
	[itemString appendString: @"> "];
	[itemString appendString: [item command]];
	[itemString appendString: @"\n"];
	actualText = itemStart + [itemString length];
	
	// 'Actual' text
	[itemString appendString: [item result]];
	[itemString appendString: @"\n"];
	expectedText = itemStart + [itemString length];
	
	// 'Expected' text
	commands = itemStart + [itemString length];
	
	// Commands
	NSEnumerator* childEnum = [[item children] objectEnumerator];
	ZoomSkeinItem* itemChild;
	
	while (itemChild = [childEnum nextObject]) {
		[itemString appendString: [itemChild command]];
		[itemString appendString: @" "];
	}
	[itemString appendString: @"\n"]; // Will be forced into 

	itemEnd = itemStart + [itemString length];
		
	// Store the result
	NSDictionary* newItem = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt: firstCommandText], @"FirstCommandText",
		[NSNumber numberWithInt: actualText],		actualTextPosition,
		[NSNumber numberWithInt: expectedText],		expectedTextPosition,
		[NSNumber numberWithInt: commands],			commandsPosition,
		[NSNumber numberWithInt: itemEnd],			finalPosition,
		nil];
	
	if (itemIndex >= [itemPositionData count]) {
		[itemPositionData addObject: newItem];
		
		// Append on to the end of the 'real' string
		[theString appendString: itemString];
	} else {
		[oldItem retain];
		[itemPositionData replaceObjectAtIndex: itemIndex
									withObject: newItem];
		
		// Replace the old item with the new item
		if (oldItem) {
			int oldStart = [[oldItem objectForKey: itemStartPosition] intValue];
			int oldEnd = [[oldItem objectForKey: finalPosition] intValue];
			
			[theString replaceCharactersInRange: NSMakeRange(oldStart, oldEnd-oldStart)
									 withString: itemString];
		}
		[oldItem release];
	}
	
	// Done.
	[itemString release];
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
	
	[self beginEditing];

	if (itemPositionData) {
		oldLength = [[[itemPositionData lastObject] objectForKey: finalPosition] intValue];
		
		[itemPositionData release];
		itemPositionData = nil;
	}
	
	itemPositionData = [[NSMutableArray alloc] init];
	
	for (x=0; x<[transcriptItems count]; x++) {
		[self calculatePositionForItemAtIndex: x];
	}
	
	// Mark ourselves as updated
	unsigned int newLength = [[[itemPositionData lastObject] objectForKey: finalPosition] intValue];
	
	[self edited: NSTextStorageEditedCharacters|NSTextStorageEditedAttributes
		   range: NSMakeRange(0, oldLength)
  changeInLength: newLength - oldLength];
	[self endEditing];
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
		
		int startChar = [[item objectForKey: itemStartPosition] intValue];
		int endChar = [[item objectForKey: finalPosition] intValue];
		
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
