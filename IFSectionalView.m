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
// TODO: add an indicator for items with subheadings

static NSFont* sectionFont = nil;
static NSFont* headingFont = nil;

@implementation IFSectionalView

// = Initialisation =

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
		contents = [[NSMutableArray alloc] init];
		calculateSizes = YES;
		
		if (sectionFont == nil) {
			sectionFont = [[NSFont systemFontOfSize: 13] retain];
			headingFont = [[NSFont boldSystemFontOfSize: 11] retain];
		}
    }
	
    return self;
}

- (void) dealloc {
	[contents release];
	[super dealloc];
}

// = Recalculating sizes =

- (void) recalculate {
	// No need to calculate any more after this has been called
	calculateSizes = NO;

	// Some font attributes
	NSDictionary* headingAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		headingFont, NSFontAttributeName,
		nil];
	NSDictionary* sectionAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		sectionFont, NSFontAttributeName,
		nil];
	
	// Reset the general calculated items
	idealSize = NSMakeSize(0,0);
	
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
			leftMargin = 12;
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
		[section setStringToRender: text];
		
		// Move on
		lastY = NSMaxY(sectionBounds);
	}
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

- (NSSize) size {
	if (calculateSizes) [self recalculate];
	
	return idealSize;
}

// = Drawing =

- (BOOL)isFlipped {
	return YES;
}

- (void)drawRect:(NSRect)rect {
	// Perform recalculation if required
	if (calculateSizes) [self recalculate];
	
	// Some font attributes
	NSDictionary* headingAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		headingFont, NSFontAttributeName,
		nil];
	NSDictionary* sectionAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		sectionFont, NSFontAttributeName,
		nil];
	
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
				leftMargin = 12;
			}
			
			// Measure this section
			float height = ([font ascender] - [font descender]);			
			
			// Draw this section
			[text drawAtPoint: NSMakePoint(leftMargin, bounds.origin.y + (bounds.size.height - height)/2)
			   withAttributes: attributes];
		}
	}
}


@end
