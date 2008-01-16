//
//  IFHeaderView.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 02/01/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFHeaderView.h"


@implementation IFHeaderView

// = Initialisation =

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		displayDepth = 5;
		backgroundColour = [[NSColor whiteColor] copy];
    }
    return self;
}

- (void) dealloc {
	[rootHeader release];		rootHeader = nil;
	[backgroundColour release];	backgroundColour = nil;
	[message release];			message = nil;
	
	[super dealloc];
}

// = Information about this view =

- (IFHeaderNode*) rootHeaderNode {
	return rootHeaderNode;
}

// = Updating the view =

- (void) sizeView {
	// Resize the view
	NSRect rootFrame = [rootHeaderNode frame];
	rootFrame.size.width = [self frame].size.width;
	rootFrame.size.height += 5;
	
	if (message && [self enclosingScrollView]) {
		rootFrame.size = [[self enclosingScrollView] contentSize];
		[self setAutoresizingMask: [self autoresizingMask] | NSViewHeightSizable];
	} else {
		[self setAutoresizingMask: [self autoresizingMask] & ~NSViewHeightSizable];
	}
	
	[self setFrameSize: rootFrame.size];
}

- (void) updateFromRoot {
	// Replace the root header node
	[rootHeaderNode release]; rootHeaderNode = nil;
	rootHeaderNode = [[IFHeaderNode alloc] initWithHeader: rootHeader
												 position: NSMakePoint(0,0)
													depth: 0];
	[rootHeaderNode populateToDepth: displayDepth];
	
	// Add a message if necessary
	if ([[rootHeaderNode children] count] == 0) {
		if ([[rootHeader children] count] == 0) {
			[self setMessage: [[NSBundle mainBundle] localizedStringForKey: @"NoHeadingsSet"
																	 value: @""
																	 table: nil]];
		} else {
			[self setMessage: [[NSBundle mainBundle] localizedStringForKey: @"NoHeadingsVisible"
																	 value: @""
																	 table: nil]];
		}
	} else {
		message = nil;
	}
	
	// Redraw the display
	[self sizeView];
	[self setNeedsDisplay: YES];	
}

- (void) setMessage: (NSString*) newMessage {
	[message release];
	if ([newMessage length] == 0) newMessage = nil;
	message = [newMessage copy];
	
	[self sizeView];
	[self setNeedsDisplay: YES];
}

// = Settings for this view =

- (BOOL) isFlipped {
	return YES;
}

- (int) displayDepth {
	return displayDepth;
}

- (void) setDisplayDepth: (int) newDisplayDepth {
	// Set the display depth for this view
	displayDepth = newDisplayDepth;
	
	// Refresh the view
	[self updateFromRoot];
}


- (void) setDelegate: (id) newDelegate {
	delegate = newDelegate;
}

- (void) setBackgroundColour: (NSColor*) colour {
	[backgroundColour release];
	backgroundColour = [colour copy];
}

// = Drawing =

- (void)drawRect:(NSRect)rect {
	// Draw the background
	[backgroundColour set];
	NSRectFill(rect);
	
	// Draw the message, if any
	if (message) {
		// Get the style for the message
		NSMutableParagraphStyle* style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[style setAlignment: NSCenterTextAlignment];
		
		NSDictionary* messageAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
										   [NSFont systemFontOfSize: 12], NSFontAttributeName,
										   style, NSParagraphStyleAttributeName, 
										   nil];
		
		// Draw roughly centered
		NSRect bounds = [self bounds];
		NSRect textBounds = NSInsetRect(bounds, 8, 8);
		textBounds.origin.y = NSMinY(bounds) + 8;
		textBounds.size.height = NSMaxY(bounds) - NSMinY(textBounds);
		
		[message drawInRect: textBounds
			 withAttributes: messageAttributes];
	} else {
		// Draw the nodes
		[rootHeaderNode drawNodeInRect: rect
							 withFrame: [self bounds]];
	}
}

// = Messages from the header controller =

- (void) refreshHeaders: (IFHeaderController*) controller {
	// Get the root header from the controller
	[rootHeader release]; rootHeader = nil;
	rootHeader = [[controller rootHeader] retain];
	
	// Update this control
	[self updateFromRoot];
	
	if (delegate && [delegate respondsToSelector:@selector(refreshHeaders:)]) {
		[delegate refreshHeaders: controller];
	}
}

// = Mouse events =

- (void) mouseDown: (NSEvent*) evt {
	// Get the position where the mouse was clicked
	NSPoint viewPos = [self convertPoint: [evt locationInWindow]
								fromView: nil];
	
	// Get which node was clicked on
	IFHeaderNode* clicked = [rootHeaderNode nodeAtPoint: viewPos];
	
	// Inform the delegate that the header has been clicked
	if (clicked && delegate && [delegate respondsToSelector: @selector(headerView:clickedOnNode:)]) {
		[delegate headerView: self
			   clickedOnNode: clicked];
	}
}

@end
