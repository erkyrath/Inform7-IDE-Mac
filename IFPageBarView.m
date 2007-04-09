//
//  IFPageBarView.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 01/04/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFPageBarView.h"

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
static const float rightMargin = 9.0;			// Margin to put on the right (to account for scrollbars, tabs, etc)
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
	
	if (!image) {
		image = [[NSImage imageNamed: @"BarHighlighted"] retain];
	}
	
	return image;
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
		
		leftCells = [[NSMutableArray alloc] initWithObjects:
			[[[NSCell alloc] initTextCell: @"Test"] autorelease],
			nil];
		rightCells = [[NSMutableArray alloc] initWithObjects:
			[[[NSCell alloc] initTextCell: @"'allo"] autorelease],
			nil];
		
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
	
	if ([cell controlView] != self) {
		[cell setControlView: self];
		[cell setFont: [NSFont systemFontOfSize: 11]];
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
		
		[layout->cellImage drawInRect: cellFrame
							 fromRect: cellSource
							operation: NSCompositeSourceOver
							 fraction: 1.0];
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
	[background drawInRect: bounds
				  fromRect: NSMakeRect(0,0, backSize.width, backSize.height)
				 operation: NSCompositeSourceOver
				  fraction: 1.0];
	
	// Draw the standard background
	background = [IFPageBarView normalImage];
	backSize = [background size];
	
	[IFPageBarView drawOverlay: background
						inRect: backgroundBounds
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
}

- (void) setRightCells: (NSArray*) newRightCells {
	[rightCells release];
	rightCells = [[NSMutableArray alloc] initWithArray: newRightCells];
	
	[rightLayout release]; rightLayout = nil;
	cellsNeedLayout = YES;
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
		cellLayout->width = cellLayout->minWidth;
		cellLayout->hidden = NO;
		
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

@end
