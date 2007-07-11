//
//  IFSingleController.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/06/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFSingleFile.h"
#import "IFSingleController.h"
#import "IFWelcomeWindow.h"
#import "IFSharedContextMatcher.h"

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
	[IFWelcomeWindow hideWelcomeWindow];
	[self awakeFromNib];
}

- (void) awakeFromNib {
	// Set the window frame save name
	[self setWindowFrameAutosaveName: @"SingleFile"];
	
	// Set the matcher for the window
	// TODO: do different things depending on the file type
	[fileView setSyntaxDictionaryMatcher: [IFSharedContextMatcher matcherForInform7]];

	// Set the view's text appropriately
	[[fileView textStorage] removeLayoutManager: [fileView layoutManager]];
	[[[self document] storage] addLayoutManager: [fileView layoutManager]];
	
	[fileView setEditable: ![[self document] isReadOnly]];
}

// = Menu items =

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
	if ([menuItem action] == @selector(saveDocument:)) {
		return ![[self document] isReadOnly];
	}
	
	return YES;
}

@end
