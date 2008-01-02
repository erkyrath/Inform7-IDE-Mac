//
//  IFTranscriptPage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFTranscriptPage.h"
#import "IFProject.h"
#import "IFProjectPane.h"
#import "IFProjectController.h"

@implementation IFTranscriptPage

// = Initialisation =

- (id) initWithProjectController: (IFProjectController*) controller {
	self = [super initWithNibName: @"Transcript"
				projectController: controller];
	
	if (self) {
		IFProject* doc = [parent document];
		
		// The transcript
		[[transcriptView layout] setSkein: [doc skein]];
		[transcriptView setDelegate: self];
		
		// The page bar cells
		blessAllCell = [[IFPageBarCell alloc] initTextCell: [[NSBundle mainBundle] localizedStringForKey: @"Bless All Button"
																								   value: @"Bless All"
																								   table: nil]];
		
		[blessAllCell setTarget: self];
		[blessAllCell setAction: @selector(transcriptBlessAll:)];

		nextDiffCell = [[IFPageBarCell alloc] initTextCell: [[NSBundle mainBundle] localizedStringForKey: @"Next Difference Button"
																								   value: @"Next"
																								   table: nil]];
		[nextDiffCell setImage: [NSImage imageNamed: @"NextDiff"]];
		[nextDiffCell setTarget: self];
		[nextDiffCell setAction: @selector(nextDiff:)];

		prevDiffCell = [[IFPageBarCell alloc] initTextCell: [[NSBundle mainBundle] localizedStringForKey: @"Previous Difference Button"
																								   value: @"Previous"
																								   table: nil]];
		[prevDiffCell setImage: [NSImage imageNamed: @"PrevDiff"]];
		[prevDiffCell setTarget: self];
		[prevDiffCell setAction: @selector(prevDiff:)];

		nextBySkeinCell = [[IFPageBarCell alloc] initTextCell: [[NSBundle mainBundle] localizedStringForKey: @"Next by Skein Button"
																									  value: @"Next by Skein"
																									  table: nil]];
		[nextBySkeinCell setImage: [NSImage imageNamed: @"NextBySkein"]];
		[nextBySkeinCell setTarget: self];
		[nextBySkeinCell setAction: @selector(nextDiffBySkein:)];
	}
	
	return self;
}

- (void) dealloc {
	[transcriptView setDelegate: nil];
	[blessAllCell release];
	[nextBySkeinCell release];
	[prevDiffCell release];
	[nextDiffCell release];

	[super dealloc];
}

// = Details about this view =

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Transcript Page Title"
												  value: @"Transcript"
												  table: nil];
}

// = The transcript view =

- (IFTranscriptLayout*) transcriptLayout {
	return [transcriptView layout];
}

- (IFTranscriptView*) transcriptView {
	return transcriptView;
}

- (void) transcriptPlayToItem: (ZoomSkeinItem*) itemToPlayTo {
	ZoomSkein* skein = [[parent document] skein];
	ZoomSkeinItem* activeItem = [skein activeItem];
	
	ZoomSkeinItem* firstPoint = nil;
	
	// See if the active item is a parent of the point we're playing to (in which case, continue playing. Otherwise, restart and play to that point)
	ZoomSkeinItem* parentItem = [itemToPlayTo parent];
	while (parentItem) {
		if (parentItem == activeItem) {
			firstPoint = activeItem;
			break;
		}
		
		parentItem = [parentItem parent];
	}
	
	if (firstPoint == nil) {
		[parent restartGame];
		firstPoint = [skein rootItem];
	}
	
	// Play to this point
	[parent playToPoint: itemToPlayTo
			  fromPoint: firstPoint];
}

- (void) transcriptShowKnot: (ZoomSkeinItem*) knot {
	// Switch to the skein view
	IFProjectPane* skeinPane = [parent skeinPane];
	
	[skeinPane selectView: IFSkeinPane];
	
	// Scroll to the knot
	[[[skeinPane skeinPage] skeinView] scrollToItem: knot];
}

- (IBAction) transcriptBlessAll: (id) sender {
	// Display a confirmation dialog (as this can't be undone. Well, not easily)
	NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"Are you sure you want to bless all these items?"
															 value: @"Are you sure you want to bless all these items?"
															 table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"Bless All"
															 value: @"Bless All"
															 table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"Cancel"
															 value: @"Cancel"
															 table: nil],
					  nil, [transcriptView window], self, 
					  @selector(transcriptBlessAllDidEnd:returnCode:contextInfo:), nil,
					  nil, [[NSBundle mainBundle] localizedStringForKey: @"Bless all explanation"
																  value: @"Bless all explanation"
																  table: nil]);
}

- (void) transcriptBlessAllDidEnd: (NSWindow*) sheet
					   returnCode: (int) returnCode
					  contextInfo: (void*) contextInfo {
	if (returnCode == NSAlertDefaultReturn) {
		[transcriptView blessAll];
	} else {
	}
}

// = The page bar =

- (NSArray*) toolbarCells {
	return [NSArray arrayWithObjects: blessAllCell, prevDiffCell, nextDiffCell, nextBySkeinCell, nil];
}

- (void) nextDiffBySkein: (id) sender {
	[parent nextDifferenceBySkein: self];
}

- (void) nextDiff: (id) sender {
	[parent nextDifference: self];
}

- (void) prevDiff: (id) sender {
	[parent lastDifference: self];
}

@end
