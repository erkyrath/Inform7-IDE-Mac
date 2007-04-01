//
//  IFPageBarView.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 01/04/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFPageBarView.h"


@implementation IFPageBarView

- (NSImage*) backgroundImage {
	static NSImage* image = nil;
	
	if (!image) {
		image = [[NSImage imageNamed: @"BarBackground"] retain];
	}
	
	return image;
}

- (NSImage*) normalImage {
	static NSImage* image = nil;
	
	if (!image) {
		image = [[NSImage imageNamed: @"BarNormal"] retain];
	}
	
	return image;
}


// = Initialisation =

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
#if 0
		// Construct the overlay window
		overlayWindow = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,100,100)
													styleMask: NSBorderlessWindowMask
													  backing: NSBackingStoreBuffered
														defer: NO];
		[overlayWindow setOpaque: NO];
		[overlayWindow setBackgroundColor: [NSColor clearColor]];
		
		// Construct the overlay view
		overlay = [[IFPageBarOverlay alloc] initWithFrame: NSMakeRect(0,0,100,100)];
		[overlayWindow setContentView: overlay];
#endif
    }
	
    return self;
}

- (void) dealloc {
	[overlayWindow release];
	[overlay release];
	
	[super dealloc];
}

// = Drawing =

- (void)drawRect:(NSRect)rect {
	// Draw the background image
	NSImage* background = [self backgroundImage];
	NSSize backSize = [background size];
	NSRect bounds = [self bounds];
	
	bounds.size.width -= 9;
	
	NSRect backgroundBounds = bounds;
	//backgroundBounds.origin.y += 1;
	//backgroundBounds.size.height -= 1;
	
	[background drawInRect: backgroundBounds
				  fromRect: NSMakeRect(0,0, backSize.width, backSize.height)
				 operation: NSCompositeSourceOver
				  fraction: 1.0];
	
	// Draw the overlay image
	background = [self normalImage];
	backSize = [background size];
	
	float edgeSize = 20;
	
	if (edgeSize*2 > bounds.size.width) {
		edgeSize = bounds.size.width/2;
	}
	
	// Reduce the size a bit more to take account of the tab view border that usually appears 
	bounds.size.width -= 4;
	
	// Draw the left
	NSRect left = bounds;
	left.size.width = edgeSize;
	
	[background drawInRect: left
				  fromRect: NSMakeRect(0,2, edgeSize, backSize.height-4)
				 operation: NSCompositeSourceOver
				  fraction: 1.0];
	
	// Draw the middle
	NSRect middle = NSInsetRect(bounds, edgeSize, 0);
	
	[background drawInRect: middle
				  fromRect: NSMakeRect(edgeSize,2, backSize.width-edgeSize*2, backSize.height-4)
				 operation: NSCompositeSourceOver
				  fraction: 1.0];
	
	// Draw the right
	NSRect right = bounds;
	right.origin.x = NSMaxX(bounds)-edgeSize;
	right.size.width = edgeSize;
	
	[background drawInRect: right
				  fromRect: NSMakeRect(backSize.width-edgeSize,2, edgeSize, backSize.height-4)
				 operation: NSCompositeSourceOver
				  fraction: 1.0];	
}

#if 0

// = Dealing with moving the view around =

- (void) relocateOverlayWindow {
	// Move the overlay window so that it is displayed over the parent window

	// Work out where this view is on the screen
	NSRect windowRect = [[self window] contentRectForFrameRect: [[self window] frame]];
	screenRect = [self convertRect: [self bounds]
							toView: nil];
	
	screenRect.origin.x += windowRect.origin.x;
	screenRect.origin.y += windowRect.origin.y;
	
	// The overlay view is slightly larger (two pixels above, four pixels below)
	screenRect.origin.y -= 4;
	screenRect.size.height += 6;
	//[overlay setNeedsDisplay: YES];
	
	// Move the overlay window if necessary
	if (!NSEqualRects([overlayWindow frame], screenRect)) {
		[overlayWindow setFrame: screenRect
						display: NO];
		[overlay setNeedsDisplay: YES];
		[overlay displayIfNeeded];
	}
}

- (void) shareOverlayWith: (IFPageBarView*) view {
	if (view == self) return;
	
	[overlay release];
	[overlayWindow release];
	
	overlay = [view->overlay retain];
	overlayWindow = [view->overlayWindow retain];
}

- (void) setFrame: (NSRect) frame {
	[super setFrame: frame];
	
	[self relocateOverlayWindow];
}

- (void) viewDidMoveToSuperview {
	[self relocateOverlayWindow];
}

- (void) viewWillMoveToWindow: (NSWindow*) newWindow {
	[[self window] removeChildWindow: overlayWindow];
	
	[super viewWillMoveToWindow: newWindow];
}

- (void) viewDidMoveToWindow {
	[super viewDidMoveToWindow];
	
	[[self window] addChildWindow: overlayWindow
						  ordered: NSWindowAbove];
	[self relocateOverlayWindow];
	[overlayWindow orderFront: self];
}

#endif

@end
