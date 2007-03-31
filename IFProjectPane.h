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
#import "IFErrorsPage.h"
#import "IFIndexPage.h"

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

    IBOutlet NSTabView* tabView;						// The tab view
    IBOutlet NSTabViewItem* gameTabView;				// Game pane
    IBOutlet NSTabViewItem* docTabView;					// Documentation pane
	IBOutlet NSTabViewItem* skeinTabView;				// Skein pane
	IBOutlet NSTabViewItem* transcriptTabView;			// Transcript pane
	
	// The pages
	NSMutableArray* pages;								// Pages being managed by this control
	
	// The pages
	IFSourcePage* sourcePage;							// The source page
	IFErrorsPage* errorsPage;							// The errors page
	IFIndexPage* indexPage;								// The index page
	
	// The documentation view
	WebView* wView;										// The web view that displays the documentation
    
    // The game view
    IBOutlet NSView* gameView;							// The view that will contain the running game
    
	GlkView*		 gView;								// The Glk (glulxe) view
    ZoomView*        zView;								// The Z-Machinev view
    NSString*        gameToRun;							// The filename of the game to start
	ZoomSkeinItem*   pointToRunTo;						// The skein item to run the game until
	
	IFProgress*      gameRunningProgress;				// The progress indicator (how much we've compiled, how the game is running, etc)

    // Documentation
    IBOutlet NSView* docView;							// The view that will contain the documentation web view
	
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

// The source page
- (void) prepareToCompile;										// Informs this pane that it's time to prepare to compile (or save) the document
- (void) showSourceFile: (NSString*) file;						// Sets the source page to show a specific source file
- (IFSourcePage*) sourcePage;									// The page representing the source page

// The errors page
- (IFErrorsPage*) errorsPage;									// The page displaying the results from the compiler

// The index page
- (IFIndexPage*) indexPage;										// The page representing the index

// The game view
- (void) activateDebug;											// Notify that the next game run should be run with debugging on (breakpoints will be set)
- (void) startRunningGame: (NSString*) fileName;				// Starts running the game file with the given name in the game pane
- (void) stopRunningGame;										// Forcibly stops running the game
- (void) pauseRunningGame;										// Forcibly pauses the running game and enters the debugger

- (ZoomView*) zoomView;											// The zoom view associated with the currently running game (NULL if a GLK game is running)
- (GlkView*) glkView;											// The glk view associated with the currently running game (if applicable)
- (BOOL) isRunningGame;											// YES if a game is running

- (void) setPointToRunTo: (ZoomSkeinItem*) item;				// Sets the skein item to run to as soon as the game has started

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

// Search/replace
- (void) performFindPanelAction: (id) sender;					// Called to invoke the find panel for the current pane

@end
