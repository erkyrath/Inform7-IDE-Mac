//
//  IFEmptyNaturalProject.m
//  Inform
//
//  Created by Andrew Hunter on Sat Sep 13 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFEmptyNaturalProject.h"


@implementation IFEmptyNaturalProject

- (NSString*) projectName {
    return [[NSBundle mainBundle] localizedStringForKey: @"Empty project"
												  value: @"Empty project"
												  table: nil];
}

- (NSString*) projectHeading {
    return [[NSBundle mainBundle] localizedStringForKey: @"Natural Inform"
												  value: @"Natural Inform"
												  table: nil];
}

- (NSAttributedString*) projectDescription {
    return [[[NSAttributedString alloc] initWithString:
        @"Creates an empty Natural Inform project"] autorelease];
}

- (NSObject<IFProjectSetupView>*) configView {
    return nil;
}

- (void) setupFile: (IFProjectFile*) file
          fromView: (NSObject<IFProjectSetupView>*) view {
    IFCompilerSettings* settings = [[IFCompilerSettings alloc] init];

    [settings setUsingNaturalInform: YES];
	[settings setLibraryToUse: @"Natural"];

    [file setSettings: [settings autorelease]];
    [file addSourceFile: @"story.ni"];
}

@end
