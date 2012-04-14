//
//  IFSkeinPage.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IFPage.h"
#import <ZoomView/ZoomSkeinView.h>

//
// The 'skein' page
//
@interface IFSkeinPage : IFPage {
	// The skein view
	IBOutlet ZoomSkeinView* skeinView;					// The skein view
	int annotationCount;								// The number of annotations (labels)
	NSString* lastAnnotation;							// The last annotation skipped to using the label button
	
	IBOutlet NSWindow* pruneSkein;						// The 'prune skein' window
	IBOutlet NSSlider* pruneAmount;						// The 'prune amount' slider
	
	IBOutlet NSWindow* skeinSpacing;					// The 'skein spacing' window
	IBOutlet NSSlider* skeinHoriz;						// The 'skein horizontal width' slider
	IBOutlet NSSlider* skeinVert;						// The 'skein vertical width' slider
	
	// The page bar buttons
	IFPageBarCell* labelsCell;							// The 'Labels' button
	IFPageBarCell* trimCell;							// The 'Trim...' button
	IFPageBarCell* playAllCell;							// The 'Play All Blessed' button
	IFPageBarCell* layoutCell;							// The 'Layout...' button
}

- (id) initWithProjectController: (IFProjectController*) controller;

// The skein view
- (ZoomSkeinView*) skeinView;									// The skein view
- (IBAction) skeinLabelSelected: (id) sender;					// The user has selected a skein item from the drop-down list (so we should scroll there)
- (void) skeinDidChange: (NSNotification*) not;					// Called by Zoom to notify that the skein has changed

- (IBAction) performPruning: (id) sender;						// The user has clicked a button in the 'prune skein' sheet
- (IBAction) pruneSkein: (id) sender;							// The user has clicked the 'prune skein' button

- (IBAction) performSkeinLayout: (id) sender;					// The user has clicked a button indicating she wants to change the skein layout
- (IBAction) skeinLayoutOk: (id) sender;						// The user has confirmed her new skein layout
- (IBAction) useDefaultSkeinLayout: (id) sender;				// The user has clicked a button indicating she wants to use the default skein layout
- (IBAction) updateSkeinLayout: (id) sender;					// The user has dragged one of the skein layout sliders

@end
