//
//  IFPageBarOverlay.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 01/04/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFPageBarOverlay.h"
#import "IFPageBarView.h"


@implementation IFPageBarOverlay

// = Images =

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
        // Initialization code here.
    }
    return self;
}

// = Drawing =

- (BOOL) isOpaque {
	return NO;
}

- (void)drawRect:(NSRect)rect {
	NSImage* background = [self normalImage];
	NSSize backSize = [background size];
	
	float edgeSize = 20;
	NSRect bounds = [self bounds];
	
	if (edgeSize*2 > bounds.size.width) {
		edgeSize = bounds.size.width/2;
	}
	
	// Draw the left
	NSRect left = bounds;
	left.size.width = edgeSize;
	
	[background drawInRect: left
				  fromRect: NSMakeRect(0,0, edgeSize, backSize.height)
				 operation: NSCompositeSourceOver
				  fraction: 1.0];
	
	// Draw the middle
	NSRect middle = NSInsetRect(bounds, edgeSize, 0);
	
	[background drawInRect: middle
				  fromRect: NSMakeRect(edgeSize,0, backSize.width-edgeSize*2, backSize.height)
				 operation: NSCompositeSourceOver
				  fraction: 1.0];
	
	// Draw the right
	NSRect right = bounds;
	right.origin.x = NSMaxX(bounds)-edgeSize;
	right.size.width = edgeSize;
	
	[background drawInRect: right
				  fromRect: NSMakeRect(backSize.width-edgeSize,0, edgeSize, backSize.height)
				 operation: NSCompositeSourceOver
				  fraction: 1.0];	
}

@end
