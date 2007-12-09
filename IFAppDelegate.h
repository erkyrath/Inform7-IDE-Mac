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
	
	NSMutableArray* extensionSources;				// Maps extension menu tags to source file names
	id<IFLeopardProtocol> leopard;					// The leopard extensions (if available)
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

- (void) updateExtensions;							// Updates extensions menu
- (NSMutableArray*) extensionsInDirectory: (NSString*) directory;		// (DEPRECATED) gets the list of extensions in a particular directory. Use the extension manager instead.
- (NSArray*) directoriesToSearch: (NSString*) extensionSubdirectory;	// (DEPRECATED) gets the list of directories to search for extensions. Use the extension manager instead.

- (id<IFLeopardProtocol>) leopard;					// The leopard extensions (if available)

@end
