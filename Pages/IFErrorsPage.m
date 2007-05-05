//
//  IFErrorsPage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFErrorsPage.h"


@implementation IFErrorsPage

// = Initialisation =

- (id) initWithProjectController: (IFProjectController*) controller {
	self = [super initWithNibName: @"Errors"
				projectController: controller];
	
	if (self) {
		
	}
	
	return self;
}

- (void) dealloc {
	[compilerController release];
	[pageCells release];
	
	[super dealloc];
}

// = Details about this view =

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Errors Page Title"
												  value: @"Errors"
												  table: nil];
}

// = IFCompilerController delegate methods =

- (void) viewSetHasUpdated: (IFCompilerController*) sender {
	if (sender != compilerController) return;
	
	// Clear out the current set of cells
	[pageCells release];
	pageCells = [[NSMutableArray alloc] init];
	
	// Show no pages if there is only one
	if ([[compilerController viewNames] count] <= 1) {
		[self toolbarCellsHaveUpdated];
		return;
	}
	
	// Rebuild the set of cells for this compiler
	int selectedIndex = [compilerController viewIndex];
	NSEnumerator* nameEnum = [[compilerController viewNames] reverseObjectEnumerator];
	int currentIndex = [[compilerController viewNames] count]-1;
	NSString* name;
	
	while (name = [nameEnum nextObject]) {
		// Create the cell for this name
		IFPageBarCell* newCell = [[IFPageBarCell alloc] initTextCell: name];
		
		[newCell setTarget: self];
		[newCell setAction: @selector(switchToErrorPage:)];
		[newCell setIdentifier: [NSNumber numberWithInt: currentIndex]];
		[newCell setRadioGroup: 128];
		
		if (currentIndex == selectedIndex) {
			[newCell setState: NSOnState];
		}
		
		[pageCells addObject: [newCell autorelease]];
		
		// Move on
		currentIndex--;
	}
}

- (void) switchToPage: (int) index {
	[compilerController switchToViewWithIndex: index];
}

- (void) compiler: (IFCompilerController*) sender
   switchedToView: (int) viewIndex {
	if (sender != compilerController) return;
	
	// Remember this in the history
	[[self history] switchToPage: viewIndex];
	
	// Turn the newly selected cell on
	if ([pageCells count] == 0) return;
	int cellIndex = [pageCells count] - 1 - [compilerController viewIndex];
	
	NSEnumerator* cellEnum = [pageCells objectEnumerator];
	int currentIndex = 0;
	IFPageBarCell* cell;
	while (cell = [cellEnum nextObject]) {
		if (currentIndex == cellIndex) {
			[cell setState: NSOnState];
		} else {
			[cell setState: NSOffState];
		}
		
		currentIndex++;
	}
}

- (IBAction) switchToErrorPage: (id) sender {
	// Get the cell that was clicked on
	IFPageBarCell* cell = nil;
	
	if ([sender isKindOfClass: [IFPageBarCell class]]) cell = sender;
	else if ([sender isKindOfClass: [IFPageBarView class]]) cell = (IFPageBarCell*)[sender lastTrackedCell];

	// Order the compiler controller to switch to the specified page
	int index = [[cell identifier] intValue];
	[compilerController switchToViewWithIndex: index];
}

// = Setting some interface building values =

// (These need to be released, so implement getters/setters)

- (IFCompilerController*) compilerController {
	return compilerController;
}

- (void) setCompilerController: (IFCompilerController*) controller {
	[compilerController release];
	compilerController = [controller retain];
}

// = History =

- (void) didSwitchToPage {
	[[self history] switchToPage: [compilerController viewIndex]];
	[super didSwitchToPage];
}

// = The page bar =

- (NSArray*) toolbarCells {
	if (pageCells == nil) return [NSArray array];
	return pageCells;
}

@end
