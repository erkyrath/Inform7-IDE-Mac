//
//  IFNaturalIntel.m
//  Inform
//
//  Created by Andrew Hunter on 05/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFNaturalIntel.h"

static NSArray* headingList = nil;

// English number arrays
static NSArray* units;
static NSArray* tens;
static NSArray* majorUnits;

@implementation IFNaturalIntel

// = Useful parsing functions = 

+ (int) parseNumber: (NSString*) number {
	// IMPLEMENT ME: parse english numbers (one, two, three, etc)
	
	return [number intValue];
}

+ (int) numberOfHeading: (NSString*) heading {
	NSArray* words = [heading componentsSeparatedByString: @" "];
	
	return [IFNaturalIntel parseNumber: [words objectAtIndex: 1]];
}

// = Startup =

+ (void) initialize {
	if (!headingList) {
		headingList = [[NSArray arrayWithObjects: @"volume", @"book", @"part", @"chapter", @"section", nil] retain];
		
		units = [[NSArray arrayWithObjects: @"zero", @"one", @"two", @"three", @"four", @"five", @"six", @"seven", 
			@"eight", @"nine", @"ten", @"eleven", @"twelve", @"thirteen", @"fourteen", @"fifteen", @"sixteen", 
			@"seventeen", @"eighteen", @"nineteen", nil] retain];
		tens = [[NSArray arrayWithObjects: @"twenty", @"thirty", @"forty", @"fifty", @"sixty", @"seventy", @"eighty",
			@"ninety", @"hundred", nil] retain];
		majorUnits = [[NSArray arrayWithObjects: @"hundred", @"thousand", @"million", @"billion", @"trillion", nil] retain];
	}
}

// = Notifying of the highlighter currently in use =

- (void) setSyntaxStorage: (IFSyntaxStorage*) storage {
	highlighter = storage;
}

// = Gathering information (works like rehint) =

- (void) gatherIntelForLine: (NSString*) line
					 styles: (IFSyntaxStyle*) styles
			   initialState: (IFSyntaxState) state
				 lineNumber: (int) lineNumber
				   intoData: (IFIntelFile*) data {
	// Clear out old data for this line
	[data clearSymbolsForLines: NSMakeRange(lineNumber, 1)];
	
	// Heading lines beginning with 'Volume', 'Part', etc  are added to the intelligence
	if ([line length] < 4) return;				// Nothing to do in this case
	
	if (styles[0] != IFSyntaxHeading) return;	// Not a heading
	
	// Check if this is a heading or not
	// MAYBE FIXME: won't deal well with headings starting with whitespace. Bug or not?
	NSArray* words = [line componentsSeparatedByString: @" "];
	if ([words count] < 1) return;
	
	int headingType = [headingList indexOfObject: [[words objectAtIndex: 0] lowercaseString]];
	if (headingType == NSNotFound) return;		// Not a heading (hmm, shouldn't happen, I guess)
	
	// Got a heading: add to the intel
	IFIntelSymbol* newSymbol = [[IFIntelSymbol alloc] init];

	[newSymbol setType: IFSectionSymbolType];
	[newSymbol setName: line];
	[newSymbol setRelation: IFSymbolOnLevel];
	[newSymbol setLevelDelta: headingType];
	
	[data addSymbol: newSymbol
			 atLine: lineNumber];

	[newSymbol release];
}

// = Rewriting =

- (NSString*) rewriteInput: (NSString*) input {
	if ([input isEqualToString: @"\n"]) {
		// Auto-tab
		// IMPLEMENT ME: preferences
		
		// 'editingLineNumber' will still be the previous line
		int lineNumber = [highlighter editingLineNumber];
		int tabs = [highlighter numberOfTabStopsForLine: lineNumber];
		
		// If we're not currently in a string...
		IFSyntaxStyle lastStyle = [highlighter styleAtEndOfLine: lineNumber];
		if (lastStyle != IFSyntaxGameText && lastStyle != IFSyntaxSubstitution) {
			unichar lastChar = [highlighter characterAtEndOfLine: lineNumber];

			if (lastChar == ':') {
				// Increase tab depth if last character of last line was ':'
				tabs++;
			} else if (lastChar == '\t' || lastChar == ' ') {
				// If line was entirely whitespace then reduce tabs back to 0
				NSString* line = [highlighter textForLine: lineNumber];
				int len = [line length];
				int x;
				BOOL whitespace = YES;
				
				for (x=0; x<len-1; x++) {
					// Loop to len-1 as last character will always be '\n'
					// Exception is the very last line in the file. But we're OK there, as we know the last
					// character is whitespace anyway
					unichar chr = [line characterAtIndex: x];
					
					if (chr != '\t' && chr != ' ') {
						whitespace = NO;
						break;
					}
				}
				
				if (whitespace) {
					// Line was entirely whitespace: no tabs now
					tabs = 0;
				}
			}
		}
		
		if (tabs > 0) {
			// Auto-indent the next line
			NSMutableString* res = [NSMutableString stringWithString: @"\n"];
			
			int x;
			for (x=0; x<tabs; x++) {
				[res appendString: @"\t"];
			}
			
			return res;
		} else {
			// Leave as-is
			return nil;
		}
	} else if ([input isEqualToString: @" "]) {
		int lineNumber = [highlighter editingLineNumber];
		IFSyntaxStyle lastStyle = [highlighter styleAtStartOfLine: lineNumber];
		
		if (lastStyle != IFSyntaxGameText && lastStyle != IFSyntaxSubstitution) {
			// If we've got a line 'Volume\n', or (pedantic last line case) 'Volume', then automagically fill
			// in the section number using context info
			NSString* line = [highlighter textForLine: lineNumber];
			NSString* prefix = nil;
			
			// Line must actually have something on it
			if ([line length] < 4) return nil;				// Too short to be of interest
			if ([line length] > 8) return nil;				// Too long to be of interest
			
			// See if we're at the last line or somewhere else
			if ([line characterAtIndex: [line length]-1] == '\n') {
				prefix = [line substringToIndex: [line length]-1];
			} else {
				prefix = line;
			}
						
			// See if this is the start of a heading
			int headingLevel = [headingList indexOfObject: [prefix lowercaseString]];
			
			if (headingLevel == NSNotFound) return nil;		// Not a heading
			
			// We've got a heading: auto-insert a number
			
			// Find the preceding heading
			IFIntelFile* data = [highlighter intelligenceData];
			IFIntelSymbol* symbol = [data nearestSymbolToLine: lineNumber];
			
			while (symbol && [symbol level] > headingLevel) symbol = [symbol parent];
			
			// Work out the numeric value of the heading
			int lastHeadingNumber = 0;
			
			if (symbol) {
				if ([symbol level] != headingLevel) {
					lastHeadingNumber = 0;			// No preceding items at this level
				} else {
					lastHeadingNumber = [IFNaturalIntel numberOfHeading: [symbol name]];
					if (lastHeadingNumber == 0) {
						lastHeadingNumber = -1;		// There was a preceding heading, but we don't know the number
					}
				}
			}
			
			// Work out the result
			NSMutableString* res = nil;
			
			if (lastHeadingNumber >= 0) {
				// Insert a suitable new heading number
				res = [NSMutableString stringWithFormat: @" %i - ", lastHeadingNumber+1];
				
				// IMPLEMENT ME: renumber the following sections
			}
			
			return res;
		}
	}
	
	// No behaviour defined: just fall through
	return nil;
}

@end
