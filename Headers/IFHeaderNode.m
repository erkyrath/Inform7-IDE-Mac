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
	frame.size.height = gap + [[self font] ascender] - [[self font] descender];
	
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
			unichar bulletPointChars[] = { 0x20, 0x2022, 0x20, 0 };
			bulletPoint = [[NSString alloc] initWithCharacters: bulletPointChars
														length: 3];
		}
		
		// Update the contents of this node
		header = [newHeader retain];
		depth = newDepth;
		position = newPosition;
		selected = IFHeaderNodeUnselected;
		
		children = nil;
		
		// Set up the parameters
		margin	= 5;
		indent	= 12;
		gap		= 8;
		corner	= 5;
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

- (IFHeaderNode*) nodeAtPoint: (NSPoint) point {
	// If the point is outside the frame for this node, then return nothing
	if (point.y < NSMinY(frame) || point.y > NSMaxY(frame)) {
		return nil;
	}
	
	// If the point is beyond the line border for this item, then search the children
	if (children && point.x > margin + indent * depth + (2*indent)/3) {
		NSEnumerator* childEnum = [children objectEnumerator];
		IFHeaderNode* child;
		while (child = [childEnum nextObject]) {
			IFHeaderNode* childNode = [child nodeAtPoint: point];
			if (childNode) return childNode;
		}
	}
	
	// If within the frame and not any of the children, then the node that was clicked was this node
	return self;
}

- (IFHeaderNode*) nodeWithLines: (NSRange) lines
					  intelFile: (IFIntelFile*) intel {
	// FIXME: this more properly belongs in IFHeader (? - won't take account of current child settings there)
	
	// Get the following symbol
	IFIntelSymbol* symbol = [header symbol];
	IFIntelSymbol* followingSymbol = [symbol sibling];
	
	if (!followingSymbol) {
		IFIntelSymbol* parent = [symbol parent];
		
		while (parent && !followingSymbol) {
			followingSymbol = [parent sibling];
			parent = [parent parent];
		}
	}

	// Work out the line range for this header node
	NSRange symbolRange;
	unsigned int finalLine;
	
	symbolRange.location = [intel lineForSymbol: symbol];
	if (followingSymbol) {
		finalLine = [intel lineForSymbol: followingSymbol];
	} else {
		finalLine = NSNotFound;
	}
	
	symbolRange.length = finalLine - symbolRange.location;
	
	// If this range does not overlap the symbol range for this symbol, then return nil
	if (symbol) {
		if (symbolRange.location >= lines.location + lines.length) return nil;
		if (finalLine != nil && lines.location > finalLine) return nil;
	}
	
	// See if any of the child nodes are better match
	if (children) {
		NSEnumerator* childEnum = [children objectEnumerator];
		IFHeaderNode* childNode;
		while (childNode = [childEnum nextObject]) {
			IFHeaderNode* foundChild = [childNode nodeWithLines: lines
													  intelFile: intel];
			if (foundChild) return foundChild;
		}
	}
	
	// This is the header node to use
	return self;
}

// = Drawing the node =

- (NSBezierPath*) highlightPathForFrame: (NSRect) drawFrame {
	// Bezier path representing the outline of this node
	NSBezierPath* result = [NSBezierPath bezierPath];
	
	// Draw the border
	[result moveToPoint: NSMakePoint(NSMinX(frame) + corner + margin + indent * depth + .5, NSMinY(frame) + .5)];
	[result lineToPoint: NSMakePoint(NSMaxX(drawFrame) - corner - margin + .5, NSMinY(frame) + .5)];
	[result curveToPoint: NSMakePoint(NSMaxX(drawFrame) - margin + .5, NSMinY(frame) + corner + .5)
		   controlPoint1: NSMakePoint(NSMaxX(drawFrame) - corner/2 - margin + .5, NSMinY(frame) + .5)
		   controlPoint2: NSMakePoint(NSMaxX(drawFrame) - margin + .5, NSMinY(frame) + corner/2 + .5)];

	[result lineToPoint: NSMakePoint(NSMaxX(drawFrame) - margin + .5, NSMaxY(frame) - corner + .5)];
	[result curveToPoint: NSMakePoint(NSMaxX(drawFrame) - corner - margin + .5, NSMaxY(frame) + .5)
		   controlPoint1: NSMakePoint(NSMaxX(drawFrame) - margin + .5, NSMaxY(frame) - corner/2 + .5)
		   controlPoint2: NSMakePoint(NSMaxX(drawFrame) - corner/2 - margin, NSMaxY(frame))];

	[result lineToPoint: NSMakePoint(NSMinX(frame) + corner + margin + indent * depth + .5, NSMaxY(frame) + .5)];
	[result curveToPoint: NSMakePoint(NSMinX(frame) + margin + indent * depth + .5, NSMaxY(frame) - corner + .5)
		   controlPoint1: NSMakePoint(NSMinX(frame) + corner/2 + margin + indent * depth + .5, NSMaxY(frame) + .5)
		   controlPoint2: NSMakePoint(NSMinX(frame) + margin + indent * depth + .5, NSMaxY(frame) - corner/2 + .5)];
	
	[result lineToPoint: NSMakePoint(NSMinX(frame) + margin + indent * depth + .5, NSMinY(frame) + corner + .5)];
	[result curveToPoint: NSMakePoint(NSMinX(frame) + corner + margin + indent * depth + .5, NSMinY(frame) + .5)
		   controlPoint1: NSMakePoint(NSMinX(frame) + margin + indent * depth + .5, NSMinY(frame) + corner/2 + .5)
		   controlPoint2: NSMakePoint(NSMinX(frame) + corner/2 + margin + indent * depth + .5, NSMinY(frame) + .5)];
	
	return result;
}

- (NSBezierPath*) truncatedHighlightPathForFrame: (NSRect) drawFrame {
	float height = gap + [[self font] ascender] - [[self font] descender];
	if (height + corner >= frame.size.height) {
		return [self highlightPathForFrame: drawFrame];
	}
	
	// Bezier path representing the outline of this node
	NSBezierPath* result = [NSBezierPath bezierPath];
	
	// Draw the border
	[result moveToPoint: NSMakePoint(NSMinX(frame) + corner + margin + indent * depth + .5, NSMinY(frame) + .5)];
	[result lineToPoint: NSMakePoint(NSMaxX(drawFrame) - corner - margin + .5, NSMinY(frame) + .5)];
	[result curveToPoint: NSMakePoint(NSMaxX(drawFrame) - margin + .5, NSMinY(frame) + corner + .5)
		   controlPoint1: NSMakePoint(NSMaxX(drawFrame) - corner/2 - margin + .5, NSMinY(frame) + .5)
		   controlPoint2: NSMakePoint(NSMaxX(drawFrame) - margin + .5, NSMinY(frame) + corner/2 + .5)];
	
	[result lineToPoint: NSMakePoint(NSMaxX(drawFrame) - margin + .5, NSMinY(frame) + height + .5)];
	[result lineToPoint: NSMakePoint(NSMinX(frame) + margin + indent * depth + .5, NSMinY(frame) + height + .5)];
	
	[result lineToPoint: NSMakePoint(NSMinX(frame) + margin + indent * depth + .5, NSMinY(frame) + corner + .5)];
	[result curveToPoint: NSMakePoint(NSMinX(frame) + corner + margin + indent * depth + .5, NSMinY(frame) + .5)
		   controlPoint1: NSMakePoint(NSMinX(frame) + margin + indent * depth + .5, NSMinY(frame) + corner/2 + .5)
		   controlPoint2: NSMakePoint(NSMinX(frame) + corner/2 + margin + indent * depth + .5, NSMinY(frame) + .5)];
	
	return result;
}

- (void) drawNodeInRect: (NSRect) rect
			  withFrame: (NSRect) drawFrame {
	// Do nothing if this node is outside the draw rectangle
	if (!NSIntersectsRect(rect, frame)) {
		return;
	}
	
	// Draw the node background, if necessary
	NSColor* nodeBackgroundColour = nil;
	
	switch (selected) {
		case IFHeaderNodeSelected:
			nodeBackgroundColour = [NSColor selectedTextBackgroundColor];
			break;
			
		default:
			break;
	}
	
	if (nodeBackgroundColour) {
		// Pick the colours that we'll use to do the drawing
		NSColor* nodeLineColour = nodeBackgroundColour;
		NSColor* nodeTextBgColour = [nodeBackgroundColour colorWithAlphaComponent: 0.8];
		NSColor* nodeChildBgColour = [nodeBackgroundColour colorWithAlphaComponent: 0.2];
		
		// Create a bezier path representing this node
		NSBezierPath* highlightPath = [self highlightPathForFrame: drawFrame];
		NSBezierPath* textHighlightPath = [self truncatedHighlightPathForFrame: drawFrame];
		
		// Draw it
		[nodeChildBgColour set];	[highlightPath fill];
		[nodeTextBgColour set];		[textHighlightPath fill];
		[nodeLineColour set];		[highlightPath stroke];
	}
	
	// Draw the node title, truncating if necessary
	[[self name] drawAtPoint: NSMakePoint(frame.origin.x + margin + depth * indent, frame.origin.y + floorf(gap/2))
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
			if (lastChild && [lastChild children] && [lastChild selectionStyle] == IFHeaderNodeUnselected) {
				[[NSColor colorWithDeviceWhite: 0.8
										 alpha: 1.0] set];
				
				NSPoint lineStart = [lastChild frame].origin;
				NSPoint lineEnd = [child frame].origin;
				
				lineStart.x	+= margin + 6 + (depth+1)*indent + 0.5;
				lineEnd.x	+= margin + 6 + (depth+1)*indent + 0.5;
				
				lineStart.y	+= [[lastChild font] ascender] - [[lastChild font] descender] + gap - 1;
				lineEnd.y	+= gap;
				
				[NSBezierPath strokeLineFromPoint: lineStart
										  toPoint: lineEnd];
			}
			
			// Move on
			lastChild = child;
		}
	}
}

@end
