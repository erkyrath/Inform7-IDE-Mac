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
	IFTranscriptLayout* layout;
}

// Retrieving the layout
- (IFTranscriptLayout*) layout;

// Displaying specific items
- (void) scrollToItem: (ZoomSkeinItem*) item;

@end
