//
//  IFPageBarView.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 01/04/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFPageBarOverlay.h"

//
// Class implementing the page bar view.
//
@interface IFPageBarView : NSControl {
	BOOL cellsNeedLayout;							// YES if we need to perform layout on the cells
	
	NSMutableArray* leftCells;						// The cells that appear on the left of this view
	NSMutableArray* rightCells;						// The cells that appear on the right of this view
	
	NSMutableArray* leftLayout;						// Left-hand cell layout
	NSMutableArray* rightLayout;					// Right-hand cell layout
}

// = Drawing =

+ (NSImage*) normalImage;							// The unselected background image

+ (void) drawOverlay: (NSImage*) overlay			// Draws (part of) the background image for this bar
			  inRect: (NSRect) rect
		 totalBounds: (NSRect) bounds
			fraction: (float) fraction;

// = Managing cells =

- (void) setLeftCells: (NSArray*) leftCells;		// Sets the set of cells displayed on the left
- (void) setRightCells: (NSArray*) rightCells;		// Sets the set of cells displayed on the right

- (void) layoutCells;								// Forces the cells to be measured and laid out appropriately for this control

@end
