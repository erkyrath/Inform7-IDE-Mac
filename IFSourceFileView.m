//
//  IFSourceFileView.m
//  Inform
//
//  Created by Andrew Hunter on Mon Feb 16 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import "IFSourceFileView.h"
#import "IFProjectController.h"
#import "IFContextMatchWindow.h"

@implementation IFSourceFileView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[syntaxDictionary release];
    }
    return self;
}

- (void) dealloc {
	[syntaxDictionary release];
	
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

- (void) setSyntaxDictionaryMatcher: (IFContextMatcher*) matcher {
	[syntaxDictionary release];
	syntaxDictionary = [matcher retain];
}

- (void) mouseDown: (NSEvent*) event {
	unsigned modifiers = [event modifierFlags];
	
	if ((modifiers&NSCommandKeyMask) != 0 &&
		(modifiers&(NSShiftKeyMask|NSControlKeyMask|NSAlternateKeyMask)) == 0) {
		// Cmd+click shows the syntax element for the area the mouse is over
		if (syntaxDictionary == nil) return;
		
		// Work out which character the mouse was clicked over
		NSPoint containerOrigin = [self textContainerOrigin];
		NSPoint viewLocation = [self convertPoint: [event locationInWindow]
										 fromView: nil];
		NSPoint containerLocation = NSMakePoint(viewLocation.x-containerOrigin.x, viewLocation.y-containerOrigin.y);
		
		unsigned characterIndex = NSNotFound;
		unsigned glyphIndex = [[self layoutManager] glyphIndexForPoint: containerLocation
								 				  inTextContainer: [self textContainer]];
		if (glyphIndex != NSNotFound) {
			characterIndex = [[self layoutManager] characterIndexForGlyphAtIndex: glyphIndex];
		}
		
		if (characterIndex == NSNotFound) return;
		
		// Build the window to display the results in
		IFContextMatchWindow* window = [[[IFContextMatchWindow alloc] init] autorelease];
		
		// Run the syntax matcher to find out what help we need to display
		NSArray* context  = [syntaxDictionary getContextAtPoint: characterIndex inString: [[self textStorage] string]];
		
		if (context && [window setElements: context]) {
			[window popupAtLocation: [event locationInWindow]
						   onWindow: [self window]];
		}
	} else {
		// Process this event as normal
		[super mouseDown: event];		
	}
}

@end
