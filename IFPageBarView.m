//
//  IFPageBarView.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 01/04/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFPageBarView.h"
#import "IFPageBarCell.h"

//
// Notes (in no particular order)
//
// There are a maximum of three separate animations that can be occuring at any one
// time:
//
// One or more cells can be animating between states
// The background can animate between states (inactive -> active)
// The left and right hand side can fade out when switching between cell sets
//
// Not sure if I'm going to implement all of these. The cell animations are presently
// the most important, followed by the background animations.
//

//
// Object used to represent the layout of an individual cell
//
@interface IFPageCellLayout : NSObject {
	@public
	float position;					// Offset from the left/right for this cell
	float minWidth;					// Minimum size that this cell can be
	float width;					// Actual size that this cell should be drawn at
	BOOL hidden;					// If YES then this cell shouldn't be drawn
	
	NSImage* cellImage;				// The image for this cell
	NSImage* animateFrom;			// The image to animate from
}

@end

@implementation IFPageCellLayout

- (void) dealloc {
	[cellImage release];
	[animateFrom release];
	
	[super dealloc];
}

@end

// = Constants =
static const float edgeSize = 20.0;				// Portion of an overlay image that is considered to be part of the 'edge'
static const float rightMargin = 5.0;			// Margin to put on the right (to account for scrollbars, tabs, etc)
static const float tabMargin = 4.0;				// Extra margin to put on the right when drawing the 'bar' image as opposed to the background
static const float cellMargin = 12.0;			// Margin on the left and right until we actually draw the first cell

@implementation IFPageBarView

// = Images =

+ (NSImage*) backgroundImage {
	static NSImage* image = nil;
	
	if (!image) {
		image = [[NSImage imageNamed: @"BarBackground"] retain];
	}
	
	return image;
}

+ (NSImage*) normalImage {
	static NSImage* image = nil;
	
	if (!image) {
		image = [[NSImage imageNamed: @"BarNormal"] retain];
	}
	
	return image;
}

+ (NSImage*) highlightedImage {
	static NSImage* image = nil;
	static NSImage* graphiteImage = nil;
	
	if (!image) {
		image = [[NSImage imageNamed: @"BarHighlighted"] retain];
		graphiteImage = [[NSImage imageNamed: @"BarSelectedGraphite"] retain];
	}
	
	if ([NSColor currentControlTint] == NSGraphiteControlTint) {
		return graphiteImage;
	} else {
		return image;
	}
}

+ (NSImage*) selectedImage {
	static NSImage* image = nil;
	
	if (!image) {
		image = [[NSImage imageNamed: @"BarSelected"] retain];
	}
	
	return image;
}

+ (NSImage*) inactiveImage {
	static NSImage* image = nil;
	
	if (!image) {
		image = [[NSImage imageNamed: @"BarInactive"] retain];
	}
	
	return image;
}

// = Initialisation =

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
		cellsNeedLayout = YES;
		
#if 0
		// Construct the overlay window
		overlayWindow = [[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,100,100)
													styleMask: NSBorderlessWindowMask
													  backing: NSBackingStoreBuffered
														defer: NO];
		[overlayWindow setOpaque: NO];
		[overlayWindow setBackgroundColor: [NSColor clearColor]];
		
		// Construct the overlay view
		overlay = [[IFPageBarOverlay alloc] initWithFrame: NSMakeRect(0,0,100,100)];
		[overlayWindow setContentView: overlay];
#endif
    }
	
    return self;
}

- (void) dealloc {
	[leftCells release];
	[rightCells release];
	[leftLayout release];
	[rightLayout release];
	
	[trackingCell release];	
	[super dealloc];
}

// = Drawing =

+ (void) drawOverlay: (NSImage*) overlay
			  inRect: (NSRect) rect
		 totalBounds: (NSRect) bounds
			fraction: (float) fraction {
	// Draws an overlay image, given the bounds of this control and the area to draw
	NSSize imageSize = [overlay size];
	NSRect sourceRect;
	NSRect destRect;
	
	// If the bounds are too small, then take an even fraction from either side of the image
	float realEdgeSize = edgeSize;
	if (bounds.size.width < realEdgeSize) {
		realEdgeSize = bounds.size.width / 2;
	}
	
	// Adjust the drawing rectangle so that it's within the bounds
	if (bounds.size.height > imageSize.height-2) {
		bounds.size.height = imageSize.height-2;
	}
	rect = NSIntersectionRect(rect, bounds);
	
	// The overlay image has edgeSize pixels on either side marking the end, 2 transparent pixels above (which we don't draw) and 6 pixels of shadow/transparent below (which we do draw in so far as there is room)
	float leftPos = NSMinX(rect)-NSMinX(bounds);
	float rightPos = NSMaxX(rect)-NSMinX(bounds);
	
	if (leftPos < realEdgeSize) {
		// Draw the left-hand end of the image
		sourceRect = NSMakeRect(leftPos,2, realEdgeSize-leftPos, bounds.size.height);
		destRect = NSMakeRect(rect.origin.x, bounds.origin.y, realEdgeSize-leftPos, bounds.size.height);
		
		if (NSMaxX(destRect) > NSMaxX(rect)) {
			float difference = NSMaxX(destRect) - NSMaxX(rect);
			sourceRect.size.width -= difference;
			destRect.size.width -= difference;
		}
		
		[overlay drawInRect: destRect
				   fromRect: sourceRect
				  operation: NSCompositeSourceOver 
				   fraction: fraction];
		
		// Adjust the area that we're drawing
		rect.origin.x += realEdgeSize-leftPos;
		rect.size.width -= realEdgeSize-leftPos;
	}
	
	float rightBorderWidth = rightPos - (bounds.size.width - realEdgeSize);
	if (rightBorderWidth > 0) {
		// Draw the right-hand end of the image
		sourceRect = NSMakeRect(imageSize.width - realEdgeSize, 2, rightBorderWidth, bounds.size.height);
		destRect = NSMakeRect(NSMaxX(rect)-rightBorderWidth, bounds.origin.y, rightBorderWidth, bounds.size.height);

		if (NSMinX(destRect) < NSMinX(rect)) {
			float difference = NSMinX(rect) - NSMinX(destRect);
			sourceRect.origin.x += difference;
			destRect.origin.x += difference;
			sourceRect.size.width -= difference;
			destRect.size.width -= difference;
		}
		
		[overlay drawInRect: destRect
				   fromRect: sourceRect
				  operation: NSCompositeSourceOver 
				   fraction: fraction];
		
		// Adjust the area that we're drawing
		rect.size.width -= rightBorderWidth;		
	}
	
	// Draw the remainder of the image
	if (rect.size.width > 0) {
		sourceRect = NSMakeRect(realEdgeSize, 2, imageSize.width - realEdgeSize*2, bounds.size.height);
		destRect = NSMakeRect(rect.origin.x, bounds.origin.y, rect.size.width, bounds.size.height);
		
		[overlay drawInRect: destRect
				   fromRect: sourceRect
				  operation: NSCompositeSourceOver 
				   fraction: fraction];		
	}
}

- (NSImage*) renderCell: (NSCell*) cell
			  forLayout: (IFPageCellLayout*) layout 
			  isOnRight: (BOOL) right {
	// Render the specified cell using the specified layout
	NSRect bounds = [self bounds];
	
	bounds.origin.x += cellMargin;
	bounds.size.width -= cellMargin*2 + tabMargin + rightMargin;
	
	// Set this cell to be owned by this view
	if ([cell controlView] != self) {
		[cell setControlView: self];
		
		// Note that this makes it hard to move a cell from the left to the right
		if ([cell respondsToSelector: @selector(setIsRight:)]) {
			[cell setIsRight: right];
		}
	}

	// Construct the image that will contain this cell
	NSImage* cellImage = [[NSImage alloc] initWithSize: NSMakeSize(layout->width, bounds.size.height)];
	[cellImage autorelease];
	
	NSRect cellFrame = NSMakeRect(bounds.origin.x, bounds.origin.y, layout->width, bounds.size.height);
	if (right) {
		cellFrame.origin.x += bounds.size.width - layout->position - layout->width;
	} else {
		cellFrame.origin.x += layout->position;
	}
	
	// Prepare to draw the cell
	[cellImage lockFocus];
	
	NSAffineTransform* cellTransform = [NSAffineTransform transform];
	[cellTransform translateXBy: -cellFrame.origin.x
							yBy: -cellFrame.origin.y];
	[cellTransform set];
	
	// Draw the cell
	[cell drawWithFrame: cellFrame
				 inView: self];
	
	// Draw the border
	float marginPos;
	if (right) {
		marginPos = NSMinX(cellFrame)+0.5;
	} else {
		marginPos = NSMaxX(cellFrame)-1.5;
	}
	
	[NSBezierPath setDefaultLineWidth: 1.0];
	[[[NSColor controlLightHighlightColor] colorWithAlphaComponent: 0.4] set];
	[NSBezierPath strokeLineFromPoint: NSMakePoint(marginPos, NSMinY(cellFrame)+2)
							  toPoint: NSMakePoint(marginPos, NSMaxY(cellFrame))];
	
	[[[NSColor controlShadowColor] colorWithAlphaComponent: 0.4] set];
	[NSBezierPath strokeLineFromPoint: NSMakePoint(marginPos+1, NSMinY(cellFrame)+2)
							  toPoint: NSMakePoint(marginPos+1, NSMaxY(cellFrame))];
	
	// Finish drawing
	[cellImage unlockFocus];
	
	// Return the result
	return cellImage;
}

- (void) drawCellsFrom: (NSArray*) cellList
				layout: (NSArray*) layoutList
			 isOnRight: (BOOL) right {
	// Draw a set of suitably laid-out cells, either on the right or on the left
	NSEnumerator* cellEnum = [cellList objectEnumerator];
	NSEnumerator* layoutEnum = [layoutList objectEnumerator];
	NSCell* cell;
	IFPageCellLayout* layout;
	NSRect bounds = [self bounds];

	bounds.origin.x += cellMargin;
	bounds.size.width -= cellMargin*2 + tabMargin + rightMargin;
	
	while ((cell = [cellEnum nextObject]) && (layout = [layoutEnum nextObject])) {
		if (layout->hidden) continue;
		
		// Redraw the cell's cached image if required
		if (layout->cellImage == nil) {
			layout->cellImage = [[self renderCell: cell
										forLayout: layout
										isOnRight: right] retain];
		}
		
		// Draw the cell itself
		NSRect cellFrame = NSMakeRect(0,0, layout->width, bounds.size.height);
		NSRect cellSource = cellFrame;
		if (right) {
			cellFrame.origin.x = bounds.size.width - layout->position - layout->width;
		} else {
			cellFrame.origin.x = layout->position;
		}
		cellFrame.origin.x += bounds.origin.x;
		
		cellFrame.size.height -= 2; cellFrame.origin.y += 2;
		cellSource.size.height -= 2; cellSource.origin.y += 2;
		
		[layout->cellImage drawInRect: NSIntegralRect(cellFrame)
							 fromRect: cellSource
							operation: NSCompositeSourceOver
							 fraction: [cell isEnabled]?1.0:0.5];
	}
}

- (void)drawRect:(NSRect)rect {
	// Update the cell positioning information
	[self layoutCells];
	
	// Draw the background image
	NSImage* background = [IFPageBarView backgroundImage];
	NSSize backSize = [background size];
	NSRect bounds = [self bounds];
	
	// Subtract the right margin to take account of the tab border
	bounds.size.width -= rightMargin;
	
	NSRect backgroundBounds = bounds;
	backgroundBounds.size.width -= tabMargin;
	
	// Draw the background gradient
	[background drawInRect: backgroundBounds
				  fromRect: NSMakeRect(0,0, backSize.width, backSize.height)
				 operation: NSCompositeSourceOver
				  fraction: 1.0];
	
	// Draw the standard background
	background = [IFPageBarView normalImage];
	backSize = [background size];

	NSRect leftBounds = backgroundBounds;
	NSRect rightBounds = backgroundBounds;
	NSRect midBounds = backgroundBounds;
	
	NSImage* leftBackground = background;
	NSImage* rightBackground = background;
	
	leftBounds.size.width = cellMargin;
	rightBounds.origin.x = NSMaxX(backgroundBounds)-cellMargin;
	rightBounds.size.width = cellMargin;
	midBounds.origin.x += cellMargin;
	midBounds.size.width -= cellMargin*2;
	
	if ([leftCells count] > 0) {
		if ([[leftCells objectAtIndex: 0] isHighlighted]) {
			leftBackground = [IFPageBarView highlightedImage];
		} else if ([[leftCells objectAtIndex: 0] state] == NSOnState) {
			leftBackground = [IFPageBarView selectedImage];
		}
	}
	if ([rightCells count] > 0) {
		if ([[rightCells objectAtIndex: 0] isHighlighted]) {
			rightBackground = [IFPageBarView highlightedImage];
		} else if ([[rightCells objectAtIndex: 0] state] == NSOnState) {
			rightBackground = [IFPageBarView selectedImage];
		}
	}
	
	[IFPageBarView drawOverlay: background
						inRect: midBounds
				   totalBounds: backgroundBounds
					  fraction: 1.0];
	[IFPageBarView drawOverlay: leftBackground
						inRect: leftBounds
				   totalBounds: backgroundBounds
					  fraction: 1.0];
	[IFPageBarView drawOverlay: rightBackground
						inRect: rightBounds
				   totalBounds: backgroundBounds
					  fraction: 1.0];
	
	// Draw the left-hand cells
	[self drawCellsFrom: leftCells
				 layout: leftLayout
			  isOnRight: NO];
	
	// Draw the right-hand cells
	[self drawCellsFrom: rightCells
				 layout: rightLayout
			  isOnRight: YES];	
	
	return;
}

#if 0

// = Dealing with moving the view around =

- (void) relocateOverlayWindow {
	// Move the overlay window so that it is displayed over the parent window

	// Work out where this view is on the screen
	NSRect windowRect = [[self window] contentRectForFrameRect: [[self window] frame]];
	screenRect = [self convertRect: [self bounds]
							toView: nil];
	
	screenRect.origin.x += windowRect.origin.x;
	screenRect.origin.y += windowRect.origin.y;
	
	// The overlay view is slightly larger (two pixels above, four pixels below)
	screenRect.origin.y -= 4;
	screenRect.size.height += 6;
	//[overlay setNeedsDisplay: YES];
	
	// Move the overlay window if necessary
	if (!NSEqualRects([overlayWindow frame], screenRect)) {
		[overlayWindow setFrame: screenRect
						display: NO];
		[overlay setNeedsDisplay: YES];
		[overlay displayIfNeeded];
	}
}

- (void) shareOverlayWith: (IFPageBarView*) view {
	if (view == self) return;
	
	[overlay release];
	[overlayWindow release];
	
	overlay = [view->overlay retain];
	overlayWindow = [view->overlayWindow retain];
}

- (void) setFrame: (NSRect) frame {
	[super setFrame: frame];
	
	[self relocateOverlayWindow];
}

- (void) viewDidMoveToSuperview {
	[self relocateOverlayWindow];
}

- (void) viewWillMoveToWindow: (NSWindow*) newWindow {
	[[self window] removeChildWindow: overlayWindow];
	
	[super viewWillMoveToWindow: newWindow];
}

- (void) viewDidMoveToWindow {
	[super viewDidMoveToWindow];
	
	[[self window] addChildWindow: overlayWindow
						  ordered: NSWindowAbove];
	[self relocateOverlayWindow];
	[overlayWindow orderFront: self];
}

#endif

// = Managing cells =

- (void) setLeftCells: (NSArray*) newLeftCells {
	[leftCells release];
	leftCells = [[NSMutableArray alloc] initWithArray: newLeftCells];
	
	[leftLayout release]; leftLayout = nil;
	cellsNeedLayout = YES;
	
	[self setNeedsDisplay: YES];
}

- (void) setRightCells: (NSArray*) newRightCells {
	[rightCells release];
	rightCells = [[NSMutableArray alloc] initWithArray: newRightCells];
	
	[rightLayout release]; rightLayout = nil;
	cellsNeedLayout = YES;
	
	[self setNeedsDisplay: YES];
}

- (void) addCells: (NSMutableArray*) cells
		 toLayout: (NSMutableArray*) layout {
	NSEnumerator* cellEnum = [cells objectEnumerator];
	NSCell* cell;
	
	float position = 0;
	while (cell = [cellEnum nextObject]) {
		IFPageCellLayout* cellLayout = [[IFPageCellLayout alloc] init];
		
		cellLayout->position = position;
		cellLayout->minWidth = [cell cellSize].width;
		cellLayout->hidden = NO;
		
		if (position == 0 && [cell image]) {
			// Prevent images from looking a bit lopsided when right on the edge
			cellLayout->position -= 2;
			position -= 2;
		}

		cellLayout->width = cellLayout->minWidth;

		[layout addObject: cellLayout];
		[cellLayout release];
		position += cellLayout->width;
	}
}

- (void) layoutCells {
	if (!cellsNeedLayout) return;
	
	[leftLayout release]; leftLayout = nil;
	[rightLayout release]; rightLayout = nil;
	
	leftLayout = [[NSMutableArray alloc] init];
	rightLayout = [[NSMutableArray alloc] init];
	
	// First pass: add all cells to the left and right regardless of how wide they are
	// TODO: preserve cell images if at all possible
	[self addCells: leftCells
		  toLayout: leftLayout];
	[self addCells: rightCells
		  toLayout: rightLayout];
	
	// Second pass: reduce the width of any cell that can be shrunk
	//
	// TODO: But less important than:
	
	// Third pass: remove cells from the right, then from the left when there is
	// still not enough space
	//
	// TODO
}

- (void) setBounds: (NSRect) bounds {
	cellsNeedLayout = YES;
	[super setBounds: bounds];
}

// = Cell housekeeping =

- (int) indexOfCellAtPoint: (NSPoint) point {
	// Returns 0 if no cell, a negative number for a right-hand cell or a positive number for a
	// left-hand cell

	// Update the cell layout
	if (cellsNeedLayout) [self layoutCells];

	// Work out the bounds for the cells
	NSRect bounds = [self bounds];
	
	bounds.origin.x += cellMargin;
	bounds.size.width -= cellMargin*2 + tabMargin + rightMargin;
	
	// Not this cell if the rectangle is outside the bounds of this control
	if (point.y < NSMinY(bounds) || point.y > NSMaxY(bounds)) {
		return 0;
	}
	
	if (point.x < NSMinX(bounds)-4 || point.y > NSMaxX(bounds)+4) {
		return 0;
	}
	
	point.x -= NSMinX(bounds);
	
	// Search the left-hand cells
	NSEnumerator* cellEnum;
	NSEnumerator* layoutEnum;
	int index;
	NSCell* cell;
	IFPageCellLayout* layout;
	
	cellEnum = [leftCells objectEnumerator];
	layoutEnum = [leftLayout objectEnumerator];
	
	index = -1;
	while ((cell = [cellEnum nextObject]) && (layout = [layoutEnum nextObject])) {
		// Get the index for the cell we're about to process
		index++;
		
		// Ignore hidden cells
		if (layout->hidden) continue;
		
		// Test for a hit on this cell
		if ((index == 0 || point.x >= layout->position) && layout->position + layout->width >= point.x) {
			return index+1;
		}
	}
	
	// Search the right-hand cells
	cellEnum = [rightCells objectEnumerator];
	layoutEnum = [rightLayout objectEnumerator];
	
	index = -1;
	while ((cell = [cellEnum nextObject]) && (layout = [layoutEnum nextObject])) {
		// Get the index for the cell we're about to process
		index++;
		
		// Ignore hidden cells
		if (layout->hidden) continue;
		
		// Test for a hit on this cell
		if (point.x >= bounds.size.width - layout->position - layout->width 
			&& (index == 0 || bounds.size.width - layout->position >= point.x)) {
			return -(index+1);
		}
	}
	
	return 0;
}

- (NSRect) boundsForCellAtIndex: (int) index
					  isOnRight: (BOOL) isRight {
	// Update the cell layout
	if (cellsNeedLayout) [self layoutCells];
	NSRect bounds = [self bounds];
	
	bounds.origin.x += cellMargin;
	bounds.size.width -= cellMargin*2 + tabMargin + rightMargin;

	IFPageCellLayout* layout = [isRight?rightLayout:leftLayout objectAtIndex: index];	
	
	NSRect cellFrame = NSMakeRect(0,0, layout->width, bounds.size.height);
	if (isRight) {
		cellFrame.origin.x = bounds.size.width - layout->position - layout->width;
	} else {
		cellFrame.origin.x = layout->position;
	}
	cellFrame.origin.x += bounds.origin.x;
	
	return cellFrame;
}

- (void) updateCell: (NSCell*) aCell {
	// Update the cell layout
	if (cellsNeedLayout) [self layoutCells];
	
	int cellIndex;
	NSMutableArray* cells = leftCells;
	NSMutableArray* layout = leftLayout;
	BOOL isRight = NO;
	
	// Find the cell in the left or right-hand collections
	cellIndex = [leftCells indexOfObjectIdenticalTo: aCell];
	if (cellIndex == NSNotFound) {
		cells = rightCells;
		layout = rightLayout;
		isRight = YES;
		cellIndex  = [rightCells indexOfObjectIdenticalTo: aCell];
	}
	
	// Do nothing if this cell is not part of this control
	if (cellIndex == NSNotFound) return;
	
	// Mark this cell as needing an update
	IFPageCellLayout* cellLayout = [layout objectAtIndex: cellIndex];
	[cellLayout->cellImage release];
	cellLayout->cellImage = nil;
	
	// Refresh this cell
	NSRect bounds = [self boundsForCellAtIndex: cellIndex
									 isOnRight: isRight];
	
	if (cellIndex == 0) {
		// If on the left or right, then we also need to update the end caps
		if (isRight) {
			bounds.size.width = NSMaxX([self bounds])-bounds.origin.x;
		} else {
			NSRect viewBounds = [self bounds];
			bounds.size.width = NSMaxX(bounds)-NSMinX(viewBounds);
			bounds.origin.x = NSMinX(viewBounds);
		}
	}
	
	[self setNeedsDisplayInRect: bounds];
}

- (void)updateCellInside:(NSCell *)aCell {
	[self updateCell: aCell];
}

// = Mouse events =

- (void) mouseDown: (NSEvent*) event {
	// Clear any tracking cell that might exist
	[trackingCell release]; trackingCell = nil;
	
	// Find which cell was clicked on
	int index = [self indexOfCellAtPoint: [self convertPoint: [event locationInWindow]
													fromView: nil]];
	BOOL isOnRight;
	if (index > 0) {
		// Left-hand cell was clicked
		isOnRight = NO;
		index--;
		
		trackingCell = [[leftCells objectAtIndex: index] retain];
	} else if (index < 0) {
		// Right-hand cell was clicked
		isOnRight = YES;
		index = (-index)-1;
		
		trackingCell = [[rightCells objectAtIndex: index] retain];
	} else {
		// No cell was clicked
		return;
	}
	
	trackingCellFrame = [self boundsForCellAtIndex: index
										 isOnRight: isOnRight];
	
	// Track the mouse
	BOOL trackResult = NO;
	NSEvent* trackingEvent = event;
	
	while (!trackResult) {
		if (![trackingCell isEnabled]) return;
		
		trackResult = [trackingCell trackMouse: trackingEvent
										inRect: trackingCellFrame
										ofView: self
								  untilMouseUp: NO];
		
		if (!trackResult) {
			// If the mouse is still down, continue tracking it in case it re-enters
			// the control
			while (trackingEvent = [NSApp nextEventMatchingMask: NSLeftMouseDraggedMask|NSLeftMouseUpMask
													  untilDate: [NSDate distantFuture]
														 inMode: NSEventTrackingRunLoopMode
														dequeue: YES]) {
				if ([trackingEvent type] == NSLeftMouseUp) {
					// All finished
					return;
				} else if ([trackingEvent type] == NSLeftMouseDragged) {
					// Restart tracking if the mouse has re-entered the cell
					NSPoint location = [self convertPoint: [trackingEvent locationInWindow]
												 fromView: nil];
					if (NSPointInRect(location, trackingCellFrame)) {
						break;
					}
				}
			}
		}
	}
}

@end
