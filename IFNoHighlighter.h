//
//  IFNoHighlighter.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 18/10/2009.
//  Copyright 2009 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFSyntaxStorage.h"

@interface IFNoHighlighter : NSObject<IFSyntaxHighlighter> {
	IFSyntaxStorage* activeStorage;					// Syntax storage that we're using
}

@end
