//
//  IFNaturalHighlighter.m
//  Inform
//
//  Created by Andrew Hunter on 18/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFNaturalHighlighter.h"


@class IFProjectPane;
@implementation IFNaturalHighlighter

// = Notifying of the highlighter currently in use =

- (void) setSyntaxStorage: (IFSyntaxStorage*) storage {
	[activeStorage release];
	activeStorage = [storage retain];
}

// = The highlighter itself =
- (IFSyntaxState) stateForCharacter: (unichar) chr
						 afterState: (IFSyntaxState) lastState {
	switch (lastState) {
		case IFNaturalStateBlankLine:
			if (chr == ' ' || chr == '\n' || chr == '\t')
				return IFNaturalStateBlankLine;
			// ObRAIF: here is why fall-through cases are a *good* thing
		case IFNaturalStateText:
			if (chr == '[') 
				return IFNaturalStateComment;
			if (chr == '"')
				return IFNaturalStateQuote;
				if (chr == '\n')
					return IFNaturalStateBlankLine;
				return IFNaturalStateText;
			
		case IFNaturalStateComment:
			if (chr == ']')
				return IFNaturalStateText;
			return IFNaturalStateComment;
			
		case IFNaturalStateQuote:
			if (chr == '"')
				return IFNaturalStateText;
			return IFNaturalStateQuote;
			
		case IFNaturalStateHeading:
			if (chr == '\n')
				return IFNaturalStateBlankLine;
			return IFNaturalStateHeading;
			
		default:
			// Unknown state
			return IFNaturalStateText;
	}
}

- (IFSyntaxStyle) styleForCharacter: (unichar) chr
							  state: (IFSyntaxState) state {
	switch (state) {
		case IFNaturalStateText:
		case IFNaturalStateBlankLine:
			if (chr == '[') return IFSyntaxComment;
			if (chr == '"') return IFSyntaxGameText;
				return IFSyntaxNone;
		case IFNaturalStateQuote:
			return IFSyntaxGameText;
		case IFNaturalStateComment:
			return IFSyntaxComment;
		case IFNaturalStateHeading:
			return IFSyntaxHeading;
		default:
			return IFSyntaxNone;
	}
}

- (void) rehintLine: (NSString*) line
			 styles: (IFSyntaxStyle*) styles
	   initialState: (IFSyntaxState) initialState {
	NSString* thisLine = [line lowercaseString];
	
	BOOL isHeader = NO;
	
	if (initialState == IFNaturalStateBlankLine) {
		if ([thisLine hasPrefix: @"volume "]) isHeader = YES;
		if ([thisLine hasPrefix: @"book "]) isHeader = YES;
		if ([thisLine hasPrefix: @"part "]) isHeader = YES;
		if ([thisLine hasPrefix: @"chapter "]) isHeader = YES;
		if ([thisLine hasPrefix: @"section "]) isHeader = YES;
	}
	
	if (isHeader) {
		int x;
		for (x=0; x<[line length]; x++) {
			styles[x] = IFSyntaxHeading;
		}
	}
}

// = Styles =
- (NSDictionary*) attributesForStyle: (IFSyntaxStyle) style {
	return [IFProjectPane attributeForStyle: style];
}

@end
