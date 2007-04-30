//
//  IFPageBarCell.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 06/04/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


//
// A cell that can be placed on the left or right of the IFPageBarView.
//
// These cells can contain an image or text. Additionally, they can contain a drop-down menu or a pop-up 
// window. The assumption is that these will be rendered as part of the page bar view.
//
@interface IFPageBarCell : NSActionCell {
	BOOL isRight;										// True if this cell is to be drawn on the right-hand side
	BOOL isHighlighted;									// True if this cell is currently highlighted by a click
	NSRect trackingFrame;								// The frame of this cell reported when the last mouse tracking started

	// Pop-up
	NSMenu* menu;										// The menu for this cell
	
	// Radio
	int radioGroup;										// The radio group identifier for this cell
	
	// View
	NSView* view;										// The view for this cell
}

// Initialisation

// Drawing the cell

// Acting as a pop-up
- (BOOL) isPopup;										// YES if this is a pop-up cell of some kind
- (void) showPopupAtPoint: (NSPoint) pointInWindow;		// Request to run the pop-up
- (void) setMenu: (NSMenu*) menu;						// The pop-up menu

// Acting as part of a radio group
- (void) setRadioGroup: (int) group;					// Sets this cell up as an on/off cell as part of a radio group
- (int) radioGroup;										// Retrieves the radio group for this cell

// Acting as a tab (you'll need to implement another control to make this work)
- (void) setView: (NSView*) view;						// Set the view to display for this item
- (NSView*) view;										// The view to display for this item

@end

//
// Optional methods that may be implemented by a cell in a page bar
//
@interface NSCell(IFPageBarCell)

- (void) setIsRight: (BOOL) isRight;					// Whether or not this cell is to be drawn on the right-hand side of the bar

@end
