//
//  IFInspectorView.m
//  Inform
//
//  Created by Andrew Hunter on Mon May 03 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import "IFInspectorView.h"

#define TitleHeight 20
#define ViewOffset  20

@implementation IFInspectorView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		innerView = nil;
		
		arrow = [[IFIsArrow alloc] initWithFrame: NSMakeRect(0, -4, 24, 28)];
		[self addSubview: arrow];
		[arrow sizeToFit];
		
		titleView = [[IFIsTitleView alloc] initWithFrame: NSMakeRect(0, 0, frame.size.width, TitleHeight)];
		[titleView setTitle: @"Untitled"];
		
		[self setAutoresizesSubviews: NO];
		[titleView setAutoresizingMask: NSViewWidthSizable];
		[arrow setAutoresizingMask: NSViewMaxYMargin];
		
		[arrow setTarget: self];
		[arrow setAction: @selector(openChanged:)];
		
		[self addSubview: titleView];
		[self addSubview: arrow];
    }
    return self;
}

- (void) dealloc {
	if (innerView) [innerView release];
	
	[arrow release];
	[titleView release];
	
	[super dealloc];
}

// = The view =

- (void) setTitle: (NSString*) title {
	[titleView setTitle: title];
}

- (void) setView: (NSView*) view {
	if (view) {
		[view removeFromSuperview];
		[view release];
	}
	
	innerView = [view retain];
	[self layoutViews];
}

- (NSView*) view {
	return innerView;
}

- (void) layoutViews {
	switch ([arrow intValue]) {
		case 1:
		case 2:
			// Closed
			if ([innerView superview] != nil)
				[innerView removeFromSuperview];
			
			NSRect ourFrame = [self frame];
			ourFrame.size.height = TitleHeight;
			[self setFrame: ourFrame];
			[self setNeedsDisplay: YES];
			break;
			
		case 3:
		{
			if ([innerView superview] != self) {
				[innerView removeFromSuperview];

				// Open
				NSRect bounds = [self bounds];
				NSRect newFrame = [self frame];
				
				NSRect innerFrame = bounds;
			
				innerFrame.size.height = [innerView frame].size.height;
				innerFrame.origin.y += ViewOffset;
				newFrame.size.height = innerFrame.size.height + ViewOffset;
			
				[innerView setFrame: innerFrame];
				[self setFrame: newFrame];
				[self addSubview: innerView
					  positioned: NSWindowBelow
					  relativeTo: titleView];
			
				[self setNeedsDisplay: YES];
			}
			break;
		}
	}
}

- (void) openChanged: (id) sender {
	[self layoutViews];
}

// = Drawing =
- (void)drawRect:(NSRect)rect {
}

- (BOOL) isFlipped {
	return YES;
}

- (BOOL) isOpaque {
	return NO;
}

@end
