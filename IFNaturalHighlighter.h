//
//  IFNaturalHighlighter.h
//  Inform
//
//  Created by Andrew Hunter on 18/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFSyntaxStorage.h"

enum {
	IFNaturalStateText = IFSyntaxStateDefault,
	IFNaturalStateComment,
	IFNaturalStateQuote,
	
	IFNaturalStateHeading,
	IFNaturalStateBlankLine
};

//
// Natural Inform syntax highlighter
//
@interface IFNaturalHighlighter : NSObject<IFSyntaxHighlighter> {
	IFSyntaxStorage* activeStorage;
}

@end
