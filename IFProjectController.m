//
//  IFProjectController.m
//  Inform
//
//  Created by Andrew Hunter on Wed Aug 27 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFProject.h"
#import "IFProjectController.h"
#import "IFProjectPane.h"
#import "IFInspectorWindow.h"
#import "IFNewProjectFile.h"
#import "IFIsIndex.h"

#import "IFPreferences.h"

#import "IFIsFiles.h"
#import "IFIsWatch.h"
#import "IFIsBreakpoints.h"

#import "IFSearchResultsController.h"

// = Preferences =

NSString* IFSplitViewSizes = @"IFSplitViewSizes";

@implementation IFProjectController

// == Toolbar items ==

static NSToolbarItem* compileItem			= nil;
static NSToolbarItem* compileAndRunItem		= nil;
static NSToolbarItem* replayItem			= nil;
static NSToolbarItem* compileAndDebugItem	= nil;
static NSToolbarItem* releaseItem			= nil;

static NSToolbarItem* stopItem				= nil;
static NSToolbarItem* pauseItem				= nil;

static NSToolbarItem* continueItem			= nil;
static NSToolbarItem* stepItem				= nil;
static NSToolbarItem* stepOverItem			= nil;
static NSToolbarItem* stepOutItem			= nil;

static NSToolbarItem* indexItem				= nil;

static NSToolbarItem* watchItem				= nil;
static NSToolbarItem* breakpointItem		= nil;

static NSToolbarItem* searchDocsItem		= nil;
static NSToolbarItem* searchProjectItem		= nil;

static NSDictionary*  itemDictionary = nil;

+ (void) initialize {
	// Register our preferences
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys: 
		[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0.625], [NSNumber numberWithFloat: 0.375], nil], IFSplitViewSizes, 
		nil]];
	
	// Create the toolbar items
    compileItem   = [[NSToolbarItem alloc] initWithItemIdentifier: @"compileItem"];
    compileAndRunItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"compileAndRunItem"];
    compileAndDebugItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"compileAndDebugItem"];
    releaseItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"releaseItem"];
	replayItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"replayItem"];
	
    stopItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"stopItem"];
    continueItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"continueItem"];
    pauseItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"pauseItem"];

	stepItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"stepItem"];
    stepOverItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"stepOverItem"];
    stepOutItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"stepOutItem"];
	
	indexItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"indexItem"];

	watchItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"watchItem"];
    breakpointItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"breakpointItem"];
	
	searchDocsItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"searchDocsItem"];
	searchProjectItem = [[NSToolbarItem alloc] initWithItemIdentifier: @"searchProjectItem"];

    itemDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
        compileItem, @"compileItem",
        compileAndRunItem, @"compileAndRunItem",
		replayItem, @"replayItem",
		compileAndDebugItem, @"compileAndDebugItem",
        releaseItem, @"releaseItem",
		stopItem, @"stopItem",
		pauseItem, @"pauseItem",
		continueItem, @"continueItem",
		stepItem, @"stepItem",
		stepOverItem, @"stepOverItem",
		stepOutItem, @"stepOutItem",
		indexItem, @"indexItem",
		watchItem, @"watchItem",
		breakpointItem, @"breakpointItem",
		searchDocsItem, @"searchDocsItem",
		searchProjectItem, @"searchProjectItem",
        nil];

	// Images
	[compileItem setImage: [NSImage imageNamed: @"compile"]];
	[compileAndRunItem setImage: [NSImage imageNamed: @"run"]];
	[compileAndDebugItem setImage: [NSImage imageNamed: @"debug"]];
	[releaseItem setImage: [NSImage imageNamed: @"release"]];
	[replayItem setImage: [NSImage imageNamed: @"replay"]];
	
	[stopItem setImage: [NSImage imageNamed: @"stop"]];
	[pauseItem setImage: [NSImage imageNamed: @"pause"]];
	[continueItem setImage: [NSImage imageNamed: @"continue"]];
	
	[stepItem setImage: [NSImage imageNamed: @"step"]];
	[stepOverItem setImage: [NSImage imageNamed: @"stepover"]];
	[stepOutItem setImage: [NSImage imageNamed: @"stepout"]];

	[indexItem setImage: [NSImage imageNamed: @"index"]];
	
	[watchItem setImage: [NSImage imageNamed: @"watch"]];
	[breakpointItem setImage: [NSImage imageNamed: @"breakpoint"]];

	// Labels
    [compileItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Compile"
																  value: @"Compile"
																  table: nil]];
    [compileAndRunItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Go!"
																		value: @"Go!"
																		table: nil]];
	[compileAndDebugItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Debug"
																		  value: @"Debug"
																		  table: nil]];
    [releaseItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Release"
																  value: @"Release"
																  table: nil]];
    [replayItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Replay"
																 value: @"Replay"
																 table: nil]];
	
	[stepItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Step"
															   value: @"Step"
															   table: nil]];
	[stepOverItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Step over"
																   value: @"Step over"
																   table: nil]];
	[stepOutItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Step out"
																  value: @"Step out"
																  table: nil]];
	
	[stopItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Stop"
															   value: @"Stop"
															   table: nil]];
	[pauseItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Pause"
																value: @"Pause"
																table: nil]];
	[continueItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Continue"
																   value: @"Continue"
																   table: nil]];

	[indexItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Index"
																value: @"Index"
																table: nil]];
	
	[watchItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Watch"
																value: @"Watch"
																table: nil]];
	[breakpointItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Breakpoints"
																	 value: @"Breakpoints"
																	 table: nil]];
	

	[searchDocsItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Search Documentation"
																	 value: @"Search Documentation"
																	 table: nil]];
	[searchProjectItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Search Project"
																		value: @"Search Project"
																		table: nil]];

	// The tooltips
    [compileItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"CompileTip"
																	value: nil
																	table: nil]];
    [compileAndRunItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"GoTip"
																		  value: nil
																		  table: nil]];
	[compileAndDebugItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"DebugTip"
																			value: nil
																			table: nil]];
    [releaseItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"ReleaseTip"
																	value: nil
																	table: nil]];
	[replayItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"ReplayTip"
																   value: nil
																   table: nil]];
	
	[stepItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"StepTip"
																 value: nil
																 table: nil]];
	[stepOverItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"StepOverTip"
																	 value: nil
																	 table: nil]];
	[stepOutItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"StepOutTip"
																	value: nil
																	table: nil]];
	
	[stopItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"StopTip"
																 value: nil
																 table: nil]];
	[pauseItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"PauseTip"
																  value: nil
																  table: nil]];
	[continueItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"ContinueTip"
																   value: nil
																   table: nil]];
	
	[indexItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"IndexTip"
																value: nil
																table: nil]];
	
	[watchItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"WatchTip"
																  value: nil
																  table: nil]];
	[breakpointItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"BreakpointsTip"
																	 value: nil
																	 table: nil]];

	[searchDocsItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"SearchDocsTip"
																	   value: nil
																	   table: nil]];
	[searchProjectItem setToolTip: [[NSBundle mainBundle] localizedStringForKey: @"SearchProjectTip"
																		  value: nil
																		  table: nil]];
	
    // The action heroes
    [compileItem setAction: @selector(compile:)];
    [compileAndRunItem setAction: @selector(compileAndRun:)];
    [compileAndDebugItem setAction: @selector(compileAndDebug:)];
    [releaseItem setAction: @selector(release:)];
    [replayItem setAction: @selector(replayUsingSkein:)];
	
	[indexItem setAction: @selector(docIndex:)];
	
    [stopItem setAction: @selector(stopProcess:)];
	[pauseItem setAction: @selector(pauseProcess:)];
	
	[continueItem setAction: @selector(continueProcess:)];
	[stepItem setAction: @selector(stepIntoProcess:)];
	[stepOverItem setAction: @selector(stepOverProcess:)];
	[stepOutItem setAction: @selector(stepOutProcess:)];
	
	[watchItem setAction: @selector(showWatchpoints:)];
	[breakpointItem setAction: @selector(showBreakpoints:)];
}

// == Initialistion ==

- (id) init {
    self = [super initWithWindowNibName:@"Project"];

    if (self) {
        toolbar = nil;
        projectPanes = [[NSMutableArray allocWithZone: [self zone]] init];
        splitViews   = [[NSMutableArray allocWithZone: [self zone]] init];
		
		lineHighlighting = [[NSMutableDictionary allocWithZone: [self zone]] init];
        
        [self setShouldCloseDocument: YES];
		
		generalPolicy = [[IFProjectPolicy alloc] initWithProjectController: self];
		docPolicy = [[IFProjectPolicy alloc] initWithProjectController: self];
		[docPolicy setRedirectToDocs: YES];
		
		progressIndicators = [[NSMutableArray alloc] init];
		progressing = NO;
    }

    return self;
}

- (void) dealloc {
	[progressIndicators makeObjectsPerformSelector: @selector(setDelegate:)
										withObject: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];

    if (toolbar) [toolbar release];
    [projectPanes release];
    [splitViews release];
	
	[lastFilename release];
	
	[lineHighlighting release];
	
	[generalPolicy release];
	[docPolicy release];

	[progressIndicators release];
	
    [super dealloc];
}

- (void) updateSettings {
	// Update the toolbar if required
	NSString* toolbarIdentifier;
	
	if ([[[self document] settings] usingNaturalInform]) {
		toolbarIdentifier = @"ProjectNiToolbar";
	} else {
		toolbarIdentifier = @"ProjectToolbar";
	}
	
	if (![[toolbar identifier] isEqualToString: toolbarIdentifier]) {
		[toolbar autorelease];
		
		toolbar = [[NSToolbar allocWithZone: [self zone]] initWithIdentifier: toolbarIdentifier];
		
		[toolbar setDelegate: self];
		[toolbar setAllowsUserCustomization: YES];
		[toolbar setAutosavesConfiguration: YES];
		
		[[self window] setToolbar: toolbar];
	}
}

- (void) windowDidLoad {
	[self setWindowFrameAutosaveName: @"ProjectWindow"];
}

- (void) windowWillClose: (NSNotification*) not {
	[[self gamePane] stopRunningGame];
}

- (void) awakeFromNib {
	[self setWindowFrameAutosaveName: @"ProjectWindow"];

	// Register for settings updates
    [[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(updateSettings)
												 name: IFSettingNotification
											   object: [[self document] settings]];
	
	// Register for breakpoints updates
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(updatedBreakpoints:)
												 name: IFProjectBreakpointsChangedNotification
											   object: [self document]];
	
	[self updatedBreakpoints: nil];

    // Setup the default panes
    [projectPanes removeAllObjects];
    [projectPanes addObject: [IFProjectPane standardPane]];
    [projectPanes addObject: [IFProjectPane standardPane]];
	
    [[projectPanes objectAtIndex: 0] selectView: IFSourcePane];
    [[projectPanes objectAtIndex: 1] selectView: IFErrorPane];

    [self layoutPanes];

    // Monitor for compiler finished notifications
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(compilerFinished:)
                                                 name: IFCompilerFinishedNotification
                                               object: [[self document] compiler]];

	// Monitor for skein changed notifications
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(skeinChanged:)
												 name: ZoomSkeinChangedNotification
											   object: [[self document] skein]];
	
    // Create the view switch toolbar
	if ([[[self document] settings] usingNaturalInform]) {
		toolbar = [[NSToolbar allocWithZone: [self zone]] initWithIdentifier: @"ProjectNiToolbar"];
	} else {
		toolbar = [[NSToolbar allocWithZone: [self zone]] initWithIdentifier: @"ProjectToolbar"];
	}
	
    [toolbar setDelegate: self];
    [toolbar setAllowsUserCustomization: YES];
	[toolbar setAutosavesConfiguration: YES];
    
    [[self window] setToolbar: toolbar];
	
	[statusInfo setStringValue: @""];
}

// == Project pane layout ==

- (void) layoutPanes {
    if ([projectPanes count] == 0) {
        return;
    }

    [projectPanes makeObjectsPerformSelector: @selector(removeFromSuperview)];
    [splitViews makeObjectsPerformSelector: @selector(removeFromSuperview)];
    [splitViews removeAllObjects];
    [[panesView subviews] makeObjectsPerformSelector:
        @selector(removeFromSuperview)];

    if ([projectPanes count] == 1) {
        // Just one pane
        IFProjectPane* firstPane = [projectPanes objectAtIndex: 0];

        [firstPane setController: self];
        
        [[firstPane paneView] setFrame: [panesView bounds]];
        [panesView addSubview: [firstPane paneView]];
    } else {
        // Create the splitViews
        int view, nviews;
        double dividerWidth = 5;

        nviews = [projectPanes count];
        for (view=0; view<nviews-1; view++) {
            NSSplitView* newView = [[NSSplitView allocWithZone: [self zone]] init];

            [newView setVertical: YES];
            [newView setIsPaneSplitter: YES];
            [newView setDelegate: self];
            [newView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];

            dividerWidth = [newView dividerThickness];

            [splitViews addObject: [newView autorelease]];
        }

        // Remaining space for other dividers
        double remaining = [panesView bounds].size.width - dividerWidth*(double)(nviews-1);
        double totalRemaining = [panesView bounds].size.width;
        double viewWidth = floor(remaining / (double)nviews);
		
		// Work out the widths of the dividers using the preferences
		NSMutableArray* realDividerWidths = [NSMutableArray array];
		NSArray* dividerProportions = [[NSUserDefaults standardUserDefaults] objectForKey: IFSplitViewSizes];
		
		if (![dividerProportions isKindOfClass: [NSArray class]] || [dividerProportions count] <= 0) 
			dividerProportions = [NSArray arrayWithObject: [NSNumber numberWithFloat: 1.0]];
		
		float totalWidth = 0;
		
		for (view=0; view<nviews; view++) {
			float width;
			
			if (view >= [dividerProportions count]) {
				width = [[dividerProportions objectAtIndex: [dividerProportions count]-1] floatValue];
			} else {
				width = [[dividerProportions objectAtIndex: view] floatValue];
			}
			
			if (width <= 0) width = 1.0;
			[realDividerWidths addObject: [NSNumber numberWithFloat: width]];
			
			totalWidth += width;
		}
		
		// Work out the actual widths to use, and size and add the views appropriately
		float proportion = remaining / totalWidth;

        //NSRect paneBounds = [panesView bounds];
        
        // Insert the views
        NSSplitView* lastView = nil;
        for (view=0; view<nviews-1; view++) {
            // Garner some information about the views we're dealing with
            NSSplitView*   thisView = [splitViews objectAtIndex: view];
            IFProjectPane* pane     = [projectPanes objectAtIndex: view];
            NSView*        thisPane = [[projectPanes objectAtIndex: view] paneView];

            [pane setController: self];
			
			viewWidth = floorf(proportion * [[realDividerWidths objectAtIndex: view] floatValue]);

            // Resize the splitview
            NSRect splitFrame;
            if (lastView != nil) {
                splitFrame = [lastView bounds];
                splitFrame.origin.x += viewWidth + dividerWidth;
                splitFrame.size.width = totalRemaining;
            } else {
                splitFrame = [panesView bounds];
            }
            [thisView setFrame: splitFrame];

            // Add it as a subview
            if (lastView != nil) {
                [lastView addSubview: thisView];
                //[lastView adjustSubviews];
            } else {
                [panesView addSubview: thisView];
            }

            // Add the leftmost view
            NSRect paneFrame = [thisView bounds];
            paneFrame.size.width = viewWidth;

            [thisPane setFrame: paneFrame];
            [thisView addSubview: thisPane];
			[thisView setDelegate: self];

            lastView = thisView;

            // Update the amount of space remaining
            remaining -= viewWidth;
            totalRemaining -= viewWidth + dividerWidth;
        }

        // Final view
        NSView* finalPane = [[projectPanes lastObject] paneView];
        NSRect finalFrame = [lastView bounds];

        [[projectPanes lastObject] setController: self];

        finalFrame.origin.x += viewWidth + dividerWidth;
        finalFrame.size.width = totalRemaining;
        [finalPane setFrame: finalFrame];
        
        [lastView addSubview: finalPane];
        [lastView adjustSubviews];
    }
}

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
	// Update the preferences with the view widths
	int nviews = [projectPanes count];
	int view;
	
	NSMutableArray* viewSizes = [NSMutableArray array];
	
	float totalWidth = [[self window] frame].size.width;
	
	for (view=0; view<nviews; view++) {
		IFProjectPane* pane = [projectPanes objectAtIndex: view];
		NSRect paneFrame = [[pane paneView] frame];
		
		[viewSizes addObject: [NSNumber numberWithFloat: paneFrame.size.width/totalWidth]];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject: viewSizes
											  forKey: IFSplitViewSizes];
}

// == Toolbar delegate functions ==

- (NSToolbarItem *)toolbar: (NSToolbar *) toolbar
     itemForItemIdentifier: (NSString *)  itemIdentifier
 willBeInsertedIntoToolbar: (BOOL)        flag {
	// Cheat!
	// Actually, I thought you could share NSToolbarItems between windows, but you can't (the images disappear,
	// weirdly). However, copying the item is just as good as creating a new one here, and makes the code
	// somewhat more readable.

	NSToolbarItem* item = [[[itemDictionary objectForKey: itemIdentifier] copy] autorelease];	
	[item setPaletteLabel: [item label]];
	
	// The search views need to be set up here
	if ([itemIdentifier isEqualToString: @"searchDocsItem"]) {
		NSSearchField* searchDocs = [[NSSearchField alloc] initWithFrame: NSMakeRect(0,0,150,22)];
		[[searchDocs cell] setPlaceholderString: [[NSBundle mainBundle] localizedStringForKey: @"Documentation"
																						value: @"Documentation"
																						table: nil]];

		[item setMinSize: NSMakeSize(100, 22)];
		[item setMaxSize: NSMakeSize(150, 22)];
		[item setView: [searchDocs autorelease]];
		[searchDocs sizeToFit];
		
		[searchDocs setContinuous: NO];
		[[searchDocs cell] setSendsWholeSearchString: YES];
		[searchDocs setTarget: self];
		[searchDocs setAction: @selector(searchDocs:)];
		
		[item setLabel: nil];
		
		return item;
	} else if ([itemIdentifier isEqualToString: @"searchProjectItem"]) {
		NSSearchField* searchProject = [[NSSearchField alloc] initWithFrame: NSMakeRect(0,0,150,22)];
		[[searchProject cell] setPlaceholderString: [[NSBundle mainBundle] localizedStringForKey: @"Project"
																						   value: @"Project"
																						   table: nil]];
		
		[item setMinSize: NSMakeSize(100, 22)];
		[item setMaxSize: NSMakeSize(150, 22)];
		[item setView: [searchProject autorelease]];
		[searchProject sizeToFit];

		[searchProject setContinuous: NO];
		[[searchProject cell] setSendsWholeSearchString: YES];
		[searchProject setTarget: self];
		[searchProject setAction: @selector(searchProject:)];
		
		[item setLabel: nil];
		
		return item;
	}
	
	return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
        @"compileItem", @"compileAndRunItem", @"replayItem", @"compileAndDebugItem", @"pauseItem", @"continueItem", @"stepItem", 
		@"stepOverItem", @"stepOutItem", @"stopItem", @"watchItem", @"breakpointItem", @"indexItem", @"searchDocsItem", @"searchProjectItem",
		NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, 
		@"releaseItem",
        nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)tb {
	if ([[tb identifier] isEqualToString: @"ProjectNiToolbar"]) {
		return [NSArray arrayWithObjects: @"compileAndRunItem", @"replayItem", @"stopItem", NSToolbarSeparatorItemIdentifier, 
			@"releaseItem", NSToolbarFlexibleSpaceItemIdentifier, @"searchDocsItem", NSToolbarSeparatorItemIdentifier, @"indexItem", nil];
	} else {
		return [NSArray arrayWithObjects: @"compileAndRunItem", @"replayItem", @"compileAndDebugItem",
			NSToolbarSeparatorItemIdentifier,  @"stopItem", @"pauseItem", NSToolbarSeparatorItemIdentifier, 
			@"continueItem", @"stepOutItem", @"stepOverItem", @"stepItem", NSToolbarSeparatorItemIdentifier,
			@"releaseItem", NSToolbarFlexibleSpaceItemIdentifier, @"indexItem", NSToolbarSeparatorItemIdentifier, 
			@"breakpointItem", @"watchItem", nil];
	}
}

// == Toolbar item validation ==

- (BOOL) validateToolbarItem: (NSToolbarItem*) item {
	BOOL isRunning = [[self gamePane] isRunningGame];
	
	if ([[item itemIdentifier] isEqualToString: [stopItem itemIdentifier]] || [[item itemIdentifier] isEqualToString: [pauseItem itemIdentifier]]) {
		return isRunning;
	}
	
	if ([[item itemIdentifier] isEqualToString: [continueItem itemIdentifier]] || 
		[[item itemIdentifier] isEqualToString: [stepOutItem itemIdentifier]]  || 
		[[item itemIdentifier] isEqualToString: [stepOverItem itemIdentifier]] || 
		[[item itemIdentifier] isEqualToString: [stepItem itemIdentifier]]) {
		return isRunning?waitingAtBreakpoint:NO;
	}

	SEL itemSelector = [item action];
	if (itemSelector == @selector(compile:) || 
		itemSelector == @selector(release:) ||
		itemSelector == @selector(compileAndRun:) ||
		itemSelector == @selector(compileAndDebug:) ||
		itemSelector == @selector(replayUsingSkein:)) {
		return ![[[self document] compiler] isRunning];
	}
	
	return YES;
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
	SEL itemSelector = [menuItem action];
	BOOL isRunning = [[self gamePane] isRunningGame];
		
	if (itemSelector == @selector(continueProcess:) ||
		itemSelector == @selector(stepOverProcess:) ||
		itemSelector == @selector(stepIntoProcess:) ||
		itemSelector == @selector(stepOutProcess:)) {
		return isRunning?waitingAtBreakpoint:NO;
	}
			
	if (itemSelector == @selector(stopProcess:) ||
		itemSelector == @selector(pauseProcess:)) {
		return isRunning;
	}
	
	if (itemSelector == @selector(compile:) || 
		itemSelector == @selector(release:) ||
		itemSelector == @selector(compileAndRun:) ||
		itemSelector == @selector(compileAndDebug:) ||
		itemSelector == @selector(replayUsingSkein:)) {
		return ![[[self document] compiler] isRunning];
	}
	
	// Format options
	if (itemSelector == @selector(shiftLeft:) ||
		itemSelector == @selector(shiftRight:) ||
		itemSelector == @selector(renumberSections:)) {
		// First responder must be an NSTextView object
		if (![[[self window] firstResponder] isKindOfClass: [NSTextView class]])
			return NO;
	}
	
	if (itemSelector == @selector(renumberSections:)) {
		// Intelligence must be on
		if (![[IFPreferences sharedPreferences] enableIntelligence])
			return NO;
		
		// First responder must be an NSTextView object containing a IFSyntaxStorage with some intel data
		if (![[[self window] firstResponder] isKindOfClass: [NSTextView class]])
			return NO;

		if (![[(NSTextView*)[[self window] firstResponder] textStorage] isKindOfClass: [IFSyntaxStorage class]])
			return NO;
		
		IFSyntaxStorage* storage = (IFSyntaxStorage*)[(NSTextView*)[[self window] firstResponder] textStorage];
		
		if ([storage highlighting]) return NO;
		if ([storage intelligenceData] == nil) return NO;
	}
	
	if (itemSelector == @selector(lastCommand:) ||
		itemSelector == @selector(lastCommandInSkein:)) {
		return [[[[self skeinPane] skeinView] skein] activeItem] != nil;
	}

	return YES;
}

// == View selection functions ==

- (void) performCompileWithRelease: (BOOL) release {
    IFProject* doc = [self document];
	
	[self removeHighlightsOfStyle: IFLineStyleError];
	[self removeHighlightsOfStyle: IFLineStyleExecutionPoint];
		
    // Save the document
    [doc saveDocument: self];
    
    [projectPanes makeObjectsPerformSelector: @selector(stopRunningGame)];
	
    // Set up the compiler
    IFCompiler* theCompiler = [doc compiler];
	[theCompiler setBuildForRelease: release];
    [theCompiler setSettings: [doc settings]];
	
    if (![doc singleFile]) {
        [theCompiler setOutputFile: [NSString stringWithFormat: @"%@/Build/output.%@",
            [doc fileName],
			[[doc settings] zcodeVersion]==256?@"ulx":@"z5"]];
		
        if ([[doc settings] usingNaturalInform]) {
            [theCompiler setInputFile: [NSString stringWithFormat: @"%@",
                [doc fileName]]];
        } else {
            [theCompiler setInputFile: [NSString stringWithFormat: @"%@/Source/%@",
                [doc fileName], [doc mainSourceFile]]];
        }
        
        [theCompiler setDirectory: [NSString stringWithFormat: @"%@/Build", [doc fileName]]];
    } else {
        [theCompiler setInputFile: [NSString stringWithFormat: @"%@",
            [doc fileName]]];
        
        [theCompiler setDirectory: [NSString stringWithFormat: @"%@", [[doc fileName] stringByDeletingLastPathComponent]]];
    }
	
    // Time to go!
	[self addProgressIndicator: [theCompiler progress]];
    [theCompiler prepareForLaunch];
    [theCompiler launch];
	
    // [[projectPanes objectAtIndex: 1] selectView: IFErrorPane];
}

- (IBAction) release: (id) sender {
    compileFinishedAction = @selector(saveCompilerOutput);
	[self performCompileWithRelease: YES];
}

- (IBAction) compile: (id) sender {
    compileFinishedAction = @selector(saveCompilerOutput);
	[self performCompileWithRelease: NO];
}

- (IBAction) compileAndRun: (id) sender {
	[[projectPanes objectAtIndex: 1] setPointToRunTo: nil];
    compileFinishedAction = @selector(runCompilerOutput);
    [self performCompileWithRelease: NO];

	waitingAtBreakpoint = NO;
}

- (IBAction) replayUsingSkein: (id) sender {
    compileFinishedAction = @selector(runCompilerOutputAndReplay);
	[self performCompileWithRelease: NO];
	
	waitingAtBreakpoint = NO;
}

- (IBAction) compileAndDebug: (id) sender {
	[[projectPanes objectAtIndex: 1] setPointToRunTo: nil];
	compileFinishedAction = @selector(debugCompilerOutput);
    [self performCompileWithRelease: NO];
	
	waitingAtBreakpoint = NO;
 }

- (IBAction) stopProcess: (id) sender {
	[projectPanes makeObjectsPerformSelector: @selector(stopRunningGame)];
	[self removeHighlightsOfStyle: IFLineStyleExecutionPoint];
}

// = Things to do after the compiler has finished =
- (void) saveCompilerOutput {
    // Setup a save panel
    NSSavePanel* panel = [NSSavePanel savePanel];
    IFCompilerSettings* settings = [[self document] settings];

    [panel setAccessoryView: nil];
    [panel setRequiredFileType: [settings fileExtension]];
    [panel setCanSelectHiddenExtension: YES];
    [panel setDelegate: self];
    [panel setPrompt: @"Save"];
    [panel setTreatsFilePackagesAsDirectories: NO];

    // Show it
    NSString* file = [[[self document] fileName] lastPathComponent];
    file = [file stringByDeletingPathExtension];
    
    [panel beginSheetForDirectory: @"~" // FIXME: preferences
                             file: file
                   modalForWindow: [self window]
                    modalDelegate: self
                   didEndSelector: @selector(compilerSavePanelDidEnd:returnCode:contextInfo:)
                      contextInfo: NULL];    
}

- (void) runCompilerOutput {
	waitingAtBreakpoint = NO;
    [[projectPanes objectAtIndex: 1] startRunningGame: [[[self document] compiler] outputFile]];
}

- (void) runCompilerOutputAndReplay {
	[[projectPanes objectAtIndex: 1] setPointToRunTo: [[[self document] skein] activeItem]];
	[self runCompilerOutput];
}

- (void) debugCompilerOutput {
	waitingAtBreakpoint = NO;
	[[projectPanes objectAtIndex: 1] activateDebug];
    [[projectPanes objectAtIndex: 1] startRunningGame: [[[self document] compiler] outputFile]];
}

- (void) compilerFinished: (NSNotification*) not {
    int exitCode = [[[not userInfo] objectForKey: @"exitCode"] intValue];

    NSFileWrapper* buildDir;
	
	[self removeProgressIndicator: [[[self document] compiler] progress]];
	
	if (exitCode != 0) {
		// Show the errors pane if there was an error while compiling
		[[projectPanes objectAtIndex: 1] selectView: IFErrorPane];
	}

	// Show the 'build results' file
	NSString* buildPath = [NSString stringWithFormat: @"%@/Build", [[self document] fileName]];
    buildDir = [[NSFileWrapper alloc] initWithPath: buildPath];
    [buildDir autorelease];

    int x;
    for (x=0; x<[projectPanes count]; x++) {
        IFProjectPane* pane = [projectPanes objectAtIndex: x];

        [[pane compilerController] showContentsOfFilesIn: buildDir
												fromPath: buildPath];
    }
	
	// Update the index tab(s) (if there's anything to update)
	for (x=0; x<[projectPanes count]; x++) {
        IFProjectPane* pane = [projectPanes objectAtIndex: x];
		[pane updateIndexView];
	}

	// Reload the index file
	[[self document] reloadIndexFile];
	
	// Update the index in the controller
	[[IFIsFiles sharedIFIsFiles] updateFiles];
	[[IFIsIndex sharedIFIsIndex] updateIndexFrom: self];

    if (exitCode == 0) {
        // Success!
        if ([[NSFileManager defaultManager] fileExistsAtPath: [[[self document] compiler] outputFile]]) {
            if ([self respondsToSelector: compileFinishedAction]) {
                [self performSelector: compileFinishedAction];
            }
        } else {
            // FIXME: show an alert sheet
            
        }
    }
}

- (void)compilerFaultAlertDidEnd: (NSWindow *)sheet
                      returnCode:(int)returnCode
                     contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        [self saveCompilerOutput]; // Try agin
    } else {
        // Do nothing
    }
}

- (void)compilerSavePanelDidEnd:(NSSavePanel *) sheet
                     returnCode:(int)           returnCode
                    contextInfo:(void *)        contextInfo {
    if (returnCode == NSOKButton) {
        NSString* whereToSave = [sheet filename];

        if (![[NSFileManager defaultManager] copyPath: [[[self document] compiler] outputFile]
                                              toPath: whereToSave
                                             handler: nil]) {
            // File failed to save
            
            // FIXME: internationalisation
            /* FIXME: doesn't work (save panel sheet is still displayed, doh!)
            NSBeginAlertSheet(@"Unable to save file", @"Retry", @"Cancel", nil,
                              [self window], self,
                              @selector(compilerFaultAlertDidEnd:returnCode:contextInfo:),
                              nil, nil,
                              @"An error was encountered while trying to save the file '%@'",
                              [whereToSave lastPathComponent]);
             */
        }
    } else {
        // Change nothing
    }
}

// = Communication from the containing panes =
- (IFProjectPane*) sourcePane {
	// Returns the current pane containing the source code (or an appropriate pane that source code can be displayed in)
    int paneToUse = 0;
    int x;
	
    for (x=0; x<[projectPanes count]; x++) {
        IFProjectPane* thisPane = [projectPanes objectAtIndex: x];
		
        if ([thisPane currentView] == IFSourcePane) {
            // Always use the first source pane found
            paneToUse = x;
            break;
        }
		
        if ([thisPane currentView] == IFErrorPane) {
            // Avoid a pane showing error messages
            paneToUse = x+1;
        }
    }
	
    if (paneToUse >= [projectPanes count]) {
        // All error views?
        paneToUse = 0;
    }
	
	return [projectPanes objectAtIndex: paneToUse];
}

- (IFProjectPane*) auxPane {
	// Returns the auxiliary pane: the one to use for displaying documentation, etc
    int paneToUse = -1;
    int x;
	
    for (x=0; x<[projectPanes count]; x++) {
        IFProjectPane* thisPane = [projectPanes objectAtIndex: x];
		
        if ([thisPane currentView] == IFDocumentationPane) {
			// Doc pane has priority
            paneToUse = x;
            break;
        }
    }
	
	if (paneToUse == -1) {
		paneToUse = 1;
		for (x=[projectPanes count]-1; x>=0; x--) {
			IFProjectPane* thisPane = [projectPanes objectAtIndex: x];
			
			if ([thisPane currentView] != IFSourcePane &&
				[thisPane currentView] != IFGamePane) {
				// Anything but the source or game...
				paneToUse = x;
				break;
			}
			
			if ([thisPane currentView] == IFSourcePane) {
				// Avoid a pane showing the source code
				paneToUse = x+1;
			}
		}
	}
	
    if (paneToUse >= [projectPanes count]) {
        // All source views?
        paneToUse = 0;
    }
	
	return [projectPanes objectAtIndex: paneToUse];
}

- (IFProjectPane*) transcriptPane {
	// Returns the current pane containing the transcript
    int x;
	
    for (x=0; x<[projectPanes count]; x++) {
        IFProjectPane* thisPane = [projectPanes objectAtIndex: x];
		
        if ([thisPane currentView] == IFTranscriptPane) {
			// This is the transcript pane
			return thisPane;
        }
    }
	
	// No transcript pane showing: use the auxilary pane
	return [self auxPane];
}

- (IFProjectPane*) oppositePane: (IFProjectPane*) pane {
	// Find this pane
	int index = [projectPanes indexOfObjectIdenticalTo: pane];
	if (index == NSNotFound) return nil;
	
	// Get it's 'opposite'
	int opposite = index-1;
	if (opposite < 0) opposite = [projectPanes count]-1;
	
	return [projectPanes objectAtIndex: opposite];
}

- (IFProjectPane*) skeinPane {
	// Returns the current pane containing the skein
    int x;
	
    for (x=0; x<[projectPanes count]; x++) {
        IFProjectPane* thisPane = [projectPanes objectAtIndex: x];
		
        if ([thisPane currentView] == IFSkeinPane) {
			// This is the transcript pane
			return thisPane;
        }
    }
	
	// No transcript pane showing: use the auxilary pane
	return [self auxPane];
}

- (BOOL) selectSourceFile: (NSString*) fileName {	
	if ([[self document] storageForFile: fileName] != nil) {
		// Load this file
		[projectPanes makeObjectsPerformSelector: @selector(showSourceFile:)
									  withObject: fileName];
		
		// Display a warning if this is a temporary file
		if (![lastFilename isEqualToString: fileName] && [[self document] fileIsTemporary: fileName]) {
			NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"Opening temporary file"
																	 value: @"Opening temporary file"
																	 table: nil],
							  @"Continue",nil,nil,
							  [self window],
							  nil,nil,nil,nil,
							  [[NSBundle mainBundle] localizedStringForKey: @"You are opening a temporary file"
																	 value: @"You are opening a temporary file"
																	 table: nil]);
		}
	} else {
		// Display an error if we couldn't find the file
		NSBeginAlertSheet([[NSBundle mainBundle] localizedStringForKey: @"Unable to open source file"
																 value: @"Unable to open source file"
																 table: nil],
						  @"Cancel",nil,nil,
						  [self window],
						  nil,nil,nil,nil,
						  [[NSBundle mainBundle] localizedStringForKey: @"Unable to open source file description"
																 value: @"Unable to open source file description"
																 table: nil]);
	}

	[lastFilename release];
	lastFilename = [fileName copy];

    return YES; // Only one source file ATM (Not any more... changed this)
}

- (NSString*) selectedSourceFile {
	return [[self sourcePane] currentFile];
}

- (void) moveToSourceFileLine: (int) line {
	IFProjectPane* thePane = [self sourcePane];

    [thePane selectView: IFSourcePane];
    [thePane moveToLine: line];
    [[self window] makeFirstResponder: [thePane activeView]];
}

- (void) moveToSourceFilePosition: (int) location {
	IFProjectPane* thePane = [self sourcePane];
	
    [thePane selectView: IFSourcePane];
    [thePane moveToLocation: location];
    [[self window] makeFirstResponder: [thePane activeView]];
}

- (void) selectSourceFileRange: (NSRange) range {
	IFProjectPane* thePane = [self sourcePane];
	
    [thePane selectView: IFSourcePane];
    [thePane selectRange: range];
    [[self window] makeFirstResponder: [thePane activeView]];
}

- (void) removeHighlightsInFile: (NSString*) file
						ofStyle: (enum lineStyle) style {
	file = [[self document] pathForFile: file];
	
	NSMutableArray* lineHighlight = [lineHighlighting objectForKey: file];
	if (lineHighlight == nil) return;
	
	BOOL updated = NO;
	
	// Loop through each highlight, and remove any of this style
	int x;
	for (x=0; x<[lineHighlight count]; x++) {
		if ([[[lineHighlight objectAtIndex: x] objectAtIndex: 1] intValue] == style) {
			[lineHighlight removeObjectAtIndex: x];
			updated = YES;
			x--;
		}
	}
	
	if (updated) {
		NSEnumerator* paneEnum = [projectPanes objectEnumerator];
		IFProjectPane* pane;
	
		while (pane = [paneEnum nextObject]) {
			if ([[[self document] pathForFile: [pane currentFile]] isEqualToString: file]) {
				[pane updateHighlightedLines];
			}
		}
	}
}

- (void) removeHighlightsOfStyle: (enum lineStyle) style {
	// Remove highlights in all files
	NSEnumerator* fileEnum = [lineHighlighting keyEnumerator];
	NSString* file;
	
	while (file = [fileEnum nextObject]) {
		[self removeHighlightsInFile: file
							 ofStyle: style];
	}
}

- (void) removeAllTemporaryHighlights {
	if (!temporaryHighlights) return;
	
	int style;
	
	for (style = IFLineStyle_Temporary; style<IFLineStyle_LastTemporary; style++) {
		[self removeHighlightsOfStyle: style];
	}
	
	temporaryHighlights = NO;
}

- (void) highlightSourceFileLine: (int) line
						  inFile: (NSString*) file {
    [self highlightSourceFileLine: line
						   inFile: file
                            style: IFLineStyleNeutral];
}

- (void) highlightSourceFileLine: (int) line
						  inFile: (NSString*) file
                           style: (enum lineStyle) style {
	file = [[self document] pathForFile: file];
	
	NSMutableArray* lineHighlight = [lineHighlighting objectForKey: file];
	
	if (lineHighlight == nil) {
		lineHighlight = [NSMutableArray array];
		[lineHighlighting setObject: lineHighlight
							 forKey: file];
	}
	
	[lineHighlight addObject: [NSArray arrayWithObjects: [NSNumber numberWithInt: line], 
		[NSNumber numberWithInt: style], 
		nil]];
	
	if (style >= IFLineStyle_Temporary && style < IFLineStyle_LastTemporary)
		temporaryHighlights = YES;
	
	NSEnumerator* paneEnum = [projectPanes objectEnumerator];
	IFProjectPane* pane;
	
	while (pane = [paneEnum nextObject]) {
		if ([[[self document] pathForFile: [pane currentFile]] isEqualToString: file]) {
			[pane updateHighlightedLines];
		}
	}
}

- (NSArray*) highlightsForFile: (NSString*) file {
	file = [[self document] pathForFile: file];
	
	return [lineHighlighting objectForKey: file];
}

// = Debugging controls =
- (IFProjectPane*) gamePane {
	// Return the pane that we're displaying/going to display the game in
	NSEnumerator* paneEnum = [projectPanes objectEnumerator];
	IFProjectPane* pane;
	
	while (pane = [paneEnum nextObject]) {
		if ([pane isRunningGame]) return pane;
	}
	
	return nil;
}

- (void) restartRunning {
	// Perform actions to switch back to the game when we click on continue, etc
	[[self window] makeFirstResponder: [[self gamePane] zoomView]];
	[self removeHighlightsOfStyle: IFLineStyleExecutionPoint];	

	// Docs say we shouldn't do this, but how else are we to force the toolbar to update correctly?
	[toolbar validateVisibleItems];
}

- (void) pauseProcess: (id) sender {
	[[self gamePane] pauseRunningGame];
}

- (void) continueProcess: (id) sender {
	BOOL isRunning = [[self gamePane] isRunningGame];

	if (isRunning && waitingAtBreakpoint) {
		waitingAtBreakpoint = NO;
		[self restartRunning];
		[[[[self gamePane] zoomView] zMachine] continueFromBreakpoint];
	}
}

- (void) stepOverProcess: (id) sender {
	BOOL isRunning = [[self gamePane] isRunningGame];

	if (isRunning && waitingAtBreakpoint) {
		waitingAtBreakpoint = NO;
		[self restartRunning];
		[[[[self gamePane] zoomView] zMachine] stepFromBreakpoint];
	}
}

- (void) stepOutProcess: (id) sender {
	BOOL isRunning = [[self gamePane] isRunningGame];

	if (isRunning && waitingAtBreakpoint) {
		waitingAtBreakpoint = NO;
		[self restartRunning];
		[[[[self gamePane] zoomView] zMachine] finishFromBreakpoint];
	}
}

- (void) stepIntoProcess: (id) sender {
	BOOL isRunning = [[self gamePane] isRunningGame];

	if (isRunning && waitingAtBreakpoint) {
		waitingAtBreakpoint = NO;
		[self restartRunning];
		[[[[self gamePane] zoomView] zMachine] stepIntoFromBreakpoint];
	}
}

- (void) hitBreakpoint: (int) pc {
	// Retrieve the game view
	IFProjectPane* gamePane = [self gamePane];
	ZoomView* zView = [gamePane zoomView];
	
	NSString* filename = [[zView zMachine] sourceFileForAddress: pc];
	int line_no = [[zView zMachine] lineForAddress: pc];
	int char_no = [[zView zMachine] characterForAddress: pc];
		
	if (line_no > -1 && filename != nil) {
		[[self sourcePane] showSourceFile: filename];
		
		if (char_no > -1)
			[[self sourcePane] moveToLine: line_no
								character: char_no];
		else
			[[self sourcePane] moveToLine: line_no];
		[self removeHighlightsOfStyle: IFLineStyleExecutionPoint];
		[self highlightSourceFileLine: line_no
							   inFile: filename
								style: IFLineStyleExecutionPoint];
		[[self window] makeFirstResponder: [[self sourcePane] activeView]];
	}
	
	waitingAtBreakpoint = YES;
	
	// Docs say we shouldn't do this, but how else are we to force the toolbar to update correctly?
	[toolbar validateVisibleItems];
}

- (NSString*) pathToIndexFile {
	IFProject* proj = [self document];
	
	NSString* buildPath = [NSString stringWithFormat: @"%@/Build", [proj fileName]];
	NSString* indexPath = [buildPath stringByAppendingPathComponent: @"index.html"];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath: indexPath])
		return indexPath;
	else
		return nil;
}

- (IFIntelFile*) currentIntelligence {
	return [[self sourcePane] currentIntelligence];
}

// = Documentation controls =
- (void) docIndex: (id) sender {
	[[self auxPane] openURL: [NSURL URLWithString: @"inform:/index.html"]];
}

// = Adding files =
- (void) addNewFile: (id) sender {
	IFNewProjectFile* npf = [[IFNewProjectFile alloc] initWithProjectController: self];
	
	NSString* newFile = [npf getNewFilename];
	if (newFile) {
		if (![(IFProject*)[self document] addFile: newFile]) {
			NSBundle* mB = [NSBundle mainBundle];
			
			NSBeginAlertSheet([mB localizedStringForKey: @"Unable to create file"
												  value: @"Unable to create file"
												  table: nil],
							  [mB localizedStringForKey: @"FileUnable - Cancel"
												  value: @"Cancel"
												  table: nil], nil, nil,
							  [self window], nil, nil, nil, nil,
							  [mB localizedStringForKey: @"FileUnable - Description"
												  value: @"Inform was unable to create that file: most probably because a file already exists with that name"
												  table: nil]);
		}
	}
	
	[[IFIsFiles sharedIFIsFiles] updateFiles];
	[npf release];
}

// = Skein delegate =

- (void) restartGame {
	if ([[projectPanes objectAtIndex: 1] isRunningGame]) {
		[[projectPanes objectAtIndex: 1] setPointToRunTo: nil];
		[self runCompilerOutput];
	} else {
		//[self compileAndRun: self]; -- we do this when 'playToPoint' is called
	}
}

- (void) playToPoint: (ZoomSkeinItem*) point
		   fromPoint: (ZoomSkeinItem*) currentPoint {
	if ([[projectPanes objectAtIndex: 1] isRunningGame]) {
		id inputSource = [ZoomSkein inputSourceFromSkeinItem: currentPoint
												  toItem: point];
	
		[[[projectPanes objectAtIndex: 1] zoomView] setInputSource: inputSource];
	} else {
		[self compileAndRun: self];
		[[projectPanes objectAtIndex: 1] setPointToRunTo: point];
	}
}

- (void) moveTranscriptToPoint: (ZoomSkeinItem*) point {
	// Set all the transcript views to the right item
	NSEnumerator* paneEnum = [projectPanes objectEnumerator];
	IFProjectPane* pane;
	
	while (pane = [paneEnum nextObject]) {
		[[pane transcriptLayout] transcriptToPoint: point];
		[[pane transcriptView] scrollToItem: point];
		[[pane skeinView] highlightSkeinLine: point];
	}
}

- (void) transcriptToPoint: (ZoomSkeinItem*) point {
	// Select the transcript in the appropriate pane
	IFProjectPane* transcriptPane = [self transcriptPane];
	[transcriptPane selectView: IFTranscriptPane];
	
	[self moveTranscriptToPoint: point];
	
	// Highlight the item in the transcript view and skein view
	NSEnumerator* paneEnum = [projectPanes objectEnumerator];
	IFProjectPane* pane;
	
	while (pane = [paneEnum nextObject]) {
		[[pane transcriptView] setHighlightedItem: point];
	}
}

- (void) skeinChanged: (NSNotification*) not {
	ZoomSkein* skein = [[self document] skein];
	
	if ([skein activeItem] != lastActiveItem) {
		[self moveTranscriptToPoint: [skein activeItem]];
		
		lastActiveItem = [skein activeItem];
		
		// Highlight the item in the transcript view
		NSEnumerator* paneEnum = [projectPanes objectEnumerator];
		IFProjectPane* pane;
		
		while (pane = [paneEnum nextObject]) {
			[[pane transcriptView] setHighlightedItem: nil];
			[[pane transcriptView] setActiveItem: lastActiveItem];
		}
	}
}

// = Policy delegates =

- (IFProjectPolicy*) generalPolicy {
	return generalPolicy;
}

- (IFProjectPolicy*) docPolicy {
	return docPolicy;
}

// = Displaying progress =

- (void) clearStatus: (NSNumber*) oldNum {
	if (!progressing && [oldNum intValue] == progressNum) {
		[statusInfo setStringValue: @""];
	}
}

- (void) updateProgress {
	float totalPercentage = 100.0 * [progressIndicators count];
	
	if (totalPercentage <= 0) {
		if (progressing) {
			// Disable progress bars
			[progress setUsesThreadedAnimation: NO];
			[progress stopAnimation: self];
			[self performSelector: @selector(clearStatus:)
					   withObject: [NSNumber numberWithInt: progressNum]
					   afterDelay: 20.0];
			
			progressing = NO;
		}

		return;
	}
	
	// Enable progress bars
	if (!progressing) {
		[progress startAnimation: self];
		[progress setUsesThreadedAnimation: YES];

		progressNum++;
		progressing = YES;
	}
	
	[progress setMaxValue: totalPercentage];
	
	// Set percentage
	float actualPercentage = -1.0;
	
	NSEnumerator* progressEnum = [progressIndicators objectEnumerator];
	IFProgress* indicator;
	
	while (indicator = [progressEnum nextObject]) {
		float iPercent = [indicator percentage];
		
		if (iPercent >= 0) {
			if (actualPercentage < 0) actualPercentage = 0;
			
			actualPercentage += iPercent;
		}
	}
	
	if (actualPercentage < 0) {
		[progress setIndeterminate: YES];
	} else {
		[progress setIndeterminate: NO];
		[progress setDoubleValue: actualPercentage];
	}
}

- (void) addProgressIndicator: (IFProgress*) indicator {
	[indicator setDelegate: self];
	[progressIndicators addObject: indicator];
	
	[self updateProgress];
}

- (void) removeProgressIndicator: (IFProgress*) indicator {
	[indicator setDelegate: nil];
	[progressIndicators removeObjectIdenticalTo: indicator];
	
	[self updateProgress];
}

- (void) progressIndicator: (IFProgress*) indicator
				percentage: (float) newPercentage {
	[self updateProgress];
}

- (void) progressIndicator: (IFProgress*) indicator
				   message: (NSString*) newMessage {
	if (progressing) {
		[statusInfo setStringValue: newMessage];
	}
}

// = Debugging =

- (void) showWatchpoints: (id) sender {
	[[IFInspectorWindow sharedInspectorWindow] showWindow: self];
	[[IFInspectorWindow sharedInspectorWindow] showInspectorWithKey: IFIsWatchInspector];
}

- (void) showBreakpoints: (id) sender {
	[[IFInspectorWindow sharedInspectorWindow] showWindow: self];
	[[IFInspectorWindow sharedInspectorWindow] showInspectorWithKey: IFIsBreakpointsInspector];
}

// = Breakpoints =

// (Grr, need to be able to make IFProjectPane the first responder or something, but it isn't
// listening to messages from the main menu. Or at least, it's not being called that way)
// This may not work the way the user expects if she has two source panes open. Blerh.

- (IBAction) setBreakpoint: (id) sender {
	[[self sourcePane] setBreakpoint: sender];
}

- (IBAction) deleteBreakpoint: (id) sender {
	[[self sourcePane] deleteBreakpoint: sender];
}

- (void) updatedBreakpoints: (NSNotification*) not {
	// Update the breakpoint highlights
	[self removeHighlightsOfStyle: IFLineStyleBreakpoint];
	
	int x;
	
	for (x=0; x<[[self document] breakpointCount]; x++) {
		int line = [[self document] lineForBreakpointAtIndex: x];
		NSString* file = [[self document] fileForBreakpointAtIndex: x];
		
		[self highlightSourceFileLine: line+1
							   inFile: file
								style: IFLineStyleBreakpoint];
	}
}

// = Dealing with search panels =

- (void) searchSelectedItemAtLocation: (int) location
							   phrase: (NSString*) phrase
							   inFile: (NSString*) filename
								 type: (NSString*) type {
	// If the match is a document, order the documentation pane to display it
	// (Not sure how to deal with the location: I don't think it makes much sense
	// relative to a web view)
	
	if ([type isEqualToString: @"Documentation"]) {
		// Doc pane
		[[self auxPane] openURL: [NSURL URLWithString: [@"inform:/" stringByAppendingPathComponent: [filename lastPathComponent]]]];
	} else {
		// Show the appropriate source file
		[self selectSourceFile: filename];
		[self selectSourceFileRange: NSMakeRange(location, [phrase length])];
		//[self moveToSourceFilePosition: location];
	}
}

// = Menu options =

- (NSRange) shiftRange: (NSRange) range
			 inStorage: (NSTextStorage*) storage
			  tabStops: (int) tabStops {
	int x;

	if (tabStops == 0) return NSMakeRange(0,0);
	
	NSMutableString* string = [storage mutableString];
	
	// Find the start of the line preceeding range
	while (range.location > 0 &&
		   [string characterAtIndex: range.location-1] != '\n') {
		range.location--;
		range.length++;
	}
	
	// Tab string to insert
	NSString* tabs = nil;
	if (tabStops > 0) {
		unichar chr[tabStops+1];
		
		for (x=0; x<tabStops; x++) {
			chr[x] = '\t';
		}
		chr[x] = 0;
		
		tabs = [NSString stringWithCharacters: chr
									   length: tabStops];
	}
	
	// Shift each line in turn
	if (range.length == 0) range.length = 1;
	for (x=0; x<range.length;) {
		// Position at x should be the start of a line
		if (tabStops > 0) {
			// Insert tabs at the start of this line
			[string replaceCharactersInRange: NSMakeRange(range.location+x, 0)
								  withString: tabs];

			range.length += tabStops;	// String is longer
			x += tabStops;				// No need to process these again when finding the next line
		} else if (tabStops < 0) {
			// Delete tabs at the start of this line
			
			// Work out how many tabs to delete
			int nTabs = 0;
			while (range.location+x+nTabs < [string length] &&
				   nTabs < -tabStops &&
				   [string characterAtIndex: range.location+x+nTabs] == '\t')
				nTabs++;
			
			// Delete them
			[string deleteCharactersInRange: NSMakeRange(range.location+x, nTabs)];
			
			range.length += tabStops;	// String is shorter
		}
		
		// Find the next line
		x++;
		while (x < range.length &&
			   range.location+x < [string length] &&
			   [string characterAtIndex: range.location+x-1] != '\n')
			x++;
		
		if (range.location+x >= [string length]) break;
	}
	
	return range;
}

- (NSRange) shiftRangeLeft: (NSRange) range
				 inStorage: (NSTextStorage*) textStorage {
	// These functions are used to help with undo
	[textStorage beginEditing];
	
	// This works because the undo manager for the text view will always be the same as the undo manager for this controller
	// If this ever changes, you will need to rewrite this somehow
	NSUndoManager* undo = [[self document] undoManager];
	[undo setActionName: [[NSBundle mainBundle] localizedStringForKey: @"Shift Left"
																value: @"Shift Left"
																table: nil]];
	[undo beginUndoGrouping];
	
	NSRange newRange = [self shiftRange: range
							  inStorage: textStorage
							   tabStops: -1];
	[[undo prepareWithInvocationTarget: self] shiftRangeRight: newRange
													inStorage: textStorage];
		
	[undo endUndoGrouping];
	
	[textStorage endEditing];
	
	return newRange;
}


- (NSRange) shiftRangeRight: (NSRange) range
				  inStorage: (NSTextStorage*) textStorage {
	// These functions are used to help with undo
	[textStorage beginEditing];
	
	// This works because the undo manager for the text view will always be the same as the undo manager for this controller
	// If this ever changes, you will need to rewrite this somehow
	NSUndoManager* undo = [[self document] undoManager];
	[undo setActionName: [[NSBundle mainBundle] localizedStringForKey: @"Shift Right"
																value: @"Shift Right"
																table: nil]];
	[undo beginUndoGrouping];
	
	NSRange newRange = [self shiftRange: range
							  inStorage: textStorage
							   tabStops: 1];
	[[undo prepareWithInvocationTarget: self] shiftRangeLeft: newRange
												   inStorage: textStorage];
	
	[undo endUndoGrouping];
	
	[textStorage endEditing];
	
	return newRange;
}

- (IBAction) shiftLeft: (id) sender {
	if (![[[self window] firstResponder] isKindOfClass: [NSTextView class]])
		return;
	
	// Delete one tab stop from the beginning of each line in the selection
	NSTextView* textView = (NSTextView*)[[self window] firstResponder];
	NSTextStorage* storage = [textView textStorage];

	NSRange selRange = [textView selectedRange];
	
	if (!storage) return;
	
	NSRange newRange = [self shiftRangeLeft: selRange
								  inStorage: storage];
	
	[textView setSelectedRange: newRange];
}

- (IBAction) shiftRight: (id) sender {
	if (![[[self window] firstResponder] isKindOfClass: [NSTextView class]])
		return;
	
	// Insert one tab stop at the beginning of each line in the selection
	NSTextView* textView = (NSTextView*)[[self window] firstResponder];
	NSTextStorage* storage = [textView textStorage];
	
	NSRange selRange = [textView selectedRange];
	
	if (!storage) return;
	
	
	NSRange newRange = [self shiftRangeRight: selRange
								   inStorage: storage];
	
	[textView setSelectedRange: newRange];
}

- (IBAction) renumberSections: (id) sender {
	// First responder must be an NSTextView object containing a IFSyntaxStorage with some intel data
	if (![[[self window] firstResponder] isKindOfClass: [NSTextView class]])
		return;
	
	if (![[(NSTextView*)[[self window] firstResponder] textStorage] isKindOfClass: [IFSyntaxStorage class]])
		return;
	
	IFSyntaxStorage* storage = (IFSyntaxStorage*)[(NSTextView*)[[self window] firstResponder] textStorage];
	
	if ([storage highlighting]) return;					// Can't do this while highlighting: the section data might not be accurate any more
	if ([storage intelligenceData] == nil) return;		// Also can't do this if we haven't actually gathered any data
	
	NSUndoManager* undo = [[self document] undoManager];
	
	// Renumber each section stored in the intelligence data
	// This is pretty inefficient at the moment, but it's 'unlikely' that this will ever be a problem in sensible
	// files. (Note O(n^2) semantics, due to inefficiency in lineForSymbol:)
	// If we're being pedantic, I guess we have a problem with files with more than 2147483647 symbols too.
	// If you're writing IF that big, then, er, wow. Fixing this should be no problem for you.
	IFIntelFile*   intel   = [storage intelligenceData];
	IFIntelSymbol* section = [intel firstSymbol];
	
	[undo beginUndoGrouping];
	[storage beginEditing];
		
	while (section != nil) {
		int lineNumber = [intel lineForSymbol: section];
		NSString* sectionLine = [storage textForLine: lineNumber];
		NSArray*  words = [sectionLine componentsSeparatedByString: @" "];
		
		int sectionNumber = [words count]>1?[[words objectAtIndex: 1] intValue]:0;
		
		if (sectionNumber > 0) {
			// This looks like something we can renumber... Get the preceding number
			IFIntelSymbol* lastSection = [section previousSibling];
			int lastLineNumber = [intel lineForSymbol: lastSection];
			NSArray* lastWords = [[storage textForLine: lastLineNumber] componentsSeparatedByString: @" "];
			
			int lastSectionNumber = [lastWords count]>1?[[lastWords objectAtIndex: 1] intValue]:0;
			
			if (lastSectionNumber >= 0 && lastSectionNumber+1 != sectionNumber) {
				// This section needs renumbering
				NSMutableArray* newWords = [words mutableCopy];			// Spoons!
				
				if ([newWords count] == 2) {
					// Must be followed by a newline
					[newWords replaceObjectAtIndex: 1
										withObject: [NSString stringWithFormat: @"%i\n", lastSectionNumber+1]];
				} else {
					// Must not be followed by a newline
					[newWords replaceObjectAtIndex: 1
										withObject: [NSString stringWithFormat: @"%i", lastSectionNumber+1]];
				}
				
				// OK, replace the text (IFSyntaxStorage's replaceCharactersInRange:withString: should fix things
				// up so that if the file length changes, future sections are still pointing to the right placec)
				[storage replaceLine: lineNumber
							withLine: [newWords componentsJoinedByString: @" "]];
				
				[newWords release];
			}
		}
		
		// Onwards!
		section = [section nextSymbol];
	}
		
	[storage endEditing];
	[undo endUndoGrouping];
}

// = Searching =

- (void) searchDocs: (id) sender {
	if ([[sender stringValue] isEqualToString: @""] || [sender stringValue] == nil) return;
	
	// Create a new SearchResultsController to handle the search
	IFSearchResultsController* ctrl = [[IFSearchResultsController alloc] init];
	
	// Set up the controller
	[ctrl setSearchLabelText: [NSString stringWithFormat: @"\"%@\" in documentation for %@", 
		[sender stringValue], 
		[[self document] displayName]]];
	[ctrl setSearchPhrase: [sender stringValue]];
	[ctrl setSearchType: IFSearchStartsWith];
	[ctrl setCaseSensitive: NO];
	
	[ctrl setDelegate: self];
	
	// Find the files and data to search
	[ctrl addDocumentation];
	
	// Display the window
	[ctrl showWindow: self];
	// ctrl will autorelease itself when done
	
	// Start the search
	[ctrl startSearch];
}

- (void) searchProject: (id) sender {
	if ([[sender stringValue] isEqualToString: @""] || [sender stringValue] == nil) return;

	// Create a new SearchResultsController to handle the search
	IFSearchResultsController* ctrl = [[IFSearchResultsController alloc] init];
	
	// Set up the controller
	[ctrl setSearchLabelText: [NSString stringWithFormat: @"\"%@\" in %@", 
		[sender stringValue], 
		[[self document] displayName]]];
	[ctrl setSearchPhrase: [sender stringValue]];
	[ctrl setSearchType: IFSearchStartsWith];
	[ctrl setCaseSensitive: NO];
	
	[ctrl setDelegate: self];
	
	// Find the files and data to search
	[ctrl addFilesFromProject: [self document]];
	
	// Display the window
	[ctrl showWindow: self];
	// ctrl will autorelease itself when done
	
	// Start the search
	[ctrl startSearch];
}

// == The transcript menu ==

- (IBAction) lastCommand: (id) sender {
	// Display the transcript
	IFProjectPane* transcriptPane = [self transcriptPane];
	IFTranscriptView* transcriptView = [transcriptPane transcriptView];

	if ([[[transcriptView layout] skein] activeItem] == nil) {
		// No active item to show
		NSBeep();
		return;
	}
		
	// Scroll to the 'active' item in the transcript
	[transcriptPane selectView: IFTranscriptPane];
	[[transcriptView layout] transcriptToPoint: [[[transcriptView layout] skein] activeItem]];
	[transcriptView scrollToItem: [[[transcriptView layout] skein] activeItem]];
}

- (IBAction) lastCommandInSkein: (id) sender {
	// Display the skein
	IFProjectPane* skeinPane = [self skeinPane];
	ZoomSkeinView* skeinView = [skeinPane skeinView];

	if ([[skeinView skein] activeItem] == nil) {
		// No active item to show
		NSBeep();
		return;
	}
		
	// Scroll to the 'active' item in the skein
	[skeinPane selectView: IFSkeinPane];
	[skeinView scrollToItem: [[skeinView skein] activeItem]];
}

- (ZoomSkeinItem*) currentTranscriptCommand: (BOOL) preferBottom {
	// Get the 'current' command: the command presently at the top/bottom of the window (or the selected command if it's visible)
	IFProjectPane* transcriptPane = [self transcriptPane];
	IFTranscriptView* transcriptView = [transcriptPane transcriptView];
	
	// Get the items that are currently showing in the transcript view
	ZoomSkeinItem* highlighted = [transcriptView highlightedItem];
	NSRect visibleRect = [transcriptView visibleRect];
	NSArray* visibleItems = [[transcriptView layout] itemsInRect: visibleRect];
	
	// Some trivial cases
	if ([visibleItems count] <= 0) return nil;
	if ([visibleItems count] == 1) return [[visibleItems objectAtIndex: 0] skeinItem];
	if ([visibleItems count] == 2) return [[visibleItems objectAtIndex: preferBottom?1:0] skeinItem];
	
	// If the highlighted item is showing, then return that as the current item
	NSEnumerator* itemEnum = [visibleItems objectEnumerator];
	IFTranscriptItem* item;
	
	while (item = [itemEnum nextObject]) {
		if ([item skeinItem] == highlighted) return highlighted;
	}
	
	// Return the upper/lower item depending on the value of preferBottom
	if (preferBottom) {
		return [[visibleItems objectAtIndex: [visibleItems count]-2] skeinItem];
	} else {
		return [[visibleItems objectAtIndex: 1] skeinItem];
	}
}

- (IBAction) lastChangedCommand: (id) sender {
	// Display the transcript
	IFProjectPane* transcriptPane = [self transcriptPane];
	IFTranscriptView* transcriptView = [transcriptPane transcriptView];
	
	ZoomSkeinItem* currentItem = [self currentTranscriptCommand: NO];

	if (!currentItem) {
		// Can do nothing if there's no current items
		NSBeep();
		return;
	}
	
	// Find the last item
	IFTranscriptItem* lastItem = [[transcriptView layout] lastChanged: 
		[[transcriptView layout] itemForItem: currentItem]];
	
	if (!lastItem) {
		// No previous item
		NSBeep();
		return;
	}
	
	// Move to the last item
	[transcriptView scrollToItem: [lastItem skeinItem]];
	[transcriptView setHighlightedItem: [lastItem skeinItem]];
}

- (IBAction) nextChangedCommand: (id) sender {
	// Display the transcript
	IFProjectPane* transcriptPane = [self transcriptPane];
	IFTranscriptView* transcriptView = [transcriptPane transcriptView];
	
	ZoomSkeinItem* currentItem = [self currentTranscriptCommand: NO];
	
	if (!currentItem) {
		// Can do nothing if there's no current items
		NSBeep();
		return;
	}
	
	// Find the next item
	IFTranscriptItem* nextItem = [[transcriptView layout] nextChanged: 
		[[transcriptView layout] itemForItem: currentItem]];
	
	if (!nextItem) {
		// No previous item
		NSBeep();
		return;
	}
	
	// Move to the next item
	[transcriptView scrollToItem: [nextItem skeinItem]];
	[transcriptView setHighlightedItem: [nextItem skeinItem]];
}

- (IBAction) lastDifference: (id) sender {
	// Display the transcript
	IFProjectPane* transcriptPane = [self transcriptPane];
	IFTranscriptView* transcriptView = [transcriptPane transcriptView];
	
	ZoomSkeinItem* currentItem = [self currentTranscriptCommand: NO];
	
	if (!currentItem) {
		// Can do nothing if there's no current items
		NSBeep();
		return;
	}
	
	// Find the last item
	IFTranscriptItem* lastItem = [[transcriptView layout] lastDiff: 
		[[transcriptView layout] itemForItem: currentItem]];
	
	if (!lastItem) {
		// No previous item
		NSBeep();
		return;
	}
	
	// Move to the last item
	[transcriptView scrollToItem: [lastItem skeinItem]];
	[transcriptView setHighlightedItem: [lastItem skeinItem]];
}

- (IBAction) nextDifference: (id) sender {
	// Display the transcript
	IFProjectPane* transcriptPane = [self transcriptPane];
	IFTranscriptView* transcriptView = [transcriptPane transcriptView];
	
	ZoomSkeinItem* currentItem = [self currentTranscriptCommand: NO];
	
	if (!currentItem) {
		// Can do nothing if there's no current items
		NSBeep();
		return;
	}
	
	// Find the next item
	IFTranscriptItem* nextItem = [[transcriptView layout] nextDiff: 
		[[transcriptView layout] itemForItem: currentItem]];
	
	if (!nextItem) {
		// No previous item
		NSBeep();
		return;
	}
	
	// Move to the next item
	[transcriptView scrollToItem: [nextItem skeinItem]];
	[transcriptView setHighlightedItem: [nextItem skeinItem]];
}

// = UIDelegate methods =

// We only implement a fairly limited subset of the UI methods, mainly to help show status
- (void)						webView:(WebView *)sender 
	 runJavaScriptAlertPanelWithMessage:(NSString *)message {
	NSRunAlertPanel([[NSBundle mainBundle] localizedStringForKey: @"JavaScript Alert"
														   value: @"JavaScript Alert"
														   table: nil],
					message,
					[[NSBundle mainBundle] localizedStringForKey: @"Continue"
														   value: @"Continue"
														   table: nil],
					nil, nil);
}

- (void)	webView:(WebView *)sender 
	  setStatusText:(NSString *)text {
	[statusInfo setStringValue: text];
}

@end
