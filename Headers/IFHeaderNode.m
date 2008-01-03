//
//  IFHeaderNode.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 03/01/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFHeaderNode.h"

static NSFont* headerNodeFont = nil;
static NSFont* boldHeaderNodeFont = nil;

@implementation IFHeaderNode

// = Constructing this node =

- (void) updateNodeFrame {
	// The frame has an origin at the cur
	frame.origin = position;
}

- (id) initWithHeader: (IFHeader*) newHeader
			 position: (NSPoint) newPosition
				depth: (int) newDepth {
	self = [self init];
	
	if (self) {
		// If the fonts don't exist, then update them
		if (!headerNodeFont)		headerNodeFont		= [[NSFont systemFontOfSize: 10] retain];
		if (!boldHeaderNodeFont)	boldHeaderNodeFont	= [[NSFont boldSystemFontOfSize: 10] retain];
		
		// Update the contents of this node
		header = [newHeader retain];
		depth = newDepth;
		position = newPosition;
		
		children = nil;
	}
	
	return self;
}

- (void) dealloc {
	[header release];			header = nil;
	[children release];			children = nil;
	
	[super dealloc];
}

- (void) populateToDepth: (int) maxDepth {
	// Do nothing if we've reached the end
	if (maxDepth == 0) return;
	
	// Create the children array
	[children release]; children = nil;
	[self updateNodeFrame];
	children = [[NSMutableArray alloc] init];
	
	// Work out the position for the first child node
	NSPoint childPoint = NSMakePoint(NSMinX(frame), NSMaxY(frame));
	
	// Populate it
	NSEnumerator* childNodeEnum = [[header children] objectEnumerator];
	IFHeader* childNode;
	while (childNode = [childNodeEnum nextObject]) {
		// Create a new child node
		IFHeaderNode* newChildNode = [[IFHeaderNode alloc] initWithHeader: childNode
																 position: childPoint
																	depth: depth+1];
		[newChildNode autorelease];
		
		// Populate it
		[newChildNode populateToDepth: maxDepth - 1];
		
		// Update the position of the next child element
		childPoint.y = NSMaxY([newChildNode frame]);
	}
	
	// Update the frame of this node
	[self updateNodeFrame];
}

// Getting information about this node

- (NSRect) frame {
	return frame;
}

- (IFHeader*) header {
	return header;
}

#if 0
- (IFHeaderNodeSelectionStyle) selectionStyle;		// The selection style of this node
- (void) setSelectionStyle: (IFHeaderNodeSelectionStyle) selectionStyle;

// Drawing the node

- (void) drawNodeInRect: (NSRect) rect;				// Draws this node
#endif

@end
