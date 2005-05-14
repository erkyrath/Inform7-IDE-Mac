//
//  IFTranscriptView.m
//  Inform
//
//  Created by Andrew Hunter on 12/09/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFTranscriptView.h"


@implementation IFTranscriptView

// = Initialisation =

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    
	if (self) {
		layout = [[IFTranscriptLayout alloc] init];
		
		[layout setDelegate: self];
		[layout setWidth: floorf([self bounds].size.width)];
    }
	
    return self;
}

- (void) dealloc {
	[layout setDelegate: nil];
	[layout release]; layout = nil;
	
	[super dealloc];
}

// = Retrieving the layout =

- (IFTranscriptLayout*) layout {
	return layout;
}

// = Drawing =

- (BOOL) isFlipped { return YES; }

- (void) setFrame: (NSRect) bounds {
	[super setFrame: bounds];
	
	[layout setWidth: floorf([self bounds].size.width)];
}

- (void)drawRect:(NSRect)rect {
	NSRect bounds = [self bounds];
	
	// Begin the layout if we need to
	if ([layout needsLayout]) [layout startLayout];
	
	// Get the items we need to draw
	NSArray* items = [layout itemsInRect: rect];
	
	// Draw them
	NSEnumerator* itemEnum = [items objectEnumerator];
	IFTranscriptItem* item;
	
	while (item = [itemEnum nextObject]) {
		[item drawAtPoint: NSMakePoint(NSMinX(bounds), NSMinY(bounds) + [item offset])];
	}
}

- (void) transcriptHasUpdatedItems: (NSRange) itemRange {
	// FIXME: only draw items as needed, resize the view to fit the items
	NSRect ourBounds = [self frame];
	ourBounds.size.height = [layout height];
	[self setFrame: ourBounds];

	[self setNeedsDisplay: YES];	
}

@end
