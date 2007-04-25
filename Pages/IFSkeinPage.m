//
//  IFSkeinPage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFSkeinPage.h"
#import "IFProject.h"
#import "IFPreferences.h"


@implementation IFSkeinPage

// = Initialisation =

- (id) initWithProjectController: (IFProjectController*) controller {
	self = [super initWithNibName: @"Skein"
				projectController: controller];
	
	if (self) {
		IFProject* doc = [parent document];
		
		// The skein view
		[skeinView setSkein: [doc skein]];
		[skeinView setDelegate: parent];
		
		[skeinView setItemWidth: floorf([[IFPreferences sharedPreferences] skeinSpacingHoriz])];
		[skeinView setItemHeight: floorf([[IFPreferences sharedPreferences] skeinSpacingVert])];
		
		// (Problem with this is that it updates the menu on every change, which might get to be slow)
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(skeinDidChange:)
													 name: ZoomSkeinChangedNotification
												   object: [doc skein]];
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(preferencesChangedQuickly:)
													 name: IFPreferencesDidChangeNotification
												   object: [IFPreferences sharedPreferences]];
		
		// Create the cells for the page bar
		labelsCell = [[IFPageBarCell alloc] initTextCell: @"Labels"];
		trimCell = [[IFPageBarCell alloc] initTextCell: @"Trim..."];
		playAllCell = [[IFPageBarCell alloc] initTextCell: @"Play All"];
		layoutCell = [[IFPageBarCell alloc] initTextCell: @"Layout..."];
		
		[labelsCell setMenu: [[[NSMenu alloc] init] autorelease]];
		
		[trimCell setTarget: self];
		[trimCell setAction: @selector(pruneSkein:)];
		
		[layoutCell setTarget: self];
		[layoutCell setAction: @selector(performSkeinLayout:)];
		
		[playAllCell setTarget: self];
		[playAllCell setAction: @selector(replayEntireSkein:)];

		// Update the skein settings
		[self skeinDidChange: nil];
		[skeinView scrollToItem: [[doc skein] rootItem]];
	}
	
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	if (lastAnnotation) [lastAnnotation release];
	if (pruneSkein) [pruneSkein release];
	if (skeinSpacing) [skeinSpacing release];
	
	[super dealloc];
}

// = Setting up from the nib =

- (void) setPruneSkein: (NSWindow*) newPruneSkein {
	[pruneSkein release];
	pruneSkein = [newPruneSkein retain];
}

- (NSWindow*) pruneSkein {
	return pruneSkein;
}

- (void) setSkeinSpacing: (NSWindow*) newSkeinSpacing {
	[skeinSpacing release];
	skeinSpacing = [newSkeinSpacing retain];
}

- (NSWindow*) skeinSpacing {
	return skeinSpacing;
}

// = Details about this view =

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Skein Page Title"
												  value: @"Skein"
												  table: nil];
}

// = Handling preferences changes =

- (void) preferencesChangedQuickly: (NSNotification*) not {
	[skeinView setItemWidth: floorf([[IFPreferences sharedPreferences] skeinSpacingHoriz])];
	[skeinView setItemHeight: floorf([[IFPreferences sharedPreferences] skeinSpacingVert])];
}

// = The skein view =

- (ZoomSkeinView*) skeinView {
	return skeinView;
}

- (void) skeinDidChange: (NSNotification*) not {
	[labelsCell setMenu: [[[parent document] skein] populateMenuWithAction: @selector(skeinLabelSelected:)
																	target: self]];
}

- (void) clearSkeinDidEnd: (NSWindow*) sheet
			   returnCode: (int) returnCode
			  contextInfo: (void*) contextInfo {
	if (returnCode == NSAlertAlternateReturn) {
		ZoomSkein* skein = [[parent document] skein];
		
		[skein removeTemporaryItems: 0];
		[skein zoomSkeinChanged];
	}
}

- (IBAction) performPruning: (id) sender {
	if ([sender tag] == 1) {
		// Perform the pruning
		ZoomSkein* skein = [[parent document] skein];
		
		int pruning = 31 - [pruneAmount floatValue];
		if (pruning < 1) pruning = 1;
		
		[skein removeTemporaryItems: pruning];
		[skein zoomSkeinChanged];
	}
	
	// Finish with the sheet
	[NSApp stopModal];
}

- (IBAction) pruneSkein: (id) sender {
	// Set the slider to a default value (prune a little - this is only a little harsher than the auto-pruning)
	[pruneAmount setFloatValue: 10.0];
	
	// Run the 'prune skein' sheet
	[NSApp beginSheet: pruneSkein
	   modalForWindow: [skeinView window]
		modalDelegate: self
	   didEndSelector: nil
		  contextInfo: nil];
	[NSApp runModalForWindow: [skeinView window]];
	[NSApp endSheet: pruneSkein];
	[pruneSkein orderOut: self];
}

- (IBAction) performSkeinLayout: (id) sender {
	// The user has clicked a button indicating she wants to change the skein layout
	
	// Set up the sliders
	[skeinHoriz setFloatValue: [[IFPreferences sharedPreferences] skeinSpacingHoriz]];
	[skeinVert setFloatValue: [[IFPreferences sharedPreferences] skeinSpacingVert]];
	
	// Run the 'layout skein' sheet
	[NSApp beginSheet: skeinSpacing
	   modalForWindow: [skeinView window]
		modalDelegate: self
	   didEndSelector: nil
		  contextInfo: nil];
	[NSApp runModalForWindow: [skeinView window]];
	[NSApp endSheet: skeinSpacing];
	[skeinSpacing orderOut: self];
}

- (IBAction) skeinLayoutOk: (id) sender {
	// The user has confirmed her new skein layout
	[NSApp stopModal];
}

- (IBAction) useDefaultSkeinLayout: (id) sender {
	// The user has clicked a button indicating she wants to use the default skein layout
	[skeinHoriz setFloatValue: 120.0];
	[skeinVert setFloatValue: 96.0];
	
	[self updateSkeinLayout: sender];
}

- (IBAction) updateSkeinLayout: (id) sender {
	// The user has dragged one of the skein layout sliders
	[[IFPreferences sharedPreferences] setSkeinSpacingHoriz: [skeinHoriz floatValue]];
	[[IFPreferences sharedPreferences] setSkeinSpacingVert: [skeinVert floatValue]];
}

- (IBAction) skeinLabelSelected: (id) sender {
	NSMenuItem* menuItem;
	
	if ([sender isKindOfClass: [NSMenuItem class]]) {
		menuItem = sender;
	} else {
		menuItem = [sender selectedItem];
	}
	
	NSString* annotation = [menuItem title];
	
	// Reset the annotation count if required
	if (![annotation isEqualToString: lastAnnotation]) {
		annotationCount = 0;
	}
	
	[lastAnnotation release];
	lastAnnotation = [annotation retain];
	
	// Get the list of items for this annotation
	NSArray* availableItems = [[[parent document] skein] itemsWithAnnotation: lastAnnotation];
	if (!availableItems || [availableItems count] == 0) return;
	
	// Reset the annotation count if required
	if ([availableItems count] <= annotationCount) annotationCount = 0;
	
	// Scroll to the appropriate item
	[skeinView scrollToItem: [availableItems objectAtIndex: annotationCount]];
	
	// Will scroll to the next item in the list if there's more than one
	annotationCount++;
}

- (IBAction) replayEntireSkein: (id) sender {
	[[NSApp targetForAction: @selector(replayEntireSkein:)] replayEntireSkein: sender];
}

// = The page bar =

- (NSArray*) toolbarCells {
	return [NSArray arrayWithObjects: playAllCell, trimCell, layoutCell, labelsCell, nil];
}

@end
