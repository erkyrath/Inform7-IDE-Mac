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

#import <ZoomView/ZoomView.h>
#import <ZoomView/ZoomSkeinView.h>

#import "IFSettingsView.h"
#import "IFSettingsController.h"
#import "IFTranscriptController.h"

#import "IFSyntaxStorage.h"

enum IFProjectPaneType {
    IFSourcePane = 1,
    IFErrorPane = 2,
    IFGamePane = 3,
    IFDocumentationPane = 4,
	IFIndexPane = 5,
	IFTranscriptPane = 8
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
	IBOutlet NSTabViewItem* transcriptTabView;

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
	IBOutlet NSPopUpButton* skeinLabelButton;
	int annotationCount;
	NSString* lastAnnotation;

    // Settings
	IBOutlet IFSettingsView* settingsView;
	IBOutlet IFSettingsController* settingsController;
	
	// The transcript view
	IBOutlet IFTranscriptController* transcriptController;
	
    // Other variables
    NSMutableArray* sourceFiles;
    NSString*       openSourceFile;

    BOOL awake;
    IFProjectController* parent;
	
	BOOL setBreakpoint;
}

+ (IFProjectPane*) standardPane;
+ (NSDictionary*) attributeForStyle: (IFSyntaxStyle) style;

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

- (void) showSourceFile: (NSString*) file;
- (NSString*) currentFile;

- (void) updateHighlightedLines;

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

// The documentation view
- (void) openURL: (NSURL*) url;

// The skein view
- (IBAction) skeinLabelSelected: (id) sender;
- (void) skeinDidChange: (NSNotification*) not;

// The transcript view
- (IFTranscriptController*) transcriptController;

@end
