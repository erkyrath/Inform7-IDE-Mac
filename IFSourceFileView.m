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
#import "IFRestrictedTextStorage.h"

static NSImage* topTear			= nil;
static NSImage* bottomTear		= nil;
static NSImage* arrowNotPressed = nil;
static NSImage* arrowPressed	= nil;

@implementation IFSourceFileView

- (void) loadImages {
	if (!topTear)			topTear			= [[NSImage imageNamed: @"torn_top"] retain];
	if (!bottomTear)		bottomTear		= [[NSImage imageNamed: @"torn_bottom"] retain];
	
	if (!arrowNotPressed)	arrowNotPressed = [[NSImage imageNamed: @"TearArrow"] retain];
	if (!arrowPressed)		arrowPressed	= [[NSImage imageNamed: @"TearArrowPressed"] retain];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[syntaxDictionary release];
		
		[self loadImages];
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

- (void) removeRestriction {
	// Expand to show the whole view if possible
	IFRestrictedTextStorage* storage = (IFRestrictedTextStorage*)[self textStorage];
	if ([storage isKindOfClass: [IFRestrictedTextStorage class]]) {
		// Get the old restriction, and first visible character
		NSLayoutManager* layout	= [self layoutManager];
		NSRange oldRestriction	= [storage restrictionRange];
		NSRange selected		= [self selectedRange];
		NSRect visibleRect		= [self visibleRect];
		
		NSPoint containerOrigin = [self textContainerOrigin];
		NSPoint containerLocation = NSMakePoint(NSMinX(visibleRect)-containerOrigin.x, NSMinY(visibleRect)-containerOrigin.y);
		
		unsigned characterIndex = NSNotFound;
		unsigned glyphIndex = [layout glyphIndexForPoint: containerLocation
										 inTextContainer: [self textContainer]];
		if (glyphIndex != NSNotFound) {
			characterIndex = [layout characterIndexForGlyphAtIndex: glyphIndex];
		}
		
		// Remove the storage restriction
		BOOL wasTornAtTop = tornAtTop;
		[storage removeRestriction];
		[self setTornAtTop: NO];
		[self setTornAtBottom: NO];
		
		// Reset the selection
		selected.location += oldRestriction.location;
		[self setSelectedRange: selected];
		
		// Scroll to the last visible character
		if (characterIndex != NSNotFound) {
			characterIndex += oldRestriction.location;
			
			// Scroll to the most recently visible character
			NSRange glyphs = [layout glyphRangeForCharacterRange: NSMakeRange(characterIndex, 65536)
											actualCharacterRange: nil];
			NSPoint charPoint = [layout boundingRectForGlyphRange: glyphs
												  inTextContainer: [self textContainer]].origin;
			charPoint.x = 0;
			charPoint.y += containerOrigin.y;
			
			[self scrollPoint: charPoint];
		} else {
			// Scroll to the top of the restricted range
			NSRange glyphs = [layout glyphRangeForCharacterRange: NSMakeRange(oldRestriction.location, 65536)
											actualCharacterRange: nil];
			NSPoint charPoint = [layout boundingRectForGlyphRange: glyphs
												  inTextContainer: [self textContainer]].origin;
			charPoint.x = 0;
			charPoint.y += containerOrigin.y - wasTornAtTop?[topTear size].height:0;
			
			[self scrollPoint: charPoint];
		}
	}
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
		
		return;
	}
	
	if ((modifiers&(NSShiftKeyMask|NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask)) == 0
		&& [event clickCount] == 1) {
		// Single click, no modifiers
		NSRect bounds = [self bounds];
		NSRect usedRect = [[self layoutManager] usedRectForTextContainer: [self textContainer]];
		NSPoint mousePoint = [self convertPoint: [event locationInWindow]
									   fromView: nil];
		
		
		if ((tornAtTop && mousePoint.y < NSMinY(bounds)+[topTear size].height)) {
			if ([self delegate] && [[self delegate] respondsToSelector: @selector(sourceFileShowPreviousSection:)]) {
				[[self delegate] sourceFileShowPreviousSection: self];
			} else {
				[self removeRestriction];
			}
			
			return;
		} else if (tornAtBottom && mousePoint.y > NSMinY(bounds)+[self textContainerOrigin].y+NSMaxY(usedRect)) {
			if ([self delegate] && [[self delegate] respondsToSelector: @selector(sourceFileShowNextSection:)]) {
				[[self delegate] sourceFileShowNextSection: self];
			} else {
				[self removeRestriction];
			}
			
			// Finished handling this event
			return;
		}
	}
	
	// Process this event as normal
	[super mouseDown: event];		
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
	NSColor* tearColour = [NSColor colorWithDeviceRed: 0.95
												green: 0.95
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
		
		// Draw the 'up' arrow
		NSImage* arrow = arrowNotPressed;
		NSSize upSize = [arrowNotPressed size];
		NSRect upRect;
		
		upRect.origin	= NSMakePoint(floorf(NSMinX(bounds) + (bounds.size.width - upSize.width)/2), floorf(NSMinY(bounds) + (tornSize.height - upSize.height)/2));
		upRect.size		= upSize;
		
		[arrow setFlipped: YES];
		[arrow drawInRect: upRect
				 fromRect: NSMakeRect(0,0, upSize.width, upSize.height)
				operation: NSCompositeSourceOver
				 fraction: 1.0];
	}
	if (tornAtBottom) {
		NSSize tornSize = [bottomTear size];
		NSPoint origin = [self textContainerOrigin];
		NSRect usedRect = [[self layoutManager] usedRectForTextContainer: [self textContainer]];
		NSSize containerSize = NSMakeSize(NSMaxX(usedRect), NSMaxY(usedRect));
		
		// Draw the grey background
		[tearColour set];
		NSRectFill(NSMakeRect(NSMinX(bounds), origin.y + containerSize.height, bounds.size.width, bounds.size.height - (origin.y + containerSize.height)));
		
		// Draw the tear
		[bottomTear setFlipped: YES];
		[bottomTear drawInRect: NSMakeRect(NSMinX(bounds), origin.y + containerSize.height, bounds.size.width, tornSize.height)
					  fromRect: NSMakeRect(0,0, bounds.size.width, tornSize.height)
					 operation: NSCompositeSourceOver
					  fraction: 1.0];
		
		// Draw the 'down' arrow
		NSImage* arrow = arrowNotPressed;
		NSSize upSize = [arrowNotPressed size];
		NSRect upRect;
		
		upRect.origin	= NSMakePoint(floorf(NSMinX(bounds) + (bounds.size.width - upSize.width)/2), floorf(origin.y + containerSize.height + (tornSize.height - upSize.height)/2));
		upRect.size		= upSize;
		
		[arrow setFlipped: NO];
		[arrow drawInRect: upRect
				 fromRect: NSMakeRect(0,0, upSize.width, upSize.height)
				operation: NSCompositeSourceOver
				 fraction: 1.0];
	}
}

// = Drawing 'tears' at the top and bottom =

- (void) updateTearing {
	// Load the images if they aren't already available
	[self loadImages];

	// Work out the inset to use
	NSSize inset = NSMakeSize(3,6);
	
	if (tornAtTop) {
		inset.height += floorf([topTear size].height);
	}
	if (tornAtBottom) {
		inset.height += floorf([bottomTear size].height);
	}
	inset.height = floorf(inset.height/2);
	
	// Update the display
	[self setTextContainerInset: inset];
	[self invalidateTextContainerOrigin];
	
	lastUsedRect = [[self layoutManager] usedRectForTextContainer: [self textContainer]];
	[self setNeedsDisplay: YES];
}

- (BOOL) checkForRedraw {
	if (tornAtBottom) {
		// If the last used rect is different from the current used rect, then redraw the bottom of the display as well
		NSRect newUsedRect = [[self layoutManager] usedRectForTextContainer: [self textContainer]];
		
		if (NSMaxY(newUsedRect) != NSMaxY(lastUsedRect)) {
			NSRect bounds = [self bounds];
			lastUsedRect = newUsedRect;
			
			float minY = NSMinY(lastUsedRect);
			if (NSMinY(newUsedRect) < minY) minY = NSMinY(newUsedRect);
			
			NSRect needsDisplay = NSMakeRect(NSMinX(bounds), minY, bounds.size.width, NSMaxY(bounds)-minY);
			[super setNeedsDisplayInRect: needsDisplay];
			
			return YES;
		}
	}
	
	return NO;
}

- (void)setNeedsDisplayInRect: (NSRect)invalidRect {
	[super setNeedsDisplayInRect: invalidRect];
	[self checkForRedraw];
}

- (void) unlockFocus {
	if ([self checkForRedraw]) {
		[self displayIfNeeded];
	}
	[super unlockFocus];
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
