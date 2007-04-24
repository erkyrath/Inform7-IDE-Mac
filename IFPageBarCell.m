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

+ (NSImage*) dropDownImage {
	NSImage* image = nil;
	
	if (!image) {
		image = [[NSImage imageNamed: @"BarMenuArrow"] retain];
	}
	
	return image;
}

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
				[[NSColor controlTextColor] colorWithAlphaComponent: 0.8], NSForegroundColorAttributeName,
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
		[self setImage: image];
	}
	
	return self;
}

- (void) dealloc {
	[menu release];
	
	[super dealloc];
}

// = Cell properties =

- (void) update {
	[(NSControl*)[self controlView] updateCell: self];
}

- (BOOL) isHighlighted {
	return isHighlighted;
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
		size.width += 4;
	} else if (text) {
		size = [text size];
	}
	
	if ([self isPopup]) {
		NSImage* dropDownArrow = [IFPageBarCell dropDownImage];
		size.width += [dropDownArrow size].width + 4;
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
	
	// Draw the background
	NSImage* backgroundImage = nil;
	
	if (isHighlighted) {
		backgroundImage = [IFPageBarView highlightedImage];
	} else if ([self state] == NSOnState) {
		backgroundImage = [IFPageBarView selectedImage];
	}
	
	if (backgroundImage) {
		IFPageBarView* view = (IFPageBarView*)[self controlView];
		NSRect backgroundBounds = [view bounds];
		backgroundBounds.size.width -= 9.0;
		
		NSRect backgroundFrame = cellFrame;
		if (isRight) {
			backgroundFrame.origin.x += 2;
			backgroundFrame.size.width -= 2;
		} else {
			backgroundFrame.size.width -= 1;			
		}

		[IFPageBarView drawOverlay: backgroundImage
							inRect: backgroundFrame
					   totalBounds: backgroundBounds
						  fraction: 1.0];
	}
	
	if ([self isPopup]) {
		// Draw the popup arrow
		NSImage* dropDownArrow = [IFPageBarCell dropDownImage];
		NSSize dropDownSize = [dropDownArrow size];
		
		NSRect dropDownRect = NSMakeRect(0,0, dropDownSize.width, dropDownSize.height);
		NSRect dropDownDrawRect;
		
		dropDownDrawRect.origin = NSMakePoint(NSMaxX(cellFrame) - dropDownSize.width - 2,
											  cellFrame.origin.y + (cellFrame.size.height+2-dropDownSize.height)/2);
		dropDownDrawRect.size = dropDownSize;
		
		[dropDownArrow drawInRect: dropDownDrawRect
						 fromRect: dropDownRect
						operation: NSCompositeSourceOver
						 fraction: 1.0];
		
		// Reduce the frame size
		cellFrame.size.width -= dropDownSize.width+4;
	}
	
	if (image) {
		// Draw the image
		NSSize imageSize = [image size];
		NSRect imageRect;
		
		imageRect.origin = NSMakePoint(cellFrame.origin.x + (cellFrame.size.width-imageSize.width)/2,
									   cellFrame.origin.y + (cellFrame.size.height+2-imageSize.height)/2);
		imageRect.size = imageSize;
		
		[image drawInRect: imageRect
				 fromRect: NSMakeRect(0,0, imageSize.width, imageSize.height)
				operation: NSCompositeSourceOver
				 fraction: 1.0];
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

// = Cell states =

- (int) nextState {
	// TODO: allow for push-on/push-off cells
	return NSOffState;
}

// = Acting as a pop-up =

- (BOOL) isPopup {
	if (menu) return YES;
	
	return NO;
}

- (void) showPopupAtPoint: (NSPoint) pointInWindow {
	if (menu) {
		[self setState: NSOnState];
		isHighlighted = NO;
		[self update];
		
		NSEvent* fakeEvent = [NSEvent mouseEventWithType: NSLeftMouseDown
												location: pointInWindow
										   modifierFlags: 0
											   timestamp: [[NSDate date] timeInterval]
											windowNumber: [[[self controlView] window] windowNumber]
												 context: [[[self controlView] window] graphicsContext]
											 eventNumber: 9999
											  clickCount: 0
												pressure: 1.0];
		
		[NSMenu popUpContextMenu: menu
					   withEvent: fakeEvent
						 forView: [self controlView]
						withFont: [NSFont systemFontOfSize: 11]];
		
		[self setState: NSOffState];
		[self update];
	}
}

- (void) setMenu: (NSMenu*) newMenu {
	[menu release];
	menu = [newMenu retain];
	[self update];
}

// = Tracking =

- (BOOL)trackMouse:(NSEvent *)theEvent
			inRect:(NSRect)cellFrame 
			ofView:(NSView *)controlView 
	  untilMouseUp:(BOOL)untilMouseUp {
	trackingFrame = cellFrame;
	
	return [super trackMouse: theEvent
					  inRect: cellFrame
					  ofView: controlView
				untilMouseUp: untilMouseUp];
}

- (BOOL)startTrackingAt: (NSPoint)startPoint 
				 inView: (NSView*)controlView {
	isHighlighted = YES;
	[self update];
	
	if ([self isPopup]) {
		NSRect winFrame = [[self controlView] convertRect: trackingFrame
												   toView: nil];
		[self showPopupAtPoint: NSMakePoint(NSMinX(winFrame), NSMaxY(winFrame))];
		
		isHighlighted = NO;
		[self update];
		
		return NO;
	}
	
	// TODO: if this is a menu or pop-up cell, only send the action when the user makes a selection
	// [self sendActionOn: 0];
	
	return YES;
}

- (BOOL)continueTracking:(NSPoint)lastPoint
					  at:(NSPoint)currentPoint 
				  inView:(NSView *)controlView {
	BOOL shouldBeHighlighted;
	
	shouldBeHighlighted = NSPointInRect(currentPoint, 
										trackingFrame);
	if (shouldBeHighlighted != isHighlighted) {
		isHighlighted = shouldBeHighlighted;
		[self update];
	}
	
	return YES;
}

- (void)stopTracking:(NSPoint)lastPoint 
				  at:(NSPoint)stopPoint
			  inView:(NSView *)controlView 
		   mouseIsUp:(BOOL)flag {
	isHighlighted = NO;
	[self update];

	return;
}

@end