//
//  IFIsWatch.h
//  Inform
//
//  Created by Andrew Hunter on 11/12/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFInspector.h"

#import "IFProject.h"
#import "IFProjectController.h"

// The inspector key for this window
extern NSString* IFIsWatchInspector;

// 'Special' evaluation values
enum {
	IFEvalError  = 0xffffffff,
	IFEvalNoGame = 0xfffffffe
};

//
// Inspector that provides the interface to watch or evaluate expressions
//
// Unlike 'real' debuggers, Zoom can't break on watchpoints without seriously sacrificing performance, so
// we don't do that.
//
@interface IFIsWatch : IFInspector {
	IBOutlet NSTextField* expression;
	IBOutlet NSTextField* expressionResult;
	IBOutlet NSTableView* watchTable;

	NSWindow* activeWin;
	IFProject* activeProject;
	IFProjectController* activeController;
}

+ (IFIsWatch*) sharedIFIsWatch;

- (IBAction) expressionChanged: (id) sender;

- (unsigned) evaluateExpression: (NSString*) expression;
- (void) refreshExpressions;

@end
