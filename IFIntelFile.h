//
//  IFIntelFile.h
//  Inform
//
//  Created by Andrew Hunter on 05/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFIntelSymbol.h"

//
// 'Intelligence' data for a file.
// Basically, maintains a linked list of symbols gathered from a file.
//
// Contains the details stored about a file, and the means to access them
//
@interface IFIntelFile : NSObject {
	// Data
	NSMutableArray* symbols;
	int* symbolLines;			// We access this a lot: C-style array is faster
}

// Adding and removing symbols
- (void) insertLineBeforeLine: (int) line;
- (void) removeLines: (NSRange) lines;
- (void) clearSymbolsForLines: (NSRange) lines;

- (void) addSymbol: (IFIntelSymbol*) symbol
			atLine: (int) line;

// Finding symbols
- (IFIntelSymbol*) firstSymbolOnLine: (int) line;
- (IFIntelSymbol*) lastSymbolOnLine: (int) line;
- (int) lineForSymbol: (IFIntelSymbol*) symbolToFind;

@end
