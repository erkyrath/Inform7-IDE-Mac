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
// Note that this won't work if made part of a clipping view
//
@interface IFPageBarView : NSView {
	NSWindow* overlayWindow;						// Window used to draw the actual toolbar
	IFPageBarOverlay* overlay;						// The overlay itself
	
	NSRect screenRect;								// Where the overlay window should be positioned
}

@end
