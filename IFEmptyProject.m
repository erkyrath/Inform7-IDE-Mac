//
//  IFEmptyProject.m
//  Inform
//
//  Created by Andrew Hunter on Sat Sep 13 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFEmptyProject.h"


@implementation IFEmptyProject

- (NSString*) projectName {
    return @"Empty project";
}

- (NSString*) projectHeading {
    return @"Inform 6.21";
}

- (NSAttributedString*) projectDescription {
    return [[[NSAttributedString alloc] initWithString:
        @"Creates an empty Inform 6.21 project"] autorelease];
}

- (NSObject<IFProjectSetupView>*) configView {
    return nil;
}

- (void) setupFile: (IFProjectFile*) file
          fromView: (NSObject<IFProjectSetupView>*) view {
    [file addSourceFile: @"main.inf"];
}

@end
