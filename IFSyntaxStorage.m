//
//  IFSyntaxStorage.m
//  Inform
//
//  Created by Andrew Hunter on 17/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFSyntaxStorage.h"


@implementation IFSyntaxStorage

// = Initialisation =

- (id) init {
	// Designated initialiser
	self = [super init];
	
	if (self) {
		// Setup variables
		string = [[NSMutableAttributedString alloc] initWithString: @""];
		
		linePositions = [[NSMutableArray alloc] init];
		lineStates = [[NSMutableArray alloc] init];
		
		charStyles = NULL;
		
		syntaxStack = [[NSMutableArray alloc] init];
		syntaxPos = 0;
		
		highlighter = nil;
		
		// Initial state
		[linePositions addObject: [NSNumber numberWithUnsignedInt: 0]]; // First line always starts at character 0
		[lineStates addObject: [NSMutableArray arrayWithObjects: [NSNumber numberWithUnsignedChar: IFSyntaxStateDefault], nil]]; // Initial stack starts with the default state
	}
	
	return self;
}

// = Utility methods =

- (int) lineForIndex: (unsigned) index {
	int nLines = [linePositions count];

	// Yet Another Binary Search
	int low = 0;
	int high = nLines - 1;
	
	while (low <= high) {
		int middle = (low + high)>>1;
		
		unsigned lineStart = [[linePositions objectAtIndex: middle] unsignedIntValue];
		
		if (index < lineStart) {
			// Not this line: search the lower half
			high = middle-1;
			continue;
		}
		
		unsigned lineEnd = middle<(nLines-1)?[[linePositions objectAtIndex: middle+1] unsignedIntValue]:[string length];
		
		if (index > lineEnd) {
			// Not this line: search the upper half
			low = middle+1;
			continue;
		}
		
		// Must be this line
		return middle;
	}
	
	// If we fell off, must be the last line (lines are unsigned, so we can't fall off the bottom)
	return nLines-1;
}

- (IFSyntaxStyle) styleAtIndex: (unsigned) index
				effectiveRange: (NSRangePointer) range {
	IFSyntaxStyle style = charStyles[index];
	
	if (range) {
		range->location = index;
		range->length = 0;
		
		while (range->location > 0) {
			if (charStyles[range->location-1] == style) {
				range->location--;
			} else {
				break;
			}
		}
		
		unsigned strLen = [string length];
		
		while (range->location+range->length+1 < strLen) {
			if (charStyles[range->location+range->length+1] == style) {
				range->length++;
			} else {
				break;
			}
		}
	}
	
	return style;
}

// = Required NSTextStorage methods =

- (NSString*) string {
	return [string string];
}

// Temp storage
static NSString* IFCombinedAttributes = @"IFCombinedAttributes";
static NSString* IFStyleAttributes = @"IFCombinedAttributes";

- (NSDictionary*) attributesAtIndex: (unsigned) index
					 effectiveRange: (NSRangePointer) range {
	if (!highlighter) {
		return [string attributesAtIndex: index
						  effectiveRange: range];
	}
	
	// Get the basic style
	IFSyntaxStyle style;
	NSRange styleRange;
	
	style = [self styleAtIndex: index
				effectiveRange: &styleRange];
	
	// Get the attributes for this style
	NSDictionary* styleAttributes = [highlighter attributesForStyle: style];
	
	// Get the attributes and range for the string
	NSRange stringRange;
	NSDictionary* stringAttributes = [string attributesAtIndex: index
												effectiveRange: &stringRange];
	
	NSRange finalRange = NSIntersectionRange(styleRange, stringRange);
	
	// Use the cached attributes if available
	if ([stringAttributes objectForKey: IFStyleAttributes] == styleAttributes) {
		return [stringAttributes objectForKey: IFCombinedAttributes];
	}
	
	// Create the result
	NSMutableDictionary* attributes = [stringAttributes mutableCopy];
	
	[attributes addEntriesFromDictionary: styleAttributes];
	
	if ([attributes objectForKey: IFStyleAttributes]) [attributes removeObjectForKey: IFStyleAttributes];
	if ([attributes objectForKey: IFCombinedAttributes]) [attributes removeObjectForKey: IFCombinedAttributes];
	
	// Cache it
	[string addAttribute: IFStyleAttributes
				   value: styleAttributes
				   range: finalRange];
	[string addAttribute: IFCombinedAttributes
				   value: attributes
				   range: finalRange];
	
	// Return it
	return [attributes autorelease];
}

- (void) replaceCharactersInRange: (NSRange) range
					   withString: (NSString*) newString {
	unsigned strLen = [string length];
	unsigned newLen = [newString length];

	// The range of lines to be replaced
	int firstLine = [self lineForIndex: range.location];
	int lastLine = range.length>0?[self lineForIndex: range.location + range.length - 1]:firstLine;
	
	// Build the array of new lines
	NSMutableArray* newLinePositions = [[NSMutableArray alloc] init];
	NSMutableArray* newLineStates = [[NSMutableArray alloc] init];
	
	unsigned x;
	for (x=0; x<newLen; x++) {
		unichar thisChar = [newString characterAtIndex: x];
		
		if (thisChar == '\n') {
			[newLinePositions addObject: [NSNumber numberWithUnsignedInt: x + range.location]];
			[newLineStates addObject: [NSMutableArray arrayWithObject: [NSNumber numberWithUnsignedChar: IFSyntaxStateNotHighlighted]]];
		}
	}
	
	// Replace the line positions (first line is still at the same position, with the same initial state, of course)
	[linePositions replaceObjectsInRange: NSMakeRange(firstLine+1, lastLine-firstLine)
					withObjectsFromArray: newLinePositions];
	[lineStates replaceObjectsInRange: NSMakeRange(firstLine+1, lastLine-firstLine)
				 withObjectsFromArray: newLineStates];
	
	[newLinePositions release];
	[newLineStates release];
	
	// Update the character positions
	if (newLen < range.length) {
		// Move characters down
		memmove(charStyles + range.location + range.length,
				charStyles + range.location + newLen,
				sizeof(*charStyles)*(strLen - (range.location + range.length)));
		
		charStyles = realloc(charStyles, strLen + (newLen - range.length));
	} else {
		// Move charactes up
		charStyles = realloc(charStyles, strLen + (newLen - range.length));

		memmove(charStyles + range.location + range.length,
				charStyles + range.location + newLen,
				sizeof(*charStyles)*(strLen - (range.location + range.length)));
	}
	
	// Characters no longer have valid states
	for (x=0; x<newLen; x++) {
		charStyles[x+range.location] = IFSyntaxStateNotHighlighted;
	}
	
	// Update the actual characters
	[string replaceCharactersInRange: range
						  withString: newString];
	
	// Rehighlight, update
	[self beginEditing];
	
	[self edited: NSTextStorageEditedCharacters
		   range: range
  changeInLength: newLen - range.length];
	
	[self stopBackgroundHighlighting];
	[self highlightRange: NSMakeRange(range.location, newLen)];
	[self startBackgroundHighlighting];
	
	[self endEditing];
}

- (void) setAttributes: (NSDictionary*) attributes
				 range: (NSRange) range {
	// Remove our private attributes if they've got copied through
	if ([attributes objectForKey: IFStyleAttributes] || [attributes objectForKey: IFCombinedAttributes]) {
		NSMutableDictionary* newAttr = [attributes mutableCopy];
		
		if ([attributes objectForKey: IFStyleAttributes]) [newAttr removeObjectForKey: IFStyleAttributes];
		if ([attributes objectForKey: IFCombinedAttributes]) [newAttr removeObjectForKey: IFCombinedAttributes];
		
		attributes = [newAttr autorelease];
	}
	
	// Set the attributes in the string
	[string setAttributes: attributes
					range: range];
	
	// Note that we're now edited
	[self edited: NSTextStorageEditedAttributes
		   range: range
  changeInLength: 0];
}

// = Setting/retrieving the highlighter =

- (void) setHighlighter: (id<IFSyntaxHighlighter,NSObject>) newHighlighter {
	if (highlighter) [highlighter release];
	highlighter = [newHighlighter retain];
}

- (id<IFSyntaxHighlighter>) highlighter {
	return highlighter;
}

// = Communication from the highlighter =

- (void) pushState {
	[syntaxStack addObject: [NSNumber numberWithUnsignedChar: syntaxState]];
}

- (void) popState {
	[syntaxStack removeLastObject];
}

// = Actually performing highlighting =

- (void) highlightRange: (NSRange) range {
	// The range of lines to be highlighted
	int firstLine = [self lineForIndex: range.location];
	int lastLine = range.length>0?[self lineForIndex: range.location + range.length - 1]:firstLine;
	
	// Setup
	[highlighter setSyntaxStorage: self];
		
	// Perform the highlighting
	int line;
	NSArray* lastOldStack = nil; // The 'old' stack for the last line
	
	for (line=firstLine; line<=lastLine; line++) {
		// The range of characters to be highlighted
		unsigned firstChar = [[linePositions objectAtIndex: line] unsignedIntValue];
		unsigned  lastChar = (line+1)<[linePositions count]?[[linePositions objectAtIndex: line+1] unsignedIntValue]:[string length];

		// Set up the state
		[syntaxStack setArray: [lineStates objectAtIndex: line]];

		syntaxState = [[syntaxStack lastObject] unsignedCharValue];
		[syntaxStack removeLastObject];
		
		// Highlight this line
		for (syntaxPos=firstChar; syntaxPos<lastChar; syntaxPos++) {
			// Current state
			unichar curChar = [[string string] characterAtIndex: syntaxPos];
			
			// Next state
			IFSyntaxState nextState = [highlighter stateForCharacter: curChar
														  afterState: syntaxState];
			
			// Next style
			IFSyntaxStyle nextStyle = [highlighter styleForCharacter: curChar
															   state: nextState];
			
			// Store the style
			charStyles[syntaxPos] = nextStyle;
			
			// Store the state
			syntaxState = nextState;
		}
		
		// Provide an opportunity for the highlighter to hint keywords, etc
		[highlighter rehintLine: [[string string] substringWithRange: NSMakeRange(firstChar, lastChar-firstChar)]
						 styles: charStyles+firstChar];
		
		// Finish the stack
		[syntaxStack addObject: [NSNumber numberWithUnsignedChar: syntaxState]];
		
		// Store the stack
		[lastOldStack release];
		lastOldStack = nil;
		if (line+1 < [lineStates count]) {
			lastOldStack = [[lineStates objectAtIndex: line+1] retain];
			
			[lineStates replaceObjectAtIndex: line+1
								  withObject: [[syntaxStack copy] autorelease]];
		}
	}
	
	// If the next line needs highlighting, mark it so
	if (line+1 < [lineStates count]) {
		if (![lastOldStack isEqualToArray: [lineStates objectAtIndex: line]]) {
			// The state at the start of this line has changed
			[lineStates replaceObjectAtIndex: line+1
								  withObject: [NSArray arrayWithObject: [NSNumber numberWithUnsignedChar: IFSyntaxStateNotHighlighted]]];
		}
	}

	// Clean up
	[lastOldStack release];
	[highlighter setSyntaxStorage: nil];
	
	// Mark as editied
	unsigned firstChar = [[linePositions objectAtIndex: firstLine] unsignedIntValue];
	unsigned lastChar = (lastLine+1)<[linePositions count]?[[linePositions objectAtIndex: lastLine+1] unsignedIntValue]:[string length];
	
	[self edited: NSTextStorageEditedAttributes
		   range: NSMakeRange(firstChar, lastChar-firstChar)
  changeInLength: 0];
}

- (void) highlightInTime: (NSTimeInterval) waitFor {
	unsigned firstLine = [lineStates indexOfObject: [NSArray arrayWithObject: [NSNumber numberWithUnsignedChar: IFSyntaxStateNotHighlighted]]];
		
	if (firstLine != NSNotFound) {
		// Need to highlight
	}
}

- (void) startBackgroundHighlighting {
	[self stopBackgroundHighlighting];
	
	[self highlightInTime: 0.5];
}

- (void) stopBackgroundHighlighting {
}

@end
