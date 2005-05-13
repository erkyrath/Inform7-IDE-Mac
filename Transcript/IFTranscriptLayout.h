//
//  IFTranscriptLayout.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 13/05/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <ZoomView/ZoomSkeinItem.h>
#import <ZoomView/ZoomSkein.h>

#import "IFTranscriptItem.h"

//
// Class that deals with laying out a transcript
//
// This functionality is seperated from the IFTranscriptView class so that we don't wind up performing the layout
// more than once.
//
@interface IFTranscriptLayout : NSObject {
	// Skein and the target item
	ZoomSkein* skein;								// The skein that this transcript refers to
	ZoomSkeinItem* targetItem;						// The 'target' item that we're transcripting to
	
	// The transcript items themselves
	NSMutableArray* transcriptItems;				// Transcript items in order
	int calculationPoint;							// How far we've got in the actual layout
}

// Setting the skein and the item we're transcripting to
- (void)       setSkein: (ZoomSkein*) skein;
- (ZoomSkein*) skein;

- (void) transcriptToPoint: (ZoomSkeinItem*) point;

@end
