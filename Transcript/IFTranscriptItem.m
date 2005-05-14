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
	
	textHeight = floorf(transcriptHeight>expectedHeight ? transcriptHeight : expectedHeight);
	
	height = floorf(textHeight + 2*fontHeight);
	
	// Compare the 'expected' text and the 'actual' text
	textEquality = 0;
	if (expected == nil || [expected isEqualToString: @""]) {
		textEquality = -1;				// No text
	} else if ([expected isEqualToString: transcript]) {
		textEquality = 2;				// Exact match
	} else if ([[self stripWhitespace: expected] caseInsensitiveCompare: [self stripWhitespace: transcript]] == 0) {
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
	
	[transcript drawInRect: textRect
			withAttributes: attributes];
	
	// Draw the expected text
	textRect.origin = NSMakePoint(floorf(point.x + width/2.0 + 36.0), textRect.origin.y);
	
	switch (textEquality) {
		case -1: [noExpectedCol set]; break;
		case 1:  [nearMatchCol set]; break;
		case 2:  [exactMatchCol set]; break;
		default: [noMatchCol set]; break;
	}

	NSRectFill(NSMakeRect(point.x + floorf(width/2.0), floorf(point.y + fontHeight*1.5), floorf(width/2.0), floorf(textHeight + fontHeight*0.5)));

	[expected drawInRect: textRect
		  withAttributes: attributes];
	
	// Draw the seperator lines
	[[NSColor controlShadowColor] set];
	NSRectFill(NSMakeRect(point.x+floorf(width/2.0), floorf(point.y + fontHeight*1.5), 1, floorf(textHeight + fontHeight*0.5)));	// Between the 'transcript' and the 'expected' text
	NSRectFill(NSMakeRect(point.x, floorf(point.y + fontHeight*1.5), width, 1));													// Between the command and the transcript
	NSRectFill(NSMakeRect(point.x, floorf(point.y + fontHeight*2.0 + textHeight)-1, width, 1));										// Along the bottom
}

@end
