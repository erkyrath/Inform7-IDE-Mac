//
//  IFIsWatch.m
//  Inform
//
//  Created by Andrew Hunter on 11/12/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFIsWatch.h"

#import "IFProjectPane.h"

NSString* IFIsWatchInspector = @"IFIsWatchInspector";

@implementation IFIsWatch

// = Initialisation =

+ (IFIsWatch*) sharedIFIsWatch {
	static IFIsWatch* sharedWatch = nil;
	
	if (!sharedWatch) {
		sharedWatch = [[[self class] alloc] init];
	}
	
	return sharedWatch;
}

- (id) init {
	self = [super init];
	
	if (self) {
		[NSBundle loadNibNamed: @"WatchInspector"
						 owner: self];
		[self setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Inspector Watch"
															   value: @"Watch"
															   table: nil]];
	}
	
	return self;
}

// = Inspector methods =

- (NSString*) key {
	return IFIsWatchInspector;
}

- (void) inspectWindow: (NSWindow*) newWindow {
	activeWin = newWindow;
	
	if (activeProject) {
		// Need to remove the layout manager to prevent potential weirdness
		[activeProject release];
	}
	activeController = nil;
	activeProject = nil;
	
	// Get the active project, if applicable
	NSWindowController* control = [newWindow windowController];
	
	if (control != nil && [control isKindOfClass: [IFProjectController class]]) {
		activeController = (IFProjectController*)control;
		activeProject = [[control document] retain];

		[self refreshExpressions];
	}
}

- (BOOL) available {
	return activeProject==nil?NO:YES;
}

// = Evaluating things =

- (unsigned) evaluateExpression: (NSString*) expr {
	// Find the ZoomView, if there is one
	ZoomView* zView = [[activeController gamePane] zoomView];
	
	if (zView == nil) return IFEvalNoGame;
	
	// ... then get the zMachine
	NSObject<ZMachine>* zMachine = [zView zMachine];
	
	if (zMachine == nil) return IFEvalNoGame;
	
	// ... now we can evaluate the expression
	int shortAnswer = [zMachine evaluateExpression: expr];
	if (shortAnswer ==  0x7fffffff) return IFEvalError;

	unsigned answer = shortAnswer&0xffff;		// Answers are 16-bit only
		
	// OK, we've got the answer
	return answer;
}

- (NSString*) numericValueForAnswer: (unsigned) answer {
	if (answer >= 0x80000000) {
		if (answer == IFEvalNoGame) {
			return @"## No game running";
		} else {
			return @"## Error";
		}
	} else {
		int signedAnswer = answer;
		
		if (signedAnswer >= 0x8000) signedAnswer |= 0xffff0000;
		
		return [NSString stringWithFormat: @"%i ($%04x)", signedAnswer, answer];
	}
}

- (NSString*) textualValueForExpression: (unsigned) answer {
	// IMPLEMENT ME
	return [self numericValueForAnswer: answer];
}

- (void) refreshExpressions {
	// The 'top' expression
	unsigned topAnswer = [self evaluateExpression: [expression stringValue]];
	[expressionResult setStringValue: [self numericValueForAnswer: topAnswer]];
}

// = The standard evaluator =

- (IBAction) expressionChanged: (id) sender {
	[self refreshExpressions];
}

// = Tableview delegate and data source =

@end
