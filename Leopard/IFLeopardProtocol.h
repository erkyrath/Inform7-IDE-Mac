/*
 *  IFLeopardProtocol.h
 *  Inform-xc2
 *
 *  Created by Andrew Hunter on 09/12/2007.
 *  Copyright 2007 Andrew Hunter. All rights reserved.
 *
 */

///
/// Extra functions available to the Inform UI under leopard
///
@protocol IFLeopardProtocol

// Text view magic

- (void) showFindIndicatorForRange: (NSRange) charRange					// Shows the find indicator for the specified range
						inTextView: (NSTextView*) textView;

// Animation

- (void) setFrame: (NSRect) newFrame									// Sets the frame of the specified window (with animation on leopard)
		 ofWindow: (NSWindow*) window;
- (void) setFrame: (NSRect) frame										// Sets the frame of the specified view to the specified size (with animation on leopard)
		   ofView: (NSView*) view;
- (void) addView: (NSView*) newView										// Adds the specified view to the given subview (with animation on leopard)
		  toView: (NSView*) superView;
- (void) removeView: (NSView*) view;									// Removes the specified view from its superview (with animation on leopard)

@end
