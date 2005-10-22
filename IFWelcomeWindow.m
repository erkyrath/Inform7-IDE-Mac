//
//  IFWelcomeWindow.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 05/10/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFWelcomeWindow.h"


@implementation IFWelcomeWindow

// = Initialisation =

+ (IFWelcomeWindow*) sharedWelcomeWindow {
	static IFWelcomeWindow* sharedWindow = nil;
	
	if (sharedWindow == nil) {
		sharedWindow = [[IFWelcomeWindow alloc] initWithWindowNibName: @"Welcome"];
	}
	
	return sharedWindow;
}

+ (void) hideWelcomeWindow {
	[[[IFWelcomeWindow sharedWelcomeWindow] window] close];
}

- (id) initWithWindow: (NSWindow*) win {
	self = [super initWithWindow: win];
	
	if (self) {
	}
	
	return self;
}

- (void) windowDidLoad {
	// Set the background colour for this window to be the welcome background image
	NSColor* backgroundColor = [NSColor colorWithPatternImage: [NSImage imageNamed: @"Welcome Background"]];
	[[self window] setBackgroundColor: backgroundColor];
	
	// Center the window on whichever screen it will appear on
	NSRect winFrame = [[self window] frame];
	
	NSScreen* winScreen = [[self window] screen];
	NSRect screenFrame = [winScreen frame];
	
	winFrame.origin.x = (screenFrame.size.width - winFrame.size.width)/2 + screenFrame.origin.x;
	winFrame.origin.y = (screenFrame.size.height - winFrame.size.height)/2 + screenFrame.origin.y;
	
	[[self window] setFrame: winFrame
					display: NO];
	
	// Set the introduction text
	[introText setStringValue: [[NSBundle mainBundle] localizedStringForKey: @"Welcome Text" 
																	  value: @"(Oops, welcome text is missing)"
																	  table: nil]];
	
	// Window shouldn't 'float' above the other windows like most panels
	[[self window] setLevel: NSNormalWindowLevel];
}

// = Actions =

- (IBAction) openExistingProject: (id) sender {
	[NSApp sendAction: @selector(openDocument:)
				   to: nil 
				 from: self];
}

- (IBAction) createNewProject: (id) sender {
	[NSApp sendAction: @selector(newProject:)
				   to: nil 
				 from: self];
}

- (NSURL*) lastProject {
	// Retrieves the last .inform project opened (am assuming the most recent project is top of the list)
	NSArray* projectList = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
	
	NSEnumerator* projEnum = [projectList objectEnumerator];
	NSURL* result = nil;
	NSURL* projectURL;
	
	while (projectURL = [projEnum nextObject]) {
		// To simplify things, we only deal with file URLs
		if (![projectURL isFileURL]) continue;
		
		NSString* projectPath = [projectURL path];
		if (!projectPath) continue;
		
		// Must be a .inform project
		if ([[[projectPath pathExtension] lowercaseString] isEqualToString: @"inform"]) {
			result = projectURL;
			break;
		}
	}
	
	return result;
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification {
	if ([self lastProject] == nil) {
		[openLastProject setEnabled: NO];
	} else {
		[openLastProject setEnabled: YES];
	}
}

- (IBAction) openLastProject: (id) sender {
	// Slightly more involved: find the last .inform project that was opened, and open it again
	NSURL* lastProject = [self lastProject];
	if (lastProject == nil) return;
	
	NSDocumentController* docControl = [NSDocumentController sharedDocumentController];
	
	[docControl openDocumentWithContentsOfURL: lastProject
									  display: YES];
}

@end
