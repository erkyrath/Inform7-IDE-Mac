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

// Approximate maximum length of file to highlight in one 'iteration'
#define maxHighlightAmount 2048
#undef  showHighlighting

@implementation IFProjectPane

+ (IFProjectPane*) standardPane {
    return [[[self alloc] init] autorelease];
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
    [paneView       release];
    [compController release];
    [sourceFiles    release];
    [highlighter    release];
    
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

    [mainFile addLayoutManager: [sourceText layoutManager]];
    [self highlightEntireFile];

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
    
    [sourceText setUsesFindPanel: YES];
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

- (IFCompilerController*) compilerController {
    return compController;
}

- (void) updateFiles {
    IFProject* project = [parent document];
    NSFileWrapper* files = [[[project projectFile] fileWrappers] objectForKey: @"Source"];

    if (files == nil || project == nil) {
        NSLog(@"No files found");
        NSBeep();
        return; // Doh!
    }

    [sourcePopup removeAllItems];

    NSEnumerator* keyEnum = [[files fileWrappers] keyEnumerator];
    NSString* key;
    [sourceFiles removeAllObjects];

    while (key = [keyEnum nextObject]) {
        [sourcePopup addItemWithTitle: key];
        [sourceFiles addObject: key];
    }

    [[sourcePopup menu] addItem: [NSMenuItem separatorItem]];
    [sourcePopup addItemWithTitle: @"Add file..."]; // FIXME: internationalisation
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
    } else {
        NSLog(@"Interface BUG: unknown/unimplemented setting control");
        [self updateSettings];
    }
}

// = The game view =
- (void) startRunningGame: (NSString*) fileName {
    if (zView) {
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
        [zView removeFromSuperview];
        [zView release];
        zView = nil;
    }
    
    if ([tabView selectedTabViewItem] == gameTabView) {
        [tabView selectTabViewItem: errorsView];
    }
}

// (ZoomView delegate functions)
- (void) zMachineStarted: (id) sender {
    [[zView zMachine] loadStoryFile: 
        [NSData dataWithContentsOfFile: gameToRun]];
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
    NSRange invalid = [highlighter invalidRange];
    
    if (invalid.location != NSNotFound && invalid.length != 0) {
        if (remainingFileToProcess.location == NSNotFound || remainingFileToProcess.length == 0) {
            remainingFileToProcess = invalid;
        } else {
            remainingFileToProcess = NSUnionRange(remainingFileToProcess, invalid);
        }
    }

    if (remainingFileToProcess.location != NSNotFound) {
        if (remainingFileToProcess.length < maxHighlightAmount) {
            [self highlightRange: remainingFileToProcess];
        
            remainingFileToProcess.location = NSNotFound;
            remainingFileToProcess.length   = 0;
        } else {
            [self highlightRange: NSMakeRange(remainingFileToProcess.location,
                                              maxHighlightAmount)];
            remainingFileToProcess.location += maxHighlightAmount;
            remainingFileToProcess.length   -= maxHighlightAmount;
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
    switch (style) {
        case IFSyntaxNone:
            return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSColor blueColor], NSForegroundColorAttributeName, nil];
            
        case IFSyntaxString:
            return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSColor grayColor], NSForegroundColorAttributeName, nil];

        case IFSyntaxComment:
            return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSColor greenColor], NSForegroundColorAttributeName, nil];
        
        // Inform 6 syntax types
        case IFSyntaxDirective:
            return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSColor blackColor], NSForegroundColorAttributeName, nil];
            
        case IFSyntaxProperty:
            return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSColor redColor], NSForegroundColorAttributeName, nil];
            
        case IFSyntaxFunction:
            return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSColor redColor], NSForegroundColorAttributeName, nil];
            
        case IFSyntaxCode:
            return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSColor blueColor], NSForegroundColorAttributeName, nil];
            
        case IFSyntaxCodeAlpha:
            return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSColor greenColor], NSForegroundColorAttributeName, nil];
            
        case IFSyntaxAssembly:
            return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSColor magentaColor], NSForegroundColorAttributeName, nil];
            
        case IFSyntaxEscapeCharacter:
            return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSColor redColor], NSForegroundColorAttributeName, nil];
                        
        // Natural inform syntax types
        case IFSyntaxHeading:
            
        // Debug syntax types
        default:
            printf("Unknown: %x (%x)\n", (int)style, IFSyntaxDebugHighlight);
            if ((long)style >= IFSyntaxDebugHighlight) {
                NSMutableDictionary* style = [[self attributeForStyle: (IFSyntaxType)(style - IFSyntaxDebugHighlight)] mutableCopy];
                
                
                
                [style setObject: [NSNumber numberWithInt: NSUnderlineStyleThick]
                          forKey: NSUnderlineStyleAttributeName];
                [style setObject: [NSColor redColor]
                          forKey: NSUnderlineColorAttributeName];
                
                return [style autorelease];
            }
        
            // Default syntax colouring
            return [NSDictionary dictionaryWithObjectsAndKeys: 
                [NSFont systemFontOfSize: 12], NSFontAttributeName, nil];
    }
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

    [[sourceText textStorage] setDelegate: self];
}

@end
