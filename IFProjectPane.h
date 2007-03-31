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

#import "IFPage.h"
#import "IFSourcePage.h"

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

enum IFIndexTabType {
	IFIndexActions = 1,
	IFIndexContents = 2,
	IFIndexKinds = 3,
	IFIndexPhrasebook = 4,
	IFIndexRules = 5,
	IFIndexScenes = 6,
	IFIndexWorld = 7
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
	
	// The pages
	NSMutableArray* pages;								// Pages being managed by this control
	
	// The source page
	IFSourcePage* sourcePage;							// The source page
	
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
	int indexMachineSelection;							// A reference count - number of 'machine' operations that might be affecting the index tab selection
	NSString* lastUserTab;								// The last tab selected by a user action
	
	// The skein view
	IBOutlet ZoomSkeinView* skeinView;					// The skein view
	IBOutlet NSPopUpButton* skeinLabelButton;			// The button used to jump to different skein items
	int annotationCount;								// The number of annotations (labels)
	NSString* lastAnnotation;							// The last annotation skipped to using the label button
	
	IBOutlet NSWindow* pruneSkein;						// The 'prune skein' window
	IBOutlet NSSlider* pruneAmount;						// The 'prune amount' slider
	
	IBOutlet NSWindow* skeinSpacing;					// The 'skein spacing' window
	IBOutlet NSSlider* skeinHoriz;						// The 'skein horizontal width' slider
	IBOutlet NSSlider* skeinVert;						// The 'skein vertical width' slider

    // Settings
	IBOutlet IFSettingsView* settingsView;				// The settings view
	IBOutlet IFSettingsController* settingsController;	// The settings controller
	
	// The transcript view
	IBOutlet IFTranscriptView* transcriptView;			// The transcript view
	
    // Other variables
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

// Dealing with pages
- (void) addPage: (IFPage*) newPage;							// Adds a new page to this control

// Selecting the view
- (void) selectView: (enum IFProjectPaneType) pane;				// Changes the view displayed in this pane to the specified setting
- (enum IFProjectPaneType) currentView;							// Returns the currently displayed view (IFUnknownPane is a possibility for some views I haven't added code to check for)
- (NSTabView*) tabView;											// The tab view itself

// The source view
- (void) prepareToCompile;										// Informs this pane that it's time to prepare to compile (or save) the document
- (void) showSourceFile: (NSString*) file;					// Sets the source page to show a specific source file
- (IFSourcePage*) sourcePage;									// The page representing the source page

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
- (BOOL) canSelectIndexTab: (int) whichTab;						// Returns YES if we can select a specific tab in the index pane
- (void) selectIndexTab: (int) whichTab;						// Chooses a specific index tab

// Settings
- (void) updateSettings;										// Updates the settings views with their current values

// The documentation view
- (void) openURL: (NSURL*) url;									// Tells the documentation view to open a specific URL

// The skein view
- (ZoomSkeinView*) skeinView;									// The skein view
- (IBAction) skeinLabelSelected: (id) sender;					// The user has selected a skein item from the drop-down list (so we should scroll there)
- (void) skeinDidChange: (NSNotification*) not;					// Called by Zoom to notify that the skein has changed

- (IBAction) performPruning: (id) sender;						// The user has clicked a button in the 'prune skein' sheet
- (IBAction) pruneSkein: (id) sender;							// The user has clicked the 'prune skein' button

- (IBAction) performSkeinLayout: (id) sender;					// The user has clicked a button indicating she wants to change the skein layout
- (IBAction) skeinLayoutOk: (id) sender;						// The user has confirmed her new skein layout
- (IBAction) useDefaultSkeinLayout: (id) sender;				// The user has clicked a button indicating she wants to use the default skein layout
- (IBAction) updateSkeinLayout: (id) sender;					// The user has dragged one of the skein layout sliders

// The transcript view
- (IFTranscriptView*) transcriptView;							// Returns the transcript view object associated with this pane
- (IFTranscriptLayout*) transcriptLayout;						// Returns the transcript layout object associated with this pane

- (IBAction) transcriptBlessAll: (id) sender;					// Causes, after a confirmation, all the items in the transcript to be blessed

// Breakpoints
- (IBAction) setBreakpoint: (id) sender;						// Sets a breakpoint at the current line in response to a menu selection
- (IBAction) deleteBreakpoint: (id) sender;						// Clears the breakpoint at the current line in response to a menu selection

// Search/replace
- (void) performFindPanelAction: (id) sender;					// Called to invoke the find panel for the current pane

@end
