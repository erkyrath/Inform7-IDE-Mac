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
#import "IFInspectorWindow.h"

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
	
	[[IFInspectorWindow sharedInspectorWindow] showWindow: self];
		
	NSView* innerView1 = [[NSTextView alloc] initWithFrame: NSMakeRect(0,0,240,120)];
	NSView* innerView2 = [[NSTextView alloc] initWithFrame: NSMakeRect(0,0,240,120)];
	NSView* innerView3 = [[NSTextView alloc] initWithFrame: NSMakeRect(0,0,240,120)];
	
	IFInspector* ins1 = [[IFInspector alloc] init];
	IFInspector* ins2 = [[IFInspector alloc] init];
	IFInspector* ins3 = [[IFInspector alloc] init];
	
	[ins1 setTitle: @"Inspector 1"]; [ins1 setInspectorView: innerView1];
	[ins2 setTitle: @"Inspector 2"]; [ins2 setInspectorView: innerView2];
	[ins3 setTitle: @"Inspector 3"]; [ins3 setInspectorView: innerView3];
	
	[[IFInspectorWindow sharedInspectorWindow] addInspector: ins1];
	[[IFInspectorWindow sharedInspectorWindow] addInspector: ins2];
	[[IFInspectorWindow sharedInspectorWindow] addInspector: ins3];
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

- (IBAction) showInspectors: (id) sender {
	[[IFInspectorWindow sharedInspectorWindow] showWindow: self];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
	if ([menuItem action] == @selector(showInspectors:)) {
		return [[IFInspectorWindow sharedInspectorWindow] isHidden];
	}
	
	return YES;
}

@end
