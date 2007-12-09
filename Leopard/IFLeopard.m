//
//  IFLeopard.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 09/12/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFLeopard.h"


@implementation IFLeopard

// = Text view magic =

 - (void) showFindIndicatorForRange: (NSRange) charRange
						inTextView: (NSTextView*) textView {
	[textView showFindIndicatorForRange: charRange];
}

@end
