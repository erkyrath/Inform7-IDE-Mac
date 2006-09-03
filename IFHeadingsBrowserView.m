//
//  IFHeadingsBrowserView.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 01/09/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import "IFHeadingsBrowserView.h"


@implementation IFHeadingsBrowserView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void) keyDown: (NSEvent*) ev {
	if (delegate && [delegate respondsToSelector: @selector(keyDown:)]) {
		[delegate keyDown: ev];
	} else {
		[super keyDown: ev];
	}
}

@end
