//
//  IFContextMatchWindow.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 03/07/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFContextMatchWindow.h"
#import "IFContextTopDecalView.h"
#import "IFViewAnimator.h"


@implementation IFContextMatchWindow

// = Initialisation =

- (id) init {
	NSImage* topDecal = [NSImage imageNamed: @"InfoWindowTop"];
	
	// Create the window that we're going to popup
	NSPanel* contextWindow = [[NSPanel alloc] initWithContentRect: NSMakeRect(100,100,[topDecal size].width, 320)
														  styleMask: NSBorderlessWindowMask
															backing: NSBackingStoreBuffered 
															  defer: NO];
	[contextWindow setLevel: NSTornOffMenuWindowLevel];
	[contextWindow setOpaque: NO];
	[contextWindow setAlphaValue: 0.95];
	[contextWindow setHidesOnDeactivate: YES];
	
	self = [super initWithWindow: [contextWindow autorelease]];
	
	if (self) {
		// Add the views for the window
		
		// The upper decal
		NSSize topSize = [topDecal size];
		topView = [[IFContextTopDecalView alloc] initWithFrame: NSMakeRect(0,0, topSize.width, topSize.height)];
		[contextWindow setContentView: topView];
		
		// The text view
		NSRect contentRect = [[contextWindow contentView] frame];
		textView = [[NSTextView alloc] initWithFrame: NSMakeRect(NSMinX(contentRect), NSMinY(contentRect), contentRect.size.width, contentRect.size.height-topSize.height)];
		
		[textView setBackgroundColor: [NSColor windowBackgroundColor]];
		[textView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
		[[textView textContainer] setContainerSize: NSMakeSize([[textView textContainer] containerSize].width, 1e8)];
		
		[textView setEditable: NO];
		[textView setSelectable: YES];
		[textView setTextContainerInset: NSMakeSize(8, 8)];
		[[[textView textStorage] mutableString] appendString: @"Hello, world"];
		
		[[contextWindow contentView] addSubview: textView];
		
		[textView setDelegate: self];
		
		// Ensure the window has a shadow
		[contextWindow setHasShadow: YES];
	}
	
	return self;
}

- (void) dealloc {
	// Clear up the various views
	[topView release];
	[textView release];
	
	// Clear up the data
	[currentElement release];
	[elements release];
	
	// Clear up the fading timer
	[fadeTimer invalidate];
	[fadeTimer release];
	
	[super dealloc];
}

// = Controlling this window =

- (void) setAttributedString: (NSAttributedString*) newContents
					 animate: (BOOL) shouldAnimate
					  shrink: (BOOL) canShrink {
	// Create the view animator if necessary
	IFViewAnimator* viewAnimator = nil;
	if (shouldAnimate) {
		viewAnimator = [[[IFViewAnimator alloc] init] autorelease];
		[viewAnimator prepareToAnimateView: textView];
	}
	
	// Turn off background layout
	[[textView layoutManager] setBackgroundLayoutEnabled: NO];
	
	// Update the text
	[[textView textStorage] setAttributedString: newContents];
	
	// Work out the new height for the text view
	float textViewHeight = [textView frame].size.height;
	float newTextViewHeight = textViewHeight;
	NSLayoutManager* layout = [textView layoutManager];
	
	NSRange endGlyph = [textView selectionRangeForProposedRange: NSMakeRange([newContents length]-1, 1) 
													granularity: NSSelectByCharacter];
	if (endGlyph.location > 0xf0000000) {
		// Can't work out a height from the specified string
	} else {
		// Work out where the final glyph was placed
		NSRect glyphRect = [layout boundingRectForGlyphRange: endGlyph
											 inTextContainer: [textView textContainer]];
		if (glyphRect.origin.y != 0 || glyphRect.size.height != 0) {
			// Store the height the text view should be
			newTextViewHeight = NSMaxY(glyphRect) + 16;
		}
	}
	
	// Size the window if necessary
	newTextViewHeight = floorf(newTextViewHeight);
	if (newTextViewHeight > textViewHeight || canShrink) {
		// Work out the change in height
		float changeInHeight = newTextViewHeight - textViewHeight;
		
		// Work out the new window frame
		NSRect windowFrame = [[self window] frame];
		windowFrame.size.height += changeInHeight;
		if (!flipped) {
			windowFrame.origin.y -= changeInHeight;
		}
		
		// Move the window
		[[self window] setFrame: windowFrame
						display: YES];
	}
	
	// Perform any animation requested
	if (shouldAnimate) {
		[viewAnimator animateTo: textView
						  style: IFAnimateCrossFade];
	}
}

- (void) setFlipped: (BOOL) newFlipped {
	if (newFlipped == flipped) return;
	
	// Remember the new state
	flipped = newFlipped;
	
	// Flip the top view
	[topView setFlipped: flipped];
	
	// Rearrange the views
	NSImage* topDecal = [NSImage imageNamed: @"InfoWindowTop"];
	NSRect contentRect = [[[self window] contentView] frame];
	NSSize topSize = [topDecal size];
	
	if (flipped) {
		// Move the text to the top
		[textView setFrame: NSMakeRect(NSMinX(contentRect), NSMinY(contentRect)+topSize.height, contentRect.size.width, contentRect.size.height-topSize.height)];
	} else {
		// Move the text to the bottom
		[textView setFrame: NSMakeRect(NSMinX(contentRect), NSMinY(contentRect), contentRect.size.width, contentRect.size.height-topSize.height)];
	}

	[textView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
	
	[[self window] invalidateShadow];
}

static NSAttributedString* TitleString(NSString* title) {
	return [[[NSAttributedString alloc] initWithString: title
											attributes: [NSDictionary dictionaryWithObjectsAndKeys:
												[NSFont boldSystemFontOfSize: 12.0], NSFontAttributeName,
												nil]] 
			autorelease];
}

static NSAttributedString* DescriptionString(NSString* title) {
	return [[[NSAttributedString alloc] initWithString: title
											attributes: [NSDictionary dictionaryWithObjectsAndKeys:
												[NSFont systemFontOfSize: 11.0], NSFontAttributeName,
												nil]] 
			autorelease];
}

static NSAttributedString* LinkString(NSString* title, id link) {
	return [[[NSAttributedString alloc] initWithString: title
											attributes: [NSDictionary dictionaryWithObjectsAndKeys:
												[NSFont boldSystemFontOfSize: 11.0], NSFontAttributeName,
												link, NSLinkAttributeName,
												[NSColor blueColor], NSForegroundColorAttributeName,
												[NSNumber numberWithInt: NSUnderlineStyleSingle], NSUnderlineStyleAttributeName,
												nil]] 
			autorelease];
}

- (void) displayElementChoices {
	// Begin building the text to display
	NSMutableAttributedString* result = [[NSMutableAttributedString alloc] init];
	[result appendAttributedString: TitleString([[NSBundle mainBundle] localizedStringForKey: @"Available choices"
	 																				   value: @"Available choices"
																					   table: nil])];
	[result appendAttributedString: DescriptionString(@"\n")];

	// Iterate through the list of element
	NSEnumerator* elementsEnum = [elements objectEnumerator];
	IFMatcherElement* element = nil;
	while (element = [elementsEnum nextObject]) {
		[result appendAttributedString: DescriptionString(@"\n")];
		[result appendAttributedString: LinkString([element title], element)];		
	}
	
	// Set the text that we're displaying
	[self setAttributedString: result
					  animate: shown
					   shrink: !shown];
	[result release];
}

- (void) setMatcherElement: (IFMatcherElement*) elem {
	// Build the text to display
	NSMutableAttributedString* result = [[NSMutableAttributedString alloc] init];
	[result appendAttributedString: TitleString([elem title])];
	[result appendAttributedString: DescriptionString(@"\n")];
	[result appendAttributedString: DescriptionString([elem elementDescription])];
	
	if ([elem elementLink] != nil && [[elem elementLink] length] > 0) {
		[result appendAttributedString: DescriptionString(@"\n\n")];		
		[result appendAttributedString: LinkString([[NSBundle mainBundle] localizedStringForKey: @"Read documentation"
		 																				  value: @"Read documentation"
																						  table: nil], [elem elementLink])];
	}

	// Set the text that we're displaying
	[self setAttributedString: result
					  animate: shown
					   shrink: !shown];
	[result release];
}

- (BOOL) setElements: (NSArray*) newElements {
	// Clear the current element
	[currentElement release];
	currentElement = nil;
	
	// Refresh the elements array
	[elements release];
	elements = [[NSMutableArray alloc] init];
	
	// Go through the newElements array and identify the MatcherElements (distinguish them from the structures)
	BOOL foundElements = NO;
	IFMatcherElement* defaultElement = nil;
	
	NSEnumerator* newElementsEnum = [newElements objectEnumerator];
	IFMatcherStructure* element = nil;
	while (element = [newElementsEnum nextObject]) {
		if ([element isKindOfClass: [IFMatcherElement class]]) {
			// If this is the first element, set it as the default
			if (!foundElements) {
				defaultElement = (IFMatcherElement*)element;
			} else {
				defaultElement = nil;
			}
			
			// Add this element to the array of choices
			foundElements = YES;
			[elements addObject: element];
		}
	}
	
	if (defaultElement) {
		// Display the default element
		[self setMatcherElement: defaultElement];
	} else {
		// Display the list of choices
		[self displayElementChoices];
	}
	
	// Return whether or not there's anything to display
	return foundElements;
}

- (void) popupAtLocation: (NSPoint) pointOnWindow
			    onWindow: (NSWindow*) window {
	[self popupAtLocation: [window convertBaseToScreen: pointOnWindow]
				 onScreen: [window screen]];
}

- (void) popupAtLocation: (NSPoint) pointOnScreen 
    			onScreen: (NSScreen*) screen {
	// Cancel any running animation
	if (fadeTimer) {
		[fadeTimer invalidate];
		[fadeTimer release];
		fadeTimer = nil;
	}
	
	// Flip if necessary
	NSRect screenFrame = [screen visibleFrame];
	float midYPoint = NSMinY(screenFrame) + screenFrame.size.height/2.0;
	[self setFlipped: pointOnScreen.y < midYPoint];
	
	// Move the point left or right to force it to be on the screen
	NSRect windowFrame = [[self window] frame];
	float halfWidth = windowFrame.size.width/2.0;
	
	if (pointOnScreen.x - halfWidth < NSMinX(screenFrame)) pointOnScreen.x = NSMinX(screenFrame) + halfWidth;
	if (pointOnScreen.x + halfWidth > NSMaxX(screenFrame)) pointOnScreen.x = NSMaxX(screenFrame) - halfWidth;
	
	// Work out the new frame for the window
	NSRect newWindowFrame = windowFrame;
	
	newWindowFrame.origin.x = pointOnScreen.x - halfWidth;
	if (flipped) {
		newWindowFrame.origin.y = pointOnScreen.y;	
	} else {
		newWindowFrame.origin.y = pointOnScreen.y - windowFrame.size.height;		
	}
	
	// Move the window
	newWindowFrame = NSIntegralRect(newWindowFrame);
	newWindowFrame.size.width = windowFrame.size.width;
	[[self window] setFrame: newWindowFrame
					display: YES];
	
	// Display the window (TODO: make the window fade in)
	[self showWindow: self];
	[self retain];
	shown = YES;
	
	// Run the event loop until we get an event (mouse, key?) for a different window or the menu bar
	// This is not true modal behaviour: however, we're not acting like a modal dialog and want to do some
	// weird stuff with the events.
	// TODO: annoyingly, we don't seem to be able to intercept main menu open events, which mucks things up a bit
	NSWindow* popupWindow = [self window];
	NSModalSession ses = [NSApp beginModalSessionForWindow: popupWindow];
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSEvent* resend = nil;
	NSEvent* ev = nil;
	
	while (shown) {
		[pool release];
		pool = [[NSAutoreleasePool alloc] init];
		
		ev = 
			[NSApp nextEventMatchingMask: NSAnyEventMask
							   untilDate: [NSDate distantFuture]
								  inMode: NSEventTrackingRunLoopMode
								 dequeue: YES];
		
		if (([ev type] == NSKeyDown ||
					[ev type] == NSKeyUp)) {
			// Key presses pass through and close the window
			resend = ev;
			break;
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
		} else if ([ev type] == NSSystemDefined && [ev subtype] == 7 && [ev data1] == 1 && [ev data2] == 1) {
			// System event indicating a mouse click
			if (!NSPointInRect([ev locationInWindow], [[self window] frame])) {
				break;
			}
		}
		
		// Pass the event through
		if (ev != nil) [NSApp sendEvent: ev];
	}
	[NSApp endModalSession: ses];
	
	if (resend) {
		[NSApp sendEvent: resend];
	}
	
	[pool release];
	
	// Fade out this window
	[self fadeOutWindow];
	[self release];
}

- (void) fadeOutWindow {
	// Cancel any running animation
	if (fadeTimer) {
		[fadeTimer invalidate];
		[fadeTimer release];
		fadeTimer = nil;
	}
	
	// Mark this window as not being shown
	shown = NO;
	
	// Hide the window (TODO: make the window fade out slowly)
	[[self window] orderOut: self];
}

// = Text view delegate methods =

- (BOOL) textView: (NSTextView *)aTextView 
	clickedOnLink: (id)link 
		  atIndex: (unsigned)charIndex {
	if ([link isKindOfClass: [IFMatcherElement class]]) {
		// If the link is to a matcher element, then display that element
		[self setMatcherElement: link];
		return YES;
	} else if ([link isKindOfClass: [NSString class]]) {
		// If the link is a string, then make a request to go to the documentation for that element
	} else {
		// All other links return to the choice list
		[self displayElementChoices];
		return YES;
	}
	
	return NO;
}

@end
