//
//  IFIsTitleView.m
//  Inform
//
//  Created by Andrew Hunter on Mon May 03 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import "IFIsTitleView.h"


@implementation IFIsTitleView

static NSImage* bgImage = nil;
static NSFont* titleFont = nil;
static float titleHeight = 0;

static NSDictionary* fontAttributes;

// Bug in weak linking? Can't use NSShadowAttributeName... Hmph
static NSString* IFNSShadowAttributeName = @"NSShadow";

+ (void) initialize {
	// Background image
	bgImage = [[NSImage imageNamed: @"Inspector-TitleBar"] retain];
	[bgImage setFlipped: YES];
	
	// Font to use for titles, etc
	titleFont = [[NSFont systemFontOfSize: 13] retain];
	titleHeight = [titleFont ascender] + [titleFont descender];
	titleHeight /= 2;
	
	// Font attributes
	NSShadow* shadow = nil;
	if (objc_lookUpClass("NSShadow") != nil) {
		shadow = [[NSShadow alloc] init];
		
		[shadow setShadowOffset:NSMakeSize(1, -2)];
		[shadow setShadowBlurRadius:2.5];
		[shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.75]];
		[shadow autorelease];
	}
	
	fontAttributes = [[NSDictionary dictionaryWithObjectsAndKeys: 
		titleFont, NSFontAttributeName,
		[NSColor colorWithDeviceWhite: 0.0 alpha: 0.6], NSForegroundColorAttributeName,
		shadow, IFNSShadowAttributeName,
		nil] retain];

}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		title = nil;
    }
    return self;
}

- (void) dealloc {
	[title release];
	
	if (keyEquiv) [keyEquiv release];
	[super dealloc];
}

// = What to display =

- (void) setTitle: (NSString*) newTitle {
	if (title) [title release];
	
	title = [[NSAttributedString alloc] initWithString: [[newTitle copy] autorelease]
											attributes: fontAttributes];
	
	[self setNeedsDisplay: YES];
}

- (void) setKeyEquivalent: (NSString*) equiv {
	if (keyEquiv) [keyEquiv release];
	keyEquiv = nil;
	if (equiv == nil || [equiv length] <= 0) return;
	
	static unichar returnChars[] = { 0x21a9 };
	static unichar escapeChars[] = { 0x238b };
	static unichar backspaceChars[] = { 0x232b };
	static unichar tabChars[] = { 0x21e5 };
	
	switch ([keyEquiv characterAtIndex: 0]) {
		case '\r':
		case '\n':
			keyEquiv = [[NSString stringWithCharacters: returnChars
												length: 1] retain];
			break;
			
		case '\b':
		case 127:
			keyEquiv = [[NSString stringWithCharacters: backspaceChars
												length: 1] retain];
			break;
			
		case 9:
			keyEquiv = [[NSString stringWithCharacters: tabChars
												length: 1] retain];
			break;
		
		case '\e':
			keyEquiv = [[NSString stringWithCharacters: escapeChars
												length: 1] retain];
			break;
			
		default:
			keyEquiv = [equiv copy];
	}
}

// No idea if Apple keeps constants indicating where these characters are *supposed* to be. Google and Xcode
// documentation are silent on this point.
#define CommandCharacter 0x2318
#define OptionCharacter 0x2325
#define ControlCharacter 0x2303
#define ShiftCharacter 0x21e7

- (void) setKeyEquivalentModifiers: (int) modifiers {
	
}

// = Drawing, etc =

- (void)drawRect:(NSRect)rect {
	// Fill with the background colour
	[[NSColor windowBackgroundColor] set];
	//NSRectFill(rect);
	
	float x = 0;
	NSRect imgRect;
	imgRect.origin = NSMakePoint(0,0);
	imgRect.size = [bgImage size];
	float w = imgRect.size.width;
	
	while (x < rect.origin.x) x += w;
	while (x < NSMaxX(rect)) {
		[bgImage drawAtPoint: NSMakePoint(x, 0)
					fromRect: imgRect
				   operation: NSCompositeSourceOver
					fraction: 1.0];
		x+=w;
	}
			
	// Draw the title text
	[title drawAtPoint: NSMakePoint(24, 5-titleHeight)];
}

- (BOOL) isFlipped {
	return YES;
}

- (BOOL) isOpaque {
	return NO;
}

- (NSView*) hitTest: (NSPoint) aPoint {
	// Is transparent to mouse clicks
	return nil;
}

@end
