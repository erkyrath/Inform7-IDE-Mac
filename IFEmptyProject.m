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
    return [[NSBundle mainBundle] localizedStringForKey: @"Empty v6 project"
												  value: @"Empty project"
												  table: nil];
}

- (NSString*) projectHeading {
    return [[NSBundle mainBundle] localizedStringForKey: @"InformVersion"
												  value: @"Inform 6.3"
												  table: nil];
}

- (NSAttributedString*) projectDescription {
    return [[[NSAttributedString alloc] initWithString:
        [[NSBundle mainBundle] localizedStringForKey: @"Creates an empty Inform project"
											   value: @"Creates an empty Inform project"
											   table: nil]] autorelease];
}

- (NSObject<IFProjectSetupView>*) configView {
    return nil;
}

- (void) setupFile: (IFProjectFile*) file
          fromView: (NSObject<IFProjectSetupView>*) view {
    [file addSourceFile: @"main.inf"];
}

@end
