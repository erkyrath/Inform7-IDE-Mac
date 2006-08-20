//
//  IFNaturalHighlighter.h
//  Inform
//
//  Created by Andrew Hunter on 18/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFSyntaxStorage.h"
#import "IFInform6Highlighter.h"

// Natural Inform states
enum {
	IFNaturalStateTitle = IFSyntaxStateDefault,
	IFNaturalStateText,
	IFNaturalStateComment,
	IFNaturalStateQuote,
	IFNaturalStateTitleQuote,
	IFNaturalStateSubstitution,
	
	IFNaturalStateHeading,
	IFNaturalStateBlankLine,
	
	IFNaturalStateMaybeInform6
};

// Natural Inform modes
enum {
	IFNaturalModeStandard = 0,
	IFNaturalModeInform6,
	IFNaturalModeInform6MightEnd
};

//
// Natural Inform syntax highlighter
//
@interface IFNaturalHighlighter : NSObject<IFSyntaxHighlighter> {
	IFSyntaxStorage* activeStorage;					// Syntax storage that we're using
	
	IFInform6Highlighter* inform6Highlighter;		// Highlighter for portions of the file that are Inform 6 code
}

@end
