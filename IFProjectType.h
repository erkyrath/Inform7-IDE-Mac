//
//  IFProjectType.h
//  Inform
//
//  Created by Andrew Hunter on Sat Sep 13 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IFProjectFile.h"


@protocol IFProjectSetupView;

//
// Objects implementing this protocol specify a type of project that can be created via the
// new project dialog.
//
@protocol IFProjectType

- (NSString*)           projectName;						// The name of the project that appears in the project type list
- (NSString*)           projectHeading;						// The heading that the name comes under
- (NSAttributedString*) projectDescription;					// A more detailed description that is displayed when the project is selected

- (NSObject<IFProjectSetupView>*) configView;				// nil, or a project type-specific view that can be used to customise the new project. Should be reallocated every time this is called.

- (void) setupFile: (IFProjectFile*) file					// Request to setup a file from the given IFProjectSetupView (which will have been previously created by configView)
          fromView: (NSObject<IFProjectSetupView>*) view;

@end

@protocol IFProjectSetupView

- (NSView*) view;											// The view that's displayed for this projects custom settings

@end

//
// Objects implementing the IFProjectType protocol may also implement these functions.
//
@interface NSObject(IFProjectTypeOptionalMethods)

- (BOOL) showFinalPage;				// Defaults to YES. If NO, the 'save project' page is not shown
- (NSString*) confirmationMessage;	// Return a string to display an 'are you sure' type message
- (NSString*) errorMessage;			// Return a string to indicate an error with the way things are set up
- (NSString*) saveFilename;			// If showFinalPage is NO, this is the filename to create
- (NSString*) openAsType;			// If present, the file type to open this project as

@end
