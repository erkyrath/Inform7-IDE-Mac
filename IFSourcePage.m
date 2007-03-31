//
//  IFSourcePage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFSourcePage.h"

#import "IFSyntaxStorage.h"
#import "IFViewAnimator.h"

@implementation IFSourcePage

// = Initialisation =

- (id) initWithProjectController: (IFProjectController*) controller {
	self = [super initWithNibName: @"Source"
				projectController: controller];
	
	if (self) {
		[sourceScroller retain];
		[fileManager retain];
		
		if ([sourceText undoManager] != [[parent document] undoManager]) {
			NSLog(@"Oops: undo manager broken");
		}
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(sourceFileRenamed:)
													 name: IFProjectSourceFileRenamedNotification 
												   object: [parent document]];
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
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];

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
				if ([store characterAtIndex: linepos] == otherchar) {
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
	
	[fileStorage addLayoutManager: [layout autorelease]];
	[fileStorage setDelegate: self];
	if (textStorage) { [textStorage release]; textStorage = nil; }
	textStorage = [fileStorage retain];
	
	[fileStorage endEditing];
	
	[sourceText setEditable: ![[parent document] fileIsTemporary: file]];
	
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

@end
