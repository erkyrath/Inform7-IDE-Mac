//
//  IFAppDelegate.h
//  Inform
//
//  Created by Andrew Hunter on Mon Aug 18 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

// Application delegate class

#import <Cocoa/Cocoa.h>


@interface IFAppDelegate : NSObject {
	BOOL haveWebkit;
	
	IBOutlet NSMenuItem* extensionsMenu;
}

+ (NSRunLoop*) mainRunLoop;
+ (BOOL)isWebKitAvailable;
- (BOOL)isWebKitAvailable;

- (IBAction) showInspectors: (id) sender;
- (IBAction) newHeaderFile: (id) sender;
- (IBAction) newInformFile: (id) sender;
- (IBAction) findInProject: (id) sender;

- (void) updateExtensions;
- (NSMutableArray*) extensionsInDirectory: (NSString*) directory;
- (NSArray*) directoriesToSearch: (NSString*) extensionSubdirectory;

@end
