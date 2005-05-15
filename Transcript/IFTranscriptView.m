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
	
	// Button images
	NSImage* bless = [NSImage imageNamed: @"Bless"];
	NSImage* playToHere = [NSImage imageNamed: @"PlayToHere"];
	NSImage* showSkein = [NSImage imageNamed: @"ShowSkein"];
	
	[bless setFlipped: YES];
	[playToHere setFlipped: YES];
	[showSkein setFlipped: YES];
	
	NSSize imgSize = [bless size];							// We assume all these images are the same size
	NSRect imgRect;
	
	imgRect.origin = NSMakePoint(0,0);
	imgRect.size = imgSize;
	
	// Begin the layout if we need to
	if ([layout needsLayout]) [layout startLayout];
	
	// Get the items we need to draw
	NSArray* items = [layout itemsInRect: rect];
	
	// Draw them
	NSEnumerator* itemEnum = [items objectEnumerator];
	IFTranscriptItem* item;
	
	while (item = [itemEnum nextObject]) {
		// Draw the item
		float ypos = NSMinY(bounds) + [item offset];
		
		[item drawAtPoint: NSMakePoint(NSMinX(bounds), ypos)];
		
		// Draw the buttons for the item
		NSFont* font = [[item attributes] objectForKey: NSFontAttributeName];
		float fontHeight = [font defaultLineHeightForFont];
		float itemHeight = [item height];
		float textHeight = floorf(itemHeight - fontHeight*2.0);

		float commandButtonY = floorf(ypos + fontHeight*0.75 - imgSize.height/2.0);
		
		[showSkein drawAtPoint: NSMakePoint(floorf(NSMaxX(bounds) - imgSize.width), commandButtonY)
					  fromRect: imgRect
					 operation: NSCompositeSourceOver
					  fraction: 1.0];
		[playToHere drawAtPoint: NSMakePoint(floorf(NSMaxX(bounds) - imgSize.width*2.0), commandButtonY)
					   fromRect: imgRect
					  operation: NSCompositeSourceOver
					   fraction: 1.0];
		
		[bless drawAtPoint: NSMakePoint(floorf(NSMinX(bounds)+((bounds.size.width-imgSize.width)/2.0)), floorf(ypos + (textHeight-imgSize.height)/2.0 + fontHeight*1.75))
				  fromRect: imgRect
				 operation: NSCompositeSourceOver
				  fraction: 1.0];
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
