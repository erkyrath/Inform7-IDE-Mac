//
//  IFSyntaxStorage.m
//  Inform
//
//  Created by Andrew Hunter on 17/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFSyntaxStorage.h"

#import "IFPreferences.h"

static const int maxPassLength = 1024;

#define HighlighterDebug 0

@implementation IFSyntaxStorage

// = Initialisation =

- (id) sharedInit {
	self = [super init];
	
	if (self) {
		// Setup variables
		string = [[NSMutableAttributedString alloc] initWithString: @""];
		
		lineStarts = malloc(sizeof(*lineStarts));
		lineStates = [[NSMutableArray alloc] init];
		
		charStyles = NULL;
		lineStyles = [[NSMutableArray alloc] initWithObjects: [NSDictionary dictionary], nil];
		
		syntaxStack = [[NSMutableArray alloc] init];
		syntaxPos = 0;
		
		highlighter = nil;
		
		// Initial state
		lineStarts[0] = 0;
		nLines = 1;
		[lineStates addObject: 
			[NSMutableArray arrayWithObjects: 
				[NSArray arrayWithObjects:
					[NSNumber numberWithUnsignedInt: IFSyntaxStateDefault],
					[NSNumber numberWithUnsignedInt: 0],
					nil],
				nil]]; // Initial stack starts with the default state
		
		needsHighlighting.location = NSNotFound;
		amountHighlighted = 0;
		
		enableWrapIndent = YES;
		[self paragraphStyleForTabStops: 8];
		
		// Register for preference change notifications
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(preferencesChanged:)
													 name: IFPreferencesChangedEarlierNotification
												   object: [IFPreferences sharedPreferences]];
	}
	
	return self;
}

- (id) init {
	// Designated initialiser
	self = [self sharedInit];
	
	if (self) {
	}
	
	return self;
}

- (id) initWithString: (NSString*) newString {
	// Designated initialiser
	self = [self sharedInit];
	
	if (self) {
		// Update the string
		[self replaceCharactersInRange: NSMakeRange(0,0)
							withString: newString];
	}
	
	return self;
}

- (id) initWithAttributedString: (NSAttributedString*) newString {
	// Designated initialiser
	self = [self sharedInit];
	
	if (self) {		
		// Update the string
		[self replaceCharactersInRange: NSMakeRange(0,0)
							withString: [newString string]];
		
		[string release];
		string = [newString mutableCopy];
	}
	
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	[string release];
	
	[lineStates release];
	free(lineStarts);
	free(charStyles);
	[lineStyles release];
	
	[syntaxStack release];

	if (highlighter) {
		[highlighter setSyntaxStorage: nil];
		[highlighter release];
	}
	
	if (intelSource) {
		[intelSource setSyntaxStorage: nil];
		[intelSource release];
	}
	
	if (intelData) [intelData release];
	
	[paragraphStyles release];
	[tabStops release];
	
	[super dealloc];
}

// = Utility methods =

#if HighlighterDebug
- (void) edited: (unsigned)editedMask range: (NSRange)range changeInLength: (int)delta {
	NSLog(@"Highlighter: edited range (%i, %i) mask %x, change in length %i", range.location, range.length, editedMask, delta);
	
	[super edited: editedMask range: range changeInLength: delta];
}
#endif

- (int) lineForIndex: (unsigned) index {
	// Yet Another Binary Search
	int low = 0;
	int high = nLines - 1;
	
	while (low <= high) {
		int middle = (low + high)>>1;
		
		unsigned lineStart = lineStarts[middle];
		
		if (index < lineStart) {
			// Not this line: search the lower half
			high = middle-1;
			continue;
		}
		
		unsigned lineEnd = middle<(nLines-1)?lineStarts[middle+1]:[string length];
		
		if (index >= lineEnd) {
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
		NSRange localRange;								// Optimisation suggested by Shark
		const IFSyntaxStyle* localStyles = charStyles;	// Ditto

		localRange.location = index;
		localRange.length = 0;
		
		while (localRange.location > 0) {
			if (localStyles[localRange.location-1] == style) {
				localRange.location--;
			} else {
				break;
			}
		}
		
		unsigned strLen = [string length];
		
		while (localRange.location+localRange.length < strLen) {
			if (localStyles[localRange.location+localRange.length] == style) {
				localRange.length++;
			} else {
				break;
			}
		}
		
		*range = localRange;
	}
	
	return style;
}

// = Required NSTextStorage methods =

- (NSString*) string {
	return [string string];
}

// Temp storage
static NSString* IFCombinedAttributes = @"IFCombinedAttributes";
static NSString* IFStyleAttributes = @"IFStyleAttributes";
static NSString* IFLineAttributes = @"IFLineAttributes";

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
	
	if (range) *range = finalRange;
	
	// Use the cached attributes if available
	if ([[stringAttributes objectForKey: IFStyleAttributes] pointerValue] == styleAttributes) {
		return [stringAttributes objectForKey: IFCombinedAttributes];
	}

	// Get the attributes for this line
	int line = [self lineForIndex: finalRange.location];
	NSDictionary* lineAttributes = nil;
	
#if HighlighterDebug
	NSLog(@"Attributes: recalculating attributes at line %i. Old attributes were %p, new attributes are %p. Attribute range (%i, %i)",
		  line, [[stringAttributes objectForKey: IFStyleAttributes] pointerValue], styleAttributes, finalRange.location, finalRange.length);
#endif

	if (line < [lineStyles count]) {
		lineAttributes = [lineStyles objectAtIndex: line];
	}
	
	// Create the result (we're using CF calls for speed reasons)
	CFMutableDictionaryRef attributes = CFDictionaryCreateMutableCopy(kCFAllocatorDefault,
																	  0,
																	  (CFDictionaryRef)stringAttributes);
		
	if (lineAttributes) 
		[(NSMutableDictionary*)attributes addEntriesFromDictionary: lineAttributes];
	if (styleAttributes)
		[(NSMutableDictionary*)attributes addEntriesFromDictionary: styleAttributes];
	
	if (CFDictionaryContainsKey(attributes, IFStyleAttributes))
		CFDictionaryRemoveValue(attributes, IFStyleAttributes);
	if (CFDictionaryContainsKey(attributes, IFCombinedAttributes))
		CFDictionaryRemoveValue(attributes, IFCombinedAttributes);
	
	// Cache it
	[string addAttribute: IFCombinedAttributes
				   value: (NSDictionary*)attributes
				   range: finalRange];
	[string addAttribute: IFStyleAttributes
				   value: [NSValue valueWithPointer: styleAttributes]
				   range: finalRange];
	
	// Return it
	return [(NSDictionary*)attributes autorelease];
}

- (void) replaceCharactersInRange: (NSRange) range
					   withString: (NSString*) newString {
	int strLen = [string length];
	int newLen = [newString length];
	
	// Give the intelligence source an opportunity to rewrite the input if this is a single entry
	if (intelSource && range.length == 0 && [newString length] == 1) {
		editingRange = range;
		
		NSString* rewritten = [intelSource rewriteInput: newString];
		if (rewritten) {
			newString = rewritten;
			newLen = [newString length];
		}
	}
	
	// The range of lines to be replaced
	int firstLine = [self lineForIndex: range.location];
	int lastLine = range.length>0?[self lineForIndex: range.location + range.length]:firstLine;
	
#if HighlighterDebug
	NSLog(@"Highlighter: editing lines in the range %i-%i", firstLine, lastLine);
#endif
	
	// Build the array of new lines
	unsigned* newLineStarts = NULL;
	int		  nNewLines = 0;
	NSMutableArray* newLineStates = [[NSMutableArray alloc] init];
	
	unsigned x;
	for (x=0; x<newLen; x++) {
		unichar thisChar = [newString characterAtIndex: x];
		
		if (thisChar == '\n' || thisChar == '\r') {
			nNewLines++;
			newLineStarts = realloc(newLineStarts, sizeof(*newLineStarts)*nNewLines);
			newLineStarts[nNewLines-1] = x + range.location+1;

			[newLineStates addObject: 
				[NSMutableArray arrayWithObject: 
					[NSArray arrayWithObjects:
						[NSNumber numberWithUnsignedInt: IFSyntaxStateNotHighlighted],
						[NSNumber numberWithUnsignedInt: 0],
						nil]]];
		}
	}
	
	int lineDifference = ((int)nNewLines) - (int)(lastLine-firstLine);
	
#if HighlighterDebug
	NSLog(@"Highlighter: %i %@ lines (%i total)", lineDifference, nNewLines<(lastLine-firstLine)?@"new":@"removed",nLines);
#endif
	
	// Replace the line positions (first line is still at the same position, with the same initial state, of course)
	if (nNewLines < (lastLine-firstLine)) {
		// Update first
		for (x=0; x<nNewLines; x++) {
			lineStarts[firstLine+1+x] = newLineStarts[x];

			[lineStyles removeObjectAtIndex: firstLine+1+x];
		}
		
		if (intelData) {
			// Remove the lines from the intelligence data
			[intelData removeLines: NSMakeRange(firstLine+1, nNewLines)];
		}
		
		// Move lines down
		memmove(lineStarts + firstLine + nNewLines + 1,
				lineStarts + lastLine + 1,
				sizeof(*lineStarts)*(nLines - (lastLine + 1)));
		lineStarts = realloc(lineStarts, sizeof(*lineStarts)*(nLines + lineDifference));
	} else {
		// Move lines up
		lineStarts = realloc(lineStarts, sizeof(*lineStarts)*(nLines + lineDifference));
		memmove(lineStarts + firstLine + nNewLines + 1,
				lineStarts + lastLine + 1,
				sizeof(*lineStarts)*(nLines - (lastLine + 1)));

		// Update last
		for (x=0; x<nNewLines; x++) {
			[lineStyles insertObject: [self paragraphStyleForTabStops: 0]
							 atIndex: firstLine+1];
			
			lineStarts[firstLine+1+x] = newLineStarts[x];
			
			if (intelData) [intelData insertLineBeforeLine: firstLine+1]; // Might be slow with cut+paste sometimes?
		}
	}
		
	[lineStates replaceObjectsInRange: NSMakeRange(firstLine+1, lastLine-firstLine)
				 withObjectsFromArray: newLineStates];
	
	// Update the remaining line positions
	nLines += lineDifference;
	
	int charDifference = newLen - range.length;	
	for (x=firstLine + nNewLines+1; x<nLines; x++) {
		lineStarts[x] += charDifference;
	}
	
	// Clean up data we don't need any more
	[newLineStates release];
	free(newLineStarts);
	newLineStarts = NULL;
	
	// Update the character positions
	if (newLen < range.length) {
		// Move characters down
		memmove(charStyles + range.location + newLen,
				charStyles + range.location + range.length,
				sizeof(*charStyles)*(strLen - (range.location + range.length)));
		
		charStyles = realloc(charStyles, strLen + (newLen - range.length));
	} else {
		// Move charactes up
		charStyles = realloc(charStyles, strLen + (newLen - range.length));

		memmove(charStyles + range.location + newLen,
				charStyles + range.location + range.length,
				sizeof(*charStyles)*(strLen - (range.location + range.length)));
	}
	
	// Update the actual characters
	[string replaceCharactersInRange: range
						  withString: newString];
	
	// Note the edit
	[self beginEditing];
	
	// Highlight 'around' the range
	NSRange highlightRange = range;
	highlightRange.length = newLen;
	
	// Characters no longer have valid states
	for (x=0; x<highlightRange.length; x++) {
		charStyles[x+highlightRange.location] = IFSyntaxStyleNotHighlighted;
	}
	
	[self stopBackgroundHighlighting];
	[self highlightRangeSoon: highlightRange];

	[self edited: NSTextStorageEditedCharacters
		   range: range
  changeInLength: newLen - range.length];
	
	[self endEditing];
}	

- (void) setAttributes: (NSDictionary*) attributes
				 range: (NSRange) range {
	// Remove our private attributes if they've got copied through
	if ([attributes objectForKey: IFStyleAttributes] || [attributes objectForKey: IFCombinedAttributes]) {
		NSMutableDictionary* newAttr = [attributes mutableCopy];
		
		if ([newAttr objectForKey: IFStyleAttributes]) [newAttr removeObjectForKey: IFStyleAttributes];
		if ([newAttr objectForKey: IFCombinedAttributes]) [newAttr removeObjectForKey: IFCombinedAttributes];
		if ([newAttr objectForKey: IFLineAttributes]) [newAttr removeObjectForKey: IFLineAttributes];
		
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
	
	[paragraphStyles release]; paragraphStyles = nil;
	[tabStops release]; tabStops = nil;
	
	[self highlightRange: NSMakeRange(0, [self length])];
}

- (id<IFSyntaxHighlighter>) highlighter {
	return highlighter;
}

// = Communication from the highlighter =

- (void) pushState {
	[syntaxStack addObject: [NSArray arrayWithObjects: 
		[NSNumber numberWithUnsignedInt: syntaxState],
		[NSNumber numberWithUnsignedInt: syntaxMode],
		nil]];
}

- (IFSyntaxState) popState {
	IFSyntaxState poppedState = [[[syntaxStack lastObject] objectAtIndex: 0] unsignedIntValue];
	syntaxMode = [[[syntaxStack lastObject] objectAtIndex: 1] unsignedIntValue];
	[syntaxStack removeLastObject];
	
	return poppedState;
}

- (void) backtrackWithStyle: (IFSyntaxStyle) newStyle
					 length: (int) backtrackLength {
	// Change the styles, going backwards for the specified length
	int x;
	
	for (x=syntaxPos-backtrackLength; x<syntaxPos; x++) {
		if (x >= 0) charStyles[x] = newStyle;
	}
}

- (void) setHighlighterMode: (IFHighlighterMode) newMode {
	// Sets the 'mode' of the highlighter (additional state info, basically)
	syntaxMode = newMode;
}

- (IFHighlighterMode) highlighterMode {
	// Retrieves the mode
	return syntaxMode;
}

static inline BOOL IsWhitespace(unichar c) {
	if (c == ' ' || c == '\t') 
		return YES;
	else
		return NO;
}

- (BOOL) preceededByKeyword: (NSString*) keyword
					 offset: (int) offset {
	// If the given keyword preceeds the current position (case insensitively), this returns true
	if (syntaxPos == 0) return NO;
	
	int pos = syntaxPos-1-offset;
	NSString* str = [string string];
	
	// Skip whitespace
	while (pos > 0 && IsWhitespace([str characterAtIndex: pos]))
		pos--;
	
	// pos should now point at the last letter of the keyword (if it is the keyword)
	pos++;
	
	// See if the keyword is there
	int keywordLen = [keyword length];
	if (pos < keywordLen)
		return NO;
	
	NSString* substring = [str substringWithRange: NSMakeRange(pos-keywordLen, keywordLen)];
	
	return [substring caseInsensitiveCompare: keyword]==NSOrderedSame;
}

// = Actually performing highlighting =

- (void) highlightRange: (NSRange) range {
	// The range of lines to be highlighted
	int firstLine = [self lineForIndex: range.location];
	int lastLine = range.length>0?[self lineForIndex: range.location + range.length - 1]:firstLine;
	
#if HighlighterDebug
	NSLog(@"Highlighter: highlighting range %i-%i (lines %i-%i)", range.location, range.location + range.length, firstLine, lastLine);
#endif
	
	// Setup
	[highlighter setSyntaxStorage: self];
		
	// Perform the highlighting
	int line;
	NSArray* lastOldStack = nil; // The 'old' stack for the last line
	
	for (line=firstLine; line<=lastLine; line++) {
		// The range of characters to be highlighted
		unsigned firstChar = lineStarts[line];
		unsigned  lastChar = (line+1)<nLines?lineStarts[line+1]:[string length];

		// Set up the state
		[syntaxStack setArray: [lineStates objectAtIndex: line]];

		syntaxState = [[[syntaxStack lastObject] objectAtIndex: 0] unsignedIntValue];
		syntaxMode = [[[syntaxStack lastObject] objectAtIndex: 1] unsignedIntValue];
		[syntaxStack removeLastObject];
		
		IFSyntaxState initialState = syntaxState;
		
		// Number of tab stops (used for paragraph highlighting later)
		int numTabStops = 0;
		BOOL countingTabs = YES;
		
		// Highlight this line
		for (syntaxPos=firstChar; syntaxPos<lastChar; syntaxPos++) {
			// Current state
			unichar curChar = [[string string] characterAtIndex: syntaxPos];
			
			// Count tab stops
			if (countingTabs) {
				if (curChar == 9)
					numTabStops++;
				else
					countingTabs = NO;
			}
			
			// Next state
			IFSyntaxState nextState = [highlighter stateForCharacter: curChar
														  afterState: syntaxState];
			
			// Next style
			IFSyntaxStyle nextStyle = [highlighter styleForCharacter: curChar
														   nextState: nextState
														   lastState: syntaxState];
			
			// Store the style
			charStyles[syntaxPos] = nextStyle;
			
			// Store the state
			syntaxState = nextState;
		}
		
		// Provide an opportunity for the highlighter to hint keywords, etc
		NSString* lineToHint = [[string string] substringWithRange: NSMakeRange(firstChar, lastChar-firstChar)];
#if HighlighterDebug
		NSLog(@"Highlighter: finished line %i: '%@', rehinting", line, lineToHint);
#endif
		
		[highlighter rehintLine: lineToHint
						 styles: charStyles+firstChar
				   initialState: initialState];
		
		if (intelSource && intelData) {
			// Gather intelligence for the line, if we have something to gather it with
			[intelSource gatherIntelForLine: lineToHint
									 styles: charStyles+firstChar
							   initialState: initialState
								 lineNumber: line
								   intoData: intelData];
		}
		
		// Use our own ability to set attributes to set the number of tab stops
		if (enableWrapIndent) {
			NSDictionary* lastStyle = nil;
			NSDictionary* newStyle = [self paragraphStyleForTabStops: numTabStops];
			
			if ([lineStyles count] <= line) {
				for (;[lineStyles count] <= line;) {
					[lineStyles addObject: newStyle];
				}
			} else {
				lastStyle = [lineStyles objectAtIndex: line];
				[lineStyles replaceObjectAtIndex: line
									  withObject: newStyle];
			}
			
			if (newStyle != lastStyle) {
				// Force an attribute update
				[string removeAttribute: IFStyleAttributes 
								  range: NSMakeRange(firstChar, lastChar-firstChar)];
				[string addAttributes: newStyle
								range: NSMakeRange(firstChar, lastChar-firstChar)];
			}
		}
		
		// Finish the stack
		[syntaxStack addObject: 
			[NSArray arrayWithObjects:
				[NSNumber numberWithUnsignedInt: syntaxState],
				[NSNumber numberWithUnsignedInt: syntaxMode],
				nil]];
		
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
#if HighlighterDebug
	NSLog(@"Highlighter: Finished at line %i", line);
#endif
	
	if (line < nLines) {
#if HighlighterDebug
		NSLog(@"Highlighter: Previous stack is %@, but stack now is %@", lastOldStack, [lineStates objectAtIndex: line]);
#endif
		
		if (![lastOldStack isEqualToArray: [lineStates objectAtIndex: line]]) {
			// The state at the start of this line has changed: mark it as invalid
			unsigned firstChar = lineStarts[line];
			unsigned lastChar = (line+1)<nLines?lineStarts[line+1]:[string length];
			
			unsigned x;
			for (x=firstChar; x<lastChar; x++) charStyles[x] = IFSyntaxStyleNotHighlighted;
			
			NSRange newInvalidRange = NSMakeRange(firstChar, lastChar-firstChar);
			
			if (needsHighlighting.location == NSNotFound)
				needsHighlighting = newInvalidRange;
			else
				needsHighlighting = NSUnionRange(needsHighlighting, newInvalidRange);
		}
	}

	// Clean up
	[lastOldStack release];
	[highlighter setSyntaxStorage: nil];
	
	// Mark as edited
	unsigned firstChar = lineStarts[firstLine];
	unsigned lastChar = (lastLine+1)<nLines?lineStarts[lastLine+1]:[string length];
	
	[self edited: NSTextStorageEditedAttributes
		   range: NSMakeRange(firstChar, lastChar-firstChar)
  changeInLength: 0];
	
	// Add to the number of highlighted characters
	amountHighlighted += (lastChar-firstChar);
}

- (void) highlightRangeLater: (NSRange) range {
	// Hack: improves apparent update performance for deeply mysterious reasons
	//
	// The text layout system doesn't like us calling back to finish the highlighting job finished
	// after the user started it by editing the text, which creates a weird effect: when add a line
	// by hitting enter, there's a delay before the update takes place. Taking this out removes the
	// delay, but stuffs the highlighting up a bit.
	//
	// This callback ensures that the extra highlighting happens after the runloop runs through twice
	// rather than once. This doesn't appear to eliminate the delay, but certainly appears to improve
	// it.
	//
	// Unfortunately, this creates a visible delay in highlighting :-/

	[[NSRunLoop currentRunLoop] performSelector: @selector(highlightRangeSooner:)
										 target: self
									   argument: [NSValue valueWithRange: range]
										  order: 9
										  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
}

- (void) highlightRangeSooner: (NSValue*) value {
	[self highlightRangeSoon: [value rangeValue]];
}

- (void) highlightRangeSoon: (NSRange) range {
	[[NSRunLoop currentRunLoop] performSelector: @selector(highlightRangeNow:)
										 target: self
									   argument: [NSValue valueWithRange: range]
										  order: 8
										  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
}

- (void) highlightRangeNow: (NSValue*) range {
	if (highlighter == nil) return;	// Nothing to do
	
	amountHighlighted = 0;
	
	// Highlight the range
	[self beginEditing];
	
	[self highlightRange: [range rangeValue]];
	
	// Highlight anything else that might need it
	while (amountHighlighted < maxPassLength && [self highlighterPass]);
	[self endEditing];
	
	// Continue highlighting in the background if required
	[self startBackgroundHighlighting];
}

- (BOOL) highlighterPass {
	// Highlight anything that needs highlighting
	if (needsHighlighting.location == NSNotFound) return NO;
	
	unsigned strLen = [string length];
	
	if (needsHighlighting.location >= strLen) {
		// Outside the string
		needsHighlighting.location = NSNotFound;
		return NO;
	}
	
	needsHighlighting = NSIntersectionRange(needsHighlighting, NSMakeRange(0, strLen));
	
	unsigned highlightStart = needsHighlighting.location;
	unsigned highlightEnd = needsHighlighting.location + needsHighlighting.length;
	
	int x;
	
	// Find the first character that needs highlighting
	for (x=0; x<needsHighlighting.length; x++) {
		if (charStyles[needsHighlighting.location + x] == IFSyntaxStyleNotHighlighted) {
			highlightStart = needsHighlighting.location+x;
			break;
		}
	}
	
	if (x == needsHighlighting.length) {
		// Everything is highlighted
		needsHighlighting.location = NSNotFound;
		return NO;
	}
	
	// Find the last character that needs highlighting
	int maxAmountToHighlight = maxPassLength - (amountHighlighted>0?amountHighlighted:(maxPassLength-1));
	
	if (highlightEnd-highlightStart > maxAmountToHighlight)
		highlightEnd = highlightStart + maxAmountToHighlight;
	
	for (x=highlightStart; x<highlightEnd; x++) {
		if (charStyles[x] != IFSyntaxStyleNotHighlighted)
			break;
	}
	highlightEnd = x;
	
	// Perform this pass
	[self highlightRange: NSMakeRange(highlightStart, highlightEnd - highlightStart)];
	
	// Update the 'needsHighlighting' range to start at 'highlightEnd'
	needsHighlighting.length -= highlightEnd-needsHighlighting.location;
	needsHighlighting.location = highlightEnd;
	
	if (needsHighlighting.length <= 0)
		needsHighlighting.location = NSNotFound;
	
	return YES;
}

- (void) highlightInTime: (NSTimeInterval) waitFor {
	[self stopBackgroundHighlighting];
	
	if (needsHighlighting.location != NSNotFound) {
		// Queue a highlight event
		[self performSelector: @selector(backgroundHighlight)
				   withObject: nil
				   afterDelay: waitFor];
	}
}

- (void) backgroundHighlight {
	[self beginEditing];
	amountHighlighted = 0;
	while (amountHighlighted < maxPassLength && [self highlighterPass]);
	[self endEditing];

	[self highlightInTime: 0.02];
}

- (void) startBackgroundHighlighting {
	[self highlightInTime: 0.25];
}

- (void) stopBackgroundHighlighting {
	[[self class] cancelPreviousPerformRequestsWithTarget: self
												 selector: @selector(backgroundHighlight)
												   object: nil];
}

// = Notifications from the preferences object =

- (void) preferencesChanged: (NSNotification*) not {
	// Force a re-highlight of everything
	[self highlightRange: NSMakeRange(0, [string length])];
}

// = Tabbing =

- (NSDictionary*) generateParagraphStyleForTabStops: (int) numberOfTabStops {
	float stopWidth = [highlighter tabStopWidth];
	
	if (stopWidth < 1.0) stopWidth = 16.0;
		
	NSMutableParagraphStyle* res = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	
	// Standard tab stops
	if (tabStops == nil) {
		int x;
		
		tabStops = [[NSMutableArray alloc] init];
		for (x=0; x<48; x++) {
			NSTextTab* tab = [[NSTextTab alloc] initWithType: NSLeftTabStopType
													location: stopWidth*(x+1)];
			[tabStops addObject: tab];
			[tab release];
		}
	}
	
	[res setTabStops: tabStops];
	
	// headIndent value
	[res setHeadIndent: stopWidth * ((float)numberOfTabStops) + (stopWidth/2.0)];
	[res setFirstLineHeadIndent: 0];
	
	return [NSDictionary dictionaryWithObject: [[res copy] autorelease]
									   forKey: NSParagraphStyleAttributeName];
}

- (NSDictionary*) paragraphStyleForTabStops: (int) numberOfTabStops {
	if (!paragraphStyles) {
		paragraphStyles = [[NSMutableArray alloc] init];
	}
	
	if (numberOfTabStops < 0) numberOfTabStops = 0;		// Technically an error
	if (numberOfTabStops > 48) numberOfTabStops = 48;	// Avoid eating all the pies^Wmemory
	
	// Use the cached version if available
	if (numberOfTabStops < [paragraphStyles count]) {
		return [paragraphStyles objectAtIndex: numberOfTabStops];
	}
	
	// Generate missing tab stops if not
	int x;
	for (x=[paragraphStyles count]; x<=numberOfTabStops; x++) {
		[paragraphStyles addObject: [self generateParagraphStyleForTabStops: x]];
	}
	
	return [paragraphStyles objectAtIndex: numberOfTabStops];
}

// = Gathering/retrieving intelligence data =

- (void) setIntelligence: (id<IFSyntaxIntelligence>) intel {
	if (intelData) [intelData release];
	if (intelSource) {
		[intelSource setSyntaxStorage: nil];
		[intelSource release];
	}
	
	intelData = [[IFIntelFile alloc] init];
	intelSource = [(NSObject*)intel retain];
	
	[intelSource setSyntaxStorage: self];
	
	// If this ever might be called AFTER setHighlighter, then we need to rehighlight here. For the moment, this
	// doesn't happen, so we don't do this for efficiency reasons
}

- (id<IFSyntaxIntelligence>) intelligence {
	return intelSource;
}

- (IFIntelFile*) intelligenceData {
	return intelData;
}

// = Intelligence callbacks =

- (int) editingLineNumber {
	return [self lineForIndex: editingRange.location];
}

- (int) numberOfTabStopsForLine: (int) lineNumber {
	// Details about the string
	int strLen = [string length];
	NSString* str = [string string];

	// Our current location, and the number of acquired tab stops
	int lineStart = lineStarts[lineNumber];
	int nTabStops = 0;
		
	while (lineStart < strLen && [str characterAtIndex: lineStart] == '\t') {
		lineStart++;
		nTabStops++;
	}
	
	return nTabStops;
}

- (NSString*) textForLine: (int) lineNumber {
	// Get the start/end of the line
	int lineStart = lineStarts[lineNumber];
	int lineEnd = lineNumber+1<nLines?lineStarts[lineNumber+1]:[string length];
	
	return [[string string] substringWithRange: NSMakeRange(lineStart, lineEnd-lineStart)];
}

- (IFSyntaxStyle) styleAtStartOfLine: (int) lineNumber {
	return charStyles[lineStarts[lineNumber]];
}

- (IFSyntaxStyle) styleAtEndOfLine: (int) lineNumber {
	int pos = lineNumber+1<nLines?lineStarts[lineNumber+1]:[string length];
	
	if (pos == 0) return IFSyntaxStyleNotHighlighted;
	
	return charStyles[pos-1];
}

- (unichar) characterAtEndOfLine: (int) lineNumber {
	int pos = lineNumber+1<nLines?lineStarts[lineNumber+1]:[string length]+1;
	
	if (pos <= 1) return 0;
	
	// pos-1 will always be a newline, so pos-2 is the actual last character. '\n' indicates the last line was
	// blank in this case
	return [[string string] characterAtIndex: pos-2];
}

@end
