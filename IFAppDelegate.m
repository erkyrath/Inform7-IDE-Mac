//
//  IFAppDelegate.m
//  Inform
//
//  Created by Andrew Hunter on Mon Aug 18 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFAppDelegate.h"
#import "IFCompilerController.h"
#import "IFNewProject.h"

@implementation IFAppDelegate

#if 0
- (BOOL)application:(NSApplication *)theApplication
           openFile:(NSString *)filename {
    IFCompilerController* controller;

    // Create a compiler instance for this file
    // FIXME: check type of file (eventually we'll have our own file type)
    if ([[filename pathExtension] isEqualTo: @"inf"]) {
        controller = [[IFCompilerController allocWithZone: [self zone]] init];

        [controller showWindow: self];
        [[controller compiler] setSettings: [[[IFCompilerSettings alloc] init] autorelease]];
        [[controller compiler] setInputFile: filename];
        [controller startCompiling];

        // [controller release];

        return YES;
    }

    return NO;
}
#endif

- (BOOL) applicationShouldOpenUntitledFile: (NSApplication*) sender {
    return NO;
}

- (IBAction) newProject: (id) sender {
    IFNewProject* newProj = [[IFNewProject alloc] init];

    [newProj showWindow: self];

    // newProj releases itself when done
}

@end
