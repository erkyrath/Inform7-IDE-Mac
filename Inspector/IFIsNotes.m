//
//  IFIsNotes.m
//  Inform
//
//  Created by Andrew Hunter on Fri May 07 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import "IFIsNotes.h"
#import "IFProjectController.h"

NSString* IFIsNotesInspector = @"IFIsNotesInspector";

@implementation IFIsNotes

+ (IFIsNotes*) sharedIFIsNotes {
	static IFIsNotes* notes = nil;
	
	if (!notes) {
		notes = [[IFIsNotes alloc] init];
	}
	
	return notes;
}

- (id) init {
	self = [super init];
	
	if (self) {
		[NSBundle loadNibNamed: @"NoteInspector"
						 owner: self];
		[self setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Inspector Notes"
															   value: @"Notes"
															   table: nil]];
		activeProject = nil;
	}
	
	return self;
}

- (void) dealloc {
	if (activeProject) [activeProject release];
	[super dealloc];
}

- (void) inspectWindow: (NSWindow*) newWindow {
	if (activeProject) {
		// Need to remove the layout manager to prevent weirdness
		// [[activeProject notes] removeLayoutManager: [text layoutManager]];
		
		[activeProject release];
	}
	activeProject = nil;

	// Set the notes layout manager to be us
	NSWindowController* control = [newWindow windowController];
	
	if (control != nil && [control isKindOfClass: [IFProjectController class]]) {
		activeProject = [[control document] retain];
		
		[[activeProject notes] addLayoutManager: [text layoutManager]];
		[text setEditable: YES];
	} else {
		NSTextStorage* noNotes = [[[NSTextStorage alloc] initWithString: @"No notes available"] autorelease];
		
		[noNotes addLayoutManager: [text layoutManager]];
		[text setEditable: NO];
	}
}

- (BOOL) available {
	return activeProject==nil?NO:YES;
}

- (NSString*) key {
	return IFIsNotesInspector;
}

@end
