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

@protocol IFProjectType

- (NSString*)           projectName;
- (NSString*)           projectHeading;
- (NSAttributedString*) projectDescription;

- (NSObject<IFProjectSetupView>*) configView;

- (void) setupFile: (IFProjectFile*) file
          fromView: (NSObject<IFProjectSetupView>*) view;

@end

@protocol IFProjectSetupView

- (NSView*) view;

@end

@interface NSObject(IFProjectTypeOptionalMethods)

- (BOOL) showFinalPage;				// Defaults to YES. If NO, the 'save project' page is not shown
- (NSString*) confirmationMessage;	// Return a string to display an 'are you sure' type message
- (NSString*) errorMessage;			// Return a string to indicate an error with the way things are set up
- (NSString*) saveFilename;			// If showFinalPage is NO, this is the filename to create
- (NSString*) openAsType;			// If present, the file type to open this project as

@end
