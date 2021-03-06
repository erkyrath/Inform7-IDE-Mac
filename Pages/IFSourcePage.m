//
//  IFSourcePage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFAppDelegate.h"
#import "IFSourcePage.h"

#import "IFSyntaxStorage.h"
#import "IFRestrictedTextStorage.h"
#import "IFViewAnimator.h"

@interface IFSourcePage(IFSourcePagePrivate)

- (void) limitToRange: (NSRange) range
	preserveScrollPos: (BOOL)preserveScrollPos;
- (void) limitToSymbol: (IFIntelSymbol*) symbol
	preserveScrollPos: (BOOL)preserveScrollPos;
- (int) lineForCharacter: (int) charNum 
				 inStore: (NSString*) store;

@end

@implementation IFSourcePage

// = Initialisation =

- (id) initWithProjectController: (IFProjectController*) controller {
	self = [super initWithNibName: @"Source"
				projectController: controller];
	
	if (self) {
		// Retain the source scroller and file manager
		[sourceScroller retain];
		
		// Set up the source text view
		IFProject* doc = [parent document];
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
 		
		if ([sourceText undoManager] != [[parent document] undoManager]) {
			NSLog(@"Oops: undo manager broken");
		}

		[sourceText setSyntaxDictionaryMatcher: [[parent document] syntaxDictionaryMatcherForFile: mainFilename]];
		
		// We want to monitor for file renaming events
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(sourceFileRenamed:)
													 name: IFProjectSourceFileRenamedNotification 
												   object: [parent document]];
		
		// We also want to know when to change the syntax matcher
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(matcherChanged:)
													 name: IFProjectFinishedBuildingSyntaxNotification
												   object: [parent document]];
		
		// Set up the headings browser control
		headingsBrowser = [[IFHeadingsBrowser alloc] init];
		
#if 0
		// Set up the headings drop-down control
		headingsControl = [[IFCustomPopup alloc] initTextCell: [[NSBundle mainBundle] localizedStringForKey: @"Headings"
																									  value: @"Headings"
																									  table: nil]];
		[headingsControl setDelegate: self];
		[headingsControl setTarget: self];
		[headingsControl setAction: @selector(gotoSection:)];
#endif
		
		// Create the header page
		headerPage = [[IFHeaderPage alloc] init];
		[headerPage setDelegate: self];

		// Create the header/source page controls
		headerPageControl = [[IFPageBarCell alloc] initTextCell: [[NSBundle mainBundle] localizedStringForKey: @"HeaderPage"
																										value: @"Headings"
																										table: nil]];
		[headerPageControl setTarget: self];
		[headerPageControl setAction: @selector(showHeaderPage:)];
		[headerPageControl setRadioGroup: 1];

		sourcePageControl = [[IFPageBarCell alloc] initTextCell: [[NSBundle mainBundle] localizedStringForKey: @"SourcePage"
																										value: @"Source"
																										table: nil]];
		[sourcePageControl setRadioGroup: 1];
		[sourcePageControl setTarget: self];
		[sourcePageControl setAction: @selector(showSourcePage:)];
		[sourcePageControl setState: NSOnState];
	}
	
	return self;
}

- (void) dealloc {
	if (textStorage) {
		// Hrm? Cocoa seems to like deallocating NSTextStorage despite its retain count.
		// Ah, wait, NSTextView does not retain a text storage added using [NSTextStorage addLayoutManager:]
		// so, it does honour the retain count, but doesn't monitor it correctly.
		// Regardless, this fixes the problem. Not sure if this is a Cocoa bug or not.
		// Weirdly, this causes a problem if the NSTextView is not the last owner of the NSTextStorage.
		// Hrm, likely cause: if the NSTextStorage is deallocated first, it deregisters itself gracefully.
		// If the NSTextView is deallocated first, it deallocates the NSTextStorage, but we're still using
		// it elsewhere. KABOOOM!
		
		[textStorage removeLayoutManager: [sourceText layoutManager]];
		[textStorage autorelease];
	}

	if (restrictedStorage) {
		[restrictedStorage removeLayoutManager: [sourceText layoutManager]];
		[restrictedStorage autorelease]; restrictedStorage = nil;
	}

	[sourceScroller		release];
	[fileManager		release];
	
	[headerPage setDelegate: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[bookmarksOverlay	release];
	[controlsOverlay	release];
	[headingsControl	release];
	[headerPageControl	release];
	[sourcePageControl	release];
	[headingsBrowser	release];
	[headerPage			release];
	[sourceText			release];

	[super dealloc];
}

// = Details about this view =

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Source Page Title"
												  value: @"Source"
												  table: nil];
}

- (NSView*) activeView {
	return sourceText;
}

// = Text view delegate methods =

- (NSUndoManager *)undoManagerForTextView:(NSTextView *)aTextView {
	// Always use the document undo manager
	return [[parent document] undoManager];
}

// = Misc =

- (void) pasteSourceCode: (NSString*) sourceCode {
	// Get the code that existed previously
	NSRange currentRange = [sourceText selectedRange];
	NSString* oldCode = [[textStorage attributedSubstringFromRange: [sourceText selectedRange]] string];
	
	// Undo sequence is to select a suitable range, then replace again
	NSUndoManager* undo = [sourceText undoManager];
	
	[undo setActionName: [[NSBundle mainBundle] localizedStringForKey: @"Paste Source Code"
																value: @"Paste Source Code"
																table: nil]];
	[undo beginUndoGrouping];
	
	[[undo prepareWithInvocationTarget: self] selectRange: currentRange];
	[[undo prepareWithInvocationTarget: self] pasteSourceCode: oldCode];
	[[undo prepareWithInvocationTarget: self] selectRange: NSMakeRange(currentRange.location, [sourceCode length])];
	
	[undo endUndoGrouping];
	
	// Perform the action
	[sourceText replaceCharactersInRange: currentRange
							  withString: sourceCode];
	[self selectRange: NSMakeRange(currentRange.location, [sourceCode length])];
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

// = Compiling =

- (void) prepareToCompile {
	// Really annoying: Apple changed the undo behaviour of text views in 10.4 so we need to make this call,
	// which is not backwards compatible.
	if ([sourceText respondsToSelector: @selector(breakUndoCoalescing)]) {
		[sourceText breakUndoCoalescing];
	}
}

// = Intelligence =

- (void) setElasticTabs: (BOOL) elastic {
	if ([textStorage isKindOfClass: [IFSyntaxStorage class]]) {
		[(IFSyntaxStorage*)textStorage setElasticTabs: elastic];
	}
}

- (IFIntelFile*) currentIntelligence {
	// IQ: 0
	if ([textStorage isKindOfClass: [IFSyntaxStorage class]]) {
		return [(IFSyntaxStorage*)textStorage intelligenceData];
	} else if ([textStorage isKindOfClass: [IFRestrictedTextStorage class]]) {
		NSTextStorage* realStorage = [(IFRestrictedTextStorage*)textStorage restrictedStorage];

		if ([realStorage isKindOfClass: [IFSyntaxStorage class]]) {
			return [(IFSyntaxStorage*)realStorage intelligenceData];
		} else {
			return nil;
		}
	} else {
		return nil;
	}
}

// = Syntax highlighting =

- (void) indicateRange: (NSRange) range {
	// Restrict the range if necessary
	if (restrictedStorage) {
		NSRange restriction = [restrictedStorage restrictionRange];
		if (range.location >= restriction.location && range.location < restriction.location + restriction.length) {
			range.location -= restriction.location;
		} else {
			// Try moving the restriction range to something nearer the indicated line
			int line = [self lineForCharacter: range.location
									  inStore: [textStorage string]];
			
			IFIntelFile* intel = [self currentIntelligence];
			IFIntelSymbol* symbol = [intel nearestSymbolToLine: line];
			
			if (symbol) {
				[self limitToSymbol: symbol
				  preserveScrollPos: NO];
			}
			
			// If the line is now available, then we can highlight the appropriate character
			NSRange restriction = [restrictedStorage restrictionRange];
			if (range.location >= restriction.location && range.location < restriction.location + restriction.length) {
				range.location -= restriction.location;
			} else {
				return;
			}
		}
	}
	
	[[[NSApp delegate] leopard] showFindIndicatorForRange: range
											   inTextView: sourceText];
}

- (unsigned int) indexOfLine: (int) line
					inString: (NSString*) store {
    int length = [store length];
	
    int x, lineno, linepos;
	x=0;
	
    lineno = 1; linepos = 0;
	if (line > lineno)
	{
		for (x=0; x<length; x++) {
			unichar chr = [store characterAtIndex: x];
			
			if (chr == '\n' || chr == '\r') {
				unichar otherchar = chr == '\n'?'\r':'\n';
				
				lineno++;
				linepos = x + 1;
				
				// Deal with DOS line endings
				if (linepos < length && [store characterAtIndex: linepos] == otherchar) {
					x++; linepos++;
				}
				
				if (lineno == line) {
					break;
				}
			}
		}
	}
	
	if (lineno != line) {
		return NSNotFound;
	}
	
	return x;
}

- (void) indicateLine: (int) line {
    // Find out where the line is in the source view
    NSString* store = [textStorage string];
    int length = [store length];
	
    int x, lineno, linepos, lineLength;
    lineno = 1; linepos = 0;
	if (line > lineno)
	{
		for (x=0; x<length; x++) {
			unichar chr = [store characterAtIndex: x];
			
			if (chr == '\n' || chr == '\r') {
				unichar otherchar = chr == '\n'?'\r':'\n';
				
				lineno++;
				linepos = x + 1;
				
				// Deal with DOS line endings
				if (linepos < length && [store characterAtIndex: linepos] == otherchar) {
					x++; linepos++;
				}
				
				if (lineno == line) {
					break;
				}
			}
		}
	}
	
    if (lineno != line) {
        NSBeep(); // DOH!
        return;
    }

    lineLength = 0;
    for (x=0; x<length-linepos; x++) {
        if ([store characterAtIndex: x+linepos] == '\n'
			|| [store characterAtIndex: x+linepos] == '\r') {
            break;
        }
        lineLength++;
    }
	
	// Show the find indicator
	[self indicateRange: NSMakeRange(linepos, lineLength)];
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
				
			case IFLineStyleBreakpoint:
				background = [NSColor colorWithDeviceRed: 1.0 green: 0.7 blue: 0.4 alpha: 1.0];
				break;
				
			default:
				background = [NSColor colorWithDeviceRed: 0.8 green: 0.3 blue: 0.3 alpha: 1.0];
				break;
		}
		
		NSRange lineRange = [self findLine: line];
		if (restrictedStorage) {
			NSRange restriction = [restrictedStorage restrictionRange];
			if (lineRange.location >= restriction.location && lineRange.location < (restriction.location + restriction.length)) {
				lineRange.location -= [restrictedStorage restrictionRange].location;
			} else {
				lineRange.location = NSNotFound;
			}
		}
		
		if (lineRange.location != NSNotFound) {
			[[sourceText layoutManager] setTemporaryAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
				background, NSBackgroundColorAttributeName, nil]
											 forCharacterRange: lineRange];
		}
	}
}

// = Switching to/from this page =

- (void) didSwitchAwayFromPage {
	// Close the overlay windows
	if (bookmarksOverlay)	[bookmarksOverlay hideWindow: self];
	if (controlsOverlay)	[controlsOverlay hideWindow: self];
}

- (void) didSwitchToPage {
	// Create the overlay windows if they don't already exist
	if (!bookmarksOverlay) {
		bookmarksOverlay = [[IFViewTrackingWindowController alloc] initWithView: [sourceScroller contentView]
																	   inWindow: [parent window]];
	}
	if (!controlsOverlay) {
		controlsOverlay = [[IFViewTrackingWindowController alloc] initWithView: [sourceScroller contentView]
																	  inWindow: [parent window]];
	}
	
	// Display the control windows
	[bookmarksOverlay showWindow: self];
	[controlsOverlay showWindow: self];
}

// = The selection =

- (NSString*) openSourceFile {
	return openSourceFile;
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

- (void) selectTextRange: (NSRange) range {
	// Restrict the range if needed
	if (restrictedStorage) {
		NSRange restriction = [restrictedStorage restrictionRange];
		if (range.location >= restriction.location && range.location < restriction.location + restriction.length) {
			range.location -= restriction.location;
		} else {
			// TODO: move to the appropriate section and try again
			return;
		}
	}

	// Display the range
	[sourceText scrollRangeToVisible: NSMakeRange(range.location, range.length==0?1:range.length)];
    [sourceText setSelectedRange: range];
}

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
	if (line > lineno)
	{
		for (x=0; x<length; x++) {
			unichar chr = [store characterAtIndex: x];
			
			if (chr == '\n' || chr == '\r') {
				unichar otherchar = chr == '\n'?'\r':'\n';
				
				lineno++;
				linepos = x + 1;
				
				// Deal with DOS line endings
				if (linepos < length && [store characterAtIndex: linepos] == otherchar) {
					x++; linepos++;
				}
				
				if (lineno == line) {
					break;
				}
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
	[self selectTextRange: NSMakeRange(linepos,0)];
}

- (void) moveToLocation: (int) location {
	[self selectTextRange: NSMakeRange(location, 0)];
}

- (void) selectRange: (NSRange) range {
	[sourceText scrollRangeToVisible: range];
	[sourceText setSelectedRange: range];
	
	// NOTE: as this is used as part of the undo sequence for pasteSourceCode, this function must not contain an undo action itself
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
	
	if (textStorage) { [textStorage release]; textStorage = nil; }
	textStorage = [fileStorage retain];
	[textStorage addLayoutManager: [layout autorelease]];
	[textStorage setDelegate: self];
	
	if ([textStorage isKindOfClass: [IFSyntaxStorage class]]) {
		[(IFSyntaxStorage*)textStorage setElasticTabs: [[[parent document] compilerSettings] elasticTabs]];
	}
	
	[fileStorage endEditing];
	
	[sourceText setEditable: ![[parent document] fileIsTemporary: file]];
	[sourceText setSyntaxDictionaryMatcher: [[parent document] syntaxDictionaryMatcherForFile: file]];
	
	[[IFIsFiles sharedIFIsFiles] updateFiles]; // have to update for the case where we select an 'unknown' file
}

- (int) lineForCharacter: (int) charNum 
				 inStore: (NSString*) store {
	int result = 0;
	
    int length = [store length];
	
    int x, lineno, linepos;
    lineno = 1; linepos = 0;
	for (x=0; x<length; x++) {
		unichar chr = [store characterAtIndex: x];
		
		if (chr == '\n' || chr == '\r') {
			unichar otherchar = chr == '\n'?'\r':'\n';
			
			lineno++;
			linepos = x + 1;
			
			// Deal with DOS line endings
			if (linepos < length && [store characterAtIndex: linepos] == otherchar) {
				x++; linepos++;
			}
			
			if (x > charNum) {
				break;
			} else {
				result = lineno;
			}
		}
	}
	
	return result;
}

- (NSRange) findLine: (int) line {
    NSString* store = [textStorage string];
    int length = [store length];
	
    int x, lineno, linepos;
    lineno = 1; linepos = 0;
	if (line > lineno) {
		for (x=0; x<length; x++) {
			unichar chr = [store characterAtIndex: x];
			
			if (chr == '\n' || chr == '\r') {
				unichar otherchar = chr == '\n'?'\r':'\n';
				
				lineno++;
				linepos = x + 1;
				
				// Deal with DOS line endings
				if (linepos < length && [store characterAtIndex: linepos] == otherchar) {
					x++; linepos++;
				}
				
				if (lineno == line) {
					break;
				}
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

// = Breakpoints =

- (IBAction) setBreakpoint: (id) sender {
	// Sets a breakpoint at the current location in the current source file
	
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
	
	// Work out which file and line we're in
	NSString* currentFile = [self currentFile];
	int currentLine = [self currentLine];
	
	if (currentLine >= 0) {
		NSLog(@"Deleted breakpoint at %@:%i", currentFile, currentLine);
		
		[[parent document] removeBreakpointAtLine: currentLine
										   inFile: currentFile];
	}	
}

// = Spell checking =

- (void) setSpellChecking: (BOOL) checkSpelling {
	[sourceText setContinuousSpellCheckingEnabled: checkSpelling];
}

// = The file manager =

- (IBAction) showFileManager: (id) sender {
	if (headerPageShown) [self toggleHeaderPage: self];
	if (fileManagerShown) return;
	
	// Set the frame of the file manager view appropriately
	[fileManager setFrame: [[[[self view] subviews] objectAtIndex: 0] frame]];
	
	// Animate to the new view
	IFViewAnimator* animator = [[IFViewAnimator alloc] init];
	
	[animator setTime: 0.3];
	[animator prepareToAnimateView: [[[self view] subviews] objectAtIndex: 0]];
	[animator animateTo: fileManager
				  style: IFFloatOut];
	fileManagerShown = YES;
	[animator autorelease];
}

- (IBAction) hideFileManager: (id) sender {
	if (headerPageShown) [self toggleHeaderPage: self];
	if (!fileManagerShown) return;
	
	// Set the frame of the file manager view appropriately
	[sourceScroller setFrame: [[[[self view] subviews] objectAtIndex: 0] frame]];
	
	// Animate to the new view
	IFViewAnimator* animator = [[IFViewAnimator alloc] init];
	
	[animator setTime: 0.3];
	[animator prepareToAnimateView: [[[self view] subviews] objectAtIndex: 0]];
	[animator animateTo: sourceScroller
				  style: IFFloatIn];
	fileManagerShown = NO;
	[animator autorelease];
}

- (IBAction) toggleFileManager: (id) sender {
	if (fileManagerShown)
		[self hideFileManager: sender];
	else
		[self showFileManager: sender];
}

- (void) setFileManager: (NSView*) newFileManager {
	[fileManager release];
	fileManager = [newFileManager retain];
}

- (NSView*) fileManager {
	return fileManager;
}

// = The headings browser =

- (void) customPopupOpening: (IFCustomPopup*) popup {
	[popup setPopupView: [headingsBrowser view]];
	
	[headingsBrowser setIntel: [parent currentIntelligence]];
	[headingsBrowser setSectionByLine: [self currentLine]];
}

- (void) gotoSection: (id) sender {
	IFCustomPopup* popup = sender;
	IFIntelSymbol* symbol = [popup lastCloseValue];
	
	if (symbol != nil) {
		int lineNumber = [[parent currentIntelligence] lineForSymbol: symbol]+1;
		
		if (lineNumber != NSNotFound) {
			[parent removeAllTemporaryHighlights];
			[parent highlightSourceFileLine: lineNumber
								   inFile: [self currentFile]
									style: IFLineStyleHighlight];
			[self moveToLine: lineNumber];
			[[parent window] makeFirstResponder: [self activeView]];
		}		
	}
}

- (NSArray*) toolbarCells {
	return [NSArray arrayWithObjects: /* headingsControl, */ sourcePageControl, headerPageControl, nil];
}

- (void) matcherChanged: (NSNotification*) not {
	[sourceText setSyntaxDictionaryMatcher: [[parent document] syntaxDictionaryMatcherForFile: openSourceFile]];
}

// = Managing the source text view =

- (BOOL) hasFirstResponder {
	// Returns true if this page has the first responder
	
	// Find the first responder that is a view
	NSResponder* firstResponder = [[sourceText window] firstResponder];
	while (firstResponder && ![firstResponder isKindOfClass: [NSView class]]) {
		firstResponder = [firstResponder nextResponder];
	}
	
	// See if the source text view is in the first responder hierarchy
	NSView* respondingView = (NSView*)firstResponder;
	while (respondingView) {
		if (respondingView == sourceText)  return YES;
		if (respondingView == [self view]) return YES;
		respondingView = [respondingView superview];
	}
	
	return NO;
}

- (void) setSourceText: (IFSourceFileView*) newSourceText {
	[sourceText autorelease];
	sourceText = [newSourceText retain];
}

- (IFSourceFileView*) sourceText {
	return sourceText;
}

// = The header page =

- (void) highlightHeaderSection {
	// Get the text storage
	IFRestrictedTextStorage* storage = (IFRestrictedTextStorage*)[sourceText textStorage];
	if ([storage isKindOfClass: [IFRestrictedTextStorage class]]
		&& [storage isRestricted]) {
		// Work out the line numbers the restriction applies to
		NSRange restriction = [storage restrictionRange];
		
		unsigned firstLine = 0;
		unsigned finalLine = NSNotFound;

		NSString* store = [textStorage string];
		int length = [store length];
		
		int x, lineno, linepos;
		lineno = 1; linepos = 0;

		for (x=0; x<length; x++) {
			unichar chr = [store characterAtIndex: x];
			
			if (chr == '\n' || chr == '\r') {
				unichar otherchar = chr == '\n'?'\r':'\n';
				
				lineno++;
				linepos = x + 1;
				
				if (x < restriction.location) firstLine = lineno;
				else if (x < restriction.location + restriction.length) finalLine = lineno;
				else break;
				
				// Deal with DOS line endings
				if (linepos < length && [store characterAtIndex: linepos] == otherchar) {
					x++; linepos++;
				}
			}
		}
		if (finalLine == NSNotFound) finalLine = lineno;
		
		// Highlight the appropriate node
		[headerPage highlightNodeWithLines: NSMakeRange(firstLine, finalLine-firstLine)];
	} else {
		// Highlight nothing
		[headerPage selectNode: nil];
	}
}

- (IBAction) toggleHeaderPage: (id) sender {
	// Close the file manager if it's being displayed for any reason
	if (fileManagerShown) [self hideFileManager: self];
	
	if (headerPageShown) {
		// Hide the header page and show the source page
		[headerPage setController: nil];
		[sourceScroller setFrame: [[[[self view] subviews] objectAtIndex: 0] frame]];
		
		// Animate to the new view
		IFViewAnimator* animator = [[IFViewAnimator alloc] init];
		
		[animator setTime: 0.3];
		[animator prepareToAnimateView: [[[self view] subviews] objectAtIndex: 0]];
		[animator animateTo: sourceScroller
					  style: IFAnimateLeft];
		[animator autorelease];
		
		[sourcePageControl setState: NSOnState];
		[headerPageControl setState: NSOffState];
		headerPageShown = NO;
	} else {
		// Show the header page
		[headerPage setController: [parent headerController]];
		[[headerPage pageView] setFrame: [[[[self view] subviews] objectAtIndex: 0] frame]];
		[self highlightHeaderSection];
		
		// Animate to the new view
		IFViewAnimator* animator = [[IFViewAnimator alloc] init];
		
		[animator setTime: 0.3];
		[animator prepareToAnimateView: [[[self view] subviews] objectAtIndex: 0]];
		[animator animateTo: [headerPage pageView]
					  style: IFAnimateRight];
		[animator autorelease];
		
		[sourcePageControl setState: NSOffState];
		[headerPageControl setState: NSOnState];
		headerPageShown = YES;
	}
}

- (IBAction) showHeaderPage: (id) sender {
	if (!headerPageShown) [self toggleHeaderPage: self];
}

- (IBAction) hideHeaderPage: (id) sender {
	if (headerPageShown) [self toggleHeaderPage: self];
}

- (IBAction) showSourcePage: (id) sender {
	if (headerPageShown) [self toggleHeaderPage: self];
	if (fileManagerShown) [self hideFileManager: self];
}

// = IFContextMatcherWindow delegate methods =

- (BOOL) openStringUrl: (NSString*) url {
	[parent openDocUrl: [NSURL URLWithString: url]];
	return YES;
}

// = Helping out with the cursor =

- (float) cursorOffset {
	// Returns the offset of the cursor (beginning of the current selection) relative to the top
	// of the view
	
	// Retrieve the currently selected range
	NSRange selection = [sourceText selectedRange];
	
	// Unlikely corner case
	if (selection.location < 0) return 0;
	
	// Get the offset of this location in the text view
	NSLayoutManager* layout	= [sourceText layoutManager];
	NSRange glyphRange		= [layout glyphRangeForCharacterRange: selection
											 actualCharacterRange: nil];

	NSRect boundingRect		= [layout boundingRectForGlyphRange: glyphRange
												inTextContainer: [sourceText textContainer]];
	boundingRect.origin.y	+= [sourceText textContainerOrigin].y;
	
	// Convert to coordinates relative to the containing view
	boundingRect = [sourceText convertRect: boundingRect
									toView: sourceScroller];
	
	// Offset is the minimum position of the bounding rectangle
	return NSMinY(boundingRect);
}

// = Header page delegate methods =

- (void) refreshHeaders: (IFHeaderController*) controller {
	// Relayed via the IFHeaderPage (where it's relayed via the view)
	[self highlightHeaderSection];
}

- (void) removeLimits {
	// Get the text storage object
	NSTextStorage* storage = [sourceText textStorage];
	NSUndoManager* undo = [sourceText undoManager];
	
	if (![storage isKindOfClass: [IFRestrictedTextStorage class]]) {
		return;
	} else {
		if (restrictedStorage != storage) {
			[restrictedStorage autorelease];
			restrictedStorage = [(IFRestrictedTextStorage*)storage retain];
		}

		[[undo prepareWithInvocationTarget: self] limitToRange: [restrictedStorage restrictionRange]
											 preserveScrollPos: NO];
	}
	
	[restrictedStorage removeRestriction];
	[self highlightHeaderSection];
	
	[sourceText setTornAtTop: NO];
	[sourceText setTornAtBottom: NO];
}

- (void) limitToRange: (NSRange) range 
	preserveScrollPos: (BOOL) preserveScrollPos {
	// Record the current cursor offset and selection if preservation is turned on
	float originalCursorOffset	= 0;
	NSRange selectionRange		= NSMakeRange(0, 0);
	
	if (preserveScrollPos) {
		originalCursorOffset	= [self cursorOffset];
		selectionRange			= [sourceText selectedRange];
		[[sourceText layoutManager] setBackgroundLayoutEnabled: NO];
	}
	
	// Get the text storage object
	NSTextStorage* storage = [sourceText textStorage];
	NSUndoManager* undo = [sourceText undoManager];
	
	if (![storage isKindOfClass: [IFRestrictedTextStorage class]]) {
		[[storage retain] autorelease];
		[restrictedStorage release]; restrictedStorage = nil;
		restrictedStorage = [[IFRestrictedTextStorage alloc] initWithTextStorage: storage];
		
		[storage removeLayoutManager: [sourceText layoutManager]];
		[restrictedStorage addLayoutManager: [sourceText layoutManager]];
		
		[[undo prepareWithInvocationTarget: self] removeLimits];
	 } else {
		 if (preserveScrollPos) {
			 selectionRange.location += [restrictedStorage restrictionRange].location;
		 }
		 
		 if (restrictedStorage != storage) {
			 [restrictedStorage autorelease];
			 restrictedStorage = [(IFRestrictedTextStorage*)storage retain];
		 }

		 [[undo prepareWithInvocationTarget: self] limitToRange: [restrictedStorage restrictionRange]
											  preserveScrollPos: NO];
	 }
	
	// Set the restriction range
	[restrictedStorage setRestriction: range];
	[self highlightHeaderSection];
	
	// Display or hide the tears at the top and bottom
	[sourceText setTornAtTop: range.location!=0];
	[sourceText setTornAtBottom: (range.location+range.length)<[textStorage length]];
	
	// Refresh any highlighting
	[self updateHighlightedLines];
	
	// Reset the selection and try to scroll back to the original position if we can
	if (preserveScrollPos) {
		// Update the selection
		if (range.location < selectionRange.location) {
			// Selection is after the beginning of the range
			selectionRange.location -= range.location;
			
			if (selectionRange.location > range.length) {
				// Selection is after the end of the range; just use the start of the region
				selectionRange.location = selectionRange.length = 0;
			} else if (selectionRange.location + selectionRange.length > range.length) {
				// Selection extends beyond the end of the region
				selectionRange.length = range.length - selectionRange.location;
			}
		} else {
			// Just go to the start of the region if the selection is out of bounds
			selectionRange.location = selectionRange.length = 0;
			
			// TODO: selection could start before the range and extend into it; this will work 
			// differently from the selection extending over the end of the range
		}
		
		// Set the selection
		[sourceText setSelectedRange: selectionRange];
		
		// Scroll to the top to avoid some glitching
		[sourceText scrollPoint: NSMakePoint(0,0)];

		// Get the cursor scroll offset
		float newCursorOffset	= [self cursorOffset];
		float scrollOffset		= floorf(newCursorOffset - originalCursorOffset);
		
		// Scroll the view
		NSPoint scrollPos = [[sourceScroller contentView] documentVisibleRect].origin;
		NSLog(@"Old offset: %g, new offset %g, adjusted scroll by %g from %g", originalCursorOffset, newCursorOffset, scrollOffset, scrollPos.y);
		scrollPos.y += scrollOffset;
		if (range.location > 0) scrollPos.y += 18;			// HACK
		if (scrollPos.y < 0) scrollPos.y = 0;
		[[sourceScroller contentView] scrollToPoint: scrollPos];

		[[sourceText layoutManager] setBackgroundLayoutEnabled: YES];
	}
}

- (void) limitToSymbol: (IFIntelSymbol*) symbol 
	 preserveScrollPos: (BOOL)preserveScrollPos {
	IFIntelFile* intelFile = [[parent headerController] intelFile];
	IFIntelSymbol* followingSymbol	= [symbol sibling];
	
	if (symbol == nil || symbol == [intelFile firstSymbol]) {
		// Remove the source text limitations
		[self removeLimits];
		
		// Scroll to the top
		[sourceText scrollPoint: NSMakePoint(0,0)];
		
		// Redisplay the source code
		if (headerPageShown) [self toggleHeaderPage: self];
		
		return;
	}
	
	if (followingSymbol == nil) {
		IFIntelSymbol* parentSymbol = [symbol parent];
		
		while (parentSymbol && !followingSymbol) {
			followingSymbol = [parentSymbol sibling];
			parentSymbol = [parentSymbol parent];
		}
	}
	
	// Get the range we need to limit to
	NSRange limitRange;
	
	int symbolLine = [intelFile lineForSymbol: symbol];
	if (symbolLine == NSNotFound) return;
	
	limitRange.location = [self indexOfLine: symbolLine
								   inString: [textStorage string]];
	
	unsigned finalLocation;
	if (followingSymbol) {
		int followingLine = [intelFile lineForSymbol: followingSymbol];
		if (followingLine == NSNotFound) return;
		finalLocation = [self indexOfLine: followingLine
								 inString: [textStorage string]];
	} else {
		finalLocation = [textStorage length];
	}
	
	if (finalLocation == NSNotFound) return;
	
	// Move the start of the limitation to the first non-whitespace character
	while (limitRange.location < finalLocation) {
		unichar chr = [[textStorage string] characterAtIndex: limitRange.location];
		if (chr != ' ' && chr != '\t' && chr != '\n' && chr != '\r') {
			break;
		}
		limitRange.location++;
	}
	
	// Perform the limitation
	limitRange.length = finalLocation - limitRange.location;
	[self limitToRange: limitRange
	 preserveScrollPos: preserveScrollPos];
	
	// Redisplay the source code
	if (headerPageShown) [self toggleHeaderPage: self];
	
	// Scroll to the top
	if (!preserveScrollPos) {
		[sourceText scrollPoint: NSMakePoint(0,0)];
	}
}

- (void) headerPage: (IFHeaderPage*) page
	  limitToHeader: (IFHeader*) header {
	// Work out the following symbol
	IFIntelSymbol* symbol			= [header symbol];
	
	[self limitToSymbol: symbol
	  preserveScrollPos: NO];
}

- (void) undoReplaceCharactersInRange: (NSRange) range
						   withString: (NSString*) string {
	// Create an undo action
	NSUndoManager* undo = [self undoManagerForTextView: sourceText];
	[undo beginUndoGrouping];
	[undo setActionName: [[NSBundle mainBundle] localizedStringForKey: @"Edit Header"
																value: @"Edit Header"
																table: nil]];
	 [[undo prepareWithInvocationTarget: self] undoReplaceCharactersInRange: NSMakeRange(range.location, [string length])
																withString: [[textStorage string] substringWithRange: range]];
	 [undo endUndoGrouping];
	
	// Replace the text for this range
	[[textStorage mutableString] replaceCharactersInRange: range
											   withString: string];
}

- (void) headerView: (IFHeaderView*) view
 		 updateNode: (IFHeaderNode*) node
 	   withNewTitle: (NSString*) newTitle {
	IFHeader* header = [node header];
	IFIntelSymbol* symbol = [header symbol];
	IFIntelFile* intel = [self currentIntelligence];

	NSString* lastValue = [header headingName];
	
	// Work out which line needs to be edited
	int line = [intel lineForSymbol: symbol] + 1;
	
	// Get the range of the line
	NSRange lineRange = [self findLine: line];
	if (lineRange.location == NSNotFound) return;
	
	NSString* currentValue = [[textStorage string] substringWithRange: lineRange];
	
	// If the line currently contains the previous value, then replace it with the new value
	if ([currentValue isEqualToString: lastValue] && ![currentValue isEqualToString: newTitle]) {
		// Restrict to the selected node
		[self headerPage: nil
		   limitToHeader: header];

		// Create an undo action
		NSUndoManager* undo = [self undoManagerForTextView: sourceText];
		[undo beginUndoGrouping];
		[undo setActionName: [[NSBundle mainBundle] localizedStringForKey: @"Edit Header"
																	value: @"Edit Header"
																	table: nil]];
		[[undo prepareWithInvocationTarget: self] undoReplaceCharactersInRange: NSMakeRange(lineRange.location, [newTitle length])
																	withString: [[textStorage string] substringWithRange: lineRange]];
		[undo endUndoGrouping];
		
		// Replace the text for this node
		[[textStorage mutableString] replaceCharactersInRange: lineRange
												   withString: newTitle];
	}
	
	// Force a highlighter pass
	if ([textStorage isKindOfClass: [IFSyntaxStorage class]]) {
		[(IFSyntaxStorage*)textStorage highlighterPass];
		[[parent headerController] updateFromIntelligence: [self currentIntelligence]];
	}
}
	
- (IFIntelSymbol*) currentSection {
	// Get the text storage
	IFRestrictedTextStorage* storage = (IFRestrictedTextStorage*)[sourceText textStorage];
	if ([storage isKindOfClass: [IFRestrictedTextStorage class]]
		&& [storage isRestricted]) {
		IFIntelFile* intelFile = [self currentIntelligence];
		
		// Work out the line numbers the restriction applies to
		NSRange restriction = [storage restrictionRange];
		
		// Return the nearest section
		return [intelFile nearestSymbolToLine: [self lineForCharacter: restriction.location
															  inStore: [textStorage string]]];
	}
	
	return nil;
}

- (void) sourceFileShowPreviousSection: (id) sender {
	IFIntelSymbol* section = [self currentSection];
	IFIntelSymbol* previousSection = [section previousSibling];
	
	if (!previousSection) {
		previousSection = [section parent];
		if (previousSection == [[self currentIntelligence] firstSymbol]) previousSection = nil;
	}
	
	if (previousSection) {
		IFViewAnimator* animator = [[[IFViewAnimator alloc] init] autorelease];
		BOOL hasFirstResponder = [self hasFirstResponder];
		
		[animator setTime: 0.3];
		[animator prepareToAnimateView: view];
		
		[self limitToSymbol: previousSection
		  preserveScrollPos: NO];
		[sourceText setSelectedRange: NSMakeRange(0,0)];
		[animator animateTo: view
					  style: IFAnimateDown
				sendMessage: @selector(setFirstResponder)
				   toObject: hasFirstResponder?self:nil];
	} else {
		IFViewAnimator* animator = [[[IFViewAnimator alloc] init] autorelease];
		BOOL hasFirstResponder = [self hasFirstResponder];
		
		[animator setTime: 0.3];
		[animator prepareToAnimateView: view];
		
		[self removeLimits];
		[sourceText setSelectedRange: NSMakeRange(0,0)];
		[animator animateTo: view
					  style: IFAnimateDown
				sendMessage: @selector(setFirstResponder)
				   toObject: hasFirstResponder?self:nil];
	}
}

- (void) sourceFileShowNextSection: (id) sender {
	IFIntelSymbol* section		= [self currentSection];
	IFIntelSymbol* nextSection	= [section sibling];
	
	if (!nextSection) {
		IFIntelSymbol* parentSection = [section parent];
		while (parentSection && !nextSection) {
			nextSection = [parentSection sibling];
			parentSection = [parentSection parent];
		}
	}
	
	if (nextSection) {
		IFViewAnimator* animator = [[[IFViewAnimator alloc] init] autorelease];
		BOOL hasFirstResponder = [self hasFirstResponder];
		
		[animator setTime: 0.3];
		[animator prepareToAnimateView: view];
		
		[self limitToSymbol: nextSection
		  preserveScrollPos: NO];
		[sourceText setSelectedRange: NSMakeRange(0,0)];
		[animator animateTo: view
					  style: IFAnimateUp
				sendMessage: @selector(setFirstResponder)
				   toObject: hasFirstResponder?self:nil];
	}
}

- (void) setFirstResponder {
	// View animation has finished and we want to reset the source text view as the first responder
	[[sourceText window] makeFirstResponder: sourceText];
}

- (IFIntelSymbol*) symbolNearestSelection {
	// Work out the absolute selection
	NSRange selection				= [sourceText selectedRange];
	if (restrictedStorage != nil) {
		selection.location			+= [restrictedStorage restrictionRange].location;
	}
	
	// Retrieve the symbol nearest to the line the selection is on
	IFIntelFile* intelFile			= [self currentIntelligence];
	IFIntelSymbol* nearestSymbol	= [intelFile nearestSymbolToLine: [self lineForCharacter: selection.location
																				  inStore: [textStorage string]]];
	
	return nearestSymbol;
}

- (void) showEntireSource: (id) sender {
	// Display everything
	[self limitToRange: NSMakeRange(0, [textStorage length])
	 preserveScrollPos: YES];
}

- (void) showCurrentSectionOnly: (id) sender {
	// Get the symbol nearest to the current selection
	IFIntelSymbol* cursorSection = [self symbolNearestSelection];
	
	// Limit the displayed range to it
	if (cursorSection) {
		[self limitToSymbol: cursorSection
		  preserveScrollPos: YES];
	}
}

- (void) showFewerHeadings: (id) sender {
	// Get the currently displayed section
	IFIntelSymbol* currentSection = [self currentSection];
	if (!currentSection) {
		// Ensures we don't end up picking the 'title' section which includes the whole file anyway
		currentSection = [[self currentIntelligence] firstSymbol];
	}
	
	// Also get the section that the cursor is in
	IFIntelSymbol* cursorSection = [self symbolNearestSelection];
	
	// Can't do anything if the cursor is in no section, or the currently selected section is the most specific we can use
	if (cursorSection == nil || currentSection == cursorSection) {
		return;
	}
	
	// Move up the sections until we find one which has the currentSection as a parent
	IFIntelSymbol* lowerSection = cursorSection;
	while (lowerSection && [lowerSection parent] != currentSection) {
		lowerSection = [lowerSection parent];
	}
	
	if (lowerSection) {
		// Restrict to this section
		[self limitToSymbol: lowerSection
		  preserveScrollPos: YES];
	}
}

- (void) showMoreHeadings: (id) sender {
	// Limit to one section above the current section
	IFIntelSymbol* currentSection	= [self currentSection];
	if (!currentSection) {
		return;
	}
	
	IFIntelSymbol* parentSection	= [currentSection parent];
	if (parentSection && parentSection != [[self currentIntelligence] firstSymbol]) {
		[self limitToSymbol: parentSection
		  preserveScrollPos: YES];
	} else {
		[self showEntireSource: self];
	}
}


@end
