//
//  IFProjectPane.h
//  Inform
//
//  Created by Andrew Hunter on Wed Sep 10 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IFCompilerController.h"
#import "IFSyntaxHighlighter.h"

#import <ZoomView/ZoomView.h>


enum IFProjectPaneType {
    IFSourcePane = 1,
    IFErrorPane = 2,
    IFGamePane = 3,
    IFDocumentationPane = 4
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

    // Source
    IBOutlet NSTextView* sourceText;

    // The compiler (as for IFCompilerController.h)
    IBOutlet NSTextView* compilerResults;
    IBOutlet NSScrollView* resultScroller;

    IBOutlet NSSplitView*   splitView;
    IBOutlet NSScrollView*  messageScroller;
    IBOutlet NSOutlineView* compilerMessages;

    // The various status displays
    IBOutlet NSPopUpButton* sourcePopup;
    IBOutlet NSButton*      lineButton;
    IBOutlet NSButton*      columnButton;

    // The game view
    IBOutlet NSView* gameView;
    
    ZoomView*        zView;
    NSString*        gameToRun;

    // Documentation
    IBOutlet NSView* docView;

    // Settings
    IBOutlet NSScrollView* settingsScroller;
    IBOutlet NSMatrix* zmachineVersion;

    IBOutlet NSPopUpButton* compilerVersion;
    IBOutlet NSButton* naturalInform;

    IBOutlet NSPopUpButton* libraryVersion;

    IBOutlet NSButton* strictMode;
    IBOutlet NSButton* infixMode;
    IBOutlet NSButton* debugMode;

    IBOutlet NSButton* donotCompileNaturalInform;
    IBOutlet NSButton* runBuildSh;
    IBOutlet NSButton* runLoudly;

    // Other variables
    NSMutableArray* sourceFiles;

    BOOL awake;
    IFProjectController* parent;
    
    NSTimer*             highlighterTicker;
    IFSyntaxHighlighter* highlighter;
    
    NSRange              remainingFileToProcess;
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
- (void) updateFiles;
- (void) moveToLine: (int) line;

// The game view
- (void) startRunningGame: (NSString*) fileName;
- (void) stopRunningGame;

// Settings
- (void) updateSettings;
- (IBAction) settingsHaveChanged: (id) sender;

// Syntax highlighting
- (void) highlightEntireFile;
- (void) highlightRange: (NSRange) charRange;

@end
