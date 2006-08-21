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

- (void)calcSize {
	NSPoint origin = [self bounds].origin;

	NSEnumerator* cellEnum = [cells objectEnumerator];
	IFBreadcrumbCell* cell;
	
	// Set the left/right cells
	while (cell = [cellEnum nextObject]) {
		[cell setIsLeft: NO];
		[cell setIsRight: NO];
	}
	
	[[cells objectAtIndex: 0] setIsLeft: YES];
	[[cells lastObject] setIsRight: YES];
	
	// Clear out the list of rectangles
	[cellRects release];
	cellRects = [[NSMutableArray alloc] init];
	
	cellEnum = [cells objectEnumerator];
	while (cell = [cellEnum nextObject]) {
		// Recalculate the bounds for this cell
		[cell calcDrawInfo: [self bounds]];
		
		// Move the origin on appropriately
		NSSize cellSize = [cell cellSize];
		NSRect cellRect;
		
		cellRect.origin = origin;
		cellRect.size = cellSize;
		
		[cellRects addObject: [NSValue valueWithRect: cellRect]];
		
		origin.x += cellRect.size.width - [cell overlap];
	}
	
	// TODO: compress the cells if necessary
}

// = Adding cells =

- (void) addBreadcrumbWithText: (NSString*) text 
						   tag: (int) tag {
	IFBreadcrumbCell* newCell = [[IFBreadcrumbCell alloc] initTextCell: text];
	[newCell setTag: tag];
	
	[cells addObject: [newCell autorelease]];
	
	[self calcSize];
	[self setNeedsDisplay: YES];
}

- (void) addBreadcrumbWithImage: (NSImage*) image 
							tag: (int) tag {
	IFBreadcrumbCell* newCell = [[IFBreadcrumbCell alloc] initImageCell: image];
	[newCell setTag: tag];
	
	[cells addObject: [newCell autorelease]];
	
	[self calcSize];
	[self setNeedsDisplay: YES];
}

// = Rendering =

- (void) drawRect: (NSRect) rect {
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
		[[cell target] performSelector: [cell action]
							withObject: cell];
	}

	[self selectCell: nil];
}

// TODO: accessibility
// TODO: keyboard?

@end
