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

#import "IFIsFiles.h"
#import "IFIsWatch.h"
#import "IFIsBreakpoints.h"

@implementation IFProjectController

// == Toolbar items ==
static NSToolbarItem* compileItem       = nil;
static NSToolbarItem* compileAndRunItem = nil;
static NSToolbarItem* replayItem		= nil;
static NSToolbarItem* compileAndDebugItem = nil;
static NSToolbarItem* releaseItem       = nil;

static NSToolbarItem* stopItem          = nil;
static NSToolbarItem* pauseItem		    = nil;

static NSToolbarItem* continueItem		= nil;
static NSToolbarItem* stepItem			= nil;
static NSToolbarItem* stepOverItem		= nil;
static NSToolbarItem* stepOutItem		= nil;

static NSToolbarItem* indexItem		    = nil;

static NSToolbarItem* watchItem			= nil;
static NSToolbarItem* breakpointItem	= nil;

static NSDictionary*  itemDictionary = nil;

+ (void) initialize {
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
        nil];

    // FIXME: localisation
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

        //NSRect paneBounds = [panesView bounds];
        
        // Insert the views
        NSSplitView* lastView = nil;
        for (view=0; view<nviews-1; view++) {
            // Garner some information about the views we're dealing with
            NSSplitView*   thisView = [splitViews objectAtIndex: view];
            IFProjectPane* pane     = [projectPanes objectAtIndex: view];
            NSView*        thisPane = [[projectPanes objectAtIndex: view] paneView];

            [pane setController: self];

            if (view == 0) {
                viewWidth *= 1.25;
                viewWidth = floor(viewWidth);
            } else {
                viewWidth = floor(remaining / (double)(nviews-view));
            }

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

// == Toolbar delegate functions ==

- (NSToolbarItem *)toolbar: (NSToolbar *) toolbar
     itemForItemIdentifier: (NSString *)  itemIdentifier
 willBeInsertedIntoToolbar: (BOOL)        flag {
	// Cheat!
	// Actually, I thought you could share NSToolbarItems between windows, but you can't (the images disappear,
	// weirdly). However, copying the item is just as good as creating a new one here, and makes the code
	// somewhat more readable.
    return [[[itemDictionary objectForKey: itemIdentifier] copy] autorelease];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
        @"compileItem", @"compileAndRunItem", @"replayItem", @"compileAndDebugItem", @"pauseItem", @"continueItem", @"stepItem", 
		@"stepOverItem", @"stepOutItem", @"stopItem", @"watchItem", @"breakpointItem", @"indexItem",
		NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, 
		@"releaseItem",
        nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)tb {
	if ([[tb identifier] isEqualToString: @"ProjectNiToolbar"]) {
		return [NSArray arrayWithObjects: @"compileAndRunItem", @"replayItem", @"stopItem", NSToolbarSeparatorItemIdentifier, 
			@"releaseItem", NSToolbarFlexibleSpaceItemIdentifier, @"indexItem", nil];
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
        [theCompiler setOutputFile: [NSString stringWithFormat: @"%@/Build/output.z5",
            [doc fileName]]];
		
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
	
    [[projectPanes objectAtIndex: 1] selectView: IFErrorPane];
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

    // Can't do this: things break.
    //buildDir = [[[(IFProject*)[self document] projectFile] fileWrappers] objectForKey: @"Build"];
    //[buildDir updateFromPath: [NSString stringWithFormat: @"%@/Build", [[self document] fileName]]];

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
	// Returns the current pane containing the source code (or an appropriate pane that source code can be displayed in)
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

- (void) transcriptToPoint: (ZoomSkeinItem*) point {
	IFProjectPane* transcriptPane = [self transcriptPane];
	
	[transcriptPane selectView: IFTranscriptPane];
	[[transcriptPane transcriptController] transcriptToPoint: point];
	[[transcriptPane transcriptController] scrollToItem: point];
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
		[progress setAnimationDelay: 0.1];
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

@end
