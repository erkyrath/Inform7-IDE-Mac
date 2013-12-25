//
//  IFSectionalView.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 28/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import "IFSectionalView.h"

#import "IFSectionalSection.h"

// TODO: deal with clicks
// TODO: tracking boxes

static NSFont* sectionFont = nil;
static NSFont* headingFont = nil;
static NSImage* seeSubsections = nil;

@implementation IFSectionalView

// = Initialisation =

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
		contents = [[NSMutableArray alloc] init];
		tracking = [[NSMutableArray alloc] init];
		calculateSizes = YES;
		
		if (sectionFont == nil) {
			sectionFont = [[NSFont systemFontOfSize: 13] retain];
			headingFont = [[NSFont boldSystemFontOfSize: 11] retain];
			seeSubsections = [[NSImage imageNamed: @"Arrow-Closed"] retain];
		}
    }
	
    return self;
}

- (void) dealloc {
	[contents release];
	[tracking release];
	[highlighted release];
	[super dealloc];
}

// = Updating =

- (void) redisplaySection: (IFSectionalSection*) section {
	if (section == nil) return;
	
	NSRect sectionBounds = [section bounds];
	sectionBounds.size.width = [self bounds].size.width;
	
	[self setNeedsDisplayInRect: sectionBounds];
}

// = Recalculating sizes =

- (NSString*) fitString: (NSString*) string
				toWidth: (float) width
			   withFont: (NSFont*) font {
	// Fits a string to the specified width, using the specified font. 
	
	// Get the string attributes
	NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys: font, NSFontAttributeName, nil];
	
	// Measure the length of the string
	NSSize stringSize = [string sizeWithAttributes: attributes];
	if (stringSize.width <= width) return string;
	
	// This string needs to be shortened.. measure the length of an ellipsis
	NSSize ellipsisSize = [@"..." sizeWithAttributes: attributes];
	
	// Use a binary search to find the ideal length of this string
	int bottom = 0;
	int top = [string length];
	while (top > bottom) {
		int middle = (top+bottom)>>1;
		
		NSString* testString = [string substringToIndex: middle];
		NSSize testSize = [testString sizeWithAttributes: attributes];
		testSize.width += ellipsisSize.width;
		
		if (testSize.width <= width) {
			bottom = middle + 1;
		} else if (testSize.width > width) {
			top = middle - 1;
		}
	}
	
	// Return the result (top will contain the length of the first string shorter than the specified length)
	if (top < 0) top = 0;
	return [[string substringToIndex: top] stringByAppendingString: @"..."];
}

- (void) removeTrackingRects {
	[highlighted release];
	highlighted = nil;
	
	// Remove any existing tracking rectangles
	NSEnumerator* trackingEnum = [tracking objectEnumerator];
	NSNumber* trackingTag;
	while (trackingTag = [trackingEnum nextObject]) {
		[self removeTrackingRect: [trackingTag intValue]];
	}
	
	[tracking removeAllObjects];
}

- (void) setTrackingRects {
	NSRect bounds = [self bounds];
	
	[self removeTrackingRects];
	
	// Create tracking rectangles for all of the sections
	NSEnumerator* sectionEnum = [contents objectEnumerator];
	IFSectionalSection* section;
	
	float rightMargin = [seeSubsections size].width * 2;
	
	while (section = [sectionEnum nextObject]) {
		NSRect trackingRect = [section bounds];
		
		trackingRect.size.width = bounds.size.width-rightMargin;
		
		int tag = [self addTrackingRect: trackingRect
								  owner: self
							   userData: section
						   assumeInside: NO];
		
		[tracking addObject: [NSNumber numberWithInt: tag]];
	}
}

- (void) compactStrings {
	// Compacts the strings so they fit within the bounds of this view
	compactStrings = NO;
	
	NSRect bounds = [self bounds];
	
	// Iterate through the sections
	NSEnumerator* sectionEnum = [contents objectEnumerator];
	IFSectionalSection* section;
	
	float rightMargin = [seeSubsections size].width * 2;
	
	while (section = [sectionEnum nextObject]) {
		// Get some information about this section
		NSString* text = [section title];
		NSFont* font;
		float leftMargin;
		
		if (![section isHeading]) {
			font = sectionFont;
			leftMargin = 16;
		} else {
			font = headingFont;
			leftMargin = 8;
		}

		// Compact this string
		[section setStringToRender: [self fitString: text
											toWidth: bounds.size.width - leftMargin*2 - rightMargin
										   withFont: font]];
	}
	
	// Update the tracking rectangles
	[self setTrackingRects];
}

- (void) recalculate {
	// No need to calculate any more after this has been called
	calculateSizes = NO;
	compactStrings = NO;

	// Some font attributes
	NSDictionary* headingAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		headingFont, NSFontAttributeName,
		nil];
	NSDictionary* sectionAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		sectionFont, NSFontAttributeName,
		nil];
	
	// Reset the general calculated items
	idealSize = NSMakeSize(0,0);

	float rightMargin = [seeSubsections size].width * 2;

	// Iterate through the sections
	NSEnumerator* sectionEnum = [contents objectEnumerator];
	IFSectionalSection* section;
	
	float lastY = 0;
	while (section = [sectionEnum nextObject]) {
		// Get some information about this section
		NSString* text = [section title];
		NSDictionary* attributes;
		NSFont* font;
		float leftMargin;
		
		if (![section isHeading]) {
			attributes = sectionAttributes;
			font = sectionFont;
			leftMargin = 16;
		} else {
			attributes = headingAttributes;
			font = headingFont;
			leftMargin = 8;
		}
		
		// Measure this section
		float height = [font defaultLineHeightForFont]+4;
		NSSize sectionSize = [text sizeWithAttributes: attributes];
		
		// Work out the bounds
		NSRect sectionBounds;
		
		sectionBounds.origin.x = 0;
		sectionBounds.origin.y = lastY;
		sectionBounds.size.width = sectionSize.width + leftMargin;
		sectionBounds.size.height = height;
		
		if (sectionBounds.size.width > idealSize.width) idealSize.width = sectionBounds.size.width;
		if (NSMaxY(sectionBounds) > idealSize.height) idealSize.height = NSMaxY(sectionBounds);
		
		// Store the results
		[section setBounds: sectionBounds];
		
		// Mark this string as needing compacting
		compactStrings = YES;
		
		// Move on
		lastY = NSMaxY(sectionBounds);
	}
	
	idealSize.width += rightMargin;
}

// = Setting up the contents =

- (void) clear {
	[contents removeAllObjects];
	[self setNeedsDisplay: YES];
}

- (void) addSection: (IFSectionalSection*) newSection {
	calculateSizes = YES;
	
	[contents addObject: newSection];
	
	[self setNeedsDisplay: YES];
}

- (void) addHeading: (NSString*) heading
				tag: (id) tag {
	IFSectionalSection* newSection = [[IFSectionalSection alloc] init];
	
	[newSection setTitle: heading];
	[newSection setHeading: YES];
	[newSection setHasSubsections: NO];
	[newSection setTag: tag];
	
	[self addSection: [newSection autorelease]];
}

- (void) addSection: (NSString*) section
		subSections: (BOOL) hasSubsections
				tag: (id) tag {
	IFSectionalSection* newSection = [[IFSectionalSection alloc] init];
	
	[newSection setTitle: section];
	[newSection setHeading: NO];
	[newSection setHasSubsections: hasSubsections];
	[newSection setTag: tag];
	
	[self addSection: [newSection autorelease]];
}

- (NSSize) idealSize {
	if (calculateSizes) [self recalculate];
	
	return idealSize;
}

- (void) setFrame: (NSRect) frame { 
	compactStrings = YES;
	[super setFrame: frame];
}

// = Actions =

- (void) setTarget: (id) newTarget {
	// (We don't retain the target in case this could cause a retention loop)
	target = newTarget;
}

- (void) setSelectedItemAction: (SEL) action {
	selectedItem = action;
}

- (void) setGotoSubsectionAction: (SEL) action {
	gotoSubsection = action;
}

// = Tracking =

- (void)mouseEntered:(NSEvent *)theEvent {
	[self redisplaySection: highlighted];
	
	[highlighted release];
	highlighted = [(IFSectionalSection*)[theEvent userData] retain];
	
	[self redisplaySection: highlighted];
}

- (void)mouseExited:(NSEvent *)theEvent {
	if (highlighted != [theEvent userData]) return;
	
	[self redisplaySection: highlighted];
	
	[highlighted release];
	highlighted = nil;
}

- (id) highlightedTag {
	return [highlighted tag];
}

- (void) keyDown: (NSEvent*) ev {
	// Perform an action based on the key pressed
	int highlightedIndex = [contents indexOfObjectIdenticalTo: highlighted];
	int newHighlighted = highlightedIndex;
	int direction = 0;
	
	// Move up or down as required
	if ([[ev characters] characterAtIndex: 0] == NSDownArrowFunctionKey) {
		if (highlightedIndex == NSNotFound)
			newHighlighted = 0;
		else
			newHighlighted = highlightedIndex+1;
		direction = 1;
	} else if ([[ev characters] characterAtIndex: 0] == NSUpArrowFunctionKey) {
		if (highlightedIndex == NSNotFound)
			newHighlighted = [contents count]-1;
		else
			newHighlighted = highlightedIndex-1;
		direction = -1;
	} else if ([[ev characters] characterAtIndex: 0] == '\n' ||
			   [[ev characters] characterAtIndex: 0] == '\r') {
		if (highlighted != nil) {
			SEL selector = selectedItem;
			
			if ([target respondsToSelector: selector]) {
				[target performSelector: selector
							 withObject: [highlighted tag]];
			}
			
			return;
		}
	}
	
	// If the section to highlight has changed, move it to avoid any headings (which don't highlight)
	if (newHighlighted != highlightedIndex) {
		// Work out the new highlighted section
		if (newHighlighted < 0) return;
		if (newHighlighted >= [contents count]) return;
		if (newHighlighted < 0 || [contents count] == 0) return;
		
		// TODO: if we have a block entirely consisting of headings, this will crash
		IFSectionalSection* section = [contents objectAtIndex: newHighlighted];
		while ([section isHeading]) {
			newHighlighted += direction;
			if (newHighlighted < 0) return;
			if (newHighlighted >= [contents count]) return;
			
			section = [contents objectAtIndex: newHighlighted];
		}
		
		// Redisplay the current highlighted section
		[self redisplaySection: highlighted];
		
		// Set the newly highlighted section
		[highlighted release];
		highlighted = [section retain];
		
		[self redisplaySection: highlighted];
	}
}

// = Clicking =

- (void) mouseUp: (NSEvent*) theEvent {
	// Get some information about the state of this click
	NSPoint location = [self convertPoint: [theEvent locationInWindow]
								 fromView: nil];
	NSRect bounds = [self bounds];
	
	float rightMargin = [seeSubsections size].width * 2;
	BOOL isGoto =  location.x > NSMaxX(bounds)-rightMargin;
	
	// Work out which section was clicked
	NSEnumerator* sectionEnum = [contents objectEnumerator];
	IFSectionalSection* section;
	
	while (section = [sectionEnum nextObject]) {
		NSRect sectionBounds = [section bounds];
				
		if (NSMinY(sectionBounds) < location.y && NSMaxY(sectionBounds) > location.y)
			break;
	}
	
	// Do not send goto requests to items with no subsections
	if (isGoto && ![section hasSubsections]) {
		return;
	}
	
	// Send the action
	if (section != nil) {
		SEL selector = isGoto?gotoSubsection:selectedItem;
		
		if ([target respondsToSelector: selector]) {
			[target performSelector: selector
						 withObject: [section tag]];
		}
	}
}

// = Drawing =

- (BOOL)isFlipped {
	return YES;
}

- (void)drawRect:(NSRect)rect {
	// Perform recalculation if required
	if (calculateSizes) [self recalculate];
	if (compactStrings) [self compactStrings];
	
	// Some font attributes
	NSDictionary* headingAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		headingFont, NSFontAttributeName,
		nil];
	NSDictionary* sectionAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		sectionFont, NSFontAttributeName,
		nil];
	
	NSSize subsectionSize = [seeSubsections size];
	NSRect ourBounds = [self bounds];
	
	float rightMargin = subsectionSize.width * 2;
	
	// Draw the items
	NSEnumerator* sectionEnum = [contents objectEnumerator];
	IFSectionalSection* section;
	
	while (section = [sectionEnum nextObject]) {
		NSRect bounds = [section bounds];
		
		if (NSIntersectsRect(rect, bounds)) {
			// Get some information about this section
			NSString* text = [section stringToRender];
			NSDictionary* attributes;
			NSFont* font;
			float leftMargin;
			
			if (![section isHeading]) {
				attributes = sectionAttributes;
				font = sectionFont;
				leftMargin = 16;
			} else {
				attributes = headingAttributes;
				font = headingFont;
				leftMargin = 8;
			}
			
			// Measure this section
			float height = ([font ascender] - [font descender]);			

			// Draw the selection rectangle
			if (highlighted == section && ![section isHeading]) {
				NSRect highlightRect = bounds;
				
				highlightRect.size.width = ourBounds.size.width-rightMargin;
				
				[[NSColor selectedMenuItemColor] set];
				NSRectFill(highlightRect);
				
				NSMutableDictionary* lightAttributes = [[attributes mutableCopy] autorelease];
				[lightAttributes setObject: [NSColor selectedMenuItemTextColor]
									forKey: NSForegroundColorAttributeName];
				
				attributes = lightAttributes;
			}
			
			// Draw this section
			[text drawAtPoint: NSMakePoint(leftMargin, floorf(bounds.origin.y + (bounds.size.height - height)/2)-1)
			   withAttributes: attributes];
			
			if ([section hasSubsections]) {
				NSRect subsectionArea;
				
				subsectionArea.size = subsectionSize;
				subsectionArea.origin.x = floorf(NSMaxX(ourBounds)-subsectionSize.width*1.5);
				subsectionArea.origin.y = floorf(NSMinY(bounds) + (bounds.size.height - subsectionSize.height)/2.0);
				
				[seeSubsections drawInRect: subsectionArea 
								  fromRect: NSMakeRect(0,0, subsectionSize.width, subsectionSize.height)
								 operation: NSCompositeSourceOver
								  fraction: 1.0];
			}
		}
	}
}

@end
