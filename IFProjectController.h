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
#import "IFProgress.h"

#import "IFIntelFile.h"

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
	IBOutlet NSTextField* statusInfo;
	IBOutlet NSProgressIndicator* progress;
    
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
	
	// The last file selected
	NSString* lastFilename;
	
	// Debugging
	BOOL waitingAtBreakpoint;
	
	// Policy delegates
	IFProjectPolicy* generalPolicy;
	IFProjectPolicy* docPolicy;
	
	// Progress indicators
	BOOL progressing;
	int  progressNum;
	NSMutableArray* progressIndicators;
}

- (void) layoutPanes;

- (IFProjectPane*) sourcePane;
- (IFProjectPane*) gamePane;
- (IFProjectPane*) auxPane;
- (IFProjectPane*) transcriptPane;

// Communication from the containing panes (maybe other uses, too - scripting?)
- (BOOL) selectSourceFile: (NSString*) fileName;
- (void) moveToSourceFilePosition: (int) location;
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
- (IFIntelFile*) currentIntelligence;

- (IBAction) addNewFile: (id) sender;

// Debugging
- (void) updatedBreakpoints: (NSNotification*) not;
- (void) hitBreakpoint: (int) pc;

// Policy delegates
- (IFProjectPolicy*) generalPolicy;
- (IFProjectPolicy*) docPolicy;

// Displaying progress
- (void) addProgressIndicator: (IFProgress*) indicator;
- (void) removeProgressIndicator: (IFProgress*) indicator;

@end
