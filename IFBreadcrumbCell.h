//
//  IFBreadcrumbCell.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 20/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IFBreadcrumbCell : NSActionCell {
	BOOL isRight;
	BOOL isLeft;
	
	NSSize size;
}

// Layout information
- (float) overlap;								// The amount of overlap with the next cell

- (void) setIsRight: (BOOL) isRight;			// True if this is the rightmost cell
- (void) setIsLeft: (BOOL) isLeft;				// True if this is the leftmost cell

- (BOOL) hitTest: (NSPoint) relativeToCell;		// True if the specified point (relative to this cell's origin) is within the cell

@end
