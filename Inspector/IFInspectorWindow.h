//
//  IFInspectorWindow.h
//  Inform
//
//  Created by Andrew Hunter on Thu Apr 29 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "IFInspector.h"

@interface IFInspectorWindow : NSWindowController {
	NSMutableDictionary* inspectorDict;
	
	NSMutableArray* inspectors;
	NSMutableArray* inspectorViews;
	
	BOOL updating;
	
	// The main window
	BOOL newMainWindow;
	NSWindow* activeMainWindow;
	
	// Whether or not the main window should pop up when inspectors suddenly show up
	BOOL hidden;
	BOOL shouldBeShown;
}

// The shared instance
+ (IFInspectorWindow*) sharedInspectorWindow;

// Dealing with inspector views
- (void) addInspector: (IFInspector*) newInspector;

- (void) setInspectorState: (BOOL) shown
					forKey: (NSString*) key;

- (void) showInspector: (IFInspector*) inspector;
- (void) showInspectorWithKey: (NSString*) key;
- (void) hideInspector: (IFInspector*) inspector;
- (void) hideInspectorWithKey: (NSString*) key;

// Dealing with updates
- (void) updateInspectors;
- (NSWindow*) activeWindow;

// Status
- (BOOL) isHidden;

@end
