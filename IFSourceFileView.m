//
//  IFSourceFileView.m
//  Inform
//
//  Created by Andrew Hunter on Mon Feb 16 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import "IFSourceFileView.h"
#import "IFProjectController.h"


@implementation IFSourceFileView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void) keyDown: (NSEvent*) event {
	IFProjectController* controller = [[self window] windowController];
	[[NSRunLoop currentRunLoop] performSelector: @selector(removeAllTemporaryHighlights)
										 target: controller
									   argument: nil
										  order: 8
										  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];

	[super keyDown: event];
}

@end
