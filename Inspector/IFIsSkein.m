//
//  IFIsSkein.m
//  Inform
//
//  Created by Andrew Hunter on Mon Jul 05 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import "IFIsSkein.h"

NSString* IFIsSkeinInspector = @"IFIsSkeinInspector";

@implementation IFIsSkein

+ (IFIsSkein*) sharedIFIsSkein {
	static IFIsSkein* sharedSkein = nil;
	
	if (!sharedSkein) {
		sharedSkein = [[[self class] alloc] init];
	}
	
	return sharedSkein;
}

- (id) init {
	self = [super init];
	
	if (self) {
		[NSBundle loadNibNamed: @"SkeinInspector"
						 owner: self];
		[self setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Inspector Skein"
															   value: @"Skein"
															   table: nil]];
	}
	
	return self;
}

// = Inspector methods =

- (NSString*) key {
	return IFIsSkeinInspector;
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
		
		[skeinView setSkein: [activeProject skein]];
	}
}

- (BOOL) available {
	return activeProject==nil?NO:YES;
}

@end
