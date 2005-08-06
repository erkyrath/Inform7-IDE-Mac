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
#import "IFExtensionsManager.h"

#import "IFIsNotes.h"
#import "IFIsIndex.h"
#import "IFIsFiles.h"
#import "IFIsSkein.h"
#import "IFIsWatch.h"
#import "IFIsBreakpoints.h"
#import "IFIsSearch.h"

#import "Preferences/IFPreferenceController.h"
#import "Preferences/IFStylePreferences.h"
#import "Preferences/IFInspectorPreferences.h"
#import "Preferences/IFExtensionPreferences.h"
#import "Preferences/IFIntelligencePreferences.h"

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

#import "IFSingleFile.h"

#import <ZoomView/ZoomSkein.h>
#import <ZoomView/ZoomSkeinView.h>

#import <GlkView/GlkHub.h>

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
	
	// Glk hub
	[[GlkHub sharedGlkHub] setRandomHubCookie];
	[[GlkHub sharedGlkHub] setHubName: @"GlkInform"];
}

- (void) applicationDidFinishLaunching: (NSNotification*) not {	
	// The standard inspectors
	[[IFInspectorWindow sharedInspectorWindow] addInspector: [IFIsFiles sharedIFIsFiles]];
	[[IFInspectorWindow sharedInspectorWindow] addInspector: [IFIsNotes sharedIFIsNotes]];
	[[IFInspectorWindow sharedInspectorWindow] addInspector: [IFIsIndex sharedIFIsIndex]];
	[[IFInspectorWindow sharedInspectorWindow] addInspector: [IFIsSkein sharedIFIsSkein]];
	[[IFInspectorWindow sharedInspectorWindow] addInspector: [IFIsWatch sharedIFIsWatch]];
	[[IFInspectorWindow sharedInspectorWindow] addInspector: [IFIsBreakpoints sharedIFIsBreakpoints]];
	[[IFInspectorWindow sharedInspectorWindow] addInspector: [IFIsSearch sharedIFIsSearch]];
	
	// The standard preferences
	[[IFPreferenceController sharedPreferenceController] addPreferencePane: [[[IFStylePreferences alloc] init] autorelease]];
	[[IFPreferenceController sharedPreferenceController] addPreferencePane: [[[IFInspectorPreferences alloc] init] autorelease]];
	[[IFPreferenceController sharedPreferenceController] addPreferencePane: [[[IFExtensionPreferences alloc] init] autorelease]];
	[[IFPreferenceController sharedPreferenceController] addPreferencePane: [[[IFIntelligencePreferences alloc] init] autorelease]];
	
	// Finish setting up
	[self updateExtensions];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(updateExtensions)
												 name: IFExtensionsUpdatedNotification
											   object: nil];

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
	
	// Used to use a while loop: don't any more - only want to check the first directory
	libPath = [libEnum nextObject];
	{
		NSString* extnPath = [[libPath stringByAppendingPathComponent: @"Inform"] stringByAppendingPathComponent: extensionSubdirectory];
		BOOL isDir;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: extnPath
												 isDirectory: &isDir]) {
			if (isDir) [libraryDirectories addObject: extnPath];
		}
	}
	
	// If we're talking about the natural extensions, use the ones in our own directory (SPECIAL CASE)
	if ([extensionSubdirectory isEqualToString: @"Extensions"]) {
		NSString* bundleResources = [[NSBundle mainBundle] resourcePath];
		NSString* internalExtensions = [[bundleResources stringByAppendingPathComponent: @"Inform7"] stringByAppendingPathComponent: @"Extensions"];
		
		[libraryDirectories addObject: internalExtensions];
	}
	
	if ([libraryDirectories count] <= 0) return nil;
	return libraryDirectories;
}

- (NSMutableArray*) extensionsInDirectory: (NSString*) directory {
	if (directory == nil) return nil;
	
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
	// Clear out the menu
	NSEnumerator* itemEnumerator = [[[[[extensionsMenu submenu] itemArray] copy] autorelease] objectEnumerator];
	NSMenuItem* item;
	
	while (item = [itemEnumerator nextObject]) {
		if ([item tag] != 0)
			[[extensionsMenu submenu] removeItem: item];
	}
	
	// Clear out the list of extension tags
	[extensionSources release];
	extensionSources = [[NSMutableArray alloc] init];

	// Work out a list of directories we're allowed to take extensions from
	NSMutableArray* validExtensionDirectories = [NSMutableArray array];
	NSArray* libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	
	NSEnumerator* libEnum = [libraries objectEnumerator];
	NSString* libDirectory;
	while (libDirectory = [libEnum nextObject]) {
		[validExtensionDirectories addObject: [[[libDirectory stringByAppendingPathComponent: @"Inform"] stringByAppendingPathComponent: @"Extensions"] stringByStandardizingPath]];
	}

	// Generate the extensions menu
	// Previous versions listed i6 extensions as well, but we're not doing that any more
	IFExtensionsManager* mgr = [IFExtensionsManager sharedNaturalInformExtensionsManager];
	
	NSArray* extns = [mgr availableExtensions];
	NSEnumerator* extnEnum = [extns objectEnumerator];
	NSString* extn;
	
	int extnPos = 0;
	
	NSFileManager* fileMgr = [NSFileManager defaultManager];
	
	while (extn = [extnEnum nextObject]) {
		// Create a menu for the source files in the extension directory
		NSMenu* extnMenu = [[NSMenu alloc] init];
		
		// Add each source file to the submenu
		NSArray* extnContents = [mgr sourceFilesInExtensionWithName: extn];
		NSEnumerator* contentEnum = [extnContents objectEnumerator];
		NSString* sourceFile;
		
		int itemPos = 0;
		while (sourceFile = [contentEnum nextObject]) {
			sourceFile = [sourceFile stringByStandardizingPath];
			
			// Don't add files we can't write to
			if (![fileMgr isWritableFileAtPath: sourceFile]) continue;
			
			// Don't add files that aren't in a directory in the list of valid extension directories
			NSEnumerator* dirEnum = [validExtensionDirectories objectEnumerator];
			NSString* validDir;
			BOOL isInValidDir = NO;
			while (validDir = [dirEnum nextObject]) {
				if (![sourceFile length] < [validDir length] &&
					[[sourceFile substringToIndex: [validDir length]] caseInsensitiveCompare: validDir] == 0) {
					isInValidDir = YES;
					break;
				}
			}
			
			if (!isInValidDir) continue;
			
			// Add a menu entry for this source file
			NSMenuItem* newItem = [[NSMenuItem alloc] init];
			
			[newItem setTitle: [sourceFile lastPathComponent]];
			[newItem setTarget: self];
			[newItem setTag: [extensionSources count]];
			[newItem setAction: @selector(openExtension:)];
			
			[extnMenu insertItem: [newItem autorelease]
						 atIndex: itemPos++];
			
			// Add an entry in the extensionSources array so we know which file this refers to
			[extensionSources addObject: [[sourceFile copy] autorelease]];
		}
		
		if (itemPos > 0) {
			// Add a submenu for this extension
			NSMenuItem* extnItem = [[NSMenuItem alloc] init];
			
			[extnItem setTitle: extn];
			[extnItem setSubmenu: [extnMenu autorelease]];
			
			[[extensionsMenu submenu] insertItem: [extnItem autorelease]
										 atIndex: extnPos++];
		}
	}
}

- (void) openExtension: (id) sender {
	// Get the tag, and from that, get the source file we want to open
	int tag = [sender tag];
	NSString* sourceFilename = [extensionSources objectAtIndex: tag];
	
	// Open the file
	NSDocument* newDoc = [[IFSingleFile alloc] initWithContentsOfFile: sourceFilename
															   ofType: @"Inform 7 extension"];
	
	[[NSDocumentController sharedDocumentController] addDocument: [newDoc autorelease]];
	[newDoc makeWindowControllers];
	[newDoc showWindows];	
}

// = Some misc actions =

- (IBAction) showPreferences: (id) sender {
	[[IFPreferenceController sharedPreferenceController] showWindow: self];
}

- (IBAction) findInProject: (id) sender {
	// NOT USED AT THE MOMENT
	// Apple makes it impossible to force the inspector window to become key, so we can't programatically select
	// the 'Search' box. Very ANNOYING.
	
	[self showInspectors: self];

	// Open up the 'Search' inspector ready for action, make it key
	[[IFInspectorWindow sharedInspectorWindow] showInspectorWithKey: IFIsSearchInspector];
	
	[[IFIsSearch sharedIFIsSearch] makeSearchKey: self];
}

@end
