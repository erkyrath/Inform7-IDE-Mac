//
//  IFProjectController.h
//  Inform
//
//  Created by Andrew Hunter on Wed Aug 27 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <ZoomView/ZoomView.h>

#import "IFProjectPolicy.h"

enum lineStyle {
    IFLineStyleNeutral = 0,
    
	// Temporary highlights
	IFLineStyle_Temporary = 1, // Dummy style

    IFLineStyleWarning = 1,// Temp highlight
    IFLineStyleError,      // Temp highlight
    IFLineStyleFatalError, // Temp highlight
	IFLineStyleHighlight,
	
	IFLineStyle_LastTemporary,

	// 'Permanent highlights'
	IFLineStyle_Permanent = 0xfff, // Dummy style

	// Debugging
    IFLineStyleBreakpoint,
    IFLineStyleExecutionPoint
};

@class IFProjectPane;
@interface IFProjectController : NSWindowController {
    IBOutlet NSView* panesView;
    
    // The toolbar
    NSToolbar* toolbar;

    // The collection of panes
    NSMutableArray* projectPanes;
    NSMutableArray* splitViews;
	
	// Highlighting (indexed by file)
	NSMutableDictionary* lineHighlighting;
	BOOL temporaryHighlights;

    // Action after a compile has finished
    SEL compileFinishedAction;
	
	// Debugging
	BOOL waitingAtBreakpoint;
	
	// Policy delegates
	IFProjectPolicy* generalPolicy;
	IFProjectPolicy* docPolicy;
}

- (void) layoutPanes;

- (IFProjectPane*) sourcePane;
- (IFProjectPane*) gamePane;
- (IFProjectPane*) auxPane;

// Communication from the containing panes (maybe other uses, too - scripting?)
- (BOOL) selectSourceFile: (NSString*) fileName;
- (void) moveToSourceFileLine: (int) line;
- (NSString*) selectedSourceFile;

- (void) highlightSourceFileLine: (int) line
						  inFile: (NSString*) file;
- (void) highlightSourceFileLine: (int) line
						  inFile: (NSString*) file
                           style: (enum lineStyle) style;
- (NSArray*) highlightsForFile: (NSString*) file;

- (void) removeHighlightsInFile: (NSString*) file
						ofStyle: (enum lineStyle) style;
- (void) removeHighlightsOfStyle: (enum lineStyle) style;
- (void) removeAllTemporaryHighlights;

- (NSString*) pathToIndexFile;

- (IBAction) addNewFile: (id) sender;

// Debugging
- (void) hitBreakpoint: (int) pc;

// Policy delegates
- (IFProjectPolicy*) generalPolicy;
- (IFProjectPolicy*) docPolicy;

@end
