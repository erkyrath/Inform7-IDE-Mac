//
//  IFBreadcrumbCell.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 20/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import "IFBreadcrumbCell.h"

static NSImage* leftUnselect;
static NSImage* rightUnselect;
static NSImage* centerUnselect;
static NSImage* leftArrowUnselect;
static NSImage* rightArrowUnselect;

static NSImage* leftSelect;
static NSImage* rightSelect;
static NSImage* centerSelect;
static NSImage* leftArrowSelect;
static NSImage* rightArrowSelect;

@implementation IFBreadcrumbCell

// = Properties =

+ (BOOL)prefersTrackingUntilMouseUp {
	return YES;
}

+ (void) initialize {
	leftUnselect = [NSImage imageNamed: @"bc_lu"];
	rightUnselect = [NSImage imageNamed: @"bc_ru"];
	centerUnselect = [NSImage imageNamed: @"bc_cu"];
	leftArrowUnselect = [NSImage imageNamed: @"bc_alu"];
	rightArrowUnselect = [NSImage imageNamed: @"bc_aru"];

	leftSelect = [NSImage imageNamed: @"bc_ls"];
	rightSelect = [NSImage imageNamed: @"bc_rs"];
	centerSelect = [NSImage imageNamed: @"bc_cs"];
	leftArrowSelect = [NSImage imageNamed: @"bc_als"];
	rightArrowSelect = [NSImage imageNamed: @"bc_ars"];
}

// = Initialisation =

- (id) initTextCell: (NSString*) text {
	self = [super initTextCell: text];
	
	if (self) {
		[self setAttributedStringValue: 
			[[[NSAttributedString alloc] initWithString: text
											 attributes:
				[NSDictionary dictionaryWithObjectsAndKeys:
					[NSFont systemFontOfSize: 10], NSFontAttributeName,
					nil]] autorelease]];
	}
	
	return self;
}

// = Layout information =

- (float) overlap {
	if (!isRight) {
		return [leftArrowUnselect size].width;
	} else {
		return 0;
	}
}

- (void) setIsRight: (BOOL) ir {
	isRight = ir;
}

- (void) setIsLeft: (BOOL) il {
	isLeft = il;
}

// = NSCell overrides =

- (void) calcDrawInfo: (NSRect) bounds {
	float contentWidth;
	
	if ([self image] != nil) {
		contentWidth = [[self image] size].width;
	} else {
		contentWidth = [[self attributedStringValue] size].width;
	}
	
	NSImage* left = isLeft?leftUnselect:leftArrowUnselect;
	NSImage* right = isRight?rightUnselect:rightArrowUnselect;
	
	NSSize leftSize = [left size];
	NSSize rightSize = [right size];
	
	size.height = leftSize.height;
	size.width = leftSize.width + contentWidth + rightSize.width + 6;
}

- (NSSize) cellSize {
	return size;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame 
					   inView:(NSView *)controlView {
	NSImage* left;
	NSImage* right;
	NSImage* center;

	if ([self state] != NSOnState) {
		left = isLeft?leftUnselect:leftArrowUnselect;
		right = isRight?rightUnselect:rightArrowUnselect;
		center = centerUnselect;
	} else {
		left = isLeft?leftSelect:leftArrowSelect;
		right = isRight?rightSelect:rightArrowSelect;
		center = centerSelect;
	}
	
	NSSize leftSize = [left size];
	NSSize rightSize = [right size];
	NSSize centerSize = [center size];
	
	// Draw the leftmost image
	NSRect rect;
	NSRect source = NSMakeRect(0,0,0,0);
	rect.size = source.size = leftSize;
	rect.origin = cellFrame.origin;
	
	[left drawInRect: rect
			fromRect: source
		   operation: NSCompositeSourceOver
			fraction: 1.0];
	
	// Draw the centermost image
	source.size = centerSize;
	
	rect.origin = cellFrame.origin;
	rect.origin.x += leftSize.width;
	rect.size.width = cellFrame.size.width - leftSize.width - rightSize.width;
	rect.size.height = leftSize.height;
	
	[center drawInRect: rect
			  fromRect: source
			 operation: NSCompositeSourceOver
			  fraction: 1.0];
	
	// Draw the rightmost image
	rect.origin = cellFrame.origin;
	rect.origin.x += cellFrame.size.width - rightSize.width;
	rect.size = source.size = rightSize;
	
	[right drawInRect: rect
			 fromRect: source
			operation: NSCompositeSourceOver
			 fraction: 1.0];
	
	// Draw the text/image
	if ([self image]) {
	} else {
		NSSize textSize = [[self attributedStringValue] size];
		
		rect.origin.x = cellFrame.origin.x + leftSize.width + 3;
		rect.origin.y = (cellFrame.size.height - textSize.height + 1)/2 + cellFrame.origin.y;
		rect.size.width = cellFrame.size.width - leftSize.width - rightSize.width - 3;
		rect.size.height = textSize.height;
		
		[[self attributedStringValue] drawInRect: rect];
	}
}

- (BOOL) hitTest: (NSPoint) relativeToCell {
	// Technically, this is inaccurate, as we do not test on the right-hand side. However, as this is only ever
	// called for the left-hand side, this will be No Problem(tm)
	NSImage* hitImage = isLeft?leftUnselect:leftArrowUnselect;
	NSSize hitSize = [hitImage size];
	
	if (relativeToCell.x > hitSize.width) {
		return YES;
	}
	
	NSColor* hitColour;
	
	[hitImage lockFocus];
	hitColour = NSReadPixel(relativeToCell);
	[hitImage unlockFocus];
	
	return [hitColour alphaComponent] > 0.5;
}

@end
