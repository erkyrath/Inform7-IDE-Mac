//
//  IFNewProject.h
//  Inform
//
//  Created by Andrew Hunter on Fri Sep 12 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "IFProjectType.h"


@interface IFNewProject : NSWindowController {
    // Interface builder outlets
    IBOutlet NSView* projectPaneView;
    IBOutlet NSView* projectTypeView;
    IBOutlet NSView* projectLocationView;

    IBOutlet NSTextField* projectLocation;
    IBOutlet NSTextView* projectDescriptionView;

    IBOutlet NSButton* nextButton;
    IBOutlet NSButton* previousButton;

    IBOutlet NSOutlineView* projectTypes;

    // Information
    NSView* currentView;
    NSObject<IFProjectType>* projectType;
    NSObject<IFProjectSetupView>* projectView;

    BOOL hideExtension;
}

// Actions
- (IBAction) nextView:     (id) sender;
- (IBAction) previousView: (id) sender;
- (IBAction) cancel:       (id) sender;

- (IBAction) chooseLocation: (id) sender;

@end
