//
//  IFTranscriptItem.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 10/05/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFTranscriptItem.h"


@implementation IFTranscriptItem

static NSTextContainer* formattingContainer = nil;
static NSLayoutManager* formattingManager = nil;

// = Initialisation =

static NSDictionary* defaultAttributes = nil;

- (id) init {
	self = [super init];
	
	if (self) {
		if (!defaultAttributes) {
			defaultAttributes = [NSDictionary dictionaryWithObjectsAndKeys: 
				[NSFont systemFontOfSize: 11], NSFontAttributeName, nil];
		}
		
		attributes = [defaultAttributes retain];
	}
	
	return self;
}

- (void) dealloc {
	[command release]; command = nil;
	[transcript release]; transcript = nil;
	[expected release]; expected = nil;
	
	[attributes release]; attributes = nil;
	
	[super dealloc];
}

// = Setting the item data =

- (void) setCommand: (NSString*) newCommand {
	[command release]; command = [newCommand copy];
	
	calculated = NO;
}

- (void) setTranscript: (NSString*) newTranscript {
	[transcript release]; transcript = [newTranscript copy];
	
	calculated = NO;
}

- (void) setExpected: (NSString*) newExpected {
	[expected release]; expected = [newExpected copy];
	
	calculated = NO;
}

- (void) setAttributes: (NSDictionary*) newAttributes {
	[attributes release]; attributes = [newAttributes copy];
	
	calculated = NO;
}

// = Setting the data from the view =

- (void) setWidth: (float) newWidth {
	width = newWidth;
	
	calculated = NO;
}

// = Calculating the height of this item =

- (float) heightForString: (NSString*) string 
				withWidth: (float) stringWidth {
	// (Using the standard attributes)
	if (!string) return 0.0;
	if (stringWidth <= 8) return 0.0;
	
	if (!formattingContainer) {
		// Allocate an NSTextContainer to do the formatting in (we preserve this for all of our formatting)
		formattingContainer = [[NSTextContainer alloc] init];
		formattingManager = [[NSLayoutManager alloc] init];
		
		[formattingContainer setWidthTracksTextView: NO];
		[formattingContainer setHeightTracksTextView: NO];
		
		[formattingManager addTextContainer: formattingContainer];
		[formattingManager setBackgroundLayoutEnabled: NO];
	}
	
	// Set the text container up for formatting (er, hope this works without a pesky heavyweight NSTextView to go
	// along with it)
	NSTextStorage* storage = [[NSTextStorage alloc] initWithString: string
														attributes: attributes];
		
		
	[formattingContainer setContainerSize: NSMakeSize(stringWidth, 10e6)];
	[storage addLayoutManager: formattingManager];
	
	// Text will now be formatted: get the bounds
	NSRange glyphs = [formattingManager glyphRangeForCharacterRange: NSMakeRange(0, [string length])
											   actualCharacterRange: nil];
	
	NSRect bounds = [formattingManager boundingRectForGlyphRange: glyphs
												 inTextContainer: formattingContainer];
	
	// Shut down
	[storage removeLayoutManager: formattingManager];
	
	return floorf(NSMaxY(bounds));
}

- (void) calculateItem {
	if (calculated) return;
	
	// Height is:
	//   a = Maximum(height of transcript, height of extra)
	//   b = Height of font set in attributes
	// height = a + 2*b
	// (quarter-line gap above/below text and command)
	
	NSFont* font = [attributes objectForKey: NSFontAttributeName];
	
	float fontHeight = [font defaultLineHeightForFont];
	float transcriptHeight = [self heightForString: transcript
										 withWidth: floorf(width/2.0 - 44.0)];
	float expectedHeight = [self heightForString: expected
									   withWidth: floorf(width/2.0 - 44.0)];
	
	float textHeight = transcriptHeight>expectedHeight ? transcriptHeight : expectedHeight;
	
	height = textHeight + 2*fontHeight;
	calculated = YES;
}

- (BOOL) calculated {
	return calculated;
}

- (float) height {
	if (!calculated) return 18.0;
	
	return height;
}

// = Drawing =

- (void) drawAtPoint: (NSPoint) point {
	if (!calculated) return;

	// Work out some metrics
	NSFont* font = [attributes objectForKey: NSFontAttributeName];
	
	float fontHeight = [font defaultLineHeightForFont];
	
	// Draw the command (blue background: this is also where we put control buttons for this object)
	[command drawAtPoint: NSMakePoint(floorf(point.x + 12.0), floorf(point.y + fontHeight/4.0))
		  withAttributes: attributes];
	
	// Draw the transcript text
	NSRect textRect;
	
	textRect.origin = NSMakePoint(floorf(point.x + 8.0), floorf(point.y + fontHeight * 1.5));
	textRect.size = NSMakeSize(floorf(width/2.0 - 44.0), floorf(height - 2*fontHeight));
	
	[transcript drawInRect: textRect
			withAttributes: attributes];
	
	// Draw the expected text
	textRect.origin = NSMakePoint(floorf(point.x + width/2.0 + 36.0), textRect.origin.y);

	[expected drawInRect: textRect
		  withAttributes: attributes];
}

@end
