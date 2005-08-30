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

#import <GlkView/GlkView.h>

#import "IFSettingsView.h"
#import "IFSettingsController.h"
#import "IFTranscriptView.h"

#import "IFSyntaxStorage.h"
#import "IFProgress.h"

enum IFProjectPaneType {
    IFSourcePane = 1,
    IFErrorPane = 2,
    IFGamePane = 3,
    IFDocumentationPane = 4,
	IFIndexPane = 5,
	IFSkeinPane = 6,
	IFTranscriptPane = 8,
	
	IFUnknownPane = 256
};

@class IFProjectController;

@interface IFProjectPane : NSObject {

    // Outlets
    IBOutlet NSView* paneView;							// The main pane view
    IBOutlet IFCompilerController* compController;		// The compiler controller object

    IBOutlet NSTabView* tabView;						// The tab view
    IBOutlet NSTabViewItem* sourceView;					// Source pane
    IBOutlet NSTabViewItem* errorsView;					// Errors pane
    IBOutlet NSTabViewItem* gameTabView;				// Game pane
    IBOutlet NSTabViewItem* docTabView;					// Documentation pane
	IBOutlet NSTabViewItem* indexTabView;				// Index pane
	IBOutlet NSTabViewItem* skeinTabView;				// Skein pane
	IBOutlet NSTabViewItem* transcriptTabView;			// Transcript pane

    // Source
    IBOutlet NSTextView* sourceText;					// The view containing the source file
	
	NSTextStorage* textStorage;							// The current text storage being displayed
	
	// The documentation view
	WebView* wView;										// The web view that displays the documentation
    
    // The compiler (as for IFCompilerController.h)
    IBOutlet NSTextView* compilerResults;				// The compiler results view
    IBOutlet NSScrollView* resultScroller;				// The scroll view containing the compiler results

    IBOutlet NSSplitView*   splitView;					// The split view separating the compiler results from the errors view
    IBOutlet NSScrollView*  messageScroller;			// The compiler messages pane
    IBOutlet NSOutlineView* compilerMessages;			// The list of parsed compiler messages (Inform 6 only)

    // The game view
    IBOutlet NSView* gameView;							// The view that will contain the running game
    
	GlkView*		 gView;								// The Glk (glulxe) view
    ZoomView*        zView;								// The Z-Machinev view
    NSString*        gameToRun;							// The filename of the game to start
	ZoomSkeinItem*   pointToRunTo;						// The skein item to run the game until
	
	IFProgress*      gameRunningProgress;				// The progress indicator (how much we've compiled, how the game is running, etc)

    // Documentation
    IBOutlet NSView* docView;							// The view that will contain the documentation web view
	
	// The index view
	IBOutlet NSView* indexView;							// The view that will contain the various index web/text views
	BOOL indexAvailable;								// YES if the index tab should be active
	
	NSTabView* indexTabs;								// The tab view containing the various index files
	
	// The skein view
	IBOutlet ZoomSkeinView* skeinView;					// The skein view
	IBOutlet NSPopUpButton* skeinLabelButton;			// The button used to jump to different skein items
	int annotationCount;								// The number of annotations (labels)
	NSString* lastAnnotation;							// The last annotation skipped to using the label button

    // Settings
	IBOutlet IFSettingsView* settingsView;				// The settings view
	IBOutlet IFSettingsController* settingsController;	// The settings controller
	
	// The transcript view
	IBOutlet IFTranscriptView* transcriptView;			// The transcript view
	
    // Other variables
    NSMutableArray* sourceFiles;						// The set of available source files
    NSString*       openSourceFile;						// The filename of the presently displayed source file

    BOOL awake;											// YES if we've loaded from the nib and initialised properly
    IFProjectController* parent;						// The 'parent' project controller (not retained)
	
	BOOL setBreakpoint;									// YES if we are allowed to set breakpoints
}

+ (IFProjectPane*) standardPane;								// Create/load a project pane
+ (NSDictionary*) attributeForStyle: (IFSyntaxStyle) style;		// Retrieve the attributes to use for a certain syntax highlighting style

// Our controller
- (void) setController: (IFProjectController*) parent;			// Sets the project controller (once the nib has loaded and the project controller been set, we are considered 'awake')

// Dealing with the contents of the NIB file
- (NSView*) paneView;											// The main pane view
- (NSView*) activeView;											// The presently displayed pane
- (void) removeFromSuperview;									// Removes the pane from its superview

- (IFCompilerController*) compilerController;					// The compiler controller associated with this view

// Selecting the view
- (void) selectView: (enum IFProjectPaneType) pane;				// Changes the view displayed in this pane to the specified setting
- (enum IFProjectPaneType) currentView;							// Returns the currently displayed view (IFUnknownPane is a possibility for some views I haven't added code to check for)

// The source view
- (void) moveToLine: (int) line									// Scrolls the source view so that the given line/character to be visible
		  character: (int) chr;
- (void) moveToLine: (int) line;								// Scrolls the source view so that the given line to be visible
- (void) moveToLocation: (int) location;						// Scrolls the source view so that the given character index is visible
- (void) selectRange: (NSRange) range;							// Selects a range of characters in the source view

- (void) pasteSourceCode: (NSString*) sourceCode;				// Pastes in the given code at the current insertion position (replacing any selected code and updating the undo manager)

- (void) showSourceFile: (NSString*) file;						// Shows the source file with the given filename in the view
- (NSString*) currentFile;										// Returns the currently displayed filename
- (int) currentLine;											// Returns the line the cursor is currently on

- (void) updateHighlightedLines;								// Updates the temporary highlights (which display breakpoints, etc)

- (IFIntelFile*) currentIntelligence;							// The active IntelFile object for the current view (ie, the object that's dealing with auto-tabs, the dynamic index, etc)

// The game view
- (void) activateDebug;											// Notify that the next game run should be run with debugging on (breakpoints will be set)
- (void) startRunningGame: (NSString*) fileName;				// Starts running the game file with the given name in the game pane
- (void) stopRunningGame;										// Forcibly stops running the game
- (void) pauseRunningGame;										// Forcibly pauses the running game and enters the debugger

- (ZoomView*) zoomView;											// The zoom view associated with the currently running game (NULL if a GLK game is running)
- (GlkView*) glkView;											// The glk view associated with the currently running game (if applicable)
- (BOOL) isRunningGame;											// YES if a game is running

- (void) setPointToRunTo: (ZoomSkeinItem*) item;				// Sets the skein item to run to as soon as the game has started

// The index view
- (void) updateIndexView;										// Updates the index view with the current files in the index subdirectory

// Settings
- (void) updateSettings;										// Updates the settings views with their current values

// The documentation view
- (void) openURL: (NSURL*) url;									// Tells the documentation view to open a specific URL

// The skein view
- (ZoomSkeinView*) skeinView;									// The skein view
- (IBAction) skeinLabelSelected: (id) sender;					// The user has selected a skein item from the drop-down list (so we should scroll there)
- (void) skeinDidChange: (NSNotification*) not;					// Called by Zoom to notify that the skein has changed

// The transcript view
- (IFTranscriptView*) transcriptView;							// Returns the transcript view object associated with this pane
- (IFTranscriptLayout*) transcriptLayout;						// Returns the transcript layout object associated with this pane

- (IBAction) transcriptBlessAll: (id) sender;					// Causes, after a confirmation, all the items in the transcript to be blessed

// Breakpoints
- (IBAction) setBreakpoint: (id) sender;						// Sets a breakpoint at the current line in response to a menu selection
- (IBAction) deleteBreakpoint: (id) sender;						// Clears the breakpoint at the current line in response to a menu selection

@end
