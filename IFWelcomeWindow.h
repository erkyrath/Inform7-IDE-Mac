//
//  IFWelcomeWindow.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 05/10/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IFWelcomeWindow : NSWindowController {
	IBOutlet NSTextField* introText;					// The text field that should contain the introductory text
	IBOutlet NSButton* openLastProject;					// Button used to reopen the last project that was open in Inform
	IBOutlet NSProgressIndicator* backgroundProgress;	// Progress indicator that shows when a background process is running
}

// Creating the window
+ (IFWelcomeWindow*) sharedWelcomeWindow;				// Gets the shared welcome window
+ (void) hideWelcomeWindow;								// Should be called whenever a document is created/opened (not sure if I can deal with the general case...)

// Dealing with window actions
- (IBAction) openExistingProject: (id) sender;			// Opens an existing project
- (IBAction) createNewProject: (id) sender;			// Creates a new projects
- (IBAction) openLastProject: (id) sender;				// Opens the most recent project

@end
