//
//  IFIntelFile.m
//  Inform
//
//  Created by Andrew Hunter on 05/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFIntelFile.h"

// FIXME: symbols are supposed to be deliniated by type, so we should really be using one of these objects
// per symbol type;

@implementation IFIntelFile

- (id) init {
	self = [super init];
	
	if (self) {
		symbols = [[NSMutableArray alloc] init];
		symbolLines = NULL;
	}
	
	return self;
}

- (int) indexOfSymbolOnLine: (int) lineNumber {
	// BINARY SEARCH POWER! Is there anything this wacky algorithm cannot do?
	
	// Either the last item of the previous line, or the first item of this line
	int nSymbols = [symbols count];
	
	if (nSymbols == 0) return -1;
	
	int top, middle, bottom;
	
	bottom = 0;
	top = nSymbols - 1;
	while (top >= bottom) {
		middle = (top + bottom)>>1;
		
		if (symbolLines[middle] < lineNumber) {
			bottom = middle + 1;
		} else if (symbolLines[middle] > lineNumber) {
			top = middle - 1;
		} else if (symbolLines[middle] == lineNumber) {
			return middle;
		}
	}
	
	return middle;
}

- (int) indexOfStartOfLine: (int) lineNumber {
	// Returns the symbol location of the symbol before the start of the line
	int symbol = [self indexOfSymbolOnLine: lineNumber];
	
	while (symbol >= 0 && symbolLines[symbol] >= lineNumber) symbol--;
	
	return symbol;
}

- (int) indexOfEndOfLine: (int) lineNumber {
	// Returns the symbol location of the symbol after the start of the line
	int symbol = [self indexOfSymbolOnLine: lineNumber];
	int nSymbols = [symbols count];
	
	while (symbol >= 0 && symbolLines[symbol] >= lineNumber) symbol--;
	if (symbol < 0) symbol = 0;
	while (symbol < nSymbols && symbolLines[symbol] <= lineNumber) symbol++;
	
	return symbol;
}

// = Adding and removing symbols =

- (void) insertLineBeforeLine: (int) line {
	// Renumber lines as appropriate
	int firstSymbol = [self indexOfStartOfLine: line] + 1;
	int nSymbols = [symbols count];
	int symbol;
	
	for (symbol=firstSymbol; symbol<nSymbols; symbol++) {
		symbolLines[symbol]++;
	}
}

- (void) removeLines: (NSRange) lines {
	// Clear out the symbols for these lines
	[self clearSymbolsForLines: lines];
	
	// Change the location of the remaining lines
	int firstSymbol = [self indexOfStartOfLine: lines.location] + 1;
	int nSymbols = [symbols count];
	int symbol;
	
	for (symbol=firstSymbol; symbol<nSymbols; symbol++) {
		symbolLines[symbol] -= lines.length;
	}
}

- (void) clearSymbolsForLines: (NSRange) lines {
	// These are EXCLUSIVE (remember?)
	int firstSymbol = [self indexOfStartOfLine: lines.location];
	int lastSymbol = [self indexOfEndOfLine: lines.location + lines.length];
	
	if (firstSymbol > lastSymbol) {
		// Should never happen (aka the Programmer's Lament)
		NSLog(@"BUG: clearSymbols for line symbol %i > %i", firstSymbol, lastSymbol);
		NSLog(@"[IFIntelFile clearSymbolsForLines] failed");
		return;
	}
	
	// firstSymbol == lastSymbol iff there are no symbols to remove
	if (firstSymbol == lastSymbol)
		return;
	
	// Remove symbols between firstSymbol and lastSymbol
	[symbols removeObjectsInRange: NSMakeRange(firstSymbol+1, lastSymbol-(firstSymbol+1))];
	memmove(symbolLines + (firstSymbol+1), symbolLines + lastSymbol, sizeof(*symbolLines)*(lastSymbol-(firstSymbol+1)));
}

- (void) addSymbol: (IFIntelSymbol*) newSymbol
			atLine: (int) line {
	int symbol = [self indexOfEndOfLine: line];
	int nSymbols = [symbols count];
	
	// Need to insert at symbol...
	symbolLines = realloc(symbolLines, sizeof(*symbolLines)*(nSymbols+1));
	memmove(symbolLines + symbol + 1, symbolLines + symbol, sizeof(*symbolLines)*(nSymbols - symbol));
	
	symbolLines[symbol] = line;
	[symbols insertObject: newSymbol
				  atIndex: symbol];
	
	// Adjust the symbol list
	if (symbol > 0)
		newSymbol->lastSymbol = [symbols objectAtIndex: symbol-1];
	else
		newSymbol->lastSymbol = nil;
	
	if (symbol < nSymbols)
		newSymbol->nextSymbol = [symbols objectAtIndex: symbol+1];
	else
		newSymbol->nextSymbol = nil;
	
	if (newSymbol->lastSymbol)
		newSymbol->lastSymbol->nextSymbol = newSymbol;
	if (newSymbol->nextSymbol)
		newSymbol->nextSymbol->lastSymbol = newSymbol;
}

// = Debug =

- (NSString*) description {
	NSMutableString* res = [NSMutableString string];
	
	[res appendFormat: @"<IFIntelFile %i symbols:", [symbols count]];
	
	int symbol;
	for (symbol=0; symbol<[symbols count]; symbol++) {
		[res appendFormat: @"\n\tLine %i - %@", symbolLines[symbol], [symbols objectAtIndex: symbol]];
	}
	
	[res appendFormat: @">"];
	
	return res;
}

// = Finding symbols =

- (IFIntelSymbol*) firstSymbolOnLine: (int) line {
	int nSymbols = [symbols count];
	int symbol = [self indexOfStartOfLine: line];
	
	if (symbol >= nSymbols) return nil;
	if (symbolLines[symbol+1] != line) return nil;
	
	return [symbols objectAtIndex: symbol+1];
}

- (IFIntelSymbol*) lastSymbolOnLine: (int) line {
	int symbol = [self indexOfEndOfLine: line];
	
	if (symbol == 0) return nil;
	if (symbolLines[symbol-1] != line) return nil;
	
	return [symbols objectAtIndex: symbol-1];
}

- (int) lineForSymbol: (IFIntelSymbol*) symbolToFind {
	// Slow, but we shouldn't be calling this very often (oops, actually forgot that we'd need this)
	// (Many ways to speed up if required. Check back with Shark when everything's implemented)
	int symbol;
	int nSymbols = [symbols count];
	
	for (symbol=0; symbol<nSymbols; symbol++) {
		if ([symbols objectAtIndex: symbol] == symbolToFind)
			return symbolLines[symbol];
	}
	
	return NSNotFound;
}

@end
