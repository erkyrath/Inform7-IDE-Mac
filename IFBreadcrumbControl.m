//
//  IFBreadcrumbControl.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 20/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import "IFBreadcrumbControl.h"

#import "IFBreadcrumbCell.h"

@implementation IFBreadcrumbControl

+ (Class) cellClass
{
    return [IFBreadcrumbCell class];
}

// = Initialisation =

- (id) initWithFrame: (NSRect) frame {
	self = [super initWithFrame: frame];
	
	if (self) {
		cells = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void) dealloc {
	[cells release];
	[cellRects release];
	[selectedCell release];
	
	[super dealloc];
}

// = Maintaining cells =

- (void) calcSize {
	needsCalculation = NO;
	
	NSPoint origin = [self bounds].origin;

	NSEnumerator* cellEnum = [cells objectEnumerator];
	IFBreadcrumbCell* cell;
	
	// Set the left/right cells
	while (cell = [cellEnum nextObject]) {
		[cell setIsLeft: NO];
		[cell setIsRight: NO];
	}
	
	if ([cells count] == 0) {
		return;
	}
	
	[[cells objectAtIndex: 0] setIsLeft: YES];
	[[cells lastObject] setIsRight: YES];
	
	// Clear out the list of rectangles
	[cellRects release];
	cellRects = [[NSMutableArray alloc] init];
	
	cellEnum = [cells objectEnumerator];
	float width = 0;
	float height = 0;
	while (cell = [cellEnum nextObject]) {
		// Recalculate the bounds for this cell
		[cell calcDrawInfo: [self bounds]];
		
		// Move the origin on appropriately
		NSSize cellSize = [cell cellSize];
		NSRect cellRect;
		
		cellRect.origin = origin;
		cellRect.size = cellSize;
		
		if (cellSize.height > height) height = cellSize.height;
		
		[cellRects addObject: [NSValue valueWithRect: cellRect]];
		
		origin.x += cellRect.size.width - [cell overlap];
		width += cellRect.size.width - [cell overlap];
	}
	
	// Store the ideal size
	idealSize = NSMakeSize(width, height);
	
	// Compress the cells if necessary
	NSRect bounds = [self bounds];
	
	// If the crumbs are wider than this view, then compact them
	if ([cellRects count] > 0) {
		NSRect lastRect = [[cellRects lastObject] rectValue];
		
		horizontalRatio = bounds.size.width/NSMaxX(lastRect);
		if (horizontalRatio > 1.0) horizontalRatio = 1.0;
	}
	
	// Perform the compression
	NSEnumerator* rectEnum = [cellRects objectEnumerator];
	NSValue* rect;
	
	[cellRects autorelease];
	cellRects = [[NSMutableArray alloc] init];
	
	cellEnum = [cells objectEnumerator];
	float xpos = 0;
	while (rect = [rectEnum nextObject]) {
		cell = [cellEnum nextObject];
		
		NSRect oldRect = [rect rectValue];
		
		float overlap = [cell overlap];
		oldRect.origin.x = xpos;
		oldRect.size.width = floorf((oldRect.size.width-overlap) * horizontalRatio + overlap);
		
		xpos += oldRect.size.width-overlap;
		
		[cellRects addObject: [NSValue valueWithRect: oldRect]];
	}
}

- (NSSize) idealSize {
	if (needsCalculation) [self calcSize];
	
	return idealSize;
}

// = Adding cells =

- (void) removeAllBreadcrumbs {
	[cells removeAllObjects];
	needsCalculation = YES;
	[self setNeedsDisplay: YES];
}

- (void) addBreadcrumbWithText: (NSString*) text 
						   tag: (int) tag {
	IFBreadcrumbCell* newCell = [[IFBreadcrumbCell alloc] initTextCell: text];
	[newCell setTag: tag];
	
	[cells addObject: [newCell autorelease]];
	
	needsCalculation = YES;
	[self setNeedsDisplay: YES];
}

- (void) addBreadcrumbWithImage: (NSImage*) image 
							tag: (int) tag {
	IFBreadcrumbCell* newCell = [[IFBreadcrumbCell alloc] initImageCell: image];
	[newCell setTag: tag];
	
	[cells addObject: [newCell autorelease]];
	
	needsCalculation = YES;
	[self setNeedsDisplay: YES];
}

// = Rendering =

- (void) drawRect: (NSRect) rect {	
	if (needsCalculation) [self calcSize];
	
	// Draw the background
	NSRect bounds = [self bounds];
	
	[[NSColor lightGrayColor] set];
	bounds.origin.y += 2;
	bounds.size.height -= 2;
	NSRectFill(bounds);
	
	// Draw the cells
	NSEnumerator* cellEnum = [cells reverseObjectEnumerator];
	NSEnumerator* rectEnum = [cellRects reverseObjectEnumerator];
	IFBreadcrumbCell* cell;
	
	while (cell = [cellEnum nextObject]) {
		NSRect cellRect = [[rectEnum nextObject] rectValue];
		
		if (NSIntersectsRect(rect, cellRect)) {
			[cell drawWithFrame: cellRect
						 inView: self];
		}
	}
}

// = Dealing with mouse events =

- (void) updateCell: (IFBreadcrumbCell*) whichCell {
	int cellIndex = [cells indexOfObjectIdenticalTo: whichCell];
	if (cellIndex == NSNotFound) return;
	
	NSRect rect = [[cellRects objectAtIndex: cellIndex] rectValue];
	
	[self setNeedsDisplayInRect: rect];
}

- (void) selectCell: (IFBreadcrumbCell*) whichCell {
	if (selectedCell) {
		[selectedCell setState: NSOffState];
		[self updateCell: selectedCell];

		[selectedCell release];
		selectedCell = nil;
	}
	
	selectedCell = [whichCell retain];
	[selectedCell setState: NSOnState];
	
	[self updateCell: selectedCell];	
}

- (IFBreadcrumbCell*) cellAtPoint: (NSPoint) position {
	if (needsCalculation) [self calcSize];

	NSEnumerator* cellEnum = [cells objectEnumerator];
	NSEnumerator* rectEnum = [cellRects objectEnumerator];
	IFBreadcrumbCell* cell;
	
	while (cell = [cellEnum nextObject]) {
		NSRect rect = [[rectEnum nextObject] rectValue];
		
		if (NSPointInRect(position, rect)) {
			// Get the next cell
			IFBreadcrumbCell* nextCell = [cellEnum nextObject];
			
			// Perform a hit test to see if we're now in this cell
			if (position.x > NSMaxX(rect)-[cell overlap]) {
				if ([nextCell hitTest: NSMakePoint(position.x - (NSMaxX(rect)-[cell overlap]),
												   position.y - NSMinY(rect))]) {
					return nextCell;
				}
			}
			
			return cell;
		}
	}
	
	return nil;
}

- (void) mouseDown: (NSEvent*) evt {
	NSPoint mousePoint = [self convertPoint: [evt locationInWindow]
								   fromView: nil];
	
	IFBreadcrumbCell* cell = [self cellAtPoint: mousePoint];
	[self selectCell: cell];
}

- (void) mouseDragged: (NSEvent*) evt {
	NSPoint mousePoint = [self convertPoint: [evt locationInWindow]
								   fromView: nil];
	
	IFBreadcrumbCell* cell = [self cellAtPoint: mousePoint];
	[self selectCell: cell];
}

- (void) mouseUp: (NSEvent*) evt {
	NSPoint mousePoint = [self convertPoint: [evt locationInWindow]
								   fromView: nil];
	
	IFBreadcrumbCell* cell = [self cellAtPoint: mousePoint];
	if ([cell action] != nil) {
		[NSApp sendAction: [cell action]
					   to: [cell target]
					 from: cell];
	}
	if ([self action] != nil) {
		// For some reason, [NSApp sendAction:] fails to do what it says on the tin
		if ([[self target] respondsToSelector: [self action]]) {
			[[self target] performSelector: [self action]
								withObject: cell];
		} else {
			[NSApp sendAction: [self action]
						   to: [self target]
						 from: cell];
		}
	}

	[self selectCell: nil];
}

// TODO: accessibility
// TODO: keyboard?

@end
