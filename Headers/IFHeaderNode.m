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

// = Utilities used to help lay out this node =

- (NSFont*) font {
	switch (selected) {
		case IFHeaderNodeSelected:
			return boldHeaderNodeFont;
			
		default:
			return headerNodeFont;
	}
}

- (void) updateNodeFrame {
	// The frame has an origin at the position specified for this node
	frame.origin = position;
	
	// The initial height is determined by the title of this node
	frame.size.width = [[header headingName] sizeWithAttributes: [NSDictionary dictionaryWithObjectsAndKeys: [self font], NSFontNameAttribute, nil]].width;
	frame.size.height = 8 + [[self font] ascender] - [[self font] descender];
	
	// The total height is different if there are children for this item (depending on the y position of the final child)
	if (children && [children count] > 0) {
		// The width is that of the widest child element
		float maxX = NSMaxX(frame);
		
		NSEnumerator* childEnum = [children objectEnumerator];
		IFHeaderNode* child;
		while (child = [childEnum nextObject]) {
			float childMaxX = NSMaxX([child frame]);
			if (childMaxX > maxX) maxX = childMaxX;
		}
		
		frame.size.width = maxX - NSMinX(frame);

		// The height is based on the maximum Y position of the final child
		NSRect lastFrame = [(IFHeaderNode*)[children lastObject] frame];
		float maxY = NSMaxY(lastFrame);
		frame.size.height = maxY - NSMinY(frame);
	}
}

// = Constructing this node =

- (id) initWithHeader: (IFHeader*) newHeader
			 position: (NSPoint) newPosition
				depth: (int) newDepth {
	self = [self init];
	
	if (self) {
		// If the fonts don't exist, then update them
		if (!headerNodeFont)		headerNodeFont		= [[NSFont systemFontOfSize: [NSFont smallSystemFontSize]] retain];
		if (!boldHeaderNodeFont)	boldHeaderNodeFont	= [[NSFont boldSystemFontOfSize: [NSFont smallSystemFontSize]] retain];
		
		// Update the contents of this node
		header = [newHeader retain];
		depth = newDepth;
		position = newPosition;
		selected = IFHeaderNodeUnselected;
		
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
	return selected;
}

- (void) setSelectionStyle: (IFHeaderNodeSelectionStyle) selectionStyle {
	selected = selectionStyle;
}

// = Drawing the node =

- (void) drawNodeInRect: (NSRect) rect
			  withFrame: (NSRect) drawFrame {
	// Do nothing if this node is outside the draw rectangle
	if (!NSIntersectsRect(rect, frame)) {
		return;
	}
	
	// Draw the node title, truncating if necessary
	[[header headingName] drawAtPoint: NSMakePoint(frame.origin.x + 5 + depth * 8, frame.origin.y + 4)
					   withAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
											[self font], NSFontAttributeName,
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
