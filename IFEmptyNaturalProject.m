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
	
	// Default file content
	NSString* name = [[[file filename] lastPathComponent] stringByDeletingPathExtension];
	if ([name length] == 0 || name == nil) name = @"Untitled";
	
	NSString* longuserName = NSFullUserName();
	if ([longuserName length] == 0 || longuserName == nil) longuserName = NSUserName();
	if ([longuserName length] == 0 || longuserName == nil) longuserName = @"Unknown Author";
	
	NSString* defaultContents = [NSString stringWithFormat: @"\"%@\" by %@\n\n", name, longuserName];

	// Create the default file
    [file addSourceFile: @"story.ni" 
		   withContents: [defaultContents dataUsingEncoding: NSASCIIStringEncoding]];
}

@end
