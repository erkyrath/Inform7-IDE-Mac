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

// Dealing with updates
- (void) updateInspectors;

// Status
- (BOOL) isHidden;

@end
