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
#import "IFInform6Extensions.h"
#import "IFNaturalExtensions.h"

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
	[IFSettingsController addStandardSettingsClass: [IFNaturalExtensions class]];
	[IFSettingsController addStandardSettingsClass: [IFInform6Extensions class]];
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
	
	[self updateExtensions];

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

// = The extensions menu =

static int stringCompare(id a, id b, void* context) {
	return [(NSString*)a compare: b];
}

- (NSArray*) directoriesToSearch: (NSString*) extensionSubdirectory {
	NSArray* libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSMutableArray* libraryDirectories = [NSMutableArray array];
	
	// Look for 'Inform 6 Extensions' directories in each library directory
	NSEnumerator* libEnum = [libraries objectEnumerator];
	NSString* libPath;
	
	while (libPath = [libEnum nextObject]) {
		NSString* extnPath = [[libPath stringByAppendingPathComponent: @"Inform"] stringByAppendingPathComponent: extensionSubdirectory];
		BOOL isDir;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: extnPath
												 isDirectory: &isDir]) {
			if (isDir) [libraryDirectories addObject: extnPath];
		}
	}
	
	return libraryDirectories;
}

- (NSMutableArray*) extensionsInDirectory: (NSString*) directory {
	// Clear out the old extensions
	NSMutableArray* extensions = [NSMutableArray array];
	
	//if (extensionPath) [extensionPath release];
	//extensionPath = [[NSMutableDictionary alloc] init];
	
	// Get the list of extensions
	NSArray* directories = [NSArray arrayWithObject: directory];
	
	// An extension lives in a directory in one of the directories specified above
	NSEnumerator* dirEnum = [directories objectEnumerator];
	NSString* dir;
	
	while (dir = [dirEnum nextObject]) {
		// Get the contents of this directory
		NSArray* dirContents = [[NSFileManager defaultManager] directoryContentsAtPath: dir];
		
		if (!dirContents) continue;
		
		// Iterate through: add any directories found as an extension
		NSEnumerator* extnEnum = [dirContents objectEnumerator];
		NSString* extn;
		
		while (extn = [extnEnum nextObject]) {
			NSString* extnPath = [dir stringByAppendingPathComponent: extn];
			BOOL exists, isDir;
			
			exists = [[NSFileManager defaultManager] fileExistsAtPath: extnPath
														  isDirectory: &isDir];
			
			if (!exists || !isDir) continue;
			if ([extensions indexOfObjectIdenticalTo: extn] != NSNotFound) continue;
			
			[extensions addObject: extn];
			//[extensionPath setObject: extnPath
			//				  forKey: extn];
		}
	}
	
	// Sort them
	[extensions sortUsingFunction: stringCompare
						  context: nil];
	
	return extensions;
}

- (void) updateExtensions {
	NSMutableArray* inform6Extensions = [NSMutableArray array];
	NSMutableArray* naturalExtensions = [NSMutableArray array];
	
	// Only the extensions that we can actually edit are in this menu
	naturalExtensions = [self extensionsInDirectory: [[self directoriesToSearch: @"Extensions"] objectAtIndex: 0]];
	inform6Extensions = [self extensionsInDirectory: [[self directoriesToSearch: @"Inform 6 Extensions"] objectAtIndex: 0]];
	
	// Clear out the menu
	NSEnumerator* itemEnumerator = [[[[[extensionsMenu submenu] itemArray] copy] autorelease] objectEnumerator];
	NSMenuItem* item;
	
	while (item = [itemEnumerator nextObject]) {
		if ([item tag] != 0)
			[[extensionsMenu submenu] removeItem: item];
	}

	int itemPos = 0;
	
	// Natural Inform extensions go first
	NSEnumerator* extnEnum;
	NSString* extension;
	
	extnEnum = [naturalExtensions objectEnumerator];
	while (extension = [extnEnum nextObject]) {
		NSMenuItem* newItem = [[NSMenuItem alloc] init];
		
		[newItem setTag: 1];
		[newItem setTitle: extension];
		[newItem setTarget: self];
		[newItem setAction: @selector(openExtension:)];
		
		[[extensionsMenu submenu] insertItem: [newItem autorelease]
						   atIndex: itemPos++];
	}
	
	if ([naturalExtensions count] > 0) {
		[[extensionsMenu submenu] insertItem: [NSMenuItem separatorItem]
						   atIndex: itemPos++];		
	}
	
	// ... then Inform 6 extensions
	extnEnum = [inform6Extensions objectEnumerator];
	while (extension = [extnEnum nextObject]) {
		NSMenuItem* newItem = [[NSMenuItem alloc] init];
		
		[newItem setTag: 2];
		[newItem setTitle: extension];
		[newItem setTarget: self];
		[newItem setAction: @selector(openExtension:)];
		
		[[extensionsMenu submenu] insertItem: [newItem autorelease]
									 atIndex: itemPos++];
	}
	
	if ([inform6Extensions count] > 0) {
		[[extensionsMenu submenu] insertItem: [NSMenuItem separatorItem]
									 atIndex: itemPos++];		
	}
}

- (void) openExtension: (id) sender {
	NSString* extnDir = nil;
	
	switch ([sender tag]) {
		case 1:
			extnDir = [[self directoriesToSearch: @"Extensions"] objectAtIndex: 0];
			break;
			
		case 2:
			extnDir = [[self directoriesToSearch: @"Inform 6 Extensions"] objectAtIndex: 0];
			break;
	}
	
	if (!extnDir) return;
	
	// Open this extension
	NSDocument* newDoc = [[IFProject alloc] initWithContentsOfFile: [extnDir stringByAppendingPathComponent: [sender title]]
															ofType: @"Inform Extension Directory"];
	
	[[NSDocumentController sharedDocumentController] addDocument: [newDoc autorelease]];
	[newDoc makeWindowControllers];
	[newDoc showWindows];
}

@end
