//
//  IFProjectPane.m
//  Inform
//
//  Created by Andrew Hunter on Wed Sep 10 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFProjectPane.h"
#import "IFProject.h"
#import "IFProjectController.h"
#import "IFAppDelegate.h"
#import "IFPretendWebView.h"

#import "IFIsFiles.h"
#import "IFIsWatch.h"

#import "IFPreferences.h"

// Approximate maximum length of file to highlight in one 'iteration'
#define minHighlightAmount 2048
#define maxHighlightAmount 2048
#undef  showHighlighting        // Show what's being highlighted
#undef  highlightAll            // Always highlight the entire file (does not necessarily recalculate all highlighting)

NSDictionary* IFSyntaxAttributes[256];

@implementation IFProjectPane

+ (IFProjectPane*) standardPane {
    return [[[self alloc] init] autorelease];
}

+ (void) initialize {
    NSFont* systemFont       = [NSFont systemFontOfSize: 11];
    NSFont* smallFont        = [NSFont boldSystemFontOfSize: 9];
    NSFont* boldSystemFont   = [NSFont boldSystemFontOfSize: 11];
    NSFont* headerSystemFont = [NSFont boldSystemFontOfSize: 12];
    NSFont* monospaceFont    = [NSFont fontWithName: @"Monaco"
                                               size: 9];
	
	[[ZoomPreferences globalPreferences] setDisplayWarnings: NO];
	    
    // Default style
    NSDictionary* defaultStyle = [[NSDictionary dictionaryWithObjectsAndKeys:
        systemFont, NSFontAttributeName, 
        [NSColor blackColor], NSForegroundColorAttributeName,
        nil] retain];
    int x;
    
    for (x=0; x<256; x++) {
        IFSyntaxAttributes[x] = defaultStyle;
    }
    
    // This set of styles will eventually be the 'colourful' set
    // We also need a 'no styles' set (probably just turn off the highlighter, gives
    // speed advantages), and a 'subtle' set (styles indicated only by font changes)
    
    // Styles for various kinds of code
    IFSyntaxAttributes[IFSyntaxString] = [[NSDictionary dictionaryWithObjectsAndKeys:
        systemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.53 green: 0.08 blue: 0.08 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxComment] = [[NSDictionary dictionaryWithObjectsAndKeys:
        smallFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.14 green: 0.43 blue: 0.14 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxMonospace] = [[NSDictionary dictionaryWithObjectsAndKeys:
        monospaceFont, NSFontAttributeName,
        [NSColor blackColor], NSForegroundColorAttributeName,
        nil] retain];
    
    // Inform 6 syntax types
    IFSyntaxAttributes[IFSyntaxDirective] = [[NSDictionary dictionaryWithObjectsAndKeys:
        systemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.20 green: 0.08 blue: 0.53 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxProperty] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.08 green: 0.08 blue: 0.53 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxFunction] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.08 green: 0.53 blue: 0.53 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxCode] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.46 green: 0.06 blue: 0.31 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxAssembly] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.46 green: 0.31 blue: 0.31 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxCodeAlpha] = [[NSDictionary dictionaryWithObjectsAndKeys:
        systemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.4 green: 0.4 blue: 0.3 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    IFSyntaxAttributes[IFSyntaxEscapeCharacter] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.73 green: 0.2 blue: 0.73 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
	
	// Natural Inform tab stops
	NSMutableParagraphStyle* tabStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[tabStyle autorelease];

	NSMutableArray* tabStops = [NSMutableArray array];
	for (x=0; x<48; x++) {
		NSTextTab* tab = [[NSTextTab alloc] initWithType: NSLeftTabStopType
												location: 64.0*(x+1)];
		[tabStops addObject: tab];
		[tab release];
	}
	[tabStyle setTabStops: tabStops];
	
    // Natural inform syntax types
	IFSyntaxAttributes[IFSyntaxNaturalInform] = [[NSDictionary dictionaryWithObjectsAndKeys:
        systemFont, NSFontAttributeName, 
        [NSColor blackColor], NSForegroundColorAttributeName,
		tabStyle, NSParagraphStyleAttributeName,
        nil] retain];	
    IFSyntaxAttributes[IFSyntaxHeading] = [[NSDictionary dictionaryWithObjectsAndKeys:
        headerSystemFont, NSFontAttributeName,
		[NSColor blackColor], NSForegroundColorAttributeName,
		tabStyle, NSParagraphStyleAttributeName,
        nil] retain];
	IFSyntaxAttributes[IFSyntaxGameText] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.0 green: 0.3 blue: 0.6 alpha: 1.0], NSForegroundColorAttributeName,
		tabStyle, NSParagraphStyleAttributeName,
        nil] retain];	
	IFSyntaxAttributes[IFSyntaxSubstitution] = [[NSDictionary dictionaryWithObjectsAndKeys:
		systemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.3 green: 0.3 blue: 1.0 alpha: 1.0], NSForegroundColorAttributeName,
		tabStyle, NSParagraphStyleAttributeName,
        nil] retain];	
	
	// The 'plain' style is a bit of a special case. It's used for files that we want to run the syntax
	// highlighter on, but where we want the user to be able to set styles. The user will be able to set
	// certain styles even for things that are affected by the highlighter.
	IFSyntaxAttributes[IFSyntaxPlain] = [[NSDictionary dictionary] retain];
}

- (id) init {
    self = [super init];

    if (self) {
        parent = nil;
        zView = nil;
        gameToRun = nil;
        awake = NO;
        
        sourceFiles = [[NSMutableArray allocWithZone: [self zone]] init];
        [openSourceFile release];
		
		textStorage = nil;
    }

    return self;
}

- (void) dealloc {
	if (gameRunningProgress) {
		[parent removeProgressIndicator: gameRunningProgress];
		[gameRunningProgress release];
		gameRunningProgress = nil;
	}
	
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    // FIXME: memory leak?
    //    -- Caused by a bug in NSTextView it appears (just creating
    //       anything with an NSTextView causes the same leak).
    //       Doesn't always happen. Not very much memory. Still annoying.
    // (Better in Panther? Looks like it)
    [paneView       release];
    [compController release];
    [sourceFiles    release];
    
	if (textStorage) {
		// Hrm? Cocoa seems to like deallocating NSTextStorage despite it's retain count.
		// Ah, wait, NSTextView does not retain a text storage added using [NSTextStorage addLayoutManager:]
		// so, it does honour the retain count, but doesn't monitor it correctly.
		// Regardless, this fixes the problem. Not sure if this is a Cocoa bug or not.
		// Weirdly, this causes a problem if the NSTextView is not the last owner of the NSTextStorage.
		// Hrm, likely cause: if the NSTextStorage is deallocated first, it deregisters itself gracefully.
		// If the NSTextView is deallocated first, it deallocates the NSTextStorage, but we're still using
		// it elsewhere. KABOOOM!
		
		[textStorage removeLayoutManager: [sourceText layoutManager]];
		[textStorage release];
	}
    if (zView) {
		[zView setDelegate: nil];
		[zView killTask];
		[zView release];
	}
	if (gView) {
		[gView setDelegate: nil];
		[gView terminateClient];
		[gView release];
	}
	if (pointToRunTo) [pointToRunTo release];
    if (gameToRun) [gameToRun release];
	if (wView) [wView release];
	
	if (lastAnnotation) [lastAnnotation release];
	if (transcriptController) [transcriptController release];
    
    [super dealloc];
}

+ (NSDictionary*) attributeForStyle: (IFSyntaxStyle) style {
	return [[[IFPreferences sharedPreferences] styles] objectAtIndex: (unsigned)style];
	// return IFSyntaxAttributes[style];
}

- (NSView*) paneView {
    if (!awake) {
        [NSBundle loadNibNamed: @"ProjectPane"
                         owner: self];
    }
    
    return paneView;
}

- (NSView*) activeView {
    switch ([self currentView]) {
        case IFSourcePane:
            return sourceText;
        default:
            return [[tabView selectedTabViewItem] view];
    }
}

- (void) removeFromSuperview {
    [paneView removeFromSuperview];
}

- (void) setupFromController {
    IFProject* doc;

    [[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(updateSettings)
												 name: IFSettingNotification
											   object: [[parent document] settings]];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(updatedBreakpoints:)
												 name: IFProjectBreakpointsChangedNotification
											   object: [parent document]];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(sourceFileRenamed:)
												 name: IFProjectSourceFileRenamedNotification 
											   object: [parent document]];
		
    doc = [parent document];

	[sourceText setContinuousSpellCheckingEnabled: NO];
    [[sourceText textStorage] removeLayoutManager: [sourceText layoutManager]];

    NSTextStorage* mainFile = [doc storageForFile: [doc mainSourceFile]];
	if (mainFile == nil) {
		NSLog(@"BUG: no main file!");
		mainFile = [[[NSTextStorage alloc] init] autorelease];
	}
    NSString* mainFilename =  [doc mainSourceFile];
    
    [openSourceFile release];
    openSourceFile = [mainFilename copy];
    
    [mainFile addLayoutManager: [sourceText layoutManager]];
	if (textStorage) { [textStorage release]; textStorage = nil; }
	textStorage = [mainFile retain];

    [compController setCompiler: [doc compiler]];
    [compController setDelegate: self];
    [self updateSettings];
	
	[self updateIndexView];
	
	// The skein view
	[skeinView setSkein: [doc skein]];
	[skeinView setDelegate: parent];

	// (Problem with this is that it updates the menu on every change, which might get to be slow)
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(skeinDidChange:)
												 name: ZoomSkeinChangedNotification
											   object: [doc skein]];
	[self skeinDidChange: nil];
	
	if ([[NSApp delegate] isWebKitAvailable]) {
		[wView setPolicyDelegate: [parent generalPolicy]];
	}
	
	// The transcript controller
	[transcriptController setSkein: [doc skein]];
	
	// Misc stuff
	[self updateHighlightedLines];
}

- (void) awakeFromNib {
    awake = YES;
	    
	if ((int)[[NSApp delegate] isWebKitAvailable]) {
		// The documentation tab
		wView = [[WebView alloc] init];
		[wView setResourceLoadDelegate: self];
		[docTabView setView: wView];
		[[wView mainFrame] loadRequest: [[[NSURLRequest alloc] initWithURL: [NSURL URLWithString: @"inform:/index.html"]] autorelease]];
	} else {
		wView = nil;
	}
	
    if (parent) {
        [self setupFromController];
        [self stopRunningGame];
    }
	
    [tabView setDelegate: self];
    
    //[sourceText setUsesFindPanel: YES]; -- Not 10.2
}

- (void) setController: (IFProjectController*) p {
    if (!awake) {
        [NSBundle loadNibNamed: @"ProjectPane"
                         owner: self];
    }

    // (Don't need to retain parent, as the parent 'owns' us)
    // Don't need to release for similar reasons.
    parent = p;

    if (awake) {
        [self setupFromController];
    }
}

- (void) selectView: (enum IFProjectPaneType) pane {
    if (!awake) {
        [NSBundle loadNibNamed: @"ProjectPane"
                         owner: self];
    }
    
    NSTabViewItem* toSelect = nil;
    switch (pane) {
        case IFSourcePane:
            toSelect = sourceView;
            break;

        case IFErrorPane:
            toSelect = errorsView;
            break;

        case IFGamePane:
            toSelect = gameTabView;
            break;

        case IFDocumentationPane:
            toSelect = docTabView;
            break;
			
		case IFIndexPane:
			toSelect = indexTabView;
			break;
			
		case IFTranscriptPane:
			toSelect = transcriptTabView;
			break;
			
		case IFUnknownPane:
			// No idea
			break;
    }

    if (toSelect) {
        [tabView selectTabViewItem: toSelect];
    } else {
        NSLog(@"Unable to select pane");
    }
}

- (enum IFProjectPaneType) currentView {
    NSTabViewItem* selectedView = [tabView selectedTabViewItem];

    if (selectedView == sourceView) {
        return IFSourcePane;
    } else if (selectedView == errorsView) {
        return IFErrorPane;
    } else if (selectedView == gameTabView) {
        return IFGamePane;
    } else if (selectedView == docTabView) {
        return IFDocumentationPane;
	} else if (selectedView == indexTabView) {
		return IFIndexPane;
	} else if (selectedView == transcriptTabView) {
		return IFTranscriptPane;
    } else {
        NSLog(@"BUG: unknown tab pane selected (assuming is a source pane)");
        return IFSourcePane;
    }
}

- (void) errorMessageHighlighted: (IFCompilerController*) sender
                          atLine: (int) line
                          inFile: (NSString*) file {
    if (![parent selectSourceFile: file]) {
        // Maybe implement me: show an error alert?
        return;
    }
    
    [parent moveToSourceFileLine: line];
	[parent removeHighlightsOfStyle: IFLineStyleError];
    [parent highlightSourceFileLine: line
							 inFile: openSourceFile
							  style: IFLineStyleError]; // FIXME: error level?. Filename?
}

- (BOOL) handleURLRequest: (NSURLRequest*) req {
	[[parent auxPane] openURL: [[[req URL] copy] autorelease]];
	
	return YES;
}

- (IFCompilerController*) compilerController {
    return compController;
}

- (NSString*) currentFile {
	return [[parent document] pathForFile: openSourceFile];
}

- (int) currentLine {
	int selPos = [sourceText selectedRange].location;
	
	if (selPos < 0 || selPos >= [textStorage length]) return -1;
	
	// Count the number of newlines until the current line
	// (Take account of CRLF or LFCR style things)
	int x;
	int line = 0;
	
	unichar lastNewline = 0;
	
	for (x=0; x<selPos; x++) {
		unichar chr = [[textStorage string] characterAtIndex: x];
		
		if (chr == '\n' || chr == '\r') {
			if (lastNewline != 0 && chr != lastNewline) {
				// CRLF combination
				lastNewline = 0;
			} else {
				lastNewline = chr;
				line++;
			}
		} else {
			lastNewline = 0;
		}
	}
	
	return line;
}

// = The source view =

- (void) moveToLine: (int) line {
	[self moveToLine: line
		   character: 0];
}

- (void) moveToLine: (int) line
		  character: (int) chrNo {
    // Find out where the line is in the source view
    NSString* store = [[sourceText textStorage] string];
    int length = [store length];

    int x, lineno, linepos, lineLength;
    lineno = 1; linepos = 0;
    for (x=0; x<length; x++) {
        unichar chr = [store characterAtIndex: x];
        
        if (chr == '\n' || chr == '\r') {
            unichar otherchar = chr == '\n'?'r':'n';
            
            lineno++;
            linepos = x + 1;
            
            // Deal with DOS line endings
            if ([store characterAtIndex: linepos] == otherchar) {
                x++; linepos++;
            }
            
            if (lineno == line) {
                break;
            }
        }
    }

    if (lineno != line) {
        NSBeep(); // DOH!
        return;
    }

    lineLength = 1;
    for (x=0; x<length; x++) {
        if ([store characterAtIndex: x] == '\n') {
            break;
        }
        lineLength++;
    }
	
	// Add the character position
	linepos += chrNo;
        
    // Time to scroll
	[sourceText scrollRangeToVisible: NSMakeRange(linepos, 1)];
    [sourceText setSelectedRange: NSMakeRange(linepos,0)];
}

- (void) moveToLocation: (int) location {
	[sourceText scrollRangeToVisible: NSMakeRange(location, 0)];
	[sourceText setSelectedRange: NSMakeRange(location, 0)];
}

- (void) showSourceFile: (NSString*) file {
	if ([[[parent document] pathForFile: file] isEqualToString: [[parent document] pathForFile: openSourceFile]]) {
		// Nothing to do
		return;
	}
	
	NSTextStorage* fileStorage = [[parent document] storageForFile: file];
	
	if (fileStorage == nil) return;
	
	[fileStorage beginEditing];
	
	NSLayoutManager* layout = [[sourceText layoutManager] retain];
	
	[sourceText setSelectedRange: NSMakeRange(0,0)];
	[[sourceText textStorage] removeLayoutManager: [sourceText layoutManager]];
	
	[openSourceFile release];
	openSourceFile = [[[parent document] pathForFile: file] copy];
	//openSourceFile = [[file lastPathComponent] copy];
	
	[fileStorage addLayoutManager: [layout autorelease]];
	[fileStorage setDelegate: self];
	if (textStorage) { [textStorage release]; textStorage = nil; }
	textStorage = [fileStorage retain];
	
	[fileStorage endEditing];
	
	[sourceText setEditable: ![[parent document] fileIsTemporary: file]];
	
	[[IFIsFiles sharedIFIsFiles] updateFiles]; // have to update for the case where we select an 'unknown' file
}

- (void) sourceFileRenamed: (NSNotification*) not {
	// Called when a source file is renamed in the document. We need to do nothing, unless the source file
	// is the one we're displaying, in which we need to update the name of the source file we're displaying
	NSDictionary* dict = [not userInfo];
	NSString* oldName = [dict objectForKey: @"OldFilename"];
	NSString* newName = [dict objectForKey: @"NewFilename"];
	
	if ([[oldName lowercaseString] isEqualToString: [[openSourceFile lastPathComponent] lowercaseString]]) {
		// The file being renamed is the one currently being displayed
		NSString* newSourceFile = [[[parent document] pathForFile: newName] copy];
		
		if (newSourceFile) {
			[openSourceFile release];
			openSourceFile = newSourceFile;
		}

		[[IFIsFiles sharedIFIsFiles] updateFiles];
	}
}

- (NSRange) findLine: (int) line {
    NSString* store = [[sourceText textStorage] string];
    int length = [store length];
	
    int x, lineno, linepos;
    lineno = 1; linepos = 0;
    for (x=0; x<length; x++) {
        unichar chr = [store characterAtIndex: x];
        
        if (chr == '\n' || chr == '\r') {
            unichar otherchar = chr == '\n'?'r':'n';
            
            lineno++;
            linepos = x + 1;
            
            // Deal with DOS line endings
            if ([store characterAtIndex: linepos] == otherchar) {
                x++; linepos++;
            }
            
            if (lineno == line) {
                break;
            }
        }
    }
	
    if (lineno != line) {
        return NSMakeRange(NSNotFound, 0);
    }
	
	// Find the end of this line
	for (x=linepos; x<length; x++) {
        unichar chr = [store characterAtIndex: x];
        
        if (chr == '\n' || chr == '\r') {
			break;
		}
	}
	
	return NSMakeRange(linepos, x - linepos + 1);
}

// = Settings =

- (void) updateSettings {
	if (!parent) {
		return; // Nothing to do
	}
	
	[settingsController setCompilerSettings: [[parent document] settings]];
	[settingsController updateAllSettings];
	
	return;
}

// = The game view =

- (void) activateDebug {
	setBreakpoint = YES;
}

- (void) startRunningGame: (NSString*) fileName {
	[[[parent document] skein] zoomInterpreterRestart];
	
    if (zView) {
		[zView killTask];
        [zView removeFromSuperview];
        [zView release];
        zView = nil;
    }
	
	if (gView) {
		[gView terminateClient];
		[gView removeFromSuperview];
		[gView release];
		gView = nil;
	}
    
    if (gameToRun) [gameToRun release];
    gameToRun = [fileName copy];
	
	if (!gameRunningProgress) {
		gameRunningProgress = [[IFProgress alloc] init];
		[parent addProgressIndicator: gameRunningProgress];
	}
    
	[gameRunningProgress setMessage: [[NSBundle mainBundle] localizedStringForKey: @"Loading story file"
																			value: @"Loading story file"
																			table: nil]];
	
	if ([[gameToRun pathExtension] isEqualToString: @"ulx"]) {
		// Start running as a glulxe task
		gView = [[GlkView alloc] init];
		[gView setDelegate: self];
		
		[gView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
		[gView setFrame: [gameView bounds]];
		[gameView addSubview: gView];
		
		[gView setInputFilename: fileName];
		[gView launchClientApplication: [[NSBundle mainBundle] pathForResource: @"glulxe"
																		ofType: @""
																   inDirectory: @""]
						 withArguments: nil];
	} else {
		// Start running as a Zoom task
		zView = [[ZoomView allocWithZone: [self zone]] init];
		[zView setDelegate: self];
		[[[parent document] skein] zoomInterpreterRestart];
		[zView addOutputReceiver: [[parent document] skein]];
		[zView runNewServer: nil];
		
		[zView setColours: [NSArray arrayWithObjects:
			[NSColor colorWithDeviceRed: 0 green: 0 blue: 0 alpha: 1],
			[NSColor colorWithDeviceRed: 1 green: 0 blue: 0 alpha: 1],
			[NSColor colorWithDeviceRed: 0 green: 1 blue: 0 alpha: 1],
			[NSColor colorWithDeviceRed: 1 green: 1 blue: 0 alpha: 1],
			[NSColor colorWithDeviceRed: 0 green: 0 blue: 1 alpha: 1],
			[NSColor colorWithDeviceRed: 1 green: 0 blue: 1 alpha: 1],
			[NSColor colorWithDeviceRed: 0 green: 1 blue: 1 alpha: 1],
			[NSColor colorWithDeviceRed: 1 green: 1 blue: 1 alpha: 1],
			
			[NSColor colorWithDeviceRed: .73 green: .73 blue: .73 alpha: 1],
			[NSColor colorWithDeviceRed: .53 green: .53 blue: .53 alpha: 1],
			[NSColor colorWithDeviceRed: .26 green: .26 blue: .26 alpha: 1],
			nil]];
		
		[zView setFrame: [gameView bounds]];
		[zView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
		[gameView addSubview: zView];
	}
}

- (void) setPointToRunTo: (ZoomSkeinItem*) item {
	if (pointToRunTo) [pointToRunTo release];
	pointToRunTo = [item retain];
}

- (void) stopRunningGame {
    if (zView) {
		[zView killTask];
    }
	
	if (gView) {
		[gView terminateClient];
	}
    
    if ([tabView selectedTabViewItem] == gameTabView) {
        [tabView selectTabViewItem: errorsView];
    }
}

- (void) pauseRunningGame {
	if (zView) {
		[zView debugTask];
	}
}

- (ZoomView*) zoomView {
	return zView;
}

- (GlkView*) glkView {
	return gView;
}

- (BOOL) isRunningGame {
	return (zView != nil && [zView isRunning]) || (gView != nil);
}

// (GlkView delegate functions)
- (void) taskHasStarted {
    [tabView selectTabViewItem: gameTabView];

	[gameRunningProgress setMessage: [[NSBundle mainBundle] localizedStringForKey: @"Story started"
																			value: @"Story started"
																			table: nil]];
	[parent removeProgressIndicator: gameRunningProgress];
	[gameRunningProgress release];
	gameRunningProgress = nil;	
}

// (ZoomView delegate functions)
- (void) zMachineStarted: (id) sender {	
    [[zView zMachine] loadStoryFile: 
        [NSData dataWithContentsOfFile: gameToRun]];
	
	[[zView zMachine] loadDebugSymbolsFrom: [[[[parent document] fileName] stringByAppendingPathComponent: @"Build"] stringByAppendingPathComponent: @"gameinfo.dbg"]
							withSourcePath: [[[parent document] fileName] stringByAppendingPathComponent: @"Source"]];
	
	// Set the initial breakpoint if 'Debug' was selected
	if (setBreakpoint) {
		if (![[zView zMachine] setBreakpointAtName: @"Initialise"]) {
			[[zView zMachine] setBreakpointAtName: @"main"];
		}
	}
	
	// Set the other breakpoints anyway
	int breakpoint;
	for (breakpoint = 0; breakpoint < [[parent document] breakpointCount]; breakpoint++) {
		int line = [[parent document] lineForBreakpointAtIndex: breakpoint];
		NSString* file = [[parent document] fileForBreakpointAtIndex: breakpoint];
		
		if (line >= 0) {
			if (![[zView zMachine] setBreakpointAtName: [NSString stringWithFormat: @"%@:%i", file, line+1]]) {
				NSLog(@"Failed to set breakpoint at %@:%i", file, line+1);
			}
		}
	}
	
	setBreakpoint = NO;
	
	if (pointToRunTo) {
		id inputSource = [ZoomSkein inputSourceFromSkeinItem: [[[parent document] skein] rootItem]
													  toItem: pointToRunTo];
		
		[zView setInputSource: inputSource];
		
		[pointToRunTo release];
		pointToRunTo = nil;
	}
	
    [tabView selectTabViewItem: gameTabView];
    [[paneView window] makeFirstResponder: [zView textView]];
	
	[gameRunningProgress setMessage: [[NSBundle mainBundle] localizedStringForKey: @"Story started"
																			value: @"Story started"
																			table: nil]];
	[parent removeProgressIndicator: gameRunningProgress];
	[gameRunningProgress release];
	gameRunningProgress = nil;
}

// = Tab view delegate =
- (BOOL)            tabView: (NSTabView *)view 
    shouldSelectTabViewItem:(NSTabViewItem *)item {
    if (item == gameTabView && (zView == nil && gView == nil)) {
        // FIXME: if another view is running a game, then display the tabView in there
        return NO;
    }
	
	if (item == indexTabView && !indexAvailable) {
		return NO;
	}

    return YES;
}

// = Intelligence =

- (IFIntelFile*) currentIntelligence {
	// IQ: 0
	if ([textStorage isKindOfClass: [IFSyntaxStorage class]]) {
		return [(IFSyntaxStorage*)textStorage intelligenceData];
	} else {
		return nil;
	}
}

// = Syntax highlighting =

- (void) updateHighlightedLines {
	NSEnumerator* highEnum;
	NSArray* highlight;
	
	[[sourceText layoutManager] removeTemporaryAttribute: NSBackgroundColorAttributeName
									   forCharacterRange: NSMakeRange(0, [[sourceText textStorage] length])];
	
	// Highlight the lines as appropriate
	highEnum = [[parent highlightsForFile: openSourceFile] objectEnumerator];
	
	while (highlight = [highEnum nextObject]) {
		int line = [[highlight objectAtIndex: 0] intValue];
		enum lineStyle style = [[highlight objectAtIndex: 1] intValue];
		NSColor* background = nil;
		
		switch (style) {
			case IFLineStyleNeutral:
				background = [NSColor colorWithDeviceRed: 0.3 green: 0.3 blue: 0.8 alpha: 1.0];
				break;
				
			case IFLineStyleExecutionPoint:
				background = [NSColor colorWithDeviceRed: 0.8 green: 0.8 blue: 0.3 alpha: 1.0];
				break;
				
			case IFLineStyleHighlight:
				background = [NSColor colorWithDeviceRed: 0.3 green: 0.8 blue: 0.8 alpha: 1.0];
				break;
				
			case IFLineStyleError:
				background = [NSColor colorWithDeviceRed: 1.0 green: 0.3 blue: 0.3 alpha: 1.0];
				break;
				
			case IFLineStyleBreakpoint:
				background = [NSColor colorWithDeviceRed: 1.0 green: 0.7 blue: 0.4 alpha: 1.0];
				break;
				
			default:
				background = [NSColor colorWithDeviceRed: 0.8 green: 0.3 blue: 0.3 alpha: 1.0];
				break;
		}
		
		NSRange lineRange = [self findLine: line];
		
		if (lineRange.location != NSNotFound) {
			[[sourceText layoutManager] setTemporaryAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
				background, NSBackgroundColorAttributeName, nil]
											 forCharacterRange: lineRange];
		}
	}
}

// == Debugging ==

- (void) hitBreakpoint: (int) pc {
	[[IFIsWatch sharedIFIsWatch] refreshExpressions];
	[parent hitBreakpoint: pc];
}

- (void) zoomWaitingForInput {
	[[IFIsWatch sharedIFIsWatch] refreshExpressions];
}

// == Documentation ==

- (void) openURL: (NSURL*) url  {
	[tabView selectTabViewItem: docTabView];

	[[wView mainFrame] loadRequest: [[[NSURLRequest alloc] initWithURL: url] autorelease]];
}

// = The index view =

- (void) updateIndexView {
	indexAvailable = NO;
	
	if (![IFAppDelegate isWebKitAvailable]) return;
	
	// The index path
	NSString* indexPath = [NSString stringWithFormat: @"%@/Index", [[parent document] fileName]];
	BOOL isDir = NO;
	
	// Check that it exists and is a directory
	if (indexPath == nil) return;
	if (![[NSFileManager defaultManager] fileExistsAtPath: indexPath
											  isDirectory: &isDir]) return;
	if (!isDir) return;		
	
	// Create the tab view that will eventually go into the main view
	if (indexTabs != nil) {
		[indexTabs removeFromSuperview];
		[indexTabs release];
		indexTabs = nil;
	}
	
	indexTabs = [[NSTabView alloc] initWithFrame: [indexView bounds]];
	[indexTabs setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
	[indexView addSubview: indexTabs];
	
	[indexTabs setControlSize: NSSmallControlSize];
	[indexTabs setFont: [NSFont systemFontOfSize: 10]];
	[indexTabs setAllowsTruncatedLabels: YES];

	// Iterate through the files
	NSArray* files = [[NSFileManager defaultManager] directoryContentsAtPath: indexPath];
	NSEnumerator* fileEnum = [files objectEnumerator];
	NSString* theFile;
	
	NSBundle* mB = [NSBundle mainBundle];
	
	while (theFile = [fileEnum nextObject]) {
		NSString* extension = [[theFile pathExtension] lowercaseString];
		NSString* fullPath = [indexPath stringByAppendingPathComponent: theFile];
		
		if ([extension isEqualToString: @"htm"] ||
			[extension isEqualToString: @"html"] ||
			[extension isEqualToString: @"skein"]) {
			// Create a parent view
			NSView* fileView = [[NSView alloc] init];
			[fileView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
			[fileView autorelease];
			
			// Create a 'fake' web view which will get replaced when the view is actually displayed on screen
			IFPretendWebView* pretendView = [[IFPretendWebView alloc] initWithFrame: [fileView bounds]];
			
			[pretendView setHostWindow: [paneView window]];
			[pretendView setRequest: [[[NSURLRequest alloc] initWithURL: [IFProjectPolicy fileURLWithPath: fullPath]] autorelease]];
			[pretendView setPolicyDelegate: [parent docPolicy]];
			
			[pretendView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
			
			// Add it to fileView
			[fileView addSubview: [pretendView autorelease]];
			
			// Create the tab to put this view in
			NSTabViewItem* newTab = [[[NSTabViewItem alloc] init] autorelease];
			
			[newTab setView: fileView];
			[newTab setLabel: [mB localizedStringForKey: theFile
												  value: [theFile stringByDeletingPathExtension]
												  table: @"CompilerOutput"]];
			
			// Add the tab
			[indexTabs addTabViewItem: newTab];
			indexAvailable = YES;
		}
	}
}

// = WebResourceLoadDelegate methods =

-(void)		webView:(WebView *)sender 
		   resource:(id)identifier didFailLoadingWithError:(NSError *)error 
	 fromDataSource:(WebDataSource *)dataSource {
	NSLog(@"IFprojectPane: failed to load page with error: %@", [error localizedDescription]);
}

// = The skein view =

- (void) skeinDidChange: (NSNotification*) not {
	[[[parent document] skein] populatePopupButton: skeinLabelButton];
	[skeinLabelButton selectItem: nil];
}

- (IBAction) skeinLabelSelected: (id) sender {
	NSString* annotation = [[sender selectedItem] title];
	
	// Reset the annotation count if required
	if (![annotation isEqualToString: lastAnnotation]) {
		annotationCount = 0;
	}
	
	[lastAnnotation release];
	lastAnnotation = [annotation retain];
	
	// Get the list of items for this annotation
	NSArray* availableItems = [[[parent document] skein] itemsWithAnnotation: lastAnnotation];
	if (!availableItems || [availableItems count] == 0) return;
		
	// Reset the annotation count if required
	if ([availableItems count] <= annotationCount) annotationCount = 0;

	// Scroll to the appropriate item
	[skeinView scrollToItem: [availableItems objectAtIndex: annotationCount]];
	
	// Will scroll to the next item in the list if there's more than one
	annotationCount++;
}

// = The transcript view =

- (IFTranscriptController*) transcriptController {
	return transcriptController;
}

// = Breakpoints =

- (IBAction) setBreakpoint: (id) sender {
	// Sets a breakpoint at the current location in the current source file
	
	// If we're not at the source pane, then do nothing
	if ([self currentView] != IFSourcePane) return;
	
	// Work out which file and line we're in
	NSString* currentFile = [self currentFile];
	int currentLine = [self currentLine];
	
	if (currentLine >= 0) {
		NSLog(@"Added breakpoint at %@:%i", currentFile, currentLine);
		
		[[parent document] addBreakpointAtLine: currentLine
										inFile: currentFile];
	}
}

- (IBAction) deleteBreakpoint: (id) sender {
	// Sets a breakpoint at the current location in the current source file
	
	// If we're not at the source pane, then do nothing
	if ([self currentView] != IFSourcePane) return;
	
	// Work out which file and line we're in
	NSString* currentFile = [self currentFile];
	int currentLine = [self currentLine];
	
	if (currentLine >= 0) {
		NSLog(@"Deleted breakpoint at %@:%i", currentFile, currentLine);
		
		[[parent document] removeBreakpointAtLine: currentLine
										   inFile: currentFile];
	}	
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
	// Can't add breakpoints if we're not showing the source view
	// (Moot: this never gets called at any point where it is useful at the moment)
	if ([menuItem action] == @selector(setBreakpoint:) ||
		[menuItem action] == @selector(deleteBreakpoint:)) {
		return [self currentView]==IFSourcePane;
	}
	
	return YES;
}

- (void) updatedBreakpoints: (NSNotification*) not {
	// Give up if there's no Z-Machine running
	if (!zView) return;
	if (![zView zMachine]) return;
	
	// Clear out the old breakpoints
	[[zView zMachine] removeAllBreakpoints];
	
	// Set the breakpoints
	int breakpoint;
	for (breakpoint = 0; breakpoint < [[parent document] breakpointCount]; breakpoint++) {
		int line = [[parent document] lineForBreakpointAtIndex: breakpoint];
		NSString* file = [[parent document] fileForBreakpointAtIndex: breakpoint];
		
		if (line >= 0) {
			if (![[zView zMachine] setBreakpointAtName: [NSString stringWithFormat: @"%@:%i", file, line+1]]) {
				NSLog(@"Failed to set breakpoint at %@:%i", file, line+1);
			}
		}
	}
}

@end
