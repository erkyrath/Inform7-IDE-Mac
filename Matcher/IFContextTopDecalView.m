//
//  IFContextTopDecalView.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 03/07/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFContextTopDecalView.h"

static NSImage* topDecal;

@implementation IFContextTopDecalView

+ (void) initialize {
	topDecal = [[NSImage imageNamed: @"InfoWindowTop"] retain];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		flipped = NO;
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	NSImage* decalImage = [[NSImage alloc] initWithSize: [topDecal size]];
	NSImage* bgImage = [[NSImage alloc] initWithSize: [topDecal size]];
	NSRect topRect = NSMakeRect(0,0, [topDecal size].width, [topDecal size].height);
	
	NSRect bounds = [self bounds];
	
	// Draw the window background
	[bgImage lockFocus];
	
	[[NSGraphicsContext currentContext] setPatternPhase: NSMakePoint(-NSMinX(bounds), -NSMaxY(bounds)-topRect.size.height)];
	[[NSColor windowBackgroundColor] set];
	NSRectFill(topRect);	
	
	[bgImage unlockFocus];
	
	// Draw the upper decal
	[decalImage lockFocus];
	
	[[NSColor clearColor] set];
	NSRectFill(topRect);
	
	if (flipped) {
		[[NSGraphicsContext currentContext] saveGraphicsState];
		
		NSAffineTransform* flipTransform = [NSAffineTransform transform];
		[flipTransform scaleXBy: 1.0
							yBy: -1.0];
		[flipTransform translateXBy: 0
								yBy: -[topDecal size].height];
		[flipTransform set];
	}
	
	[topDecal drawInRect: topRect
				fromRect: topRect
			   operation: NSCompositeSourceOver
				fraction: 1.0];
	if (flipped) {
		[[NSGraphicsContext currentContext] restoreGraphicsState];
	}
				
	[bgImage drawInRect: topRect
			   fromRect: topRect
			  operation: NSCompositeSourceIn
			   fraction: 1.0];
	
	[decalImage unlockFocus];
	
	// Draw the final image
	NSRect decalRect = NSMakeRect(NSMinX(bounds), NSMaxY(bounds)-topRect.size.height, topRect.size.width, topRect.size.height);
	if (flipped) {
		decalRect.origin.y = 0;
	}
	[[NSColor clearColor] set];
	NSRectFill(decalRect);
	[decalImage drawInRect: decalRect
				  fromRect: topRect
				 operation: NSCompositeSourceOver
				  fraction: 1.0];
	
	[bgImage release];
	[decalImage release];
	
	// Draw the remainder of the background
	NSRect bgRect = NSMakeRect(0, flipped?topRect.size.height:0, bounds.size.width, bounds.size.height - topRect.size.height);
	[[NSColor windowBackgroundColor] set];
	NSRectFill(bgRect);
}

- (BOOL) isOpaque {
	return NO;
}

- (void) setFlipped: (BOOL) newFlipped {
	if (flipped == newFlipped) return;
	
	flipped = newFlipped;
	[self setNeedsDisplay: YES];
}

@end
