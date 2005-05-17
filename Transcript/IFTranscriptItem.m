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

// Colours
static NSColor* unplayedCol = nil;
static NSColor* unchangedCol = nil;
static NSColor* changedCol = nil; 

static NSColor* noExpectedCol = nil;
static NSColor* noMatchCol = nil;
static NSColor* nearMatchCol = nil;
static NSColor* exactMatchCol = nil;

static NSColor* commandCol = nil;

static NSColor* highlightCol = nil;
static NSColor* activeCol = nil;

+ (void) initialize {
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
		
		highlightCol = [[NSColor colorWithDeviceRed: 0.4
											  green: 0.4
											   blue: 1.0
											  alpha: 1.0] retain];
		activeCol = [[NSColor colorWithDeviceRed: 1.0
										   green: 1.0
											blue: 0.7
										   alpha: 1.0] retain];
	}
}

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
		
		expected = [[NSTextStorage alloc] init];
		transcript = [[NSTextStorage alloc] init];
	}
	
	return self;
}

- (void) dealloc {
	[skeinItem release]; skeinItem = nil;
	
	[command release]; command = nil;
	[transcript setDelegate: nil]; [transcript release]; transcript = nil;
	[expected setDelegate: nil]; [expected release]; expected = nil;
	
	[attributes release]; attributes = nil;
	
	[transcriptContainer release]; transcriptContainer = nil;
	[expectedContainer release]; expectedContainer = nil;
	
	[fieldEditor setDelegate: nil];
	[fieldEditor release]; fieldEditor = nil;
	
	[super dealloc];
}

// = Setting the item data =

- (void) setSkeinItem: (ZoomSkeinItem*) item {
	[skeinItem release];
	skeinItem = [item retain];
}

- (ZoomSkeinItem*) skeinItem {
	return skeinItem;
}

- (void) setCommand: (NSString*) newCommand {
	[command release]; command = [newCommand copy];
	
	calculated = NO;
}

- (void) setTranscript: (NSString*) newTranscript {
	[transcript setDelegate: nil];
	[transcript release]; transcript = nil;
	[transcriptContainer release]; transcriptContainer = nil;
	
	if (newTranscript == nil) newTranscript = @"";
	
	transcript = [[NSTextStorage alloc] initWithString: newTranscript
											attributes: attributes];
	
	calculated = NO;
}

- (void) setExpected: (NSString*) newExpected {
	[expected setDelegate: nil];
	[expected release]; expected = nil;
	[expectedContainer release]; expectedContainer = nil;
	
	if (newExpected == nil) newExpected = @"";
	
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

- (void) calculateEquality {
	// Compare the 'expected' text and the 'actual' text
	textEquality = 0;
	if (expected == nil || [[expected string] isEqualToString: @""]) {
		textEquality = -1;				// No text
	} else if ([[expected string] isEqualToString: [transcript string]]) {
		textEquality = 2;				// Exact match
	} else if ([[self stripWhitespace: [expected string]] caseInsensitiveCompare: [self stripWhitespace: [transcript string]]] == 0) {
		textEquality = 1;				// Near match
	}
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
	[self calculateEquality];

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

- (float) textHeight {
	if (!calculated) return 18.0;
	
	return textHeight;
}

// = Drawing =

- (void) drawBorder: (NSRect) border
			  width: (float) borderWidth {
	NSRect r;
	
	// Top
	r = border;
	r.size = NSMakeSize(border.size.width, borderWidth);
	NSRectFill(r);
	
	// Left
	r = border;
	r.size = NSMakeSize(borderWidth, border.size.height);
	NSRectFill(r);
	
	// Bottom
	r = NSMakeRect(border.origin.x, NSMaxY(border) - borderWidth, border.size.width, borderWidth);
	NSRectFill(r);
	
	// Right
	r = NSMakeRect(NSMaxX(border) - borderWidth, border.origin.y, borderWidth, border.size.height);
	NSRectFill(r);
}

- (void) drawAtPoint: (NSPoint) point
		 highlighted: (BOOL) highlighted
			  active: (BOOL) active {
	// Draw nothing if we don't know our size yet
	if (!calculated) return;

	// Work out some metrics
	NSFont* font = [attributes objectForKey: NSFontAttributeName];
	
	float fontHeight = [font defaultLineHeightForFont];
	
	// Draw the command (blue background: this is also where we put control buttons for this object)
	[commandCol set];
	NSRectFill(NSMakeRect(point.x, point.y, width, fontHeight * 1.5));
	
	[command drawAtPoint: NSMakePoint(floorf(point.x + 12.0), floorf(point.y + fontHeight*.25))
		  withAttributes: attributes];
	
	// Draw the transcript background
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
	
	NSPoint transcriptPoint = textRect.origin;
	
	// Draw the expected background
	textRect.origin = NSMakePoint(floorf(point.x + width/2.0 + 36.0), textRect.origin.y);
	
	switch (textEquality) {
		case -1: [noExpectedCol set]; break;
		case 1:  [nearMatchCol set]; break;
		case 2:  [exactMatchCol set]; break;
		default: [noMatchCol set]; break;
	}
	
	NSRectFill(NSMakeRect(point.x + floorf(width/2.0), floorf(point.y + fontHeight*1.5), floorf(width/2.0), floorf(textHeight + fontHeight*0.5)));
	
	NSPoint expectedPoint = textRect.origin;

	// Draw the separator lines
	[[NSColor controlShadowColor] set];
	NSRectFill(NSMakeRect(point.x+floorf(width/2.0), floorf(point.y + fontHeight*1.5), 1, floorf(textHeight + fontHeight*0.5)));	// Between the 'transcript' and the 'expected' text
	NSRectFill(NSMakeRect(point.x, floorf(point.y + fontHeight*1.5), width, 1));													// Between the command and the transcript
	NSRectFill(NSMakeRect(point.x, floorf(point.y + fontHeight*2.0 + textHeight)-1, width, 1));										// Along the bottom
	
	// Draw any borders we might want
	if (highlighted || active) {
		textRect.origin = NSMakePoint(point.x, point.y);
		textRect.size = NSMakeSize(width, height);
		
		if (active) {
			[activeCol set];
			[self drawBorder: textRect
					   width: 4.0];
		}
		
		if (highlighted) {
			[highlightCol set];
			[self drawBorder: textRect
					   width: 2.0];
		}
	}
		
	// Draw the transcript text
	NSLayoutManager* layout = [transcriptContainer layoutManager];
	NSRange glyphRange = [layout glyphRangeForTextContainer: transcriptContainer];
	[layout drawGlyphsForGlyphRange: glyphRange
							atPoint: transcriptPoint];
	
	// Draw the expected text
	layout = [expectedContainer layoutManager];
	glyphRange = [layout glyphRangeForTextContainer: expectedContainer];
	[layout drawGlyphsForGlyphRange: glyphRange
							atPoint: expectedPoint];	
}

// = Delegate =

- (void) setDelegate: (id) newDelegate {
	delegate = newDelegate;
}

- (void) transcriptItemHasChanged: (id) sender {
	if (delegate && [delegate respondsToSelector: @selector(transcriptItemHasChanged:)]) {
		[delegate transcriptItemHasChanged: self];
	}
}

// = Field editing =

- (void) setupFieldEditor: (NSTextView*) newFieldEditor
			  forExpected: (BOOL) editExpected
				  atPoint: (NSPoint) itemOrigin {
	NSRect editorFrame;
	float stringWidth = floorf(width/2.0 - 44.0);
	float fontHeight = [[attributes objectForKey: NSFontAttributeName] defaultLineHeightForFont];
	
	// Finish up the old editor, if there was one
	if (fieldEditor) {
		[fieldEditor setDelegate: nil];
		[fieldEditor release]; fieldEditor = nil;
	}
	
	fieldEditor = [newFieldEditor retain];
	
	// Work out the frame for the item
	editorFrame.origin = itemOrigin;
	editorFrame.size = NSMakeSize(stringWidth, textHeight);
	
	editorFrame.origin.y += floorf(1.75*fontHeight);
	
	if (!editExpected) {
		editorFrame.origin.x += 8.0;
	} else {
		editorFrame.origin.x += floorf(width/2.0 + 36.0);
	}
	
	// Get the item to edit
	NSTextStorage* storage;
	NSColor* background;
	
	if (!editExpected) {
		// Storage is the transcript
		storage = transcript;
		
		// Set the background colour appropriately
		if (!played) {
			background = unplayedCol;
		} else if (!changed) {
			background = unchangedCol;
		} else {
			background = changedCol;
		}
	} else {
		// Storage is the 'expected' text
		storage = expected;

		// Set the background colour appropriately
		switch (textEquality) {
			case -1: background = noExpectedCol; break;
			case 1:  background = nearMatchCol; break;
			case 2:  background = exactMatchCol; break;
			default: background = noMatchCol; break;
		}
	}
	
	// Prepare the field editor
	while ([fieldEditor textStorage] != nil) {
		[[fieldEditor textStorage] removeLayoutManager: [fieldEditor layoutManager]];
	}
	
	[storage setDelegate: self];
	[storage addLayoutManager: [fieldEditor layoutManager]];
	
	[fieldEditor setDelegate: self];
	[fieldEditor setFrame: editorFrame];
	
	[fieldEditor setRichText: NO];
	[fieldEditor setAllowsDocumentBackgroundColorChange: NO];
	[fieldEditor setBackgroundColor: background];
	[fieldEditor setFieldEditor: NO];							// (Sigh - hack, doesn't appear to be a better way to get newlines inserted properly. A field editor that is not a field editor: very zen)
	
	[fieldEditor setAlignment: NSNaturalTextAlignment];
	
	[[fieldEditor textContainer] setContainerSize: NSMakeSize(editorFrame.size.width, 10e6)];
	[[fieldEditor textContainer] setWidthTracksTextView:NO];
	[[fieldEditor textContainer] setHeightTracksTextView:NO];
	[fieldEditor setHorizontallyResizable:NO];
	[fieldEditor setVerticallyResizable:YES];
	[fieldEditor setDrawsBackground: YES];
}

- (void) finishEditing: (id) sender {	
	updating = YES;
	
	// Inform the delegate of what's happened
	[self transcriptItemHasChanged: self];

	// Update the skein item
	NSTextStorage* storage = [fieldEditor textStorage];
	
	if (skeinItem) {
		if (storage == transcript) {
			BOOL wasChanged = [skeinItem changed];
			
			[skeinItem setResult: [transcript string]];

			[skeinItem setChanged: wasChanged];
		} else if (storage == expected) {
			[skeinItem setCommentary: [expected string]];
		}
	}
	
	// Don't need to be the delegate of these things any more
	[transcript setDelegate: nil];
	[expected setDelegate: nil];
	
	// Shut down the field editor
	[fieldEditor setFieldEditor: YES];
	[[fieldEditor textStorage] removeLayoutManager: [fieldEditor layoutManager]];
	[fieldEditor setDelegate: nil];
	[fieldEditor removeFromSuperview];
	
	[fieldEditor release]; fieldEditor = nil;
	
	// Recalculate this item
	calculated = NO;
	[self calculateItem];
	
	updating = NO;
}

- (BOOL) updating {
	return updating;
}

- (void) textDidEndEditing: (NSNotification*) aNotificationn {
	// Check if the user left the field before committing changes and end the edit.
	[self finishEditing: fieldEditor];				// Store the results
}

- (void) textStorageDidProcessEditing: (NSNotification *)aNotification {
	NSTextStorage* storage = [aNotification object];
	
	// Set the attributes
	[storage addAttributes: attributes 
					 range: [storage editedRange]];
	
	// Queue up a recalculation request (we can't measure the text here, so we have to do it later)
	[[NSRunLoop currentRunLoop] performSelector: @selector(finishProcessingEditing:)
										 target: self
									   argument: storage
										  order: 64
										  modes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
}

- (void) finishProcessingEditing: (NSTextStorage*) storage {	
	// Recalculate appropriately
	float fontHeight = [[attributes objectForKey: NSFontAttributeName] defaultLineHeightForFont];
	float transcriptHeight = [self heightForContainer: transcriptContainer];
	float expectedHeight = [self heightForContainer: expectedContainer];
	
	float newTextHeight = floorf(transcriptHeight>expectedHeight ? transcriptHeight : expectedHeight);
	if (newTextHeight < 48.0) newTextHeight = 48.0;
	
	if (newTextHeight != textHeight) {
		textHeight = newTextHeight;
		height = floorf(textHeight + 2*fontHeight);
		
		[self transcriptItemHasChanged: self];
	}
	
	// If we're editing the expected text, set the background colour appropriatly
	if (storage == expected) {
		int oldEquality = textEquality;
		[self calculateEquality];
		
		if (oldEquality == textEquality) return;

		NSColor* background;
		switch (textEquality) {
			case -1: background = noExpectedCol; break;
			case 1:  background = nearMatchCol; break;
			case 2:  background = exactMatchCol; break;
			default: background = noMatchCol; break;
		}
		
		if (background != [fieldEditor backgroundColor] &&
			![background isEqualTo: [fieldEditor backgroundColor]]) {
			[fieldEditor setBackgroundColor: background];
			[self transcriptItemHasChanged: self];
		}
	}
}

@end
