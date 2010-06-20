//
//  IFSingleController.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/06/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFSingleFile.h"
#import "IFSingleController.h"
#import "IFWelcomeWindow.h"
#import "IFSharedContextMatcher.h"
#import "IFPreferences.h"
#import "IFExtensionsManager.h"
#import "IFAppDelegate.h"
#import "IFProjectController.h"

@interface IFSingleController(PrivateMethods)

- (void) showInstallPrompt: (id) sender;
- (void) hideInstallPrompt: (id) sender;

@end

@implementation IFSingleController

- (id) init {
	return [super initWithWindowNibName: @"SingleFile"];
}

- (id) initWithWindow: (NSWindow*) win {
	self = [super initWithWindow: win];
	
	if (self) {
	}
	
	return self;
}

- (void) dealloc {
	// Unset the view's text storage
	if (fileView != nil) {
		[[[self document] storage] removeLayoutManager: [fileView layoutManager]];
	}
	
	[super dealloc];
}

- (void)windowDidLoad {
	[IFWelcomeWindow hideWelcomeWindow];
	[self awakeFromNib];
}

- (void) awakeFromNib {
	// Set the window frame save name
	[self setWindowFrameAutosaveName: @"SingleFile"];
	
	// Set the matcher for the window
	// TODO: do different things depending on the file type
	[fileView setSyntaxDictionaryMatcher: [IFSharedContextMatcher matcherForInform7]];

	// Set the view's text appropriately
	[[fileView textStorage] removeLayoutManager: [fileView layoutManager]];
	[[[self document] storage] addLayoutManager: [fileView layoutManager]];
	
	[fileView setEditable: ![[self document] isReadOnly]];
	[fileView setBackgroundColor: [NSColor colorWithDeviceRed: 1.0 green: 1.0 blue: 0.9 alpha: 1.0]];
	
	// If this is an .i7x file then test to see if we're editing it from within the extensions directory or not
	NSString* filename = [[[self document] fileName] stringByStandardizingPath];
	BOOL isInstalled = YES;
	
	if ([[[filename pathExtension] lowercaseString] isEqualToString: @"i7x"]) {
		// Iterate through the i7 extension directories
		NSEnumerator* searchDirEnum = [[[IFExtensionsManager sharedNaturalInformExtensionsManager] extensionDirectories] objectEnumerator];
		NSString* searchDir;
		
		isInstalled = NO;
		
		while (searchDir = [searchDirEnum nextObject]) {
			// Need to apply the subdirectory to get the full path
			NSString* fullPath = [searchDir stringByAppendingPathComponent: [[IFExtensionsManager sharedNaturalInformExtensionsManager] subdirectory]];
			fullPath = [fullPath stringByStandardizingPath];
			
			if ([[filename lowercaseString] hasPrefix: [fullPath lowercaseString]]) {
				isInstalled = YES;
				break;
			}
		}
	}
	
	// If this file isn't installed, then create the 'install this file' prompt
	if (!isInstalled) {
		[self showInstallPrompt: self];
	}
}

// = Menu items =

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
	if ([menuItem action] == @selector(saveDocument:)) {
		return ![[self document] isReadOnly];
	}
	
	if ([menuItem action] == @selector(enableElasticTabs:)) {
		[menuItem setState: [[[self document] storage] elasticTabs]?NSOnState:NSOffState];
		return YES;
	}
	
	return YES;
}

- (void) enableElasticTabs: (id) sender {
	BOOL enabled = ![[[self document] storage] elasticTabs];

	[[[self document] storage] setElasticTabs: enabled];
	[[IFPreferences sharedPreferences] setElasticTabs: enabled];
}

// = Showing/hiding the installation prompt =

- (void) showInstallPrompt: (id) sender {
	// Get the view that the warning should be displayed in
	NSView* parentView = [mainView superview];

	// Do nothing if the view is already displayed (if it's displayed somewhere random this is going to go wrong)
	if ([installWarning superview] == parentView) {
		return;
	} else if ([installWarning superview] != nil) {
		[installWarning removeFromSuperview];
	}
	
	// Resize the main view
	NSRect warningFrame			= [installWarning frame];
	NSRect mainViewFrame		= [mainView frame];
	mainViewFrame.size.height	-= warningFrame.size.height;
	
	[mainView setFrame: mainViewFrame];
	
	// Position the warning view
	warningFrame.origin.x		= NSMinX(mainViewFrame);
	warningFrame.origin.y		= NSMaxY(mainViewFrame);
	warningFrame.size.width		= mainViewFrame.size.width;
	
	[parentView addSubview: installWarning];
	[installWarning setFrame: warningFrame];
}

- (void) hideInstallPrompt: (id) sender {
	// Get the view that the warning should be displayed in
	NSView* parentView = [mainView superview];
	
	// Do nothing if the view not already displayed (if it's displayed somewhere random this is going to go wrong)
	if ([installWarning superview] != parentView) {
		return;
	}
	
	// Remove it from the view
	[installWarning removeFromSuperview];
	
	// Resize the main view
	NSRect warningFrame			= [installWarning frame];
	NSRect mainViewFrame		= [mainView frame];
	mainViewFrame.size.height	+= warningFrame.size.height;
	
	[mainView setFrame: mainViewFrame];
}

// = Installer actions =

- (IBAction) installFile: (id) sender {
	// Install this extension
	NSString* finalPath = nil;
	if ([[IFExtensionsManager sharedNaturalInformExtensionsManager] addExtension: [[self document] fileName]
																	   finalPath: &finalPath]) {
		// Find the new path
		if (finalPath) {
			[[self document] setFileName: finalPath];
		} else {
			// Oops, TODO: show a warning
		}
		
		// Hide the install prompt
		[self hideInstallPrompt: self];
	} else {
		// Warn that the extension couldn't be installed
		NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"Failed to Install Extension"
																 value: @"Failed to Install Extension"
																 table: nil],
						  [[NSBundle mainBundle] localizedStringForKey: @"Cancel" value: @"Cancel" table: nil], nil, nil,
						  [self window],
						  nil,nil,nil,nil,
						  [[NSBundle mainBundle] localizedStringForKey: @"Failed to Install Extension Explanation"
																 value: nil
																 table: nil]);
	}
}

- (IBAction) cancelInstall: (id) sender {
	// Hide the install prompt
	[self hideInstallPrompt: self];
}

// = Highlighting lines =

- (void) highlightSourceFileLine: (int) line
						  inFile: (NSString*) file
                           style: (enum lineStyle) style {
    // Find out where the line is in the source view
    NSString* store = [[[self document] storage] string];
    int length = [store length];
	
    int x, lineno, linepos, lineLength;
    lineno = 1; linepos = 0;
	if (line > lineno)
	{
		for (x=0; x<length; x++) {
			unichar chr = [store characterAtIndex: x];
			
			if (chr == '\n' || chr == '\r') {
				unichar otherchar = chr == '\n'?'\r':'\n';
				
				lineno++;
				linepos = x + 1;
				
				// Deal with DOS line endings
				if (linepos < length && [store characterAtIndex: linepos] == otherchar) {
					x++; linepos++;
				}
				
				if (lineno == line) {
					break;
				}
			}
		}
	}
	
    if (lineno != line) {
        NSBeep(); // DOH!
        return;
    }
	
    lineLength = 0;
    for (x=0; x<length-linepos; x++) {
        if ([store characterAtIndex: x+linepos] == '\n'
			|| [store characterAtIndex: x+linepos] == '\r') {
            break;
        }
        lineLength++;
    }
	
	// Show the find indicator
	NSRange range = NSMakeRange(linepos, lineLength);
	[fileView setSelectedRange: NSMakeRange(linepos, 0)];
	[[[NSApp delegate] leopard] showFindIndicatorForRange: range
											   inTextView: fileView];
}
	
@end
