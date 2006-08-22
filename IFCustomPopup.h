//
//  IFCustomPopup.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 22/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


//
// Customised pop-up button that can work with an arbitrary view instead of only with a menu.
//
@interface IFCustomPopup : NSPopUpButton {
	// User-set parameters
	NSView* popupView;
	
	// Managing the pop-up
	NSPanel* backgroundWindow;						// Window used to detect clicks outside the popup
	NSPanel* popupWindow;							// Window that contains the pop-up view
}

// General methods
+ (void) closeAllPopups;							// Closes all open pop-up windows

// Setting up
- (void) setPopupView: (NSView*) view;				// Sets the view to use for the popup

// Getting down
- (IBAction) showPopup: (id) sender;				// Cause the pop-up window to be displayed
- (IBAction) closePopup: (id) sender;				// Responder method that can be used to close this popup and generate an action (point view controls actions to this method in the first responder)

@end
