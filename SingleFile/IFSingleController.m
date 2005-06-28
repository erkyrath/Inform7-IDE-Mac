//
//  IFSingleController.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/06/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFSingleFile.h"
#import "IFSingleController.h"


@implementation IFSingleController

- (id) init {
	return [super initWithWindowNibName: @"SingleFile"];
}

- (id) initWithWindow: (NSWindow*) win {
	self = [super initWithWindow: win];
	
	if (self) {
	}
	
	return self;
}

- (void) dealloc {
	// Unset the view's text storage
	if (fileView != nil) {
		[[[self document] storage] removeLayoutManager: [fileView layoutManager]];
	}
	
	[super dealloc];
}

- (void)windowDidLoad {
	NSLog(@"windowDidLoad called");
	[self awakeFromNib];
}

- (void) awakeFromNib {
	// Set the window frame save name
	[self setWindowFrameAutosaveName: @"SingleFile"];

	// Set the view's text appropriately
	[[fileView textStorage] removeLayoutManager: [fileView layoutManager]];
	[[[self document] storage] addLayoutManager: [fileView layoutManager]];
}

@end
