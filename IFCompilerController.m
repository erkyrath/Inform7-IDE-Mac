//
//  IFCompilerController.m
//  Inform
//
//  Created by Andrew Hunter on Mon Aug 18 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFCompilerController.h"

#import "IFCompiler.h"
#import "IFError.h"

// Possible styles (stored in the styles dictionary)
NSString* IFStyleBase               = @"IFStyleBase";

// Basic compiler messages
NSString* IFStyleCompilerVersion    = @"IFStyleCompilerVersion";
NSString* IFStyleCompilerMessage    = @"IFStyleCompilerMessage";
NSString* IFStyleCompilerWarning    = @"IFStyleCompilerWarning";
NSString* IFStyleCompilerError      = @"IFStyleCompilerError";
NSString* IFStyleCompilerFatalError = @"IFStyleCompilerFatalError";

NSString* IFStyleFilename   = @"IFStyleFilename";

// Compiler statistics/dumps/etc
NSString* IFStyleAssembly           = @"IFStyleAssembly";
NSString* IFStyleHexDump            = @"IFStyleHexDump";
NSString* IFStyleStatistics         = @"IFStyleStatistics";

static IFCompilerController* activeController = nil;

@implementation IFCompilerController

// == Styles ==
+ (NSDictionary*) defaultStyles {
    NSFont* baseFont = [NSFont labelFontOfSize: 10];
    NSFont* bigFont  = [NSFont labelFontOfSize: 10];
    NSFont* boldFont = [[NSFontManager sharedFontManager] convertFont: bigFont
                                                          toHaveTrait: NSBoldFontMask];
    NSFont* smallBoldFont = [[NSFontManager sharedFontManager] convertFont: baseFont
                                                          toHaveTrait: NSBoldFontMask];
    NSFont* italicFont = [[NSFontManager sharedFontManager] convertFont: boldFont
                                                            toHaveTrait: NSItalicFontMask];

    NSMutableParagraphStyle* centered = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [centered setAlignment: NSCenterTextAlignment];
    
    NSDictionary* baseStyle = [NSDictionary dictionaryWithObjectsAndKeys:
        baseFont, NSFontAttributeName,
        [NSColor blackColor], NSForegroundColorAttributeName,
        0];

    NSDictionary* versionStyle = [NSDictionary dictionaryWithObjectsAndKeys:
        bigFont, NSFontAttributeName,
        centered, NSParagraphStyleAttributeName,
        0];
    
    NSDictionary* filenameStyle = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSColor blackColor],
        NSForegroundColorAttributeName,
        boldFont, NSFontAttributeName,
        0];
    
    NSDictionary* messageStyle = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSColor colorWithDeviceRed: 0 green: 0.5 blue: 0 alpha: 1.0],
        NSForegroundColorAttributeName, 0];
    NSDictionary* warningStyle = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSColor colorWithDeviceRed: 0 green: 0 blue: 0.7 alpha: 1.0],
        NSForegroundColorAttributeName,
        boldFont, NSFontAttributeName,
        0];
    NSDictionary* errorStyle = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSColor colorWithDeviceRed: 0.7 green: 0 blue: 0.0 alpha: 1.0],
        NSForegroundColorAttributeName,
        boldFont, NSFontAttributeName,
        0];
    NSDictionary* fatalErrorStyle = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSColor colorWithDeviceRed: 1.0 green: 0 blue: 0.0 alpha: 1.0],
        NSForegroundColorAttributeName,
        italicFont, NSFontAttributeName,
        0];

    return [NSDictionary dictionaryWithObjectsAndKeys:
        baseStyle, IFStyleBase,
        versionStyle, IFStyleCompilerVersion,
        messageStyle, IFStyleCompilerMessage, warningStyle, IFStyleCompilerWarning,
        errorStyle, IFStyleCompilerError, fatalErrorStyle, IFStyleCompilerFatalError,
        filenameStyle, IFStyleFilename,
        0];
}

// == Initialisation ==
- (void) _registerHandlers {
    if (compiler != nil) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(started:)
                                                     name: IFCompilerStartingNotification
                                                   object: compiler];

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(finished:)
                                                     name: IFCompilerFinishedNotification
                                                   object: compiler];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(gotStdout:)
                                                     name: IFCompilerStdoutNotification
                                                   object: compiler];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(gotStderr:)
                                                     name: IFCompilerStderrNotification
                                                   object: compiler];
    }
}

- (void) _removeHandlers {
    if (compiler != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                                        name: IFCompilerStartingNotification
                                                      object: compiler];
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                                        name: IFCompilerFinishedNotification
                                                      object: compiler];
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                                        name: IFCompilerStdoutNotification
                                                      object: compiler];
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                                        name: IFCompilerStderrNotification
                                                      object: compiler];
    }
}

- (id) init {
    self = [super init];

    if (self) {
        compiler = [[IFCompiler allocWithZone: [self zone]] init];
        styles = [[[self class] defaultStyles] mutableCopy];
        highlightPos = 0;

        errorFiles    = nil;
        errorMessages = nil;
        delegate      = nil;
        fileTabView   = nil;

        [self _registerHandlers];
    }

    return self;
}

- (void) dealloc {    
    [[NSNotificationCenter defaultCenter] removeObserver: self];

    [compiler release];
    [styles release];

    if (errorFiles)    [errorFiles release];
    if (errorMessages) [errorMessages release];
    if (window)        [window release];
    if (delegate)      [delegate release];
    if (fileTabView)   [fileTabView release];
    
    [super dealloc];
}

- (void) awakeFromNib {
    [[compilerResults textStorage] setDelegate: self];

    messagesSize = [messageScroller frame].size.height;

    NSRect newFrame = [messageScroller frame];
    newFrame.size.height = 0;
    [messageScroller setFrame: newFrame];

    [splitView adjustSubviews];

    // Mutter, interface builder won't let you change the enclosing scrollview
    // of an outlineview
    [messageScroller setBorderType: NSNoBorder];

    [resultScroller setHasHorizontalScroller: YES];
    [compilerResults setMaxSize: NSMakeSize(1e8, 1e8)];
    [compilerResults setHorizontallyResizable: YES];
    [compilerResults setVerticallyResizable: YES];
    [[compilerResults textContainer] setWidthTracksTextView: NO];
    [[compilerResults textContainer] setContainerSize: NSMakeSize(1e8, 1e8)];
}

- (void) showWindow: (id) sender {
    if (!awake) {
        [NSBundle loadNibNamed: @"Compiling"
                         owner: self];
    }

    [window orderFront: sender];
}

// == Information ==
- (void) resetCompiler {
    [self _removeHandlers];
    [compiler release];

    compiler = [[IFCompiler allocWithZone: [self zone]] init];
    [self _registerHandlers];

    NSRect newFrame = [messageScroller frame];
    newFrame.size.height = 0;
    [messageScroller setFrame: newFrame];

    [splitView adjustSubviews];
}

- (void) setCompiler: (IFCompiler*) comp {
    [self _removeHandlers];
    [compiler release];

    compiler = [comp retain];
    [self _registerHandlers];

    NSRect newFrame = [messageScroller frame];
    newFrame.size.height = 0;
    [messageScroller setFrame: newFrame];

    [splitView adjustSubviews];
}

- (IFCompiler*) compiler {
    return compiler;
}

// == Starting/stopping the compiler ==
- (BOOL) startCompiling {
    if (window)
        [window setTitle: [NSString stringWithFormat: @"Compiling - '%@'...",
            [[compiler inputFile] lastPathComponent]]];
    
    [compiler prepareForLaunch];
    [compiler launch];

    if (errorFiles) [errorFiles release];
    if (errorMessages) [errorMessages release];

    errorFiles    = [[NSMutableArray array] retain];
    errorMessages = [[NSMutableArray array] retain];

    if (delegate &&
        [delegate respondsToSelector: @selector(errorMessagesCleared:)]) {
        [delegate errorMessagesCleared: self];
    }
    
    [[[compilerResults textStorage] mutableString] setString: @""];
    highlightPos = 0;
    
    return YES;
}

- (BOOL) abortCompiling {
    if (window)
        [window setTitle: [NSString stringWithFormat: @"Aborted - '%@'",
            [[compiler inputFile] lastPathComponent]]];

    return YES;
}

// == Compiler messages ==
- (void) scrollToEnd {
    NSLayoutManager* mgr = [compilerResults layoutManager];

    NSRange endGlyph = [compilerResults selectionRangeForProposedRange:
        NSMakeRange([[compilerResults textStorage] length]-1, 1)
                                                           granularity: NSSelectByCharacter];
    NSRect endRect = [mgr boundingRectForGlyphRange: endGlyph
                                    inTextContainer: [compilerResults textContainer]];
    
    [compilerResults scrollPoint:
        NSMakePoint(0,
                   NSMaxY(endRect) - [[resultScroller contentView] frame].size.height)];
}

- (void) started: (NSNotification*) not {
    if (errorFiles == nil) errorFiles = [[NSMutableArray alloc] init];
    if (errorMessages == nil) errorMessages = [[NSMutableArray alloc] init];

    [self clearTabViews];
    [errorMessages removeAllObjects];
    [errorFiles removeAllObjects];
    [compilerMessages reloadData];
    
    [[[compilerResults textStorage] mutableString] setString: @""];
    highlightPos = 0;

    if (delegate &&
        [delegate respondsToSelector: @selector(compileStarted:)]) {
        [delegate compileStarted: self];
    }
}

- (void) finished: (NSNotification*) not {
    int exitCode = [[[not userInfo] objectForKey: @"exitCode"] intValue];

    [[[compilerResults textStorage] mutableString] appendString:
        [NSString stringWithFormat: @"\nCompiler finished with code %i\n", exitCode]];

    NSString* msg;

    if (exitCode == 0) {
        msg = @"Success";

        if (delegate &&
            [delegate respondsToSelector: @selector(compileCompletedAndSucceeded:)]) {
            [delegate compileCompletedAndSucceeded: self];
        }
    } else {
        msg = @"Failed";

        if (delegate &&
            [delegate respondsToSelector: @selector(compileCompletedAndSucceeded:)]) {
            [delegate compileCompletedAndFailed: self];
        }
    }

    if (window)
        [window setTitle: [NSString stringWithFormat: @"%@ - '%@'",
            msg, [[compiler inputFile] lastPathComponent]]];

    [self scrollToEnd];
}

- (void) gotStdout: (NSNotification*) not {
    NSString* data = [[not userInfo] objectForKey: @"string"];
    
    [[[compilerResults textStorage] mutableString] appendString: data];

    [self scrollToEnd];
}

- (void) gotStderr: (NSNotification*) not {
    NSString* data = [[not userInfo] objectForKey: @"string"];

    [[[compilerResults textStorage] mutableString] appendString: data];

    [self scrollToEnd];
}

// == Dealing with highlighting of the compiler output ==
- (NSString*) styleForLine: (NSString*) line {
    activeController = self;
    IFLex res = IFErrorScanString([line cString]);
    
    switch (res) {
        case IFLexBase:
            return IFStyleBase;

        case IFLexCompilerVersion:
            return IFStyleCompilerVersion;
            
        case IFLexCompilerMessage:
            return IFStyleCompilerMessage;
            
        case IFLexCompilerWarning:
            return IFStyleCompilerWarning;
            
        case IFLexCompilerError:
            return IFStyleCompilerError;
            
        case IFLexCompilerFatalError:
            return IFStyleCompilerFatalError;

        case IFLexAssembly:
            return IFStyleAssembly;
            
        case IFLexHexDump:
            return IFStyleHexDump;
            
        case IFLexStatistics:
            return IFStyleStatistics;
    }

    return nil;
    
    // Version strings have the form 'Foo Inform x.xx (Date)'
    
    
    // MPW style errors and warnings have the form:
    // File "file.h"; line 10	#
    if ([[line substringWithRange: NSMakeRange(0, 4)] isEqualTo: @"File"]) {
        // May be an MPW string
        return nil;
    }

    return nil;
}

- (void)textStorageDidProcessEditing:(NSNotification *)aNotification {
    NSTextStorage* storage = [compilerResults textStorage];
    
    // Set the text to the base style
    [storage setAttributes: [styles objectForKey: IFStyleBase]
                     range: [storage editedRange]];

    // For each line since highlightPos...
    NSString* str = [storage string];
    int len       = [str length];

    int newlinePos;
    
    do {
        int x;
        
        newlinePos = -1;

        for (x=highlightPos; x<len; x++) {
            if ([str characterAtIndex: x] == '\n') {
                newlinePos = x;
                break;
            }
        }

        if (newlinePos == -1) {
            break;
        }

        // ... set the style appropriately
        NSRange lineRange = NSMakeRange(highlightPos, (newlinePos-highlightPos)+1);
        NSString* newStyle = [self styleForLine: [str substringWithRange: lineRange]];

        if (newStyle != nil) {
            [storage addAttributes: [styles objectForKey: newStyle]
                             range: lineRange];
        }

        highlightPos = newlinePos + 1;
    } while (newlinePos != -1);
    
    // Finish up
}

// == The error OutlineView ==

- (void) addErrorForFile: (NSString*) file
                  atLine: (int) line
                withType: (IFLex) type
                 message: (NSString*) message {
    // Find the entry for this error message, if it exists. If not,
    // add this as a new file...
    int fileNum = [errorFiles indexOfObject: file];

    if (fileNum == NSNotFound) {
        fileNum = [errorFiles count];

        [errorFiles addObject: file];
        [errorMessages addObject: [NSMutableArray array]];

        [compilerMessages reloadData];
        [compilerMessages reloadItem: file
                      reloadChildren: YES];

        [compilerMessages expandItem: file];
    }

    // Add an entry for this error message
    NSMutableArray* fileMessages = [errorMessages objectAtIndex: fileNum];
    NSArray*        newMessage = [NSArray arrayWithObjects: message, [NSNumber numberWithInt: line], [NSNumber numberWithInt: type], nil];
    [fileMessages addObject: newMessage];

    // Update the outline view
    [compilerMessages reloadData];

    // Pop up the error view if required
    if ([messageScroller frame].size.height == 0) {
        NSRect newFrame = [messageScroller frame];
        newFrame.size.height = messagesSize;
        [messageScroller setFrame: newFrame];

        NSRect splitFrame = [splitView frame];
        NSRect resultFrame = [resultScroller frame];

        resultFrame.size.height = splitFrame.size.height - newFrame.size.height - [splitView dividerThickness];
        [resultScroller setFrame: resultFrame];

        [splitView adjustSubviews];
    }

    // Notify the delegate
    if (delegate != nil &&
        [delegate respondsToSelector: @selector(compilerAddError:forFile:atLine:withType:message:)]) {
        [delegate compilerAddError: self
                           forFile: file
                            atLine: line
                          withType: type
                           message: message];
    }
}

- (int)         outlineView:(NSOutlineView *)outlineView
     numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        return [errorFiles count];
    }
    
    int fileNum = [errorFiles indexOfObjectIdenticalTo: item];

    if (fileNum == NSNotFound) {
        return 0;
    }

    return [[errorMessages objectAtIndex: fileNum] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
   isItemExpandable:(id)item {
    if (item == nil) return YES;
    return [errorFiles indexOfObjectIdenticalTo: item] != NSNotFound;
}

- (id)outlineView:(NSOutlineView *)outlineView
            child:(int)index
           ofItem:(id)item {
    if (item == nil) {
        return [errorFiles objectAtIndex: index];
    }

    int fileNum = [errorFiles indexOfObjectIdenticalTo: item];

    if (fileNum == NSNotFound) {
        return nil;
    }

    return [[errorMessages objectAtIndex: fileNum] objectAtIndex: index];
}

- (id)          outlineView:(NSOutlineView *)outlineView
  objectValueForTableColumn:(NSTableColumn *)tableColumn
                     byItem:(id)item {
    if ([item isKindOfClass: [NSString class]]) {
        // Must be a filename
        NSAttributedString* str = [[NSAttributedString alloc] initWithString: [item lastPathComponent]
                                                                  attributes: [styles objectForKey: IFStyleFilename]];

        return [str autorelease];
    }

    // Is an array of the form message, line, type
    NSString* message = [item objectAtIndex: 0];
    int line = [[item objectAtIndex: 1] intValue];
    IFLex type = [[item objectAtIndex: 2] intValue];

    NSDictionary* attr = [styles objectForKey: IFStyleCompilerMessage];

    switch (type) {
        case IFLexCompilerWarning:
            attr = [styles objectForKey: IFStyleCompilerWarning];
            break;
            
        case IFLexCompilerError:
            attr = [styles objectForKey: IFStyleCompilerError];
            break;
            
        case IFLexCompilerFatalError:
            attr = [styles objectForKey: IFStyleCompilerFatalError];
            break;

        default:
            break;
    }

    NSString* msg = [NSString stringWithFormat: @"L%i: %@", line, message];
    NSAttributedString* res = [[NSAttributedString alloc] initWithString: msg
                                                             attributes: attr];
    
    return [res autorelease];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSObject* obj = [compilerMessages itemAtRow: [compilerMessages selectedRow]];

    if (obj == nil) {
        return; // Nothing selected
    }

    int fileNum = [errorFiles indexOfObjectIdenticalTo: obj];

    if (fileNum != NSNotFound) {
        return; // File item selected
    }

    // obj is an array of the form [message, line, type]
    NSArray* msg = (NSArray*) obj;

    NSString* message = [msg objectAtIndex: 0];
    int       line    = [[msg objectAtIndex: 1] intValue];
    // IFLex type        = [[msg objectAtIndex: 2] intValue];

    // Send to the delegate
    if (delegate &&
        [delegate respondsToSelector: @selector(errorMessageHighlighted:atLine:inFile:)]) {
        [delegate errorMessageHighlighted: self
                                   atLine: line
                                   inFile: message];
    }

    return;
}

- (void) windowWillClose: (NSNotification*) not {
    [self autorelease];
}

// Other information
- (void) showContentsOfFilesIn: (NSFileWrapper*) files {
    if (![files isDirectory]) {
        return; // Nothing to do
    }

    NSEnumerator* keyEnum = [[files fileWrappers] keyEnumerator];
    NSString* key;

    while (key = [keyEnum nextObject]) {
        NSString* type = [key pathExtension];

        if ((![[[key substringToIndex: 4] lowercaseString] isEqualToString: @"temp"]) &&
            ([type isEqualTo: @"inf"] ||
             [type isEqualTo: @"txt"])) {
            if (fileTabView == nil) {
                // Put the split view inside a tabview
                NSView* inView = [splitView superview];

                [splitView retain];
                [splitView removeFromSuperview];

                fileTabView = [[NSTabView alloc] init];

                [fileTabView setControlSize: NSSmallControlSize];
                [fileTabView setFont: [NSFont systemFontOfSize: 10]];
                [fileTabView setAllowsTruncatedLabels: YES];
                [fileTabView setAutoresizingMask: [splitView autoresizingMask]];

                NSTabViewItem* splitViewItem;

                splitViewItem = [[NSTabViewItem alloc] init];
                [splitViewItem setLabel: @"Compiler"];
                [splitViewItem setView: splitView];

                [fileTabView addTabViewItem: splitViewItem];

                [fileTabView setFrame: [inView bounds]];
                [inView addSubview: fileTabView];

                [splitView release];
                [splitViewItem release];
            }
            
            // Create an NSTextView to display this file in
            NSTextView*   textView = [[NSTextView alloc] init];
            NSScrollView* scrollView = [[NSScrollView alloc] init];

            [[textView textContainer] setWidthTracksTextView: NO];
            [[textView textContainer] setContainerSize: NSMakeSize(1e8, 1e8)];
            [textView setMinSize:NSMakeSize(0.0, 0.0)];
            [textView setMaxSize:NSMakeSize(1e8, 1e8)];
            [textView setVerticallyResizable:YES];
            [textView setHorizontallyResizable:YES];
            [textView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
            [textView setEditable: NO];

            [scrollView setDocumentView: textView];
            [scrollView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
            [scrollView setHasHorizontalScroller: YES];
            [scrollView setHasVerticalScroller: YES];

            NSString* textData = [[NSString alloc] initWithData:
                [[[files fileWrappers] objectForKey: key] regularFileContents]
                                  encoding: NSISOLatin1StringEncoding];
            [[[textView textStorage] mutableString] setString: textData];

            NSTabViewItem* fileItem;
            fileItem = [[NSTabViewItem alloc] init];

            [fileItem setLabel: [key stringByDeletingPathExtension]];
            [fileItem setView: scrollView];

            [fileTabView addTabViewItem: fileItem];
            
            [fileItem   release];
            [textData   release];
            [textView   release];
            [scrollView release];
        }
    }
}

- (void) clearTabViews {
    if (fileTabView) {
        NSView* inView = [fileTabView superview];
        
        [splitView retain];
        [splitView removeFromSuperview];

        [fileTabView removeFromSuperview];
        [fileTabView release];
        fileTabView = nil;

        [splitView setFrame: [inView bounds]];
        [inView addSubview: splitView];
        [splitView release];
    }
}

// == Delegate ==

- (void) setDelegate: (NSObject*) dg {
    if (delegate) [delegate release];
    delegate = [dg retain];
}

- (NSObject*) delegate {
    return delegate;
}

@end

// == The lexical helper function to actually add error messages ==

void IFErrorAddError(const char* filC,
                     int line,
                     IFLex type,
                     const char* mesC) {
    NSString* file    = [NSString stringWithCString: filC];
    NSString* message = [NSString stringWithCString: mesC];

    [activeController addErrorForFile: file
                               atLine: line
                             withType: type
                              message: message];
}
