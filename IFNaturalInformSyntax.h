//
//  IFNaturalInformSyntax.h
//  Inform
//
//  Created by Andrew Hunter on Sun Dec 14 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IFSyntaxHighlighter.h"

/*
 * Natural Inform syntax highlighting is currently very simple
 * (thank goodness!)
 *
 * Text in square brackets [ ] is comments.
 * Text in quotes "" is text
 * All the rest is ordinary text
 *
 * As for the Inform 6 highlighter, we maintain state at the start of lines
 */

typedef struct IFNaturalInformLine  IFNaturalInformLine;
typedef enum   IFNaturalInformState IFNaturalInformState;

enum IFNaturalInformState {
	IFStateText,
	IFStateComment,
	IFStateQuote
};

struct IFNaturalInformLine {
	IFNaturalInformState startState;
	int length;
	BOOL invalid;
};

@interface IFNaturalInformSyntax : IFSyntaxHighlighter {
	NSString* file;
	
	int nLines;
	IFNaturalInformLine* lines;
}

@end
