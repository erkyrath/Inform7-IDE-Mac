//
//  IFCustomPopup.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 22/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

// TODO: wheel scrolling still works while the popup is visible (it shouldn't)

#import "IFCustomPopup.h"

static IFCustomPopup* shownPopup = nil;

// = Custom view interfaces used by this class =

@interface IFPopupTransparentView : NSView {
}

- (IBAction) closePopup: (id) sender;

@end

@interface IFPopupContentView : NSView {
}

- (IBAction) closePopup: (id) sender;

@end

// = The main event =
@implementation IFCustomPopup

// = General methods =
+ (void) closeAllPopups {
	if (shownPopup != nil) {
		[shownPopup hidePopup];
	}
}

// = Initialisation =

- (void) dealloc {
	[IFCustomPopup closeAllPopups];
	
	[popupView release];
	[popupWindow release];
	
	[super dealloc];
}

// = Setting up =

- (void) setPopupView: (NSView*) view {
	[popupView release];
	popupView = [view retain];
}

- (void) setDelegate: (id) newDelegate {
	delegate = newDelegate;
}

// = Getting down =

- (void) hidePopup {
	[popupWindow orderOut: self];
	
	[[self cell] setHighlighted: NO];
	[self setNeedsDisplay: YES];
	
	if (shownPopup == self) {
		[shownPopup release];
		shownPopup = nil;
	}
}

- (IBAction) showPopup: (id) sender {
	// Close any open popups
	[[self class] closeAllPopups];
	
	[shownPopup release];
	shownPopup = [self retain];
	
	// Talk to the delegate
	if (delegate && [delegate respondsToSelector: @selector(customPopupOpening:)]) {
		[delegate customPopupOpening: self];
	}
	
	// Get the current screen
	NSScreen* currentScreen = [[self window] screen];
	NSRect screenFrame = [currentScreen frame];
	
	// Not a lot we can do if the control is not visible
	if (currentScreen == nil) return;
	
	// Create the windows if they do not already exist
	if (popupWindow == nil) {
		// Construct the windows
		popupWindow = [[NSPanel alloc] initWithContentRect: NSMakeRect(0,0, 100, 100)
												 styleMask: NSBorderlessWindowMask
												   backing: NSBackingStoreBuffered
													 defer: NO];
		[popupWindow setWorksWhenModal: YES];
		
		// Set up the popup window
		IFPopupContentView* contentView = [[IFPopupContentView alloc] initWithFrame: [[popupWindow contentView] frame]];
		[popupWindow setContentView: contentView];
		
		[popupWindow setLevel: NSPopUpMenuWindowLevel];
		[popupWindow setHasShadow: YES];
		[popupWindow setHidesOnDeactivate: YES];
		[popupWindow setAlphaValue: 0.95];
	}
	
	// Set up the content window view
	IFPopupContentView* contentView	 = [popupWindow contentView];
	
	[[[[contentView subviews] copy] autorelease] makeObjectsPerformSelector: @selector(removeFromSuperview)];
	
	NSSize windowSize = [contentView frame].size;
	if (popupView != nil) {
		// Set the content view
		[contentView addSubview: popupView];
		
		// Get the size we need to set the window to
		windowSize = [popupView frame].size;
		
		// Move the popup view so that it is displayed
		[popupView setFrameOrigin: [contentView bounds].origin];
	}
	
	// Set the cell state
	[[self cell] setHighlighted:YES];
	[self setNeedsDisplay: YES];
	
	// Get the control position
	NSRect controlFrame = [self convertRect: [self bounds]
									 toView: nil];
	NSPoint windowOrigin = [[self window] frame].origin;
	
	controlFrame.origin.x += windowOrigin.x;
	controlFrame.origin.y += windowOrigin.y;
	
	// Calculate the popup window position
	NSRect windowFrame;
	windowFrame.size = windowSize;
	
	windowFrame.origin.x = NSMinX(controlFrame) + (controlFrame.size.width-windowFrame.size.width)/2;
	windowFrame.origin.y = NSMinY(controlFrame)-windowFrame.size.height+1;
	
	// Move back onscreen (left/right)
	float offscreenRight = NSMaxX(windowFrame) - NSMaxX(screenFrame);
	float offscreenLeft = NSMinX(screenFrame) - NSMinX(windowFrame);
	
	if (offscreenRight > 0) windowFrame.origin.x -= offscreenRight;
	if (offscreenLeft > 0) windowFrame.origin.x += offscreenLeft;
	
	// Move back onscreen (bottom)
	float offscreenBottom = NSMinY(screenFrame) - NSMinY(windowFrame);
	if (offscreenBottom > 0) windowFrame.origin.y += offscreenBottom;
	
	// Position the window
	[popupWindow setFrame: windowFrame
				  display: NO];
	
	// Display the windows
	[popupWindow makeKeyAndOrderFront: self];
	
	unichar escape = 27;
	NSString* escapeString = [NSString stringWithCharacters: &escape
													 length: 1];
	
	// Run modally until it's time to close the window
	// This is not true modal behaviour: however, we're not acting like a modal dialog and want to do some
	// weird stuff with the events.
	while (shownPopup == self) {
		NSEvent* ev = 
			[NSApp nextEventMatchingMask: NSAnyEventMask
							   untilDate: [NSDate distantFuture]
								  inMode: NSEventTrackingRunLoopMode
								 dequeue: YES];
		
		// Background window events get discarded
		if (([ev type] == NSKeyDown ||
					[ev type] == NSKeyUp) &&
				   [[ev characters] isEqualToString: escapeString]) {
			// Escape pressed
			break;
		} else if (([ev type] == NSKeyDown ||
					[ev type] == NSKeyUp) &&
				   [ev window] != popupWindow) {
			// Redirect any key events to the popup window
			ev = [NSEvent keyEventWithType: [ev type]
								  location: [ev locationInWindow]
							 modifierFlags: [ev modifierFlags]
								 timestamp: [ev timestamp]
							  windowNumber: [popupWindow windowNumber]
								   context: [popupWindow graphicsContext]
								characters: [ev characters]
			   charactersIgnoringModifiers: [ev charactersIgnoringModifiers]
								 isARepeat: [ev isARepeat]
								   keyCode: [ev keyCode]];
		} else if (([ev type] == NSLeftMouseDown ||
					[ev type] == NSRightMouseDown ||
					[ev type] == NSOtherMouseDown ||
					[ev type] == NSScrollWheel) &&
				   [ev window] != popupWindow) {
			// Click outside of the window
			if ([ev type] != NSLeftMouseDown ||
				![NSApp isActive]) {
				[NSApp sendEvent: ev];
			}
			break;
		}
		
		// Pass the event through
		if (ev != nil) [NSApp sendEvent: ev];
	}
	
	// TODO: if the last event was a mouse down event, loop until we get the mouse up
	[self hidePopup];
}

- (IBAction) closePopup: (id) sender {
	[self hidePopup];
}

- (void) mouseDown: (NSEvent*) evt {
	[self showPopup: self];
}

- (void) mouseDragged: (NSEvent*) evt {
	// TODO: offer this event to objects in the popup view
}

- (void) mouseUp: (NSEvent*) evt {
	// TODO: only actually close the popup if the mouse up event was outside the popup view, otherwise forward the event on
	//[self hidePopup];
}

@end

// = Custom view implementations =

@implementation IFPopupTransparentView

- (IBAction) closePopup: (id) sender {
	[IFCustomPopup closeAllPopups];
	NSLog(@"Bing!");
}

- (BOOL) isOpaque {
	return NO;
}

- (NSView *)hitTest:(NSPoint)aPoint {
	NSLog(@"hitTest");
	return self;
}

@end

@implementation IFPopupContentView

- (IBAction) closePopup: (id) sender {
	[IFCustomPopup closeAllPopups];
}

@end
