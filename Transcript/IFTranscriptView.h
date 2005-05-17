//
//  IFTranscriptView.h
//  Inform
//
//  Created by Andrew Hunter on 12/09/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFTranscriptLayout.h"

//
// The transcript view
//
@interface IFTranscriptView : NSView {
	// Laying out the view
	IFTranscriptLayout* layout;					// The layout manager that we're using
	
	IFTranscriptItem* activeItem;				// The item that's drawn with the 'active' (yellow) border
	IFTranscriptItem* highlightedItem;			// The item that's drawn with the 'highlighted' (blue) border
}

// Retrieving the layout
- (IFTranscriptLayout*) layout;

// Displaying specific items
- (void) scrollToItem: (ZoomSkeinItem*) item;				// Scrolls a specific item to be visible
- (void) setHighlightedItem: (ZoomSkeinItem*) item;			// Sets a specific item to be the 'highlighted' item
- (void) setActiveItem: (ZoomSkeinItem*) item;				// Sets a specific item to be the 'active' item

@end
