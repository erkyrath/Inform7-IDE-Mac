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
static NSString* bulletPoint = nil;

@implementation IFHeaderNode

// = Utilities used to help lay out this node =

- (NSFont*) font {
	if (depth == 0) return boldHeaderNodeFont;
	
	switch (selected) {
		case IFHeaderNodeSelected:
			return boldHeaderNodeFont;
			
		default:
			return headerNodeFont;
	}
}

- (NSString*) name {
	NSString* name = [header headingName];
	if (depth > 0) {
		name = [bulletPoint stringByAppendingString: name];
	}
	return name;
}

- (void) updateNodeFrame {
	// The frame has an origin at the position specified for this node
	frame.origin = position;
	
	// The initial height is determined by the title of this node
	frame.size.width = [[self name] sizeWithAttributes: [NSDictionary dictionaryWithObjectsAndKeys: [self font], NSFontNameAttribute, nil]].width;
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
		
		// Create a bullet point
		if (!bulletPoint) {
			unichar bulletPointChars[] = { 0x2022, 0x20, 0 };
			bulletPoint = [[NSString alloc] initWithCharacters: bulletPointChars
														length: 2];
		}
		
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
	if (maxDepth == 0) {
		[children release]; children = nil;
		[self updateNodeFrame];
		return;
	}
	
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

- (NSArray*) children {
	if (!children || [children count] == 0) return nil;
	return children;
}

// = Drawing the node =

- (void) drawNodeInRect: (NSRect) rect
			  withFrame: (NSRect) drawFrame {
	// Do nothing if this node is outside the draw rectangle
	if (!NSIntersectsRect(rect, frame)) {
		return;
	}
	
	// Draw the node title, truncating if necessary
	[[self name] drawAtPoint: NSMakePoint(frame.origin.x + 5 + depth * 8, frame.origin.y + 4)
			  withAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
							   [self font], NSFontAttributeName,
							   nil]];
	
	// Draw the node children
	if (children && [children count] > 0) {
		NSEnumerator* childEnum = [children objectEnumerator];
		IFHeaderNode* child, *lastChild;
		
		lastChild = nil;
		
		while (child = [childEnum nextObject]) {
			// Draw this child
			[child drawNodeInRect: rect
						withFrame: drawFrame];
			
			// Draw a line linking this child to the last child if possible
			if (lastChild && [lastChild children]) {
				[[NSColor colorWithDeviceWhite: 0.8
										 alpha: 1.0] set];
				
				NSPoint lineStart = [lastChild frame].origin;
				NSPoint lineEnd = [child frame].origin;
				
				lineStart.x	+= 7 + (depth+1)*8 + 0.5;
				lineEnd.x	+= 7 + (depth+1)*8 + 0.5;
				
				lineStart.y	+= [[lastChild font] ascender] - [[lastChild font] descender] + 7;
				lineEnd.y	+= 4;
				
				[NSBezierPath strokeLineFromPoint: lineStart
										  toPoint: lineEnd];
			}
			
			// Move on
			lastChild = child;
		}
	}
}

@end
