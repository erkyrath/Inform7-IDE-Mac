//
//  IFPage.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFProject.h"
#import "IFProjectController.h"

//
// Controller class that represents a page in a project pane
//
@interface IFPage : NSObject {
	IFProjectController* parent;			// The project controller that 'owns' this page (not retained)
	
	BOOL releaseView;						// YES if the view has been set using setView: and should be released
	IBOutlet NSView* view;					// The view to display for this page
}

// Initialising
- (id) initWithNibName: (NSString*) nib
	 projectController: (IFProjectController*) controller;

// Page properties
- (NSString*) title;						// The name of the tab this page appears under
- (NSView*) view;							// The view that should be used to display this page
- (NSView*) activeView;						// The view that is considered to have focus for this page
- (IBOutlet void) setView: (NSView*) view;	// Sets the view to use

// TODO: page-specific toolbar items (NSCells?)

@end
