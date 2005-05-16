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
	if ([layout needsLayout]) {
		[[NSRunLoop currentRunLoop] performSelector: @selector(startLayout)
											 target: layout
										   argument: nil
											  order: 128
											  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
	}
	
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
	
	// Start the layout if necessary (avoids flicker sometimes)
	if ([layout needsLayout]) [layout startLayout];

	// Set our frame appropriately if we need to
	NSRect ourBounds = [self frame];
	ourBounds.size.height = [layout height];
	if (ourBounds.size.height <= 12) ourBounds.size.height = 12;
	[self setFrame: ourBounds];

	// Redraw the items
	[self setNeedsDisplay: YES];	
}

// = Mousing around =

- (void) mouseDown: (NSEvent*) evt {
	NSRect bounds = [self bounds];
	NSPoint viewPos = [self convertPoint: [evt locationInWindow]
								fromView: nil];
	
	// Work out which item was clicked (if any)
	NSArray* clickItems = [layout itemsInRect: NSMakeRect(viewPos.x - NSMinX(bounds), viewPos.y - NSMinY(bounds), 1, 1)];
	
	IFTranscriptItem* item = nil;
	if ([clickItems count] > 0) item = [clickItems objectAtIndex: 0];
	
	// Get some item metrics
	//float itemHeight = [item height];
	//float itemTextHeight = [item textHeight];
	float fontHeight = [[[item attributes] objectForKey: NSFontAttributeName] defaultLineHeightForFont];
	
	float itemOffset = [item offset];
	NSPoint itemPos = NSMakePoint(viewPos.x - NSMinX(bounds), viewPos.y - NSMinY(bounds) - itemOffset);
	
	// Clicking a button activates that button (this is the obvious bit)
	
	if (item != nil && itemPos.y > fontHeight * 1.5) {
		[[self window] makeFirstResponder: self];
		
		NSTextView* fieldEditor = [[self window] fieldEditor: YES
												   forObject: item];
		
		if (itemPos.x < bounds.size.width/2.0) {
			// Clicking in the left-hand field gives us a field editor for that field
			[item setupFieldEditor: fieldEditor
					   forExpected: NO
						   atPoint: NSMakePoint(NSMinX(bounds), NSMinY(bounds) + itemOffset)];
			
			[fieldEditor setEditable: NO];
		} else {
			// Clicking in the right-hand field gives us a field editor for that field
			[item setupFieldEditor: fieldEditor
					   forExpected: YES
						   atPoint: NSMakePoint(NSMinX(bounds), NSMinY(bounds) + itemOffset)];
			
			[fieldEditor setEditable: YES];
		}
		
		// Finish setting up the field editor (the item itself handles everything else)
		[self addSubview: fieldEditor];
		[[self window] makeFirstResponder: fieldEditor];
		
		[fieldEditor mouseDown: evt];
	}
}


// = Displaying specific items =

- (void) scrollToItem: (ZoomSkeinItem*) item {
	NSRect bounds = [self bounds];
	float offset = [layout offsetOfItem: item];
	
	if (offset >= 0) {
		NSRect itemRect;
		
		itemRect.origin = NSMakePoint(NSMinX(bounds), NSMinY(bounds) + offset);
		itemRect.size = NSMakeSize(bounds.size.width, [layout heightOfItem: item]);
		
		[self scrollRectToVisible: itemRect];
	}
}

@end
