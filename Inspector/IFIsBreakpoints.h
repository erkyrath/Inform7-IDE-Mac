//
//  IFIsBreakpoints.h
//  Inform
//
//  Created by Andrew Hunter on 14/12/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFInspector.h"

#import "IFProject.h"
#import "IFProjectController.h"

// The inspector key for this window
extern NSString* IFIsBreakpointsInspector;

@interface IFIsBreakpoints : IFInspector {
	NSWindow* activeWin;
	IFProject* activeProject;
	IFProjectController* activeController;
	
	IBOutlet NSTableView* breakpointTable;
}

+ (IFIsBreakpoints*) sharedIFIsBreakpoints;

// Menu actions
- (IBAction) cut:    (id) sender;
- (IBAction) copy:   (id) sender;
- (IBAction) paste:  (id) sender;
- (IBAction) delete: (id) sender;

@end
