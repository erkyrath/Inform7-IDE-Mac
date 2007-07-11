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
		[syntaxDictionary release];
    }
    return self;
}

- (void) dealloc {
	
	[super dealloc];
}

- (void) keyDown: (NSEvent*) event {
	IFProjectController* controller = [[self window] windowController];
	if ([controller isKindOfClass: [IFProjectController class]]) {
		[[NSRunLoop currentRunLoop] performSelector: @selector(removeAllTemporaryHighlights)
											 target: controller
										   argument: nil
											  order: 8
											  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
	}

	[super keyDown: event];
}

- (void) mouseDown: (NSEvent*) event {
	if ([event modifierFlags] == NSCommandKeyMask) {
		// Cmd+click shows the syntax element for the area the mouse is over
	} else {
		// Process this event as normal
		[super mouseDown: event];		
	}
}

@end
