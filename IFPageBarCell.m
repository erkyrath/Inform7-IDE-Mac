//
//  IFPageBarCell.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 06/04/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFPageBarCell.h"
#import "IFPageBarView.h"

@implementation IFPageBarCell

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
	}
	
	return self;
}

- (id) initTextCell: (NSString*) text {
	self = [self init];
	
	if (self) {
		NSAttributedString* attrText = [[NSAttributedString alloc] initWithString: text
																	   attributes: 
			[NSDictionary dictionaryWithObjectsAndKeys: 
				[[NSColor controlTextColor] colorWithAlphaComponent: 1.0], NSForegroundColorAttributeName,
				[NSColor clearColor], NSBackgroundColorAttributeName,
				[NSFont systemFontOfSize: 11], NSFontAttributeName,
				nil]];
		
		[self setAttributedStringValue: attrText];
		[attrText release];
	}
	
	return self;
}

- (id) initImageCell: (NSImage*) image {
	self = [self init];
	
	if (self) {
		
	}
	
	return self;
}

// = Sizing and rendering =

- (void) setIsRight: (BOOL) newIsRight {
	isRight = newIsRight;
}

- (NSSize) cellSize {
	NSSize size = NSZeroSize;

	// Work out the minimum size required to contain the text or the image
	NSImage* image = [self image];
	NSAttributedString* text = [self attributedStringValue];
	
	if (image) {
		size = [image size];
	} else if (text) {
		size = [text size];
	}
	
	// Add a border for the margins
	size.width += 8;
	size.width = floorf(size.width+0.5);
	size.height = floorf(size.height);
	
	return size;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame 
					   inView:(NSView *)controlView {
	NSImage* image = [self image];
	NSAttributedString* text = [self attributedStringValue];
	
#if 0
	// Draw the background
	IFPageBarView* view = (IFPageBarView*)[self controlView];
	NSRect backgroundBounds = [view bounds];
	backgroundBounds.size.width -= 13.0;

	[IFPageBarView drawOverlay: [IFPageBarView normalImage]
						inRect: cellFrame
				   totalBounds: backgroundBounds
					  fraction: 1.0];
#endif
	
	if (image) {
		// TODO: draw the image
	} else if (text) {
		// Draw the text
		NSSize textSize = [text size];
		NSPoint textPoint = NSMakePoint(cellFrame.origin.x + (cellFrame.size.width-textSize.width)/2,
										cellFrame.origin.y + (cellFrame.size.height+2-textSize.height)/2);
		
		if (isRight) textPoint.x += 2;

		NSRect textRect;
		textRect.origin = textPoint;
		textRect.size = textSize;
		
		[text drawInRect: NSIntegralRect(textRect)];
	}
}

@end
