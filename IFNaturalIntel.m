//
//  IFNaturalIntel.m
//  Inform
//
//  Created by Andrew Hunter on 05/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFNaturalIntel.h"

static NSArray* headingList = nil;

@implementation IFNaturalIntel

+ (void) initialize {
	if (!headingList) {
		headingList = [[NSArray arrayWithObjects: @"volume", @"book", @"part", @"chapter", @"section", nil] retain];
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

@end
