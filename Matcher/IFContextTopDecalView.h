//
//  IFContextTopDecalView.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 03/07/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IFContextTopDecalView : NSView {
	// View state
	BOOL flipped;													// YES if the image should be drawn upside-down
}

- (void) setFlipped: (BOOL) flipped;								// Set to draw the decal image upside down

@end
