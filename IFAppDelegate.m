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

+ (BOOL)isWebKitAvailable {
    static BOOL _webkitAvailable=NO;
    static BOOL _initialized=NO;
    
    if (_initialized)
        return _webkitAvailable;
	
    NSBundle* webKitBundle;
    webKitBundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/WebKit.framework"];
    if (webKitBundle) {
        _webkitAvailable = [webKitBundle load];
    }
    _initialized=YES;
    
    return _webkitAvailable;
}

- (BOOL)isWebKitAvailable {
	return haveWebkit;
}

- (void) applicationDidFinishLaunching: (NSNotification*) not {
	haveWebkit = [[self class] isWebKitAvailable];
}

- (BOOL) applicationShouldOpenUntitledFile: (NSApplication*) sender {
    return NO;
}

- (IBAction) newProject: (id) sender {
    IFNewProject* newProj = [[IFNewProject alloc] init];

    [newProj showWindow: self];

    // newProj releases itself when done
}

- (IBAction) newInformFile: (id) sender {
    [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType: @"Inform source file"
                                                                        display: YES];
}

- (IBAction) newHeaderFile: (id) sender {
    [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType: @"Inform header file"
                                                                        display: YES];
}

@end
