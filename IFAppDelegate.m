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

#import "IFIsNotes.h"
#import "IFIsIndex.h"
#import "IFIsFiles.h"
#import "IFIsSkein.h"

#import "IFNoDocProtocol.h"
#import "IFInformProtocol.h"

#import "IFSettingsController.h"
#import "IFMiscSettings.h"
#import "IFOutputSettings.h"
#import "IFCompilerOptions.h"
#import "IFLibrarySettings.h"
#import "IFDebugSettings.h"

#import <ZoomView/ZoomSkein.h>
#import <ZoomView/ZoomSkeinView.h>

@implementation IFAppDelegate

static NSRunLoop* mainRunLoop = nil;
+ (NSRunLoop*) mainRunLoop {
	return mainRunLoop;
}

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

- (void) applicationWillFinishLaunching: (NSNotification*) not {
	mainRunLoop = [NSRunLoop currentRunLoop];
	
	haveWebkit = [[self class] isWebKitAvailable];
	
	if (haveWebkit) {
		// Register some custom URL handlers
		// [NSURLProtocol registerClass: [IFNoDocProtocol class]];
		[NSURLProtocol registerClass: [IFInformProtocol class]];
	}
	
	// Standard settings
	[IFSettingsController addStandardSettingsClass: [IFOutputSettings class]];
	[IFSettingsController addStandardSettingsClass: [IFCompilerOptions class]];
	[IFSettingsController addStandardSettingsClass: [IFLibrarySettings class]];
	[IFSettingsController addStandardSettingsClass: [IFMiscSettings class]];
	[IFSettingsController addStandardSettingsClass: [IFDebugSettings class]];
}

- (void) applicationDidFinishLaunching: (NSNotification*) not {	
	// Show the inspector window
	[[IFInspectorWindow sharedInspectorWindow] showWindow: self];
	
	// The standard inspectors
	[[IFInspectorWindow sharedInspectorWindow] addInspector: [IFIsFiles sharedIFIsFiles]];
	[[IFInspectorWindow sharedInspectorWindow] addInspector: [IFIsNotes sharedIFIsNotes]];
	[[IFInspectorWindow sharedInspectorWindow] addInspector: [IFIsIndex sharedIFIsIndex]];
	[[IFInspectorWindow sharedInspectorWindow] addInspector: [IFIsSkein sharedIFIsSkein]];

#if 0
	// Allow skeins to be rendered in web views
	[WebView registerViewClass: [ZoomSkeinView class]
		   representationClass: [ZoomSkein class]
				   forMIMEType: @"application/x-zoom-skein"];
	
	NSLog(@"(%i) As HTML: %i", [WebView canShowMIMEType: @"application/x-zoom-skein"],
		  [WebView canShowMIMETypeAsHTML: @"application/x-zoom-skein"]);
	NSLog(@"%i %i", [ZoomSkeinView conformsToProtocol: @protocol(WebDocumentView)],
		  [ZoomSkein conformsToProtocol: @protocol(WebDocumentRepresentation)]);
#endif

	[NSURLProtocol registerClass: [IFInformProtocol class]];
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
