//
//  IFBreadcrumbControl.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 20/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFBreadcrumbCell.h"

@interface IFBreadcrumbControl : NSControl {
	BOOL needsCalculation;
	NSMutableArray* cells;
	NSMutableArray* cellRects;
	
	IFBreadcrumbCell* selectedCell;
	float horizontalRatio;
	NSSize idealSize;
}

- (void) addBreadcrumbWithText: (NSString*) text						// Adds a breadcrumb item with the specified tag
						   tag: (int) tag;
- (void) removeAllBreadcrumbs;											// Clears this control

- (NSSize) idealSize;													// Returns the 'ideal' size of this control

@end
