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
#import "IFWelcomeWindow.h"
#import "IFFindController.h"
#import "IFMaintenanceTask.h"

#import "IFIsNotes.h"
#import "IFIsIndex.h"
#import "IFIsFiles.h"
#import "IFIsSkein.h"
#import "IFIsWatch.h"
#import "IFIsBreakpoints.h"
#import "IFIsSearch.h"

#import "Preferences/IFPreferenceController.h"
#import "Preferences/IFAuthorPreferences.h"
#import "Preferences/IFStylePreferences.h"
#import "Preferences/IFInspectorPreferences.h"
#import "Preferences/IFExtensionPreferences.h"
#import "Preferences/IFIntelligencePreferences.h"
#import "Preferences/IFAdvancedPreferences.h"

#import "IFNoDocProtocol.h"
#import "IFInformProtocol.h"
#import "IFWebUriProtocol.h"

#import "IFSettingsController.h"
#import "IFMiscSettings.h"
#import "IFOutputSettings.h"
#import "IFRandomSettings.h"
#import "IFCompilerOptions.h"
#import "IFLibrarySettings.h"
#import "IFDebugSettings.h"
#import "IFInform6Extensions.h"
#import "IFNaturalExtensions.h"

#import "IFSingleFile.h"
#import "IFSharedContextMatcher.h"
#import "IFContextMatchWindow.h"				// TODO: remove this
#import "IFPreferences.h"
#import "IFProject.h"

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

// Lex delegate function used to test the context matcher
- (BOOL) match: (NSArray*) match
	  inString: (NSString*) matchString
		 range: (NSRange) range {
	NSMutableString* description = [[@"" mutableCopy] autorelease];
	
	NSEnumerator* matchEnum = [match objectEnumerator];
	IFMatcherStructure* matchItem;
	while (matchItem = [matchEnum nextObject]) {
		[description appendFormat: @" %@", [matchItem title]];
	}
	
	NSLog(@"Matched '%@': %@", [matchString substringWithRange: range], description);
	
	return YES;
}

- (void) applicationWillFinishLaunching: (NSNotification*) not {
	mainRunLoop = [NSRunLoop currentRunLoop];
	
	haveWebkit = [[self class] isWebKitAvailable];
	
	// Ensure that the context matcher is immediately available
	[IFSharedContextMatcher matcherForInform7];
	
#if 0
	// Test the context matcher
	NSString* contextExample = @"Understand \"this\" as that.\n\nTable of something\n\n\"Multiline\nString\"\n\"String\"";
	[[IFSharedContextMatcher matcherForInform7] match: contextExample
										 withDelegate: self];
	
	NSLog(@"%@", [[IFSharedContextMatcher matcherForInform7] getContextAtPoint: 7
																	  inString: contextExample]);
	NSLog(@"%@", [[IFSharedContextMatcher matcherForInform7] getContextAtPoint: 7
																	  inString: @"\"[1234567]\""]);
	
	IFContextMatchWindow* testWindow = [[[IFContextMatchWindow alloc] init] autorelease];
	
	[testWindow setElements:  [[IFSharedContextMatcher matcherForInform7] getContextAtPoint: 7
																				   inString: contextExample]];
	[testWindow popupAtLocation: [NSEvent mouseLocation]
					   onScreen: [[NSScreen screens] objectAtIndex: 0]];
#endif
	
	// Load the leopard extensions if we're running on the right version of OS X
	if (NSAppKitVersionNumber >= 949) {
		NSBundle* leopardBundle = [NSBundle bundleWithPath: [[NSBundle mainBundle] pathForAuxiliaryExecutable: @"Inform-Leopard.bundle"]];
		[leopardBundle load];
		leopard = [[[leopardBundle principalClass] alloc] init];
	}
	
	if (haveWebkit) {
		// Register some custom URL handlers
		// [NSURLProtocol registerClass: [IFNoDocProtocol class]];
		[NSURLProtocol registerClass: [IFInformProtocol class]];
        [NSURLProtocol registerClass: [IFWebUriProtocol class]];
	}
	
	// Standard settings
	[IFSettingsController addStandardSettingsClass: [IFOutputSettings class]];
	[IFSettingsController addStandardSettingsClass: [IFRandomSettings class]];
	[IFSettingsController addStandardSettingsClass: [IFCompilerOptions class]];
	[IFSettingsController addStandardSettingsClass: [IFLibrarySettings class]];
	[IFSettingsController addStandardSettingsClass: [IFMiscSettings class]];
	[IFSettingsController addStandardSettingsClass: [IFInform6Extensions class]];
	
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
	[[IFPreferenceController sharedPreferenceController] addPreferencePane: [[[IFAuthorPreferences alloc] init] autorelease]];
	[[IFPreferenceController sharedPreferenceController] addPreferencePane: [[[IFIntelligencePreferences alloc] init] autorelease]];
	[[IFPreferenceController sharedPreferenceController] addPreferencePane: [[[IFStylePreferences alloc] init] autorelease]];
	// [[IFPreferenceController sharedPreferenceController] addPreferencePane: [[[IFInspectorPreferences alloc] init] autorelease]];
	//[[IFPreferenceController sharedPreferenceController] addPreferencePane: [[[IFExtensionPreferences alloc] init] autorelease]];

	[[IFPreferenceController sharedPreferenceController] addPreferencePane: [[[IFAdvancedPreferences alloc] init] autorelease]];

	// Finish setting up
	[self updateExtensions];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(updateExtensions)
												 name: IFExtensionsUpdatedNotification
											   object: nil];

	[NSURLProtocol registerClass: [IFInformProtocol class]];
}

- (BOOL) applicationShouldOpenUntitledFile: (NSApplication*) sender {
	[[IFWelcomeWindow sharedWelcomeWindow] showWindow: self];
	[[[IFWelcomeWindow sharedWelcomeWindow] window] orderFront: self];

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

// = Menu actions =

- (void) visitWebsite: (id) sender {
	// Get the URL
	NSURL* websiteUrl = [NSURL URLWithString: @"http://www.inform7.com"];
	
	// Visit it
	[[NSWorkspace sharedWorkspace] openURL: websiteUrl];
}

// = The extensions menu =

static NSInteger stringCompare(id a, id b, void* context) {
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
	while ([[extensionsMenu submenu] numberOfItems] > 0) {
		[[extensionsMenu submenu] removeItemAtIndex: 0];
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
	
	// Also add the built-in extension directories, so that these can be inspected (these are opened in a read-only mode)
	NSString* internalDir = [[NSBundle mainBundle] pathForResource: @"Extensions"
															ofType: @""
													   inDirectory: @"Inform7"];
	[validExtensionDirectories addObject: [[NSBundle mainBundle] pathForResource: @"Extensions"
																		  ofType: @""
																	 inDirectory: @"Inform7"]];

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

			// Work out if this is an internal extension
			BOOL isInternal = NO;
			if ([[sourceFile lowercaseString] hasPrefix: [internalDir lowercaseString]]) isInternal = YES;
			
			// Don't add files we can't write to
			if (![fileMgr isWritableFileAtPath: sourceFile] && !isInternal) continue;
			
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
			
			[newItem setTitle: [[sourceFile stringByDeletingPathExtension] lastPathComponent]];
			[newItem setTarget: self];
			[newItem setTag: [extensionSources count]];
			[newItem setAction: @selector(openExtension:)];
			
			if (isInternal) {
				NSAttributedString* attributedTitle = [[NSAttributedString alloc] initWithString: [[sourceFile stringByDeletingPathExtension] lastPathComponent]
																					  attributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSColor grayColor], NSForegroundColorAttributeName, nil]];
				[newItem setAttributedTitle: [attributedTitle autorelease]];
			}
			
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

// = The help menu =

- (IBAction) docIndex: (id) sender {
	// This is called if there is no project currently open: in this case, the help isn't really available as
	// it's dependent on the project window.
	NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"Help not yet available"
															 value: @"Help not yet available"
															 table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"Cancel"
															 value: @"Cancel"
															 table: nil],
					  nil, nil, nil, nil, nil, nil, nil,
					  [[NSBundle mainBundle] localizedStringForKey: @"Help not available description"
															 value: @"Help not available description"
															 table: nil]);
}

// = Installing extensions =

- (void) finishAddingExtensions: (NSArray*) filenames {
	// Add the files
	NSEnumerator* fileEnum = [filenames objectEnumerator];
	BOOL succeeded = YES;
	NSString* file;
	
	while (file = [fileEnum nextObject]) {
		succeeded = [[IFExtensionsManager sharedNaturalInformExtensionsManager] addExtension: file
																				   finalPath: nil];
		if (!succeeded) break;
	}	
	
	// Re-run the maintenance tasks
	NSString* compilerPath = [[NSBundle mainBundle] pathForResource: @"ni"
															 ofType: @""
														inDirectory: @"Compilers"];
	if (compilerPath != nil) {
		[[IFMaintenanceTask sharedMaintenanceTask] queueTask: compilerPath
											   withArguments: [NSArray arrayWithObjects: 
															   @"-census",
															   @"-rules",
															   [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"Inform7"] stringByAppendingPathComponent: @"Extensions"],
															   nil]];
	}
	
	// Report an error if we couldn't install the extension for some reason
	if (!succeeded) {
		[[NSRunLoop currentRunLoop] performSelector: @selector(failedToAddExtension:)
											 target: self
										   argument: nil
											  order: 64
											  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
	}
	
	// Update the extension list whatever happened
	[self updateExtensions];
}

- (IBAction) installExtension: (id) sender {
	// Present a panel for adding new extensions
	NSOpenPanel* panel;
	if (!openExtensionPanel) {
		openExtensionPanel = [[NSOpenPanel openPanel] retain];
	}
	panel = openExtensionPanel;
	
	[panel setAccessoryView: nil];
	[panel setCanChooseFiles: YES];
	[panel setCanChooseDirectories: NO];
	[panel setResolvesAliases: YES];
	[panel setAllowsMultipleSelection: YES];
	[panel setTitle: @"Add new Inform 7 Extension"];
	[panel setDelegate: self];
	
	[panel beginForDirectory: @"~"
						file: nil
					   types: nil
			modelessDelegate: self
			  didEndSelector: @selector(addNaturalExtensionPanelDidEnd:returnCode:contextInfo:)
				 contextInfo: @"Add new Inform 7 Extension"];
}

- (void) addNaturalExtensionPanelDidEnd: (NSOpenPanel*) sheet
							 returnCode: (int) returnCode
							contextInfo: (void*) contextInfo {
	[sheet setDelegate: nil];
	
	if (returnCode != NSOKButton) return;
	
	// Check to see if any of the files exist
	NSEnumerator* fileEnum = [[sheet filenames] objectEnumerator];
	NSString* file;
	BOOL exists = NO;
	
	while (file = [fileEnum nextObject]) {
		NSString* title;
		NSString* author;
		
		author = [[IFExtensionsManager sharedNaturalInformExtensionsManager] authorForNaturalInformExtension: file
																									   title: &title];
		
		if (author != nil) {
			NSArray* authorFiles = [[IFExtensionsManager sharedNaturalInformExtensionsManager] filesInExtensionWithName: author];
			
			NSEnumerator* extnEnum = [authorFiles objectEnumerator];
			title = [title lowercaseString];
			NSString* extn;
			
			while (extn = [extnEnum nextObject]) {
				if ([[[extn lastPathComponent] lowercaseString] isEqualToString: title]) {
					exists = YES;
					break;
				}
			}
		}
		
		if (exists) break;
	}
	
	if (exists) {
		// Ask for confirmation
		[[NSRunLoop currentRunLoop] performSelector: @selector(confirmExtensionOverwrite:)
											 target: self
										   argument: [[[sheet filenames] copy] autorelease]
											  order: 64
											  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
	} else {
		// Just add the extension
		[self finishAddingExtensions: [sheet filenames]];
	}
}

- (void) confirmExtensionOverwrite: (id) filenames {
	// Display a 'failed to add extension' alert sheet
	int overwrite = NSRunAlertPanel([[NSBundle mainBundle] localizedStringForKey: @"Overwrite Extension"
															 value: @"Overwrite Extension?"
															 table: nil],
					[[NSBundle mainBundle] localizedStringForKey: @"Overwrite Extension Explanation"
														   value: nil
														   table: nil],
					  [[NSBundle mainBundle] localizedStringForKey: @"Cancel" value: @"Cancel" table: nil], 
					  [[NSBundle mainBundle] localizedStringForKey: @"Replace" value: @"Replace" table: nil], nil,
					  nil);
	if (overwrite == NSAlertAlternateReturn) {
		[self finishAddingExtensions: filenames];
	}
}

- (void) overwriteConfirmation: (NSWindow *)sheet
					returnCode: (int) returnCode
				   contextInfo: (void*) filen {
	// User has clicked 'Replace' or 'Cancel' to the 'overwrite extensions' dialog
	NSArray* filenames = [(NSArray*)filen autorelease];
	
	if (returnCode == NSAlertAlternateReturn) {
		[self finishAddingExtensions: filenames];
	}
}

- (void) failedToAddExtension: (id) obj {
	// Display a 'failed to add extension' alert sheet
	NSRunAlertPanel([[NSBundle mainBundle] localizedStringForKey: @"Failed to Install Extension"
															 value: @"Failed to Install Extension"
															 table: nil],
					[[NSBundle mainBundle] localizedStringForKey: @"Failed to Install Extension Explanation"
														   value: nil
														   table: nil],
					[[NSBundle mainBundle] localizedStringForKey: @"Cancel" value: @"Cancel" table: nil], nil, nil);
}

// = Searching =

- (IBAction) showFind2: (id) sender {
	[[IFFindController sharedFindController] showWindow: self];
}

- (IBAction) findNext: (id) sender {
	[[IFFindController sharedFindController] findNext: self];
}

- (IBAction) findPrevious: (id) sender {
	[[IFFindController sharedFindController] findPrevious: self];
}

- (IBAction) useSelectionForFind: (id) sender {
	[[IFFindController sharedFindController] useSelectionForFind: self];
}

// = Leopard extensions =

- (id<IFLeopardProtocol>) leopard {
	return leopard;
}

- (void) setFrame: (NSRect) newFrame
		 ofWindow: (NSWindow*) window {
	if (leopard) {
		[leopard setFrame: newFrame
				 ofWindow: window];
	} else {
		[window setFrame: newFrame
				 display: YES];
	}
}

- (void) setFrame: (NSRect) frame
		   ofView: (NSView*) view {
	if (leopard) {
		[leopard setFrame: frame
				   ofView: view];
	} else {
		[view setFrame: frame];
	}
}

- (void) addView: (NSView*) newView
		  toView: (NSView*) superView {
	if (leopard) {
		[leopard addView: newView
				  toView: superView];
	} else {
		[superView addSubview: newView];
	}
}

- (void) removeView: (NSView*) view {
	if (leopard) {
		[leopard removeView: view];
	} else {
		[view removeFromSuperview];
	}
}

// = Termination =

- (void) applicationWillTerminate: (NSNotification*) not {
	// I'll be back
	
	if ([[IFPreferences sharedPreferences] cleanProjectOnClose]) {
		NSEnumerator* docEnum = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
		NSDocument* document;
		while (document = [docEnum nextObject]) {
			// If this document can clean itself up, then ask it to do so
			if ([document respondsToSelector: @selector(cleanOutUnnecessaryFiles:)] && ![document isDocumentEdited]) {
				[(id)document cleanOutUnnecessaryFiles: NO];
				[document saveDocument: self];
			}
		}
	}
}

- (NSMenuItem*) debugMenu {
	return debugMenu;
}

@end
