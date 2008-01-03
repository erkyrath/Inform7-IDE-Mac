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
	// The frame has an origin at the position specified for this node
	frame.origin = position;
	
	// The initial height is determined by the title of this node
	frame.size.width = [[header headingName] sizeWithAttributes: [NSDictionary dictionaryWithObjectsAndKeys: headerNodeFont, NSFontNameAttribute, nil]].width;
	frame.size.height = 6 + [headerNodeFont ascender] - [headerNodeFont descender];
	
	// The total height is different if there are children for this item (depending on the y position of the final child)
	if (children && [children count] > 0) {
		NSRect lastFrame = [(IFHeaderNode*)[children lastObject] frame];
		float maxY = NSMaxY(lastFrame);
		
		frame.size.height = maxY - NSMinY(frame);
	}
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
	NSPoint childPoint = NSMakePoint(NSMinX(frame), floorf(NSMaxY(frame)));
	
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
		[children addObject: newChildNode];
		
		// Update the position of the next child element
		childPoint.y = floorf(NSMaxY([newChildNode frame]));
	}
	
	// Update the frame of this node
	[self updateNodeFrame];
}

// = Getting information about this node =

- (NSRect) frame {
	return frame;
}

- (IFHeader*) header {
	return header;
}

- (IFHeaderNodeSelectionStyle) selectionStyle {
	return IFHeaderNodeUnselected;
}

- (void) setSelectionStyle: (IFHeaderNodeSelectionStyle) selectionStyle {
	// TODO: implement me
}

// = Drawing the node =

- (void) drawNodeInRect: (NSRect) rect
			  withFrame: (NSRect) drawFrame {
	// Do nothing if this node is outside the draw rectangle
	if (!NSIntersectsRect(rect, frame)) {
		return;
	}
	
	// Draw the node title, truncating if necessary
	[[header headingName] drawAtPoint: NSMakePoint(frame.origin.x + 5 + depth * 8, frame.origin.y + 3)
					   withAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
											headerNodeFont, NSFontAttributeName,
										nil]];
	
	// Draw the node children
	if (children && [children count] > 0) {
		NSEnumerator* childEnum = [children objectEnumerator];
		IFHeaderNode* child;
		while (child = [childEnum nextObject]) {
			[child drawNodeInRect: rect
						withFrame: drawFrame];
		}
	}
}

@end
