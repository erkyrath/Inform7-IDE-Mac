//
//  IFTranscriptString.m
//  Inform
//
//  Created by Andrew Hunter on 07/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFTranscriptString.h"

#import <ZoomView/ZoomSkeinItem.h>

@implementation IFTranscriptString

// = Initialisation =

- (id) initWithTranscriptStorage: (IFTranscriptStorage*) store {
	self = [super init];
	
	if (self) {
		storage = [store retain]; 
	}
	
	return self;
}

- (void) dealloc {
	[storage release];
	
	[super dealloc];
}

// = Required subclass methods =

- (unsigned) length {
	NSArray* ipd = [storage itemPositionData];
	NSDictionary* lastItem = [ipd lastObject];
	
	// Length is the final position character
	return [[lastItem objectForKey: @"FinalPosition"] intValue];
}

- (unichar) characterAtIndex: (unsigned)index {
	unsigned itemIndex = [storage indexOfItemAtCharacterPosition: index];
	
	// Return a space if the character is not found
	if (index == NSNotFound) return ' ';
	
	// Find the relevant string to get the character from
	NSDictionary* itemData = [[storage itemPositionData] objectAtIndex: itemIndex];
	ZoomSkeinItem* item = [[storage transcriptItems] objectAtIndex: itemIndex];
		
	// 'Actual' text
	int expectedPos;
	if (index < (expectedPos=[[itemData objectForKey: @"ExpectedTextPosition"] intValue])) {
		unsigned offset = index - [[itemData objectForKey: @"ActualTextPosition"] intValue];
		
		return [[item result] characterAtIndex: offset];
	}
	
	// 'Expected' text
	int commandPos;
	if (index < (commandPos=[[itemData objectForKey: @"CommandsPosition"] intValue])) {
		unsigned offset = index - expectedPos;
		
		// FIXME: no support for this in skeins yet
		return [@"" characterAtIndex: offset];
	}
	
	// Commands
	int endPos;
	if (index < (endPos=[[itemData objectForKey: @"FinalPosition"] intValue])) {
		unsigned offset = index - commandPos;
		
		NSSet* kids = [item children];
		NSEnumerator* kidEnum = [kids objectEnumerator];
		
		ZoomSkeinItem* kid;
		
		// Go through the commands of the children items until we find one this can be a part of
		while (kid = [kidEnum nextObject]) {
			NSString* command = [kid command];
			
			// See if this character lies within this command
			if (offset < [command length]) {
				return [command characterAtIndex: offset];
			}
			
			// All commands are followed by a space character
			if (offset == [command length]) 
				return ' ';
			
			offset -= [command length] + 1;
		}
		
		// Er, whoops, if we reach here
	}
	
	// Not in this item (?!)
	NSLog(@"BUG: character %i doesn't appear to belong to the item it should", index);
	return '?';
}

// = Implementations of various methods to improve performance =

@end
