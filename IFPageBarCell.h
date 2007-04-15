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
	BOOL isSelected;									// True if this cell is currently selected by a click
}

// Initialisation

// Drawing the cell

@end

//
// Optional methods that may be implemented by a cell in a page bar
//
@interface NSCell(IFPageBarCell)

- (void) setIsRight: (BOOL) isRight;					// Whether or not this cell is to be drawn on the right-hand side of the bar

@end
