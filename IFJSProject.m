//
//  IFJSProject.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 29/08/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFJSProject.h"


@implementation IFJSProject

// = Initialisation =

- (id) initWithPane: (IFProjectPane*) newPane {
	self = [super init];
	
	if (self) {
		pane = newPane;
	}
	
	return self;
}

- (void) dealloc {
	pane = nil;
	
	[super dealloc];
}

// = JavaScript names for our selectors =

+ (NSString *) webScriptNameForSelector: (SEL)sel {
	if (sel == @selector(selectView:)) {
		return @"selectView";
	} else if (sel == @selector(pasteCode:)) {
		return @"pasteCode";
	} else if (sel == @selector(runStory:)) {
		return @"runStory";
	} else if (sel == @selector(replayStory:)) {
		return @"replayStory";
	} else if (sel == @selector(addCommand:)) {
		return @"addCommand";
	} else if (sel == @selector(clearCommands)) {
		return @"clearCommands";
	}
	
	return nil;
}

+ (BOOL) isSelectorExcludedFromWebScript: (SEL)sel {
	if (sel == @selector(selectView:) || sel == @selector(pasteCode:) || sel == @selector(replayStory:) || sel == @selector(addCommand:) || sel == @selector(clearCommands)) {
		return NO;
	}
	
	return YES;
}

// = JavaScript operations on the pane =

- (void) selectView: (NSString*) view {
	view = [view lowercaseString];
	
	if ([view isEqualToString: @"source"]) {
		[pane selectView: IFSourcePane];
	} else if ([view isEqualToString: @"error"]) {
		[pane selectView: IFErrorPane];
	} else if ([view isEqualToString: @"game"]) {
		[pane selectView: IFGamePane];
	} else if ([view isEqualToString: @"documentation"]) {
		[pane selectView: IFDocumentationPane];
	} else if ([view isEqualToString: @"index"]) {
		[pane selectView: IFIndexPane];
	} else if ([view isEqualToString: @"skein"]) {
		[pane selectView: IFSkeinPane];
	} else if ([view isEqualToString: @"transcript"]) {
		[pane selectView: IFTranscriptPane];
	} else {
		// Other view types are not supported at present
	}
}

- (NSString*) unescapeString: (NSString*) string {
	// Change '\n', '\t', etc marks in a string to newlines, tabs, etc
	int length = [string length];
	if (length == 0) return @"";

	int outLength = -1;
	int totalLength = 256;
	unichar* newString = malloc(sizeof(unichar)*totalLength);

	int chNum;
	for (chNum = 0; chNum < length; chNum++) {
		// Get the next character
		unichar chr = [string characterAtIndex: chNum];
		unichar outChar = '?';
		
		// If it's an escape character, parse as appropriate
		if (chr == '\\' && chNum+1<length) {
			// The result depends on the next character
			chNum++;
			unichar nextChar = [string characterAtIndex: chNum];
			
			switch (nextChar) {
				case 'n':
					// Newline
					outChar = 10;
					break; 
					
				case 'r':
					// Return
					outChar = 13;
					break;
						
				case 't':
					// Tab
					outChar = 9;
					break;
					
				default:
					// Default behaviour is just to strip the '\'
					outChar = nextChar;
			}
		} else {
			// Otherwise, just pass it through
			outChar = chr;
		}
		
		// Add to the output string
		outLength++;
		if (outLength >= totalLength) {
			totalLength += 256;
			newString = realloc(newString, sizeof(unichar)*totalLength);
		}
		
		newString[outLength] = outChar;
	}
	
	// Turn newString into an NSString
	outLength++;
	NSString* result = [NSString stringWithCharacters: newString
											   length: outLength];
	free(newString);
	
	return result;
}

- (void) pasteCode: (NSString*) code {
	[pane pasteSourceCode: [self unescapeString: code]];
}

- (void) runStory: (NSString*) game {
}

- (void) replayStory: (NSString*) game {
}

- (void) addCommand: (NSString*) command {
}

- (void) clearCommands {
}

- (void)finalizeForWebScript {
	pane = nil;
}

@end
