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

static NSImage* topTear = nil;
static NSImage* bottomTear = nil;

@implementation IFSourceFileView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[syntaxDictionary release];
		
		if (!topTear)		topTear = [[NSImage imageNamed: @"torn_top"] retain];
		if (!bottomTear)	bottomTear = [[NSImage imageNamed: @"torn_bottom"] retain];
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
		[window setDelegate: self];
		
		// Run the syntax matcher to find out what help we need to display
		BOOL contextOk = NO;
		
		[syntaxDictionary setCaseSensitive: YES];
		NSArray* context  = [syntaxDictionary getContextAtPoint: characterIndex inString: [[self textStorage] string]];
		
		if (!context || ![window setElements: context]) {
			[syntaxDictionary setCaseSensitive: NO];			
			context = [syntaxDictionary getContextAtPoint: characterIndex inString: [[self textStorage] string]];
			
			if (context) contextOk = [window setElements: context];
		} else {
			contextOk = YES;
		}
		
		if (context && contextOk) {
			[window popupAtLocation: [event locationInWindow]
						   onWindow: [self window]];
		}
	} else {
		// Process this event as normal
		[super mouseDown: event];		
	}
}

- (BOOL) openStringUrl: (NSString*) url {
	if ([[self delegate] respondsToSelector:@selector(openStringUrl:)]) {
		return [[self delegate] openStringUrl: url];
	}
	return NO;
}

// = Drawing =

- (void) drawRect: (NSRect) rect {
	// Perform normal drawing
	[[NSGraphicsContext currentContext] saveGraphicsState];
	[super drawRect: rect];
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	// Draw the 'page tears' if necessary
	NSRect bounds = [self bounds];
	NSColor* tearColour = [NSColor colorWithDeviceRed: 0.9
												green: 0.9
												 blue: 0.9
												alpha: 1.0];

	if (tornAtTop) {
		NSSize tornSize = [topTear size];
		
		// Draw the grey background
		[tearColour set];
		NSRectFill(NSMakeRect(NSMinX(bounds), NSMinY(bounds), bounds.size.width, tornSize.height));
	
		// Draw the tear
		[topTear setFlipped: YES];
		[topTear drawInRect: NSMakeRect(NSMinX(bounds), NSMinY(bounds), bounds.size.width, tornSize.height)
				   fromRect: NSMakeRect(0,0, bounds.size.width, tornSize.height)
				  operation: NSCompositeSourceOver
				   fraction: 1.0];
	}
	if (tornAtBottom) {
		NSSize tornSize = [bottomTear size];
		NSPoint origin = [self textContainerOrigin];
		NSRect usedRect = [[self layoutManager] usedRectForTextContainer: [self textContainer]];
		NSSize containerSize = NSMakeSize(NSMaxX(usedRect), NSMaxY(usedRect));;
		
		// Draw the grey background
		[tearColour set];
		NSRectFill(NSMakeRect(NSMinX(bounds), origin.y + containerSize.height, bounds.size.width, bounds.size.height - (origin.y + containerSize.height)));
		
		// Draw the tear
		[bottomTear setFlipped: YES];
		[bottomTear drawInRect: NSMakeRect(NSMinX(bounds), origin.y + containerSize.height, bounds.size.width, tornSize.height)
					  fromRect: NSMakeRect(0,0, bounds.size.width, tornSize.height)
					 operation: NSCompositeSourceOver
					  fraction: 1.0];
	}
}

// = Drawing 'tears' at the top and bottom =

- (void) updateTearing {
	// Load the images if they aren't already available
	if (!topTear)		topTear = [[NSImage imageNamed: @"torn_top"] retain];
	if (!bottomTear)	bottomTear = [[NSImage imageNamed: @"torn_bottom"] retain];

	// Work out the inset to use
	NSSize inset = NSMakeSize(3,3);
	
	if (tornAtTop) {
		inset.height += floorf([topTear size].height);
	}
	if (tornAtBottom) {
		inset.height += floorf([bottomTear size].height);
	}
	
	// Update the display
	[self setTextContainerInset: inset];
	[self invalidateTextContainerOrigin];
	[self setNeedsDisplay: YES];
}

- (NSPoint) textContainerOrigin {
	// Calculate the origin
	NSPoint origin = NSMakePoint(3,3);
	
	if (tornAtTop) {
		origin.y += [topTear size].height;
	}
	
	return origin;
}

- (void) setTornAtTop: (BOOL) newTornAtTop {
	if (tornAtTop != newTornAtTop) {
		tornAtTop = newTornAtTop;
		[self updateTearing];
	}
}

- (void) setTornAtBottom: (BOOL) newTornAtBottom {
	if (tornAtBottom != newTornAtBottom) {
		tornAtBottom = newTornAtBottom;
		[self updateTearing];
	}
}

@end
