//
//  IFIsBreakpoints.m
//  Inform
//
//  Created by Andrew Hunter on 14/12/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFIsBreakpoints.h"

NSString* IFIsBreakpointsInspector = @"IFIsBreakpointsInspector";

@implementation IFIsBreakpoints

// = Initialisation =

+ (IFIsBreakpoints*) sharedIFIsBreakpoints {
	IFIsBreakpoints* sharedBreakpoints = nil;
	
	if (!sharedBreakpoints) {
		sharedBreakpoints = [[[self class] alloc] init];
	}
	
	return sharedBreakpoints;
}

- (id) init {
	self = [super init];
	
	if (self) {
		[NSBundle loadNibNamed: @"BreakpointInspector"
						 owner: self];
		[self setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Inspector Breakpoints"
															   value: @"Breakpoints"
															   table: nil]];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(breakpointsChanged:)
													 name: IFProjectBreakpointsChangedNotification
												   object: nil];
	}
	
	return self;
}

// = Inspectory stuff =

- (NSString*) key {
	return IFIsBreakpointsInspector;
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
	// Can't be available if there's no project
	if (activeProject == nil) return NO;
	
	// Breakpoints and watchpoints are not implemented for Natural Inform projects
	if ([[activeProject settings] usingNaturalInform]) return NO;
	
	return YES;
}

// = Menu actions =

- (IBAction) cut: (id) sender {
}

- (IBAction) copy: (id) sender {
}

- (IBAction) paste: (id) sender {
}

- (IBAction) delete: (id) sender {
}

// = Table data source =

- (int)numberOfRowsInTableView: (NSTableView*) aTableView {
	return [activeProject breakpointCount];
}

- (id)				tableView: (NSTableView*) aTableView 
	objectValueForTableColumn: (NSTableColumn*) aTableColumn
						  row: (int) rowIndex {
	NSString* ident = [aTableColumn identifier];
	
	if ([ident isEqualToString: @"enabled"]) {
		return [NSNumber numberWithBool: YES];
	} else if ([ident isEqualToString: @"file"]) {
		return [[activeProject fileForBreakpointAtIndex: rowIndex] lastPathComponent];
	} else if ([ident isEqualToString: @"line"]) {
		return [NSString stringWithFormat: @"%i", [activeProject lineForBreakpointAtIndex: rowIndex]];
	}
	
	return nil;
}

- (void)tableViewSelectionDidChange: (NSNotification *)aNotification {
	if ([breakpointTable numberOfSelectedRows] != 1) return;
	
	int selectedRow = [breakpointTable selectedRow];
	
	NSString* file = [activeProject fileForBreakpointAtIndex: selectedRow];
	int line = [activeProject lineForBreakpointAtIndex: selectedRow];
	
	// Move to this breakpoint
	[activeController selectSourceFile: file];
	[activeController moveToSourceFileLine: line+1];
}

- (void) breakpointsChanged: (NSNotification*) not {
	[breakpointTable reloadData];
}

@end
