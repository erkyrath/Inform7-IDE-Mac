//
//  IFIsSearch.m
//  Inform
//
//  Created by Andrew Hunter on 29/01/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFIsSearch.h"

NSString* IFIsSearchInspector = @"IFIsSearchInspector";

@implementation IFIsSearch

// = Initialisation =

+ (IFIsSearch*) sharedIFIsSearch {
	IFIsSearch* sharedSearch = nil;
	
	if (!sharedSearch) {
		sharedSearch = [[[self class] alloc] init];
	}
	
	return sharedSearch;
}

- (id) init {
	self = [super init];
	
	if (self) {
		[NSBundle loadNibNamed: @"SearchInspector"
						 owner: self];
		[self setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Inspector Search"
															   value: @"Search"
															   table: nil]];
	}
	
	return self;
}

// = Inspectory stuff =

- (NSString*) key {
	return IFIsSearchInspector;
}

- (void) inspectWindow: (NSWindow*) newWindow {
	activeWin = newWindow;
	
	if (activeProject) {
		// Need to remove the layout manager to prevent potential weirdness
		[activeProject release];
	}
	activeController = nil;
	activeProject = nil;
	
	// Get the active project, if applicable
	NSWindowController* control = [newWindow windowController];
	
	if (control != nil && [control isKindOfClass: [IFProjectController class]]) {
		activeController = (IFProjectController*)control;
		activeProject = [[control document] retain];
	}
}

- (BOOL) available {
	return activeProject==nil?NO:YES;
}

@end
