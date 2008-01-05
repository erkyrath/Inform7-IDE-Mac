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
		
		// Set up the headings drop-down control
		headingsControl = [[IFCustomPopup alloc] initTextCell: [[NSBundle mainBundle] localizedStringForKey: @"Headings"
																									  value: @"Headings"
																									  table: nil]];
		[headingsControl setDelegate: self];
		[headingsControl setTarget: self];
		[headingsControl setAction: @selector(gotoSection:)];
		
		// Create the header page
		headerPage = [[IFHeaderPage alloc] init];
		[headerPage setDelegate: self];

		headerPageControl = [[IFPageBarCell alloc] initTextCell: [[NSBundle mainBundle] localizedStringForKey: @"HeaderPage"
																										value: @"Headings"
																										table: nil]];
		[headerPageControl setTarget: self];
		[headerPageControl setAction: @selector(toggleHeaderPage:)];
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
		[textStorage release];
	}
	
	[sourceScroller release];
	[fileManager release];
	
	[headerPage setDelegate: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[headingsControl release];
	[headerPageControl release];
	[headingsBrowser release];
	[headerPage release];
	[sourceText release];

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
	[[[NSApp delegate] leopard] showFindIndicatorForRange: range
											   inTextView: sourceText];
}

- (unsigned int) indexOfLine: (int) line
					inString: (NSString*) store {
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
		return NSNotFound;
	}
	
	return x;
}

- (void) indicateLine: (int) line {
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
		
		if (lineRange.location != NSNotFound) {
			[[sourceText layoutManager] setTemporaryAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
				background, NSBackgroundColorAttributeName, nil]
											 forCharacterRange: lineRange];
		}
	}
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
	[sourceText scrollRangeToVisible: NSMakeRange(linepos, 1)];
    [sourceText setSelectedRange: NSMakeRange(linepos,0)];
}

- (void) moveToLocation: (int) location {
	[sourceText scrollRangeToVisible: NSMakeRange(location, 0)];
	[sourceText setSelectedRange: NSMakeRange(location, 0)];
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
	[fileStorage endEditing];
	
	[sourceText setEditable: ![[parent document] fileIsTemporary: file]];
	[sourceText setSyntaxDictionaryMatcher: [[parent document] syntaxDictionaryMatcherForFile: file]];
	
	[[IFIsFiles sharedIFIsFiles] updateFiles]; // have to update for the case where we select an 'unknown' file
}

- (NSRange) findLine: (int) line {
    NSString* store = [[sourceText textStorage] string];
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
	return [NSArray arrayWithObjects: headingsControl, headerPageControl, nil];
}

- (void) matcherChanged: (NSNotification*) not {
	[sourceText setSyntaxDictionaryMatcher: [[parent document] syntaxDictionaryMatcherForFile: openSourceFile]];
}

// = Managing the source text view =

- (void) setSourceText: (IFSourceFileView*) newSourceText {
	[sourceText autorelease];
	sourceText = [newSourceText retain];
}

- (IFSourceFileView*) sourceText {
	return sourceText;
}

// = The header page =

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
		
		[headerPageControl setState: NSOffState];
		headerPageShown = NO;
	} else {
		// Show the header page
		[headerPage setController: [parent headerController]];
		[[headerPage pageView] setFrame: [[[[self view] subviews] objectAtIndex: 0] frame]];
		
		// Animate to the new view
		IFViewAnimator* animator = [[IFViewAnimator alloc] init];
		
		[animator setTime: 0.3];
		[animator prepareToAnimateView: [[[self view] subviews] objectAtIndex: 0]];
		[animator animateTo: [headerPage pageView]
					  style: IFAnimateRight];
		[animator autorelease];
		
		[headerPageControl setState: NSOnState];
		headerPageShown = YES;
	}
}

// = IFContextMatcherWindow delegate methods =

- (BOOL) openStringUrl: (NSString*) url {
	[parent openDocUrl: [NSURL URLWithString: url]];
	return YES;
}

// = Header page delegate methods =

- (void) limitToRange: (NSRange) range {
	// Get the text storage object
	NSTextStorage* storage = [sourceText textStorage];
	IFRestrictedTextStorage* restrictedStorage;
	
	if (![storage isKindOfClass: [IFRestrictedTextStorage class]]) {
		[[storage retain] autorelease];
		restrictedStorage = [[IFRestrictedTextStorage alloc] initWithTextStorage: storage];
		
		[storage removeLayoutManager: [sourceText layoutManager]];
		[restrictedStorage addLayoutManager: [sourceText layoutManager]];
	 } else {
		 restrictedStorage = (IFRestrictedTextStorage*)storage;
	 }
	
	// Set the restriction range
	[restrictedStorage setRestriction: range];
	
	// Display or hide the tears at the top and bottom
	[sourceText setTornAtTop: range.location!=0];
	[sourceText setTornAtBottom: (range.location+range.length)<[textStorage length]];
}

- (void) headerPage: (IFHeaderPage*) page
	  limitToHeader: (IFHeader*) header {
	IFIntelFile* intelFile = [[parent headerController] intelFile];
	
	// Work out the following symbol
	IFIntelSymbol* symbol			= [header symbol];
	IFIntelSymbol* followingSymbol	= [symbol sibling];
	
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
	
	limitRange.length = finalLocation - limitRange.location;

	[self limitToRange: limitRange];

	// Redisplay the source code
	if (headerPageShown) [self toggleHeaderPage: self];
}

@end
