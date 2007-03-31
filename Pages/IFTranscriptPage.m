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
	}
	
	return self;
}

- (void) dealloc {
	[transcriptView setDelegate: nil];

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
					  [[NSBundle mainBundle] localizedStringForKey: @"Cancel"
															 value: @"Cancel"
															 table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"Bless All"
															 value: @"Bless All"
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
	if (returnCode == NSAlertAlternateReturn) {
		[transcriptView blessAll];
	} else {
	}
}

@end
