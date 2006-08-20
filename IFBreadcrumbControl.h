//
//  IFBreadcrumbControl.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 20/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IFBreadcrumbControl : NSControl {
	NSMutableArray* cells;
	NSMutableArray* cellRects;
}

- (void) addBreadcrumbWithText: (NSString*) text						// Adds a breadcrumb item with the specified tag
						   tag: (int) tag;

@end
