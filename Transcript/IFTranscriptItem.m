//
//  IFTranscriptItem.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 10/05/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFTranscriptItem.h"


@implementation IFTranscriptItem

// = Initialisation =

static NSDictionary* defaultAttributes = nil;

- (id) init {
	self = [super init];
	
	if (self) {
		if (!defaultAttributes) {
			defaultAttributes = [[NSDictionary dictionaryWithObjectsAndKeys: 
				[NSFont systemFontOfSize: 11], NSFontAttributeName,
				[[[NSParagraphStyle alloc] init] autorelease], NSParagraphStyleAttributeName,
				nil] retain];
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
	
	[transcriptContainer release]; transcriptContainer = nil;
	[expectedContainer release]; expectedContainer = nil;
	
	[super dealloc];
}

// = Setting the item data =

- (void) setCommand: (NSString*) newCommand {
	[command release]; command = [newCommand copy];
	
	calculated = NO;
}

- (void) setTranscript: (NSString*) newTranscript {
	[transcript release]; transcript = nil;
	[transcriptContainer release]; transcriptContainer = nil;
	
	if (newTranscript == nil) return;
	
	transcript = [[NSTextStorage alloc] initWithString: newTranscript
											attributes: attributes];
	
	calculated = NO;
}

- (void) setExpected: (NSString*) newExpected {
	[expected release]; expected = nil;
	[expectedContainer release]; expectedContainer = nil;
	
	if (newExpected == nil) return;
	
	expected = [[NSTextStorage alloc] initWithString: newExpected
										  attributes: attributes];
	
	calculated = NO;
}

- (void) setPlayed: (BOOL) newPlayed {
	played = newPlayed;
}

- (void) setChanged: (BOOL) newChanged {
	changed = newChanged;
}

- (void) setAttributes: (NSDictionary*) newAttributes {
	[attributes release]; attributes = [newAttributes copy];
	
	calculated = NO;
}

- (NSDictionary*) attributes {
	return attributes;
}

// = Setting the data from the view =

- (void) setWidth: (float) newWidth {
	width = newWidth;
	
	calculated = NO;
}

- (void) setOffset: (float) newOffset {
	offset = newOffset;
}

- (float) offset {
	return offset;
}

// = Calculating the height of this item =

- (NSString*) stripWhitespace: (NSString*) otherString {
	NSMutableString* res = [[otherString mutableCopy] autorelease];
	
	// Sigh. Need perl. (stringByTrimmingCharactersInSet would have been perfect if it applied across the whole string)
	int pos;
	for (pos=0; pos<[res length]; pos++) {
		unichar chr = [res characterAtIndex: pos];
		
		if (chr == '\n' || chr == '\r' || chr == ' ' || chr == '\t') {
			// Whitespace character
			[res deleteCharactersInRange: NSMakeRange(pos, 1)];
			pos--;
		}
	}
	
	return res;
}

- (NSTextContainer*) containerForString: (NSTextStorage*) string
							  withWidth: (float) stringWidth {
	// Return nothing if it's not sensible to lay out this string
	if (!string) return nil;
	if (stringWidth <= 48) return nil;
	
	// Create the NSTextContainer and the layout manager
	NSTextContainer* container = [[NSTextContainer alloc] initWithContainerSize: NSMakeSize(stringWidth, 10e6)];
	NSLayoutManager* layout = [[NSLayoutManager alloc] init];

	[container setWidthTracksTextView: NO];
	[container setHeightTracksTextView: NO];
	
	[layout setBackgroundLayoutEnabled: NO];
	
	[layout addTextContainer: container];
	
	// Add the storage to the layout manager
	[string addLayoutManager: layout];
	
	// Return the results
	[layout autorelease];
	return [container autorelease];
}

- (float) heightForContainer: (NSTextContainer*) container {
	NSLayoutManager* layout = [container layoutManager];

	NSRange glyphs = [layout glyphRangeForCharacterRange: NSMakeRange(0, [[layout textStorage] length])
									actualCharacterRange: nil];
	NSRect bounds = [layout boundingRectForGlyphRange: glyphs
									  inTextContainer: container];
	
	return NSMaxY(bounds);
}

- (void) calculateItem {
	if (calculated) return;
	
	// Make/resize the text containers
	float stringWidth = floorf(width/2.0 - 44.0);
	
	if (!transcriptContainer) {
		transcriptContainer = [[self containerForString: transcript
											  withWidth: stringWidth] retain];
	} else {
		[transcriptContainer setContainerSize: NSMakeSize(stringWidth, 10e6)];
	}
	
	if (!expectedContainer) {
		expectedContainer = [[self containerForString: expected
											withWidth: stringWidth] retain];
	} else {
		[expectedContainer setContainerSize: NSMakeSize(stringWidth, 10e6)];
	}
	
	// Height is:
	//   a = Maximum(height of transcript, height of extra)
	//   b = Height of font set in attributes
	// height = a + 2*b
	// (quarter-line gap above/below text and command)
	
	NSFont* font = [attributes objectForKey: NSFontAttributeName];
	
	float fontHeight = [font defaultLineHeightForFont];
	float transcriptHeight = [self heightForContainer: transcriptContainer];
	float expectedHeight = [self heightForContainer: expectedContainer];
	
	textHeight = floorf(transcriptHeight>expectedHeight ? transcriptHeight : expectedHeight);
	if (textHeight < 48.0) textHeight = 48.0;
	
	height = floorf(textHeight + 2*fontHeight);
	
	// Compare the 'expected' text and the 'actual' text
	textEquality = 0;
	if (expected == nil || [[expected string] isEqualToString: @""]) {
		textEquality = -1;				// No text
	} else if ([[expected string] isEqualToString: [transcript string]]) {
		textEquality = 2;				// Exact match
	} else if ([[self stripWhitespace: [expected string]] caseInsensitiveCompare: [self stripWhitespace: [transcript string]]] == 0) {
		textEquality = 1;				// Near match
	}

	// Mark this item as calculated
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
	// Draw nothing if we don't know our size yet
	if (!calculated) return;
	
	// Colours
	static NSColor* unplayedCol = nil;
	static NSColor* unchangedCol = nil;
	static NSColor* changedCol = nil; 
	
	static NSColor* noExpectedCol = nil;
	static NSColor* noMatchCol = nil;
	static NSColor* nearMatchCol = nil;
	static NSColor* exactMatchCol = nil;
	
	static NSColor* commandCol = nil;
	
	if (!unplayedCol) {
		unplayedCol = [[NSColor colorWithDeviceRed: 0.8
											 green: 0.8
											  blue: 0.8 
											 alpha: 1.0] retain];
		unchangedCol = [[NSColor colorWithDeviceRed: 0.6
											  green: 1.0
											   blue: 0.6
											  alpha: 1.0] retain];
		changedCol = [[NSColor colorWithDeviceRed: 1.0
											green: 0.6
											 blue: 0.6
											alpha: 1.0] retain];

		noExpectedCol = [[NSColor colorWithDeviceRed: 0.7
											   green: 0.7
												blue: 0.7 
											   alpha: 1.0] retain];
		noMatchCol = [[NSColor colorWithDeviceRed: 1.0
											green: 0.5
											 blue: 0.5
											alpha: 1.0] retain];
		nearMatchCol = [[NSColor colorWithDeviceRed: 1.0
											  green: 1.0
											   blue: 0.5
											  alpha: 1.0] retain];
		exactMatchCol = [[NSColor colorWithDeviceRed: 0.5
											   green: 1.0
												blue: 0.5
											   alpha: 1.0] retain];
		
		commandCol = [[NSColor colorWithDeviceRed: 0.6
										 green: 0.8
										  blue: 1.0
										 alpha: 1.0] retain];
	}

	// Work out some metrics
	NSFont* font = [attributes objectForKey: NSFontAttributeName];
	
	float fontHeight = [font defaultLineHeightForFont];
	
	// Draw the command (blue background: this is also where we put control buttons for this object)
	[commandCol set];
	NSRectFill(NSMakeRect(point.x, point.y, width, fontHeight * 1.5));
	
	[command drawAtPoint: NSMakePoint(floorf(point.x + 12.0), floorf(point.y + fontHeight*.25))
		  withAttributes: attributes];
	
	// Draw the transcript text
	NSRect textRect;
	
	textRect.origin = NSMakePoint(floorf(point.x + 8.0), floorf(point.y + fontHeight * 1.75));
	textRect.size = NSMakeSize(floorf(width/2.0 - 44.0), floorf(textHeight));
	
	if (!played) {
		[unplayedCol set];
	} else if (!changed) {
		[unchangedCol set];
	} else {
		[changedCol set];
	}
	
	NSRectFill(NSMakeRect(point.x, floorf(point.y + fontHeight*1.5), floorf(width/2.0), floorf(textHeight + fontHeight*0.5)));
	
	NSLayoutManager* layout = [transcriptContainer layoutManager];
	NSRange glyphRange = [layout glyphRangeForTextContainer: transcriptContainer];
	[layout drawGlyphsForGlyphRange: glyphRange
							atPoint: textRect.origin];
	
	// Draw the expected text
	textRect.origin = NSMakePoint(floorf(point.x + width/2.0 + 36.0), textRect.origin.y);
	
	switch (textEquality) {
		case -1: [noExpectedCol set]; break;
		case 1:  [nearMatchCol set]; break;
		case 2:  [exactMatchCol set]; break;
		default: [noMatchCol set]; break;
	}

	NSRectFill(NSMakeRect(point.x + floorf(width/2.0), floorf(point.y + fontHeight*1.5), floorf(width/2.0), floorf(textHeight + fontHeight*0.5)));

	layout = [expectedContainer layoutManager];
	glyphRange = [layout glyphRangeForTextContainer: expectedContainer];
	[layout drawGlyphsForGlyphRange: glyphRange
							atPoint: textRect.origin];
	
	// Draw the seperator lines
	[[NSColor controlShadowColor] set];
	NSRectFill(NSMakeRect(point.x+floorf(width/2.0), floorf(point.y + fontHeight*1.5), 1, floorf(textHeight + fontHeight*0.5)));	// Between the 'transcript' and the 'expected' text
	NSRectFill(NSMakeRect(point.x, floorf(point.y + fontHeight*1.5), width, 1));													// Between the command and the transcript
	NSRectFill(NSMakeRect(point.x, floorf(point.y + fontHeight*2.0 + textHeight)-1, width, 1));										// Along the bottom
}

@end
