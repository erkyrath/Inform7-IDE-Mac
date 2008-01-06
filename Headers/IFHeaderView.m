//
//  IFHeaderView.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 02/01/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFHeaderView.h"


@implementation IFHeaderView

// = Initialisation =

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		displayDepth = 5;
    }
    return self;
}

- (void) dealloc {
	[rootHeader release];		rootHeader = nil;
	
	[super dealloc];
}

// = Information about this view =

- (IFHeaderNode*) rootHeaderNode {
	return rootHeaderNode;
}

// = Updating the view =

- (void) updateFromRoot {
	// Replace the root header node
	[rootHeaderNode release]; rootHeaderNode = nil;
	rootHeaderNode = [[IFHeaderNode alloc] initWithHeader: rootHeader
												 position: NSMakePoint(0,0)
													depth: 0];
	[rootHeaderNode populateToDepth: displayDepth];
	
	// Redraw the display
	[self setNeedsDisplay: YES];
	
	// Resize the view
	NSRect rootFrame = [rootHeaderNode frame];
	rootFrame.size.width = [self frame].size.width;
	rootFrame.size.height += 5;
	[self setFrameSize: rootFrame.size];
}

// = Settings for this view =

- (BOOL) isFlipped {
	return YES;
}

- (int) displayDepth {
	return displayDepth;
}

- (void) setDisplayDepth: (int) newDisplayDepth {
	// Set the display depth for this view
	displayDepth = newDisplayDepth;
	
	// Refresh the view
	[self updateFromRoot];
}


- (void) setDelegate: (id) newDelegate {
	delegate = newDelegate;
}

// = Drawing =

- (void)drawRect:(NSRect)rect {
	// Draw the background
	[[NSColor whiteColor] set];
	NSRectFill(rect);
	
	// Draw the nodes
	[rootHeaderNode drawNodeInRect: rect
						 withFrame: [self bounds]];
}

// = Messages from the header controller =

- (void) refreshHeaders: (IFHeaderController*) controller {
	// Get the root header from the controller
	[rootHeader release]; rootHeader = nil;
	rootHeader = [[controller rootHeader] retain];
	
	// Update this control
	[self updateFromRoot];
}

// = Mouse events =

- (void) mouseDown: (NSEvent*) evt {
	// Get the position where the mouse was clicked
	NSPoint viewPos = [self convertPoint: [evt locationInWindow]
								fromView: nil];
	
	// Get which node was clicked on
	IFHeaderNode* clicked = [rootHeaderNode nodeAtPoint: viewPos];
	
	// Inform the delegate that the header has been clicked
	if (clicked && delegate && [delegate respondsToSelector: @selector(headerView:clickedOnNode:)]) {
		[delegate headerView: self
			   clickedOnNode: clicked];
	}
}

@end
