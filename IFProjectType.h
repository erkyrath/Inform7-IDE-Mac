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
