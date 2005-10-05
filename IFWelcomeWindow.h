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
}

// Creating the window
+ (IFWelcomeWindow*) sharedWelcomeWindow;				// Gets the shared welcome window
+ (void) hideWelcomeWindow;								// Should be called whenever a document is created/opened (not sure if I can deal with the general case...)

// Dealing with window actions
- (IBAction) openExistingProject: (id) sender;			// Opens an existing project
- (IBAction) createNewProject: (id) section;			// Creates a new projects

@end
