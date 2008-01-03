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
		displayDepth = 3;
    }
    return self;
}

- (void) dealloc {
	[rootHeader release];		rootHeader = nil;
	
	[super dealloc];
}

// = Updating the view =

- (void) updateFromRoot {
	// Replace the root header node
	[rootHeaderNode release]; rootHeaderNode = nil;
	rootHeaderNode = [[IFHeaderNode alloc] initWithHeader: rootHeader
												 position: NSMakePoint(0,0)
													depth: 0];
	[rootHeaderNode populateToDepth: displayDepth];
	
	// Resize the view
	NSRect rootFrame = [rootHeaderNode frame];
	[self setFrameSize: rootFrame.size];
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

// = Drawing =

- (void)drawRect:(NSRect)rect {
	
}

// = Messages from the header controller =

- (void) refreshHeaders: (IFHeaderController*) controller {
	// Get the root header from the controller
	[rootHeader release];
	rootHeader = [controller rootHeader];
	
	// Update this control
	[self updateFromRoot];
}

@end
