//
//  IFInspector.h
//  Inform
//
//  Created by Andrew Hunter on Thu Apr 29 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IFInspectorWindow;

@interface IFInspector : NSObject {
	IBOutlet NSView* inspectorView;
	IBOutlet id delegate;
	
	NSResponder* owner;
	
	NSString* title;
	BOOL expanded;
	BOOL gotWindow;
	
	IFInspectorWindow* inspectorWin;
}

// Setting the view to use
- (void) setInspectorView: (NSView*) view;
- (NSView*) inspectorView;

// Notifications from the inspector controller
- (void) inspectWindow: (NSWindow*) newWindow;

// Inspector details
- (void) setTitle: (NSString*) title;
- (NSString*) title;

- (void) setExpanded: (BOOL) expanded;
- (BOOL) expanded;

- (BOOL) available;

// The controller
- (void) setInspectorWindow: (IFInspectorWindow*) window;

@end

// (IFInspectorWindow #imports us, and has priority)
#import "IFInspectorWindow.h"
