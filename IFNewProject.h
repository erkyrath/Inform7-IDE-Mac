//
//  IFNewProject.h
//  Inform
//
//  Created by Andrew Hunter on Fri Sep 12 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "IFProjectType.h"


//
// Window controller for the 'new project' window
//
@interface IFNewProject : NSWindowController {
    // Interface builder outlets
    IBOutlet NSView* projectPaneView;				// The pane that contains the display for the current stage in the creation process
    IBOutlet NSView* projectTypeView;				// View used to select the type of project
    IBOutlet NSView* projectLocationView;			// View used to select where the project should be created

    IBOutlet NSTextField* projectLocation;			// Text field that displays the location of the project
    IBOutlet NSTextView* projectDescriptionView;	// Text view that displays a description of the currently selected project type

    IBOutlet NSButton* nextButton;					// Button to go to the next stage in the process
    IBOutlet NSButton* previousButton;				// Button to go to the preceding stage in the process

    IBOutlet NSOutlineView* projectTypes;			// Outline view that lists the available project types

    // Information
    NSView* currentView;							// The view that's currently being displayed
    NSObject<IFProjectType>* projectType;			// The object that represents the current project type
    NSObject<IFProjectSetupView>* projectView;		// The project setup view that the specific project type has provided

    BOOL hideExtension;								// Whether or not the user has selected the 'hide extension' option when creating the project
}

// Actions
- (IBAction) nextView:     (id) sender;				// Move to the next stage
- (IBAction) previousView: (id) sender;				// Move to the previous stage
- (IBAction) cancel:       (id) sender;				// Lets call the whole thing off

- (IBAction) chooseLocation: (id) sender;			// The user has asked to specify the location of the project

@end
