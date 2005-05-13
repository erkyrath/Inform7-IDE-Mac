//
//  IFTranscriptLayout.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 13/05/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFTranscriptLayout.h"


@implementation IFTranscriptLayout

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
	}
	
	return self;
}

- (void) dealloc {
	[skein release];
	[targetItem release];
	
	[super dealloc];
}

// = Setting the skein and the item we're transcripting to =

- (void) setSkein: (ZoomSkein*) newSkein {
	// Clear out the old
	[skein release]; skein = nil;
	[targetItem release]; targetItem = nil;
	[transcriptItems release]; transcriptItems = nil;
	calculationPoint = -1;
	
	// Bring in the new
	skein = [newSkein retain];
}

- (ZoomSkein*) skein {
	return skein;
}

- (void) transcriptToPoint: (ZoomSkeinItem*) point {
	// Delete the old transcript items
	[targetItem release]; targetItem = nil;
	[transcriptItems release]; transcriptItems = nil;
	calculationPoint = -1;
	
	// Create new transcript items
	transcriptItems = [[NSMutableArray alloc] init];
	targetItem = [point retain];
	
	// Move up the tree until we get to the root	
	ZoomSkeinItem* item = point;
	
	while (item != nil) {
		// Create the transcript item
		IFTranscriptItem* transItem = [[IFTranscriptItem alloc] init];
		
		[transItem setCommand: [item command]];
		[transItem setTranscript: [item result]];
		// [transItem setExpected: [item commentary]]; -- IMPLEMENT ME
		
		// Add to the set of items
		[transcriptItems insertObject: transItem
							  atIndex: 0];
		[transItem release];
		
		item = [item parent];
	}
	
	// Move down the tree for as long as there's a clear path
	item = point;
	while ([[item children] count] == 1) {
		// Move down the tree
		item = [[[item children] allObjects] objectAtIndex: 0];

		// Create the transcript item
		IFTranscriptItem* transItem = [[IFTranscriptItem alloc] init];
		
		[transItem setCommand: [item command]];
		[transItem setTranscript: [item result]];
		// [transItem setExpected: [item commentary]]; -- IMPLEMENT ME
		
		// Add to the set of items
		[transcriptItems insertObject: transItem
							  atIndex: 0];
		[transItem release];
	}
}

@end
