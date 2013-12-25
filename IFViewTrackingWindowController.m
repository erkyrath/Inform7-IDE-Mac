//
//  IFViewTrackingWindowController.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 01/02/2009.
//  Copyright 2009 Andrew Hunter. All rights reserved.
//

#import "IFViewTrackingWindowController.h"

@interface IFViewTrackingWindowController(PrivateMethods)

- (void) repositionWindow;								// Forces this object to reposition its window

@end

@implementation IFViewTrackingWindowController

// = Initialisation =

- (id) initWithView: (NSView*)		newTargetView 
		   inWindow: (NSWindow*)	newTargetWindow {
	// Create the window
	NSWindow* window = [[[NSWindow alloc] initWithContentRect: NSMakeRect(0,0,100,100) 
													styleMask: NSBorderlessWindowMask
													  backing: NSBackingStoreBuffered
														defer: YES] autorelease];
	
	// Initialise this object
	self = [super initWithWindow: window];
	
	if (self) {
		targetView		= [newTargetView	retain];
		targetWindow	= [newTargetWindow	retain];
		
		// The target view must exist
		if (!targetView) {
			[self autorelease];
			return nil;
		}
		
		// The target window should be configured to be transparent
		[window setBackgroundColor: [NSColor clearColor]];
		[window setOpaque: NO];
		[window setHasShadow: NO];
		
		// The initial content view is whatever the window is currently using
		contentView = [[window contentView] retain];
		
		// Register for notifications on the view, in particular frame changed events
		[targetView setPostsFrameChangedNotifications: YES];
		[[NSNotificationCenter defaultCenter] addObserver: self	selector: @selector(targetViewFrameChanged:) name: NSViewFrameDidChangeNotification object: targetView];
		
		// Ideally we'd also track the view when it moves between windows, but OS X provides no easy way to do so, so we only monitor the window that it is in now
		if (!targetWindow) {
			[self autorelease];
			return nil;
		}
		
		// We need to know when the window is being closed. We'd like to deal with open events as well, but we can't, so the owner of this object will need to display the window manually
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(targetWindowDidClose:) name: NSWindowWillCloseNotification object: targetWindow];
		
		// Position the window so that it's ready to be opened
		[self repositionWindow];
	}
	
	return self;
}
		  
- (void) dealloc {
	// Our window is no longer a child window of the window belonging to the target view
	[targetWindow removeChildWindow: [self window]];
			
	// Done with notifications
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	// Finished with the views
	[contentView release];
	[targetView release];
	[targetWindow release];
	
	[super dealloc];
}

// = Showing/hiding the window =

- (void) queueShowHide {
	// If we're not waiting...
	if (!waitingToShowOrHide) {
		// Queue up a show/hide event to run once all the current events have finished executing (prevents flicker)
		[[NSRunLoop currentRunLoop] performSelector: @selector(showOrHide) target: self argument: nil order: 32 modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
		waitingToShowOrHide = YES;
	}
}

- (void) showOrHide {
	if (hideCount > showCount) {
		
		// This window can't be a child window when we order it out or both will get hidden
		if ([targetWindow childWindows] && [[targetWindow childWindows] indexOfObjectIdenticalTo: [self window]] != NSNotFound) {
			[targetWindow removeChildWindow: [self window]];
		}
		
		// Close the window
		[[self window] orderOut: self];

	} else if (showCount > hideCount) {
	
		// If this window is not already a child window of the target window then make it so
		if ([[targetWindow childWindows] indexOfObjectIdenticalTo: [self window]] == NSNotFound || ![targetWindow childWindows]) {
			[targetWindow addChildWindow: [self window]
								 ordered: NSWindowAbove];
			[self repositionWindow];
		}
		
		// Finish showing the window
		[super showWindow: self];

	}
	
	// No longer waiting for this event
	hideCount = showCount = 0;
	waitingToShowOrHide = NO;
}

- (IBAction) hideWindow: (id) sender {
	hideCount++;
	[self queueShowHide];
}

- (IBAction) showWindow: (id) sender {
	showCount++;
	[self queueShowHide];
}

// = View notifications =

- (void) targetViewFrameChanged: (NSNotification*) not {
	// Reposition the window appropriately
	[self repositionWindow];
}

// = Window notifications =

- (void) targetWindowDidClose: (NSNotification*) not {
	// Our window closes along with its parent
	[[self window] orderOut: self];
}

// = Updating the contents =

- (NSView*) contentView {
	return contentView;
}

- (void) setContentView: (NSView*) newContentView {
	[contentView autorelease];
	contentView = [newContentView retain];
	[[self window] setContentView: newContentView];
}

// = Positioning the window =

- (void) repositionWindow {
	// Get the frame of the view, and translate it so that it's relative to its window
	NSRect viewFrame = [targetView convertRect: [targetView bounds] toView: nil];
	
	// Convert this so that it's in screen coordinates
	NSRect windowFrame	= [targetWindow contentRectForFrameRect: [targetWindow frame]];
	viewFrame.origin.x	+= NSMinX(windowFrame);
	viewFrame.origin.y	+= NSMinY(windowFrame);
	
	// Position our window
	[[self window] setFrame: viewFrame
					display: YES];
}

@end
