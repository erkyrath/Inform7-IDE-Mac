//
//  IFProjectPane.h
//  Inform
//
//  Created by Andrew Hunter on Wed Sep 10 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "IFCompilerController.h"
#import "IFSyntaxHighlighter.h"

#import <ZoomView/ZoomView.h>
#import <ZoomView/ZoomSkeinView.h>

#import "IFSettingsView.h"
#import "IFSettingsController.h"

enum IFProjectPaneType {
    IFSourcePane = 1,
    IFErrorPane = 2,
    IFGamePane = 3,
    IFDocumentationPane = 4,
	IFIndexPane = 5
};

@class IFProjectController;

@interface IFProjectPane : NSObject {

    // Outlets
    IBOutlet NSView* paneView;
    IBOutlet IFCompilerController* compController;

    IBOutlet NSTabView* tabView;
    IBOutlet NSTabViewItem* sourceView;
    IBOutlet NSTabViewItem* errorsView;
    IBOutlet NSTabViewItem* gameTabView;
    IBOutlet NSTabViewItem* docTabView;
	IBOutlet NSTabViewItem* indexTabView;

    // Source
    IBOutlet NSTextView* sourceText;
	
	NSTextStorage* textStorage;
	
	// The documentation view
	WebView* wView;
    
    // The compiler (as for IFCompilerController.h)
    IBOutlet NSTextView* compilerResults;
    IBOutlet NSScrollView* resultScroller;

    IBOutlet NSSplitView*   splitView;
    IBOutlet NSScrollView*  messageScroller;
    IBOutlet NSOutlineView* compilerMessages;

    // The game view
    IBOutlet NSView* gameView;
    
    ZoomView*        zView;
    NSString*        gameToRun;
	ZoomSkeinItem*   pointToRunTo;

    // Documentation
    IBOutlet NSView* docView;
	
	// The index view
	IBOutlet NSView* indexView;
	BOOL indexAvailable;
	
	NSTabView* indexTabs;
	
	// The skein view
	IBOutlet ZoomSkeinView* skeinView;

    // Settings
	IBOutlet IFSettingsView* settingsView;
	IBOutlet IFSettingsController* settingsController;
	
    // Other variables
    NSMutableArray* sourceFiles;
    NSString*       openSourceFile;

    BOOL awake;
    IFProjectController* parent;
    
    NSTimer*             highlighterTicker;
    IFSyntaxHighlighter* highlighter;
    
    NSRange              remainingFileToProcess;
	
	BOOL setBreakpoint;
}

+ (IFProjectPane*) standardPane;

// Our controller
- (void) setController: (IFProjectController*) parent;

// Dealing with the contents of the NIB file
- (NSView*) paneView;
- (NSView*) activeView;
- (void) removeFromSuperview;

- (IFCompilerController*) compilerController;

// Selecting the view
- (void) selectView: (enum IFProjectPaneType) pane;
- (enum IFProjectPaneType) currentView;

// The source view
- (void) moveToLine: (int) line;

- (void) updateHighlightedLines;

- (void) showSourceFile: (NSString*) file;
- (NSString*) currentFile;

// The game view
- (void) activateDebug;
- (void) startRunningGame: (NSString*) fileName;
- (void) stopRunningGame;
- (void) pauseRunningGame;

- (ZoomView*) zoomView;
- (BOOL) isRunningGame;

- (void) setPointToRunTo: (ZoomSkeinItem*) item;

// The index view
- (void) updateIndexView;

// Settings
- (void) updateSettings;

// Syntax highlighting
- (void) selectHighlighterForCurrentFile;
- (void) highlightEntireFile;
- (void) highlightRange: (NSRange) charRange;

// The documentation view
- (void) openURL: (NSURL*) url;

@end
