//
//  IFAppDelegate.h
//  Inform
//
//  Created by Andrew Hunter on Mon Aug 18 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

// Application delegate class

#import <Cocoa/Cocoa.h>

#import "IFLeopardProtocol.h"

@interface IFAppDelegate : NSObject {
	BOOL haveWebkit;								// YES if webkit is installed (NO otherwise; only really does anything on early 10.2 versions, and we don't support them any more)
	
	IBOutlet NSMenuItem* extensionsMenu;			// The 'Open Extension' menu
	IBOutlet NSMenuItem* debugMenu;					// The Debug menu
	
	NSMutableArray* extensionSources;				// Maps extension menu tags to source file names
	id<IFLeopardProtocol> leopard;					// The leopard extensions (if available)
	
	NSOpenPanel* openExtensionPanel;				// The 'open extension' panel
}

+ (NSRunLoop*) mainRunLoop;							// Retrieves the runloop used by the main thread (Cocoa sometimes calls our callbacks from a sooper-sekrit bonus thread, causing pain if we don't use this)
+ (BOOL)isWebKitAvailable;							// YES if WebKit is around
- (BOOL)isWebKitAvailable;							// YES if WebKit is around

- (IBAction) showInspectors: (id) sender;			// Displays/hides the inspector window
- (IBAction) newHeaderFile: (id) sender;			// Creates a new .h file (in a new window)
- (IBAction) newInformFile: (id) sender;			// Creates a new .inf file (in a new window)
- (IBAction) findInProject: (id) sender;			// (UNUSED) opens the find inspector. Unused because I can't make the field key (as the inspectors are becomeKeyIfNeeded)
- (IBAction) showPreferences: (id) sender;			// Shows the preferences window
- (IBAction) docIndex: (id) sender;					// Displays an error about not being able to show help yet

- (IBAction) showFind2: (id) sender;				// Shows the 'new' find dialog
- (IBAction) findNext: (id) sender;					// 'Find next'
- (IBAction) findPrevious: (id) sender;				// 'Find previous'
- (IBAction) useSelectionForFind: (id) sender;		// 'Use selection for find'

- (void) updateExtensions;							// Updates extensions menu
- (NSMutableArray*) extensionsInDirectory: (NSString*) directory;		// (DEPRECATED) gets the list of extensions in a particular directory. Use the extension manager instead.
- (NSArray*) directoriesToSearch: (NSString*) extensionSubdirectory;	// (DEPRECATED) gets the list of directories to search for extensions. Use the extension manager instead.

- (NSMenuItem*) debugMenu;							// The Debug menu
- (id<IFLeopardProtocol>) leopard;					// The leopard extensions (if available)
- (void) setFrame: (NSRect) newFrame				// Sets the frame of the specified window (with animation on leopard)
		 ofWindow: (NSWindow*) window;
- (void) setFrame: (NSRect) frame					// Sets the frame of the specified view to the specified size (with animation on leopard)
		   ofView: (NSView*) view;
- (void) addView: (NSView*) newView					// Adds the specified view to the given subview (with animation on leopard)
		  toView: (NSView*) superView;
- (void) removeView: (NSView*) view;				// Removes the specified view from its superview (with animation on leopard)

@end
