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

#import "IFInform6Syntax.h"
#import "IFNaturalInformSyntax.h"

#import "IFIsFiles.h"

// Approximate maximum length of file to highlight in one 'iteration'
#define minHighlightAmount 2048
#define maxHighlightAmount 2048
#undef  showHighlighting        // Show what's being highlighted
#undef  highlightAll            // Always highlight the entire file (does not necessarily recalculate all highlighting)

static NSDictionary* styles[256];

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
    
    // Default style
    NSDictionary* defaultStyle = [[NSDictionary dictionaryWithObjectsAndKeys:
        systemFont, NSFontAttributeName, 
        [NSColor blackColor], NSForegroundColorAttributeName,
        nil] retain];
    int x;
    
    for (x=0; x<256; x++) {
        styles[x] = defaultStyle;
    }
    
    // This set of styles will eventually be the 'colourful' set
    // We also need a 'no styles' set (probably just turn off the highlighter, gives
    // speed advantages), and a 'subtle' set (styles indicated only by font changes)
    
    // Styles for various kinds of code
    styles[IFSyntaxString] = [[NSDictionary dictionaryWithObjectsAndKeys:
        systemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.53 green: 0.08 blue: 0.08 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    styles[IFSyntaxComment] = [[NSDictionary dictionaryWithObjectsAndKeys:
        smallFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.14 green: 0.43 blue: 0.14 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    styles[IFSyntaxMonospace] = [[NSDictionary dictionaryWithObjectsAndKeys:
        monospaceFont, NSFontAttributeName,
        [NSColor blackColor], NSForegroundColorAttributeName,
        nil] retain];
    
    // Inform 6 syntax types
    styles[IFSyntaxDirective] = [[NSDictionary dictionaryWithObjectsAndKeys:
        systemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.20 green: 0.08 blue: 0.53 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    styles[IFSyntaxProperty] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.08 green: 0.08 blue: 0.53 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    styles[IFSyntaxFunction] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.08 green: 0.53 blue: 0.53 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    styles[IFSyntaxCode] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.46 green: 0.06 blue: 0.31 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    styles[IFSyntaxAssembly] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.46 green: 0.31 blue: 0.31 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    styles[IFSyntaxCodeAlpha] = [[NSDictionary dictionaryWithObjectsAndKeys:
        systemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.5 green: 0.5 blue: 0.5 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
    styles[IFSyntaxEscapeCharacter] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.73 green: 0.2 blue: 0.73 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];
        
    // Natural inform syntax types
    styles[IFSyntaxHeading] = [[NSDictionary dictionaryWithObjectsAndKeys:
        headerSystemFont, NSFontAttributeName,
		[NSColor blackColor], NSForegroundColorAttributeName,
        nil] retain];
	styles[IFSyntaxGameText] = [[NSDictionary dictionaryWithObjectsAndKeys:
        boldSystemFont, NSFontAttributeName,
        [NSColor colorWithDeviceRed: 0.0 green: 0.3 blue: 0.6 alpha: 1.0], NSForegroundColorAttributeName,
        nil] retain];	
	
	// The 'plain' style is a bit of a special case. It's used for files that we want to run the syntax
	// highlighter on, but where we want the user to be able to set styles. The user will be able to set
	// certain styles even for things that are affected by the highlighter.
	styles[IFSyntaxPlain] = [[NSDictionary dictionary] retain];
}

- (id) init {
    self = [super init];

    if (self) {
        parent = nil;
        zView = nil;
        gameToRun = nil;
        awake = NO;
        
        highlighter = [[IFInform6Syntax alloc] init];

        sourceFiles = [[NSMutableArray allocWithZone: [self zone]] init];
        [openSourceFile release];

        remainingFileToProcess.location = NSNotFound;
        remainingFileToProcess.length   = 0;
		
		textStorage = nil;
    }

    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    // FIXME: memory leak?
    //    -- Caused by a bug in NSTextView it appears (just creating
    //       anything with an NSTextView causes the same leak).
    //       Doesn't always happen. Not very much memory. Still annoying.
    // (Better in Panther?)
    [paneView       release];
    [compController release];
    [sourceFiles    release];
    [highlighter    release];
    
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
    if (zView) [zView release];
	if (pointToRunTo) [pointToRunTo release];
    if (gameToRun) [gameToRun release];
	if (wView) [wView release];

    if (highlighterTicker) {
        [highlighterTicker invalidate];
        [highlighterTicker release];
        highlighterTicker = nil;
    }
    
    [super dealloc];
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

    doc = [parent document];

	[sourceText setContinuousSpellCheckingEnabled: NO];
    [[sourceText textStorage] removeLayoutManager: [sourceText layoutManager]];

    NSTextStorage* mainFile = [doc storageForFile: [doc mainSourceFile]];
    NSString* mainFilename =  [doc mainSourceFile];
    
    [openSourceFile release];
    openSourceFile = [mainFilename copy];
    
    [mainFile addLayoutManager: [sourceText layoutManager]];
	if (textStorage) { [textStorage release]; textStorage = nil; }
	textStorage = [mainFile retain];
    [self selectHighlighterForCurrentFile];

    [compController setCompiler: [doc compiler]];
    [compController setDelegate: self];
    [self updateSettings];

    [[sourceText textStorage] setDelegate: self];
	
	[self updateIndexView];
	
	[skeinView setSkein: [doc skein]];
	[skeinView setDelegate: parent];
	
	if ([[NSApp delegate] isWebKitAvailable]) {
		[wView setPolicyDelegate: [parent generalPolicy]];
	}
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

// = The source view =
- (void) moveToLine: (int) line {
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
        
    // Find out where it is in the layoutManager
    NSLayoutManager* layout = [sourceText layoutManager];
    
    NSRange ourLine;

    // Time to scroll
	[sourceText scrollRangeToVisible: NSMakeRange(linepos, 1)];
    [sourceText setSelectedRange: NSMakeRange(linepos,0)];
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
	[[sourceText textStorage] setDelegate: nil];
	[[sourceText textStorage] removeLayoutManager: [sourceText layoutManager]];
	
	[openSourceFile release];
	openSourceFile = [[[parent document] pathForFile: file] copy];
	//openSourceFile = [[file lastPathComponent] copy];
	
	[fileStorage addLayoutManager: [layout autorelease]];
	[fileStorage setDelegate: self];
	if (textStorage) { [textStorage release]; textStorage = nil; }
	textStorage = [fileStorage retain];
	[self selectHighlighterForCurrentFile];
	
	[fileStorage endEditing];
	
	[[IFIsFiles sharedIFIsFiles] updateFiles]; // have to update for the case where we select an 'unknown' file
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
    
    if (gameToRun) [gameToRun release];
    gameToRun = [fileName copy];
    
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

- (void) setPointToRunTo: (ZoomSkeinItem*) item {
	if (pointToRunTo) [pointToRunTo release];
	pointToRunTo = [item retain];
}

- (void) stopRunningGame {
    if (zView) {
		[zView killTask];
        //[zView removeFromSuperview];
        //[zView release];
        //zView = nil;
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

- (BOOL) isRunningGame {
	return zView != nil && [zView isRunning];
}

// (ZoomView delegate functions)
- (void) zMachineStarted: (id) sender {	
    [[zView zMachine] loadStoryFile: 
        [NSData dataWithContentsOfFile: gameToRun]];

	[[zView zMachine] loadDebugSymbolsFrom: [[[[parent document] fileName] stringByAppendingPathComponent: @"Build"] stringByAppendingPathComponent: @"gameinfo.dbg"]
							withSourcePath: [[[parent document] fileName] stringByAppendingPathComponent: @"Source"]];
	
	if (setBreakpoint) {
		if (![[zView zMachine] setBreakpointAtName: @"Initialise"]) {
			[[zView zMachine] setBreakpointAtName: @"main"];
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
}

// = Tab view delegate =
- (BOOL)            tabView: (NSTabView *)view 
    shouldSelectTabViewItem:(NSTabViewItem *)item {
    if (item == gameTabView && zView == nil) {
        // FIXME: if another view is running a game, then display the tabView in there
        return NO;
    }
	
	if (item == indexTabView && !indexAvailable) {
		return NO;
	}

    return YES;
}

// = Text view delegate =

// FIXME: storage delegate should be the document, NOT the view, as this causes weirdness

- (void) createHighlighterTickerIfRequired: (NSTimeInterval) timeout {
    if (highlighterTicker) {
        [highlighterTicker invalidate];
        [highlighterTicker release];
        highlighterTicker = nil;
    }
    
    NSRange invalidRange = [highlighter invalidRange];
    
    if ((invalidRange.location != NSNotFound && invalidRange.length != 0) ||
        (remainingFileToProcess.location != NSNotFound && remainingFileToProcess.length != 0)) {
        highlighterTicker = [NSTimer timerWithTimeInterval:timeout
                                                    target:self
                                                  selector:@selector(highlighterIteration)
                                                  userInfo:nil
                                                   repeats: NO];
        [[NSRunLoop currentRunLoop] addTimer: highlighterTicker
                                     forMode: NSDefaultRunLoopMode];
        [highlighterTicker retain];
    }
}

- (void) highlighterIteration {
	int amountToHighlight = minHighlightAmount;
	//int amountToHighlight = [[sourceText textStorage] length] / 16;
	//int amountToHighlight = [[sourceText textStorage] length];
	
	//if (amountToHighlight < minHighlightAmount) amountToHighlight = minHighlightAmount;
	//if (amountToHighlight > maxHighlightAmount) amountToHighlight = maxHighlightAmount;
		
	NSRange selected = [sourceText selectedRange];
	    
	[textStorage setDelegate: nil];
	[textStorage beginEditing];
	
    while (amountToHighlight > 0) {
        NSRange invalid = [highlighter invalidRange];

        // Add anything that needs highlighting to the range that we're working on
        if (invalid.location != NSNotFound && invalid.length != 0) {
            if (remainingFileToProcess.location == NSNotFound || remainingFileToProcess.length == 0) {
                remainingFileToProcess = invalid;
            } else {
                remainingFileToProcess = NSUnionRange(remainingFileToProcess, invalid);
            }
        }
        
        if (remainingFileToProcess.location == NSNotFound || remainingFileToProcess.length == 0)
            break;
        
#ifdef highlightAll
		int start = clock();
		[self highlightRange: remainingFileToProcess];
		remainingFileToProcess.location = NSNotFound;
		remainingFileToProcess.length = 0;
		NSLog(@"Time: %.04f\n", (float)(clock() - start) / (float)CLOCKS_PER_SEC);
#else
        // Highlight!
        if (remainingFileToProcess.length < amountToHighlight) {
            // Highlight everything if that's all there is to do
            [self highlightRange: remainingFileToProcess];
            
            amountToHighlight -= remainingFileToProcess.length;
           
            remainingFileToProcess.location = NSNotFound;
            remainingFileToProcess.length   = 0;
        } else {
            // Highlight up to the maximum amount
            [self highlightRange: NSMakeRange(remainingFileToProcess.location,
                                              amountToHighlight)];
            remainingFileToProcess.location += amountToHighlight;
            remainingFileToProcess.length   -= amountToHighlight;
            
            amountToHighlight = 0;
        }
#endif
    }
	
	[textStorage endEditing];
	
	if (selected.location + selected.length > [[textStorage string] length]) {
		int newLen = selected.length;
		
		newLen = [[textStorage string] length] - selected.location;
		if (newLen <= 0) {
			newLen = 0;
			selected.location = [[textStorage string] length];
		}
		
		selected.length = newLen;
	}
	
	[sourceText scrollRangeToVisible: selected];
	[sourceText setSelectedRange: selected];
	[textStorage setDelegate: self];
        
    [self createHighlighterTickerIfRequired: 0.01];
}

- (void)textStorageDidProcessEditing: (NSNotification*) not {
    NSRange editedRange = [[sourceText textStorage] editedRange];
    
	[[sourceText textStorage] setDelegate: nil];

#ifdef showHighlighting
    [[sourceText textStorage] addAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
        [NSColor colorWithDeviceRed: 0.8 green: 0.8 blue: 1.0 alpha: 1.0],
        NSForegroundColorAttributeName, nil]
                                      range: NSMakeRange(0, [[sourceText textStorage] length])];
#endif
    
    // Redo any necessary highlighting
    [highlighter invalidateRange: editedRange];
    
	// Highlighting a bit around the edited range
	NSRange highlightRange = editedRange;
	
	if (highlightRange.location > 10)
		highlightRange.location -= 10;
	else
		highlightRange.location = 0;
	
	highlightRange.length += 15;
	if (highlightRange.location + highlightRange.length > [textStorage length]) {
		highlightRange.length = [textStorage length] - highlightRange.location;
	}
	
	//[self highlightRange: highlightRange];
	
	//[self highlighterIteration];
	
	// Create a highlighter ticker to highlight everything that's changed (the delay ensures that
	// we can type without being interrupted by the highlighter)
	//[self createHighlighterTickerIfRequired: 0.2];
	
	// Check if we're in the wrong run loop?? (Yep, Apple sometimes calls these things from different threads)
	if ([NSRunLoop currentRunLoop] != [IFAppDelegate mainRunLoop]) {
		NSBeep();
		NSLog(@"Oops, wrong run loop!!");
	}

	// Vague attempt to avoid a crash that keeps occuring while editing
	[[IFAppDelegate mainRunLoop] performSelector: @selector(highlighterIteration)
										  target: self
										argument: nil
										   order: 10
										   modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
    
    [[sourceText textStorage] setDelegate: self];
}

// = Syntax highlighting =
- (NSDictionary*) attributeForStyle: (enum IFSyntaxType) style {
    return styles[style];
}

- (void) highlightEntireFile {
    [highlighter setFile: [[sourceText textStorage] string]];
    [self highlightRange: NSMakeRange(0, [[sourceText textStorage] length])];
}

- (void) highlightRange: (NSRange) charRange {
    IFSyntaxType lastSyntax = IFSyntaxNone;
    int startPos = charRange.location;
    int curPos;
	
    if (charRange.location + charRange.length > [[textStorage string] length]) {
        charRange.length = [[textStorage string] length] - charRange.location;
    }
    	
	id oldDelegate = [textStorage delegate];
    [textStorage setDelegate: nil];
    
    unsigned char* buf = malloc(charRange.length);
    [highlighter colourForCharacterRange: charRange
                                  buffer: buf];
    
    // Do the highlighting
	[textStorage beginEditing];
    for (curPos = charRange.location; curPos < charRange.location + charRange.length; curPos++) {
        IFSyntaxType thisSyntax = buf[curPos-charRange.location];
        
        if (thisSyntax != lastSyntax && curPos != 0) {
            NSRange r;
            NSDictionary* attr = [self attributeForStyle: lastSyntax];
            
            r = NSMakeRange(startPos, curPos - startPos);
            
#ifdef useTemporaryAttributes
			if (r.length > 0) {
				[[sourceText layoutManager] removeTemporaryAttribute: NSForegroundColorAttributeName
												   forCharacterRange: r];
				attr = [NSDictionary dictionaryWithObject: [attr objectForKey: NSForegroundColorAttributeName]
												   forKey: NSForegroundColorAttributeName];
				[[sourceText layoutManager] addTemporaryAttributes: attr
												 forCharacterRange: r];
				[[sourceText layoutManager] invalidateDisplayForCharacterRange: r];
			}
#else
            [textStorage addAttributes: attr
								 range: r];
#endif
			
			
#ifdef showHighlighting
			[[sourceText textStorage] addAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
				[NSColor colorWithDeviceRed: 0.8 green: 0.0 blue: 0.0 alpha: 1.0],
				NSForegroundColorAttributeName, nil]
											  range: r];
#endif			
            
            startPos = curPos;
        }
        
        lastSyntax = thisSyntax;
    }
    
    // Final attributes
    NSRange r;
    NSDictionary* attr = [self attributeForStyle: lastSyntax];
    
    r = NSMakeRange(startPos, curPos - startPos);
    if (r.length > 0) {
#ifdef UseTemporaryAttributes
		[[sourceText layoutManager] removeTemporaryAttribute: NSForegroundColorAttributeName
										   forCharacterRange: r];
		attr = [NSDictionary dictionaryWithObject: [attr objectForKey: NSForegroundColorAttributeName]
										   forKey: NSForegroundColorAttributeName];
		[[sourceText layoutManager] addTemporaryAttributes: attr
										 forCharacterRange: r];
		[[sourceText layoutManager] invalidateDisplayForCharacterRange: r];
#else
        [textStorage addAttributes: attr
							 range: r];
#endif
    }
    
    free(buf);

	[textStorage endEditing];
    [textStorage setDelegate: oldDelegate];
}

- (void) selectHighlighterForCurrentFile {
	if (highlighterTicker) {
		[highlighterTicker invalidate];
		[highlighterTicker release];
		highlighterTicker = nil;
	}
	
	// In the future, we'll also meddle with the paragraph styles while formatting (to maintain indentation over
	// multiple lines). But for now, we'll just set the style for the whole document
	BOOL applyTabStyle = NO;
	NSMutableParagraphStyle* tabStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[tabStyle autorelease];
	
	int x;
	NSMutableArray* tabStops = [NSMutableArray array];
	for (x=0; x<48; x++) {
		NSTextTab* tab = [[NSTextTab alloc] initWithType: NSLeftTabStopType
												location: 64.0*(x+1)];
		[tabStops addObject: tab];
		[tab release];
	}
	[tabStyle setTabStops: tabStops];

	// Various bits & bobs
	BOOL useSystemFont = YES;
	
    if (highlighter) [highlighter release];
    highlighter = nil;
	
	remainingFileToProcess.location = NSNotFound;
	remainingFileToProcess.length   = 0;
    
    NSString* fileType = [openSourceFile pathExtension];
    
	// Actually work out which highlighter to use
    if ([fileType isEqualToString: @"inf"] ||
        [fileType isEqualToString: @"h"] ||
		[fileType isEqualToString: @"i6"]) {
        // Inform 6 file
        highlighter = [[IFInform6Syntax alloc] init];
        [sourceText setRichText: NO];
		applyTabStyle = YES;
    } else if ([fileType isEqualToString: @"ni"] ||
               [fileType isEqualToString: @"nih"]) {
        // Natural inform file
        highlighter = [[IFNaturalInformSyntax alloc] init];
        [sourceText setRichText: NO];
		applyTabStyle = YES;
    } else if ([fileType isEqualToString: @"rtf"]) {
        // Rich text file
        highlighter = [[IFSyntaxHighlighter alloc] init];
        [sourceText setRichText: YES];
		useSystemFont = NO;
    } else {
        // Unknown file type
        highlighter = [[IFSyntaxHighlighter alloc] init];
        [sourceText setRichText: NO];
    }
	
	if (useSystemFont) {
		[[sourceText textStorage] setDelegate: nil];

		[[sourceText textStorage] addAttributes: [self attributeForStyle: IFSyntaxNone]
										  range: NSMakeRange(0, [[sourceText textStorage] length])];
		
		[[sourceText textStorage] setDelegate: self];
	}
	
    [highlighter setFile: [[sourceText textStorage] string]];
	
	if (applyTabStyle) {
		// (Will call the highlighter)
		[[sourceText textStorage] addAttribute: NSParagraphStyleAttributeName
										 value: tabStyle
										 range: NSMakeRange(0, [[sourceText textStorage] length])];
	}

	[self highlightRange: NSMakeRange(0, [[sourceText textStorage] length])];
    [self createHighlighterTickerIfRequired: 0.2];
}

// == Debugging ==

- (void) hitBreakpoint: (int) pc {
	[parent hitBreakpoint: pc];
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
			// Create a web view to view this file
			WebView* fileView = [[WebView alloc] init];
			[fileView setPolicyDelegate: [parent docPolicy]]; // Enables the 'source' protocol
			[fileView autorelease];
			
			// Need to set a window, as we'll be part of a tab view in a tab view
			[fileView setHostWindow: [paneView window]];
			
			// Load the HTML
			[[fileView mainFrame] loadRequest: [[[NSURLRequest alloc] initWithURL: [IFProjectPolicy fileURLWithPath: fullPath]] autorelease]];
			
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

-(void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource {
	NSLog(@"IFprojectPane: failed to load page with error: %@", [error localizedDescription]);
}

@end
