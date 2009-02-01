//
//  IFViewTrackingWindowController.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 01/02/2009.
//  Copyright 2009 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


///
/// Window controller that creates a window that tracks the specified view
///
@interface IFViewTrackingWindowController : NSWindowController {
	NSView*				targetView;							// The view that is to be tracked
	IBOutlet NSView*	contentView;						// The view that represents the contents of the window
	NSWindow*			targetWindow;						// The target window
	
	int					showCount;							// Number of times 'show window' has been called
	int					hideCount;							// Number of times 'hide window' has been called
	BOOL				waitingToShowOrHide;				// Whether or not a show/hide event is waiting
}

- (id) initWithView: (NSView*) targetView
		   inWindow: (NSWindow*) targetWindow;

- (NSView*)		contentView;								// The content view that is displayed in this tracker
- (void)		setContentView: (NSView*) contentView;

- (IBAction)	hideWindow: (id) sender;					// Causes this tracking window to be hidden

@end
