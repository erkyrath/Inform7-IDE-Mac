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

#import "IFInform6Syntax.h"
#import "IFNaturalInformSyntax.h"

// Approximate maximum length of file to highlight in one 'iteration'
#define maxHighlightAmount 512
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
    NSFont* headerSystemFont = [NSFont boldSystemFontOfSize: 16];
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
        nil] retain];
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
    [addFilePanel   release];
    
    if (zView) [zView release];
    if (gameToRun) [gameToRun release];

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

    [[sourceText textStorage] removeLayoutManager: [sourceText layoutManager]];

    NSTextStorage* mainFile = [doc storageForFile: [doc mainSourceFile]];
    NSString* mainFilename =  [doc mainSourceFile];
    
    [openSourceFile release];
    openSourceFile = [mainFilename copy];
    
    [mainFile addLayoutManager: [sourceText layoutManager]];
    [self selectHighlighterForCurrentFile];

    [compController setCompiler: [doc compiler]];
    [compController setDelegate: self];
    [self updateFiles];
    [self updateSettings];

    [[sourceText textStorage] setDelegate: self];
}

- (void) awakeFromNib {
    awake = YES;

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
    [parent highlightSourceFileLine: line]; // FIXME: error level?
}

- (IFCompilerController*) compilerController {
    return compController;
}

// = The source view =
- (void) moveToLine: (int) line {
    // Find out where the line is in the source view
    NSString* store = [[sourceText textStorage] string];
    int length = [store length];

    int x, lineno, linepos, lineLength;
    lineno = 1;
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
    NSRange ourGlyph = [layout glyphRangeForCharacterRange: NSMakeRange(linepos,lineLength)
                                      actualCharacterRange: &ourLine];

    NSRect lineLocation = [layout boundingRectForGlyphRange: ourGlyph
                                            inTextContainer: [sourceText textContainer]];
    //NSRect lineLocation = [layout lineFragmentRectForGlyphAtIndex: ourGlyph.location
    //                                               effectiveRange: nil];

    // Time to scroll
    [sourceText scrollRectToVisible: lineLocation];
    [sourceText setSelectedRange: NSMakeRange(linepos,0)];
}

- (void) updateFiles {
    IFProject* project = [parent document];
    NSDictionary* files = [project sourceFiles];

    if (files == nil || project == nil) {
        NSLog(@"No files found");
        NSBeep();
        return; // Doh!
    }

    [sourcePopup removeAllItems];

    NSEnumerator* keyEnum = [files keyEnumerator];
    NSString* key;
    [sourceFiles removeAllObjects];
    
    int selectedItem = -1;
    
    [sourcePopup addItemWithTitle: openSourceFile];
    [sourceFiles addObject: openSourceFile];

    while (key = [keyEnum nextObject]) {        
        if (![key isEqualToString: openSourceFile]) {
            [sourcePopup addItemWithTitle: key];
            [sourceFiles addObject: key];
        } else {
            selectedItem = 0;
        }
    }
    
    if (selectedItem == -1) {
        NSLog(@"(BUG?) can't find currently open source file in project");
    } else {
        [sourcePopup selectItemAtIndex: selectedItem];
    }

    [[sourcePopup menu] addItem: [NSMenuItem separatorItem]];
    [sourcePopup addItemWithTitle: @"Add file..."]; // FIXME: internationalisation
}

- (IBAction) selectSourceFile: (id) sender {
    int item = [sourcePopup indexOfSelectedItem];
    
    if (item < [sourceFiles count]) {
        // Select a new source file
        [[sourceText textStorage] removeLayoutManager: [sourceText layoutManager]];
        
        NSTextStorage* mainFile = [[parent document] storageForFile: [sourceFiles objectAtIndex: item]];
        
        [openSourceFile release];
        openSourceFile = [[sourceFiles objectAtIndex: item] copy];
        
        [mainFile addLayoutManager: [sourceText layoutManager]];
        [self selectHighlighterForCurrentFile];
        
        [self updateFiles];
    } else {
        // Show the 'add source files' dialog
        [NSApp beginSheet: addFilePanel
           modalForWindow: [parent window]
            modalDelegate: nil
           didEndSelector: nil
              contextInfo: nil];
        [NSApp runModalForWindow: addFilePanel];
        [NSApp endSheet: addFilePanel];
        [addFilePanel orderOut: self];
        
        [self updateFiles];
    }
}

- (IBAction) addFileClicked: (id) sender {
    [NSApp stopModal];
    
    [[parent document] addFile: [newFileName stringValue]];
}

- (IBAction) cancelAddFile: (id) sender {
    [NSApp stopModal];
}

// = Settings =
- (void) updateSettings {
    if (!parent) {
        return; // Nothing to do
    }

    IFCompilerSettings* settings = [[parent document] settings];

    [strictMode setState: [settings strict]?NSOnState:NSOffState];
    [infixMode setState: [settings infix]?NSOnState:NSOffState];
    [debugMode setState: [settings debug]?NSOnState:NSOffState];

    [naturalInform setState: [settings usingNaturalInform]?NSOnState:NSOffState];

    [donotCompileNaturalInform setState:
        (![settings compileNaturalInformOutput])?NSOnState:NSOffState];
    [runBuildSh setState: [settings runBuildScript]?NSOnState:NSOffState];

    if ([zmachineVersion cellWithTag: [settings zcodeVersion]] != nil) {
        [zmachineVersion selectCellWithTag: [settings zcodeVersion]];
    } else {
        [zmachineVersion deselectAllCells];
    }
    
    [runLoudly setState: [settings loudly]?NSOnState:NSOffState];
    
    // Compiler versions
    double version = [settings compilerVersion];
    NSEnumerator* compilerEnum = [[IFCompiler availableCompilers] objectEnumerator];
    
    [compilerVersion removeAllItems];
    NSDictionary* compilerInfo;
    
    while (compilerInfo = [compilerEnum nextObject]) {
        NSString* compilerStr = [NSString stringWithFormat: @"%@ %.2f (%@)",
            [compilerInfo objectForKey: @"name"],
            [[compilerInfo objectForKey: @"version"] doubleValue],
            [compilerInfo objectForKey: @"platform"]];
        
        [compilerVersion addItemWithTitle: compilerStr];
        
        if ([[compilerInfo objectForKey: @"version"] doubleValue] == version) {
            [compilerVersion selectItemAtIndex: [compilerVersion numberOfItems]-1];
        }
    }
    
    // Library versions
	NSArray* libraryDirectory = [IFCompilerSettings availableLibraries];
    
    NSEnumerator* libEnum = [libraryDirectory objectEnumerator];
    NSString* libVer;
    NSString* currentLibVer = [settings libraryToUse];
    
    [libraryVersion removeAllItems];
    
    while (libVer = [libEnum nextObject]) {
        [libraryVersion addItemWithTitle: libVer];
        
        if ([libVer isEqualToString: currentLibVer]) {
            [libraryVersion selectItemAtIndex: [libraryVersion numberOfItems]-1];
        }
    }
}

- (IBAction) settingsHaveChanged: (id) sender {
    if (sender == nil) return;

    IFCompilerSettings* settings = [[parent document] settings];

    // Update the appropriate setting
    if (sender == strictMode) {
        [settings setStrict: [sender state]==NSOnState];
    } else if (sender == infixMode) {
        [settings setInfix: [sender state]==NSOnState];
    } else if (sender == debugMode) {
        [settings setDebug: [sender state]==NSOnState];
    } else if (sender == naturalInform) {
        [settings setUsingNaturalInform: [sender state]==NSOnState];
    } else if (sender == donotCompileNaturalInform) {
        [settings setCompileNaturalInformOutput: [sender state]!=NSOnState];
    } else if (sender == runBuildSh) {
        [settings setRunBuildScript: [sender state]==NSOnState];
    } else if (sender == zmachineVersion) {
        [settings setZCodeVersion: [[sender selectedCell] tag]];
    } else if (sender == runLoudly) {
        [settings setLoudly: [sender state]==NSOnState];
    } else if (sender == compilerVersion) {
        int item = [compilerVersion indexOfSelectedItem];
        double newVersion;
        
        newVersion = [[[[IFCompiler availableCompilers] objectAtIndex: item] objectForKey: @"version"] doubleValue];
        
        [settings setCompilerVersion: newVersion];
    } else if (sender == libraryVersion) {
        [settings setLibraryToUse: [libraryVersion itemTitleAtIndex: [libraryVersion indexOfSelectedItem]]];
    } else {
        NSLog(@"Interface BUG: unknown/unimplemented setting control");
        [self updateSettings];
    }
}

// = The game view =
- (void) startRunningGame: (NSString*) fileName {
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

    return YES;
}

// = Text view delegate =

- (void) createHighlighterTickerIfRequired {
    if (highlighterTicker) {
        [highlighterTicker invalidate];
        [highlighterTicker release];
        highlighterTicker = nil;
    }
    
    NSRange invalidRange = [highlighter invalidRange];
    
    if ((invalidRange.location != NSNotFound && invalidRange.length != 0) ||
        (remainingFileToProcess.location != NSNotFound && remainingFileToProcess.length != 0)) {
        highlighterTicker = [NSTimer timerWithTimeInterval:0.001
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
    int amountToHighlight = maxHighlightAmount;
    
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
        [self highlightRange: NSMakeRange(0, [[sourceText textStorage] length])];
#endif

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
    }
        
    [self createHighlighterTickerIfRequired];
}

- (void)textStorageDidProcessEditing: (NSNotification*) not {
    NSRange editedRange = [[sourceText textStorage] editedRange];
    
#ifdef showHighlighting
    [[sourceText textStorage] addAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
        [NSColor colorWithDeviceRed: 0.8 green: 0.8 blue: 1.0 alpha: 1.0],
        NSForegroundColorAttributeName, nil]
                                      range: NSMakeRange(0, [[sourceText textStorage] length])];
#endif
    
    // Redo any necessary highlighting
    [highlighter invalidateRange: editedRange];
    
    [self highlighterIteration];
    
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
    
    if (charRange.location + charRange.length > [[[sourceText textStorage] string] length]) {
        charRange.length = [[[sourceText textStorage] string] length] - charRange.location;
    }
    
    [[sourceText textStorage] setDelegate: nil];
    
    unsigned char* buf = malloc(charRange.length);
    [highlighter colourForCharacterRange: charRange
                                  buffer: buf];
    
    // Do the highlighting
    for (curPos = charRange.location; curPos < charRange.location + charRange.length; curPos++) {
        IFSyntaxType thisSyntax = buf[curPos-charRange.location];
        
        if (thisSyntax != lastSyntax && curPos != 0) {
            NSRange r;
            NSDictionary* attr = [self attributeForStyle: lastSyntax];
            
            r = NSMakeRange(startPos, curPos - startPos);
            
            [[sourceText textStorage] addAttributes: attr
                                            range: r];
            
            startPos = curPos;
        }
        
        lastSyntax = thisSyntax;
    }
    
    // Final attributes
    NSRange r;
    NSDictionary* attr = [self attributeForStyle: lastSyntax];
    
    r = NSMakeRange(startPos, curPos - startPos);
    if (r.length > 0) {
        [[sourceText textStorage] addAttributes: attr
                                        range: r];
    }
    
    free(buf);

    [[sourceText textStorage] setDelegate: self];
}

- (void) selectHighlighterForCurrentFile {
    if (highlighter) [highlighter release];
    highlighter = nil;
    
    NSString* fileType = [openSourceFile pathExtension];
    
    if ([fileType isEqualToString: @"inf"] ||
        [fileType isEqualToString: @"h"]) {
        // Inform 6 file
        highlighter = [[IFInform6Syntax alloc] init];
        [sourceText setRichText: NO];
    } else if ([fileType isEqualToString: @"ni"] ||
               [fileType isEqualToString: @"nih"]) {
        // Natural inform file
        highlighter = [[IFNaturalInformSyntax alloc] init];
        [sourceText setRichText: NO];
    } else if ([fileType isEqualToString: @"rtf"]) {
        // Rich text file
        highlighter = [[IFSyntaxHighlighter alloc] init];
        [sourceText setRichText: YES];
    } else {
        // Unknown file type
        highlighter = [[IFSyntaxHighlighter alloc] init];
        [sourceText setRichText: NO];
    }
    
    [highlighter setFile: [[sourceText textStorage] string]];
    [self highlighterIteration];
}

@end
