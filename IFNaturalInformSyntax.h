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
 */

@interface IFNaturalInformSyntax : IFSyntaxHighlighter {
	NSString* file;
	
}

@end
