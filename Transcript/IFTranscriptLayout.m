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
	[self cancelLayout];
	
	[skein release]; skein = nil;
	[targetItem release]; targetItem = nil;
	[transcriptItems release]; transcriptItems = nil;
	layoutPosition = 0;
	
	// Bring in the new
	skein = [newSkein retain];
}

- (ZoomSkein*) skein {
	return skein;
}

- (void) transcriptToPoint: (ZoomSkeinItem*) point {
	// Delete the old transcript items
	[self cancelLayout];

	[targetItem release]; targetItem = nil;
	[transcriptItems release]; transcriptItems = nil;
	layoutPosition = 0;
	height = 0;
	
	// Create new transcript items
	transcriptItems = [[NSMutableArray alloc] init];
	targetItem = [point retain];
	
	// Move up the tree until we get to the root	
	ZoomSkeinItem* item = point;
	
	while (item != nil) {
		// Create the transcript item
		IFTranscriptItem* transItem = [[IFTranscriptItem alloc] init];
		
		[transItem setWidth: width];
		[transItem setCommand: [item command]];
		[transItem setTranscript: [item result]];
		[transItem setExpected: [item commentary]];
		
		[transItem setPlayed: [item played]];
		[transItem setChanged: [item changed]];
		
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
				
		[transItem setWidth: width];
		[transItem setCommand: [item command]];
		[transItem setTranscript: [item result]];
		[transItem setExpected: [item commentary]];
		
		[transItem setPlayed: [item played]];
		[transItem setChanged: [item changed]];
		
		// Add to the set of items
		[transcriptItems addObject: transItem];
		[transItem release];
	}
	
	// Start laying out the new items
	needsLayout = YES;
}

- (void) setWidth: (float) newWidth {
	if (newWidth == width) return;
	
	width = newWidth;
	
	NSEnumerator* itemEnum = [transcriptItems objectEnumerator];
	IFTranscriptItem* item;
	
	while (item = [itemEnum nextObject]) {
		[item setWidth: width];
	}
	
	needsLayout = YES;
	layoutPosition = 0;
	height = 0;
}

- (float) height {
	return height;
}

// = The delegate =

- (void) setDelegate: (id) newDelegate {
	delegate = newDelegate;
}

- (id) delegate {
	return delegate;
}

- (void) transcriptHasUpdatedItems: (NSRange) itemRange {
	if (delegate && [delegate respondsToSelector: @selector(transcriptHasUpdatedItems:)]) {
		[delegate transcriptHasUpdatedItems: itemRange];
	}
}

// = Performing the layout =

- (void) runLayout {
	needsLayout = NO;
	
	// Actually performs the layout
	if (!layoutRunning) return;
	
	layoutRunning = NO;
	
	// Run through the items from the last one we laid out to find the first one that hasn't been laid out properly
	while (layoutPosition < [transcriptItems count] && [[transcriptItems objectAtIndex: layoutPosition] calculated]) {
		layoutPosition++;
	}
	
	// Give up if we're at the end
	if (layoutPosition >= [transcriptItems count]) {
		return;
	}
	
	// Lay out a maximum of 10 items
	int numberLaidOut = 0;
	int firstItem = layoutPosition;
	while (numberLaidOut < 10 && layoutPosition < [transcriptItems count]) {
		IFTranscriptItem* item = [transcriptItems objectAtIndex: layoutPosition];
		
		// Calculate the item
		[item calculateItem];
		
		// Calculate where it appears in the transcript
		if (layoutPosition > 0) {
			IFTranscriptItem* lastItem = [transcriptItems objectAtIndex: layoutPosition-1];
			[item setOffset: [lastItem offset] + [lastItem height]];
		} else {
			[item setOffset: 0];
		}
		
		// Calculate the transcript height
		float newHeight = [item offset] + [item height];
		if (newHeight > height) height = newHeight;
		
		// Move on
		layoutPosition++;
		numberLaidOut++;
	}
	
	// Inform the delegate
	[self transcriptHasUpdatedItems: NSMakeRange(firstItem, numberLaidOut)];
	
	// Give up if we're at the end
	if (layoutPosition >= [transcriptItems count]) return;
	
	// Queue up the next layout event
	needsLayout = YES;
	layoutRunning = YES;
	
	[self performSelector: @selector(runLayout)
			   withObject: nil 
			   afterDelay: 0.005
				  inModes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
}

- (BOOL) needsLayout {
	return needsLayout && !layoutRunning;
}

- (void) startLayout {
	// Queues up the layout in the background
	if (!layoutRunning) {
		layoutRunning = YES;
		layoutPosition = 0;
		
		[self runLayout];
	}
}

- (void) cancelLayout {
	if (layoutRunning) {
		layoutRunning = NO;
		
		[NSObject cancelPreviousPerformRequestsWithTarget: self];
	}
}

// = Getting items to draw =

- (NSArray*) itemsInRect: (NSRect) rect {
	int itemNum;
	IFTranscriptItem* item = nil;
	
	for (itemNum = 0; itemNum < [transcriptItems count]; itemNum++) {
		item = [transcriptItems objectAtIndex: itemNum];
		
		if (![item calculated]) continue;
		if ([item offset] + [item height] > rect.origin.y) break;
	}
	
	NSMutableArray* res = [NSMutableArray array];
	for (; itemNum < [transcriptItems count]; itemNum++) {
		item = [transcriptItems objectAtIndex: itemNum];
		
		if (![item calculated]) break;
		if ([item offset] > NSMaxY(rect)) break;
		
		[res addObject: item];
	}
	
	return res;
}

@end
