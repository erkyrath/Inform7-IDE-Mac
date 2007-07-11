//
//  IFContextMatchWindow.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 03/07/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFContextTopDecalView.h"
#import "IFMatcherElement.h"

///
/// Popup window representing information on the item the user has indicated in the main window
///
@interface IFContextMatchWindow : NSWindowController {
	// The views within this window
	IFContextTopDecalView* 	topView;								// The decal at the top (or bottom) of this window
	NSTextView*				textView;								// The text view containing the information being displayed by this window
	
	// What is displayed
	NSMutableArray* 		elements;								// The elements that we should show in this window
	IFMatcherElement* 		currentElement;							// The matcher element the user has chosen to view
	
	// Animations
	NSTimer* 				fadeTimer;								// The timer used for fading this window up or down after it has been positioned
	float					initialAlpha;							// The initial alpha value for this window
	NSDate*					fadeStart;								// When the current fade operation started
	
	// Window state                                                 
	BOOL 					shown;									// YES if this window has been shown and has retained itself
	BOOL					flipped;								// YES if this window is flipped
}

// Controlling this window
- (BOOL) setElements: (NSArray*) elements;							// Sets the matcher elements to display in the window, returns YES if there's something to display
- (void) popupAtLocation: (NSPoint) pointOnScreen					// Shows this window at the specified location (and retains it)
			    onScreen: (NSScreen*) screen; 
- (void) popupAtLocation: (NSPoint) pointOnWindow					// Shows this window at the specified location (and retains it)
			    onWindow: (NSWindow*) window; 
- (void) fadeOutWindow;												// Fades out this window (and releases it)

@end
