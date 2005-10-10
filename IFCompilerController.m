//
//  IFCompilerController.m
//  Inform
//
//  Created by Andrew Hunter on Mon Aug 18 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFCompilerController.h"

#import "IFAppDelegate.h"

#import "IFCompiler.h"
#import "IFError.h"
#import "IFProjectController.h"

#import "IFPretendWebView.h"
#import "IFPretendTextView.h"

// Possible styles (stored in the styles dictionary)
NSString* IFStyleBase               = @"IFStyleBase";

// Basic compiler messages
NSString* IFStyleCompilerVersion    = @"IFStyleCompilerVersion";
NSString* IFStyleCompilerMessage    = @"IFStyleCompilerMessage";
NSString* IFStyleCompilerWarning    = @"IFStyleCompilerWarning";
NSString* IFStyleCompilerError      = @"IFStyleCompilerError";
NSString* IFStyleCompilerFatalError = @"IFStyleCompilerFatalError";
NSString* IFStyleProgress			= @"IFStyleProgress";

NSString* IFStyleFilename   = @"IFStyleFilename";

// Compiler statistics/dumps/etc
NSString* IFStyleAssembly           = @"IFStyleAssembly";
NSString* IFStyleHexDump            = @"IFStyleHexDump";
NSString* IFStyleStatistics         = @"IFStyleStatistics";

static IFCompilerController* activeController = nil;

@implementation IFCompilerController

// == Styles ==
+ (NSDictionary*) defaultStyles {
    NSFont* smallFont = [NSFont labelFontOfSize: 6];
    NSFont* baseFont = [NSFont labelFontOfSize: 10];
    NSFont* bigFont  = [NSFont labelFontOfSize: 10];
	
	smallFont = baseFont = bigFont = [NSFont fontWithName: @"Monaco" size: 10.0];
    NSFont* boldFont = [[NSFontManager sharedFontManager] convertFont: bigFont
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
    NSDictionary* progressStyle = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSColor colorWithDeviceRed: 0.0 green: 0 blue: 0.6 alpha: 1.0],
        NSForegroundColorAttributeName,
        smallFont, NSFontAttributeName,
        0];
	
    return [NSDictionary dictionaryWithObjectsAndKeys:
        baseStyle, IFStyleBase,
        versionStyle, IFStyleCompilerVersion,
        messageStyle, IFStyleCompilerMessage, warningStyle, IFStyleCompilerWarning,
        errorStyle, IFStyleCompilerError, fatalErrorStyle, IFStyleCompilerFatalError,
        filenameStyle, IFStyleFilename,
		progressStyle, IFStyleProgress,
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
    //if (delegate)      [delegate release];
    if (fileTabView)   [fileTabView release];
	
	if (lastProblemURL) [lastProblemURL release];
    
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
        [window setTitle: [NSString stringWithFormat: [[NSBundle mainBundle] localizedStringForKey:@"Compiling - '%@'..."
																							 value:@"Compiling - '%@'..."
																							 table:nil],
            [[compiler inputFile] lastPathComponent]]];

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
    
    [compiler prepareForLaunch];

	[compiler launch];
   
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
	[compilerResults scrollRangeToVisible: NSMakeRange([[compilerResults textStorage] length], 0)];
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
	
	[lastProblemURL release];
	lastProblemURL = [[compiler problemsURL] retain];

    [[[compilerResults textStorage] mutableString] appendString: @"\n"];
	[[[compilerResults textStorage] mutableString] appendString: 
		[NSString stringWithFormat: [[NSBundle mainBundle] localizedStringForKey: @"Compiler finished with code %i" 
																		   value: @"Compiler finished with code %i"
																		   table: nil], exitCode]];
	[[[compilerResults textStorage] mutableString] appendString: @"\n"];

    NSString* msg;

    if (exitCode == 0) {
		[[compiler progress] setMessage: [NSString stringWithFormat: [[NSBundle mainBundle] localizedStringForKey: @"Compilation succeeded" 
																											value: @"Compilation succeeded"
																											table: nil], exitCode]];
		
		
        msg = [[NSBundle mainBundle] localizedStringForKey: @"Success"
													 value: @"Success"
													 table: nil];

        if (delegate &&
            [delegate respondsToSelector: @selector(compileCompletedAndSucceeded:)]) {
            [delegate compileCompletedAndSucceeded: self];
        }
    } else {
		switch (exitCode) {
			case SIGILL:
			case SIGABRT:
			case SIGBUS:
			case SIGSEGV:
				[[compiler progress] setMessage: [NSString stringWithFormat: [[NSBundle mainBundle] localizedStringForKey: @"Compiler crashed with code %i" 
																													value: @"Compiler crashed with code %i"
																													table: nil], exitCode]];
				break;
				
			default:
				[[compiler progress] setMessage: [NSString stringWithFormat: [[NSBundle mainBundle] localizedStringForKey: @"Compilation failed with code %i" 
																													value: @"Compilation failed with code %i"
																													table: nil], exitCode]];
				break;
		}

        msg = [[NSBundle mainBundle] localizedStringForKey: @"Failed"
													 value: @"Failed"
													 table: nil];

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
	NSAttributedString* newString = [[[NSAttributedString alloc] initWithString: data
																	 attributes: [styles objectForKey: IFStyleBase]] autorelease];
	
	[[compilerResults textStorage] appendAttributedString: newString];
}

- (void) gotStderr: (NSNotification*) not {
    NSString* data = [[not userInfo] objectForKey: @"string"];
	NSAttributedString* newString = [[[NSAttributedString alloc] initWithString: data
																	 attributes: [styles objectForKey: IFStyleBase]] autorelease];
	
	[[compilerResults textStorage] appendAttributedString: newString];
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
			
		case IFLexProgress:
			[[compiler progress] setPercentage: IFLexLastProgress];
			
			if (IFLexLastProgressString) {
				NSString* msg;
				
				msg = [[NSString alloc] initWithBytes: IFLexLastProgressString
											   length: strlen(IFLexLastProgressString)-2
											 encoding: NSUTF8StringEncoding];
				
				// (Second attempt if UTF-8 makes no sense)
				if (msg == nil) msg = [[NSString alloc] initWithBytes: IFLexLastProgressString
															   length: strlen(IFLexLastProgressString)-2
															 encoding: NSISOLatin1StringEncoding];
				
				[[compiler progress] setMessage: [msg autorelease]];
			}
	
			return IFStyleProgress;
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
	[storage beginEditing];

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
	[storage endEditing];
	
	[[NSRunLoop currentRunLoop] performSelector: @selector(scrollToEnd)
										 target: self
									   argument: nil
										  order: 128
										  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
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
    NSArray*        newMessage = [NSArray arrayWithObjects: message, [NSNumber numberWithInt: line], [NSNumber numberWithInt: type], [NSNumber numberWithInt: fileNum], nil];
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

    // NSString* message = [msg objectAtIndex: 0];
    int       line    = [[msg objectAtIndex: 1] intValue];
    // IFLex type        = [[msg objectAtIndex: 2] intValue];
	fileNum = [[msg objectAtIndex: 3] intValue];

    // Send to the delegate
    if (delegate &&
        [delegate respondsToSelector: @selector(errorMessageHighlighted:atLine:inFile:)]) {
        [delegate errorMessageHighlighted: self
                                   atLine: line
                                   inFile: [errorFiles objectAtIndex: fileNum]];
    }

    return;
}

- (void) windowWillClose: (NSNotification*) not {
    [self autorelease];
}

// Other information
- (void) showContentsOfFilesIn: (NSFileWrapper*) files
					  fromPath: (NSString*) path {
    if (![files isDirectory]) {
        return; // Nothing to do
    }

    NSEnumerator* keyEnum = [[files fileWrappers] keyEnumerator];
    NSString* key;
	NSTabViewItem* preferredTabView = nil;
	
	// If there is a compiler-supplied problems file, add this to the tab view
	if (lastProblemURL != nil) {
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
			[splitViewItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Compiler" 
																			value: @"Compiler"
																			table: @"CompilerOutput"]];
			[splitViewItem setView: splitView];
			
			[fileTabView addTabViewItem: splitViewItem];
			
			[fileTabView setFrame: [inView bounds]];
			[inView addSubview: fileTabView];
			
			[splitView release];
			[splitViewItem release];
		}

		// Create a web view for the new problems view
		NSView* newView;
		if ([[NSApp delegate] isWebKitAvailable]) {
			// Create a parent view
			NSView* aView = [[NSView alloc] initWithFrame: [fileTabView contentRect]];
			[aView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
			newView = aView;
			
			// Create a 'fake' web view which will get replaced when the view is actually displayed on screen
			IFPretendWebView* pretendView = [[IFPretendWebView alloc] initWithFrame: [aView bounds]];
			
			[pretendView setHostWindow: [[splitView superview] window]];
			[pretendView setRequest: [[[NSURLRequest alloc] initWithURL: lastProblemURL] autorelease]];
			[pretendView setPolicyDelegate: self];
			
			[pretendView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
			
			// Add it to aView
			[aView addSubview: [pretendView autorelease]];
		}

		NSTabViewItem* fileItem;
		fileItem = [[NSTabViewItem alloc] init];
		
		// 'Problems.html' is the preferred view. May also be called 'log of problems?'
		// A file called 'Problems' is preferred to a file called 'log of problems'
		preferredTabView = fileItem;
		
		[fileItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Problems.html" 
																   value: @"Problems"
																   table: @"CompilerOutput"]];
		[newView setFrame: [fileTabView contentRect]];
		[fileItem setView: newView];
		
		[fileTabView addTabViewItem: fileItem];
		
		[fileItem   release];
		[newView    release];
	}

	// Enumerate across the list of files in the filewrapper
    while (key = [keyEnum nextObject]) {
        NSString* type = [[key pathExtension] lowercaseString];

		// HTML, text and inf files go in a tab view showing various different status messages
		// With NI, the problems file is most important: we substitute this if the compiler wants
        if ((![[[key substringToIndex: 4] lowercaseString] isEqualToString: @"temp"]) &&
			(lastProblemURL == nil || ![[[key stringByDeletingPathExtension] lowercaseString] isEqualToString: @"problems"]) &&
            ([type isEqualTo: @"inf"] ||
             [type isEqualTo: @"txt"] ||
			 [type isEqualTo: @"html"] ||
			 [type isEqualTo: @"htm"])) {
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
                [splitViewItem setLabel: [[NSBundle mainBundle] localizedStringForKey: @"Compiler" 
																				value: @"Compiler"
																				table: @"CompilerOutput"]];
                [splitViewItem setView: splitView];

                [fileTabView addTabViewItem: splitViewItem];

                [fileTabView setFrame: [inView bounds]];
                [inView addSubview: fileTabView];

                [splitView release];
                [splitViewItem release];
            }
            
			NSView* newView;
			
			if ([[NSApp delegate] isWebKitAvailable] && ([type isEqualTo: @"html"] ||
														 [type isEqualTo: @"htm"])) {
				// Create a parent view
				NSView* aView = [[NSView alloc] initWithFrame: [fileTabView contentRect]];
				[aView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
				newView = aView;
				
				// Create a 'fake' web view which will get replaced when the view is actually displayed on screen
				IFPretendWebView* pretendView = [[IFPretendWebView alloc] initWithFrame: [aView bounds]];
				
				NSString* file = [path stringByAppendingPathComponent: key];
				[pretendView setHostWindow: [[splitView superview] window]];
				[pretendView setRequest: [[[NSURLRequest alloc] initWithURL: [IFProjectPolicy fileURLWithPath: file]] autorelease]];
				[pretendView setPolicyDelegate: self];
				
				[pretendView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
				
				// Add it to aView
				[aView addSubview: [pretendView autorelease]];
			} else {
				// Create the 'parent' view
				NSView* aView = [[NSView alloc] initWithFrame: [fileTabView contentRect]];

				// Create the 'pretend' text view
				IFPretendTextView* pretendView = [[IFPretendTextView alloc] initWithFrame: [aView bounds]];

				[pretendView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];

				// Load the data for the file
				NSString* textData = [[NSString alloc] initWithData:
					[[[files fileWrappers] objectForKey: key] regularFileContents]
														   encoding: NSUTF8StringEncoding];
				
				// Set up the view
				[pretendView setEventualString: textData];
				
				// This is our new view
				[aView addSubview: [pretendView autorelease]];

				newView = aView;
				
				[textData release];
			}

            NSTabViewItem* fileItem;
            fileItem = [[NSTabViewItem alloc] init];
			
			// 'Problems.html' is the preferred view. May also be called 'log of problems?'
			// A file called 'Problems' is preferred to a file called 'log of problems'
			if ([[[key stringByDeletingPathExtension] lowercaseString] isEqualToString: @"problems"]) {
				preferredTabView = fileItem;
			}
			
			if (preferredTabView == nil &&
				[[[key stringByDeletingPathExtension] lowercaseString] isEqualToString: @"log of problems"]) {
				preferredTabView = fileItem;
			}
				
            [fileItem setLabel: [[NSBundle mainBundle] localizedStringForKey: key 
																	   value: [key stringByDeletingPathExtension] 
																	   table: @"CompilerOutput"]];
			[newView setFrame: [fileTabView contentRect]];
            [fileItem setView: newView];

            [fileTabView addTabViewItem: fileItem];
            
            [fileItem   release];
            [newView    release];
        }
    }
	
	if (preferredTabView && fileTabView) {
		[fileTabView selectTabViewItem: preferredTabView];
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
	delegate = dg;
    //if (delegate) [delegate release];
    //delegate = [dg retain];
}

- (NSObject*) delegate {
    return delegate;
}

// = Web policy delegate methods =

- (void)					webView: (WebView *)sender 
	decidePolicyForNavigationAction: (NSDictionary *)actionInformation 
							request: (NSURLRequest *)request 
							  frame: (WebFrame *)frame 
				   decisionListener: (id<WebPolicyDecisionListener>)listener {
	// Blah. Link failure if WebKit isn't available here. Constants aren't weak linked
	
	// Double blah. WebNavigationTypeLinkClicked == null, but the action value == 0. Bleh
	if ([[actionInformation objectForKey: WebActionNavigationTypeKey] intValue] == 0) {
		NSURL* url = [request URL];
		
		if ([[url scheme] isEqualTo: @"source"]) {
			// We deal with these ourselves
			[listener ignore];
			
			// Format is 'source file name#line number'
			NSString* path = [[[request URL] resourceSpecifier] stringByReplacingPercentEscapesUsingEncoding: NSASCIIStringEncoding];
			NSArray* components = [path componentsSeparatedByString: @"#"];
			
			if ([components count] != 2) {
				NSLog(@"Bad source URL: %@", path);
				if ([components count] < 2) return;
				// (try anyway)
			}
			
			NSString* sourceFile = [[components objectAtIndex: 0] stringByReplacingPercentEscapesUsingEncoding: NSUnicodeStringEncoding];
			NSString* sourceLine = [[components objectAtIndex: 1] stringByReplacingPercentEscapesUsingEncoding: NSUnicodeStringEncoding];
			
			// sourceLine can have format 'line10' or '10'. 'line10' is more likely
			int lineNumber = [sourceLine intValue];
			
			if (lineNumber == 0 && [[sourceLine substringToIndex: 4] isEqualToString: @"line"]) {
				lineNumber = [[sourceLine substringFromIndex: 4] intValue];
			}
			
			if (delegate &&
				[delegate respondsToSelector: @selector(errorMessageHighlighted:atLine:inFile:)]) {
				[delegate errorMessageHighlighted: self
										   atLine: lineNumber
										   inFile: sourceFile];
			}
			
			// Finished
			return;
		}
		
		// General URL policy
		WebDataSource* activeSource = [frame dataSource];
		
		if (activeSource == nil) {
			activeSource = [frame provisionalDataSource];
			if (activeSource != nil) {
				NSLog(@"Using the provisional data source - frame not finished loading?");
			}
		}
		
		if (activeSource == nil) {
			NSLog(@"Unable to establish a datasource for this frame: will probably redirect anyway");
		}
		
		NSURL* absolute1 = [[[request URL] absoluteURL] standardizedURL];
		NSURL* absolute2 = [[[[activeSource request] URL] absoluteURL] standardizedURL];
		
		// We only redirect if the page is different to the current one
		if (!([[absolute1 scheme] caseInsensitiveCompare: [absolute2 scheme]] == 0 &&
			  [[absolute1 path] caseInsensitiveCompare: [absolute2 path]] == 0 &&
			  ([absolute1 query] == [absolute2 query] || [[absolute1 query] caseInsensitiveCompare: [absolute2 query]] == 0))) {			
			if (delegate &&
				[delegate respondsToSelector: @selector(handleURLRequest:)]) {
				if ([delegate handleURLRequest: request]) {
					[listener ignore];
					return;
				}
			}
		}
	}
	
	// default action
	[listener use];
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
