//
//  IFHeaderView.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 02/01/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFHeader.h"
#import "IFHeaderController.h"

///
/// View used to allow the user to restrict the section of the source file that they are
/// browsing
///
@interface IFHeaderView : NSView {
	int displayDepth;														// The display depth for this view
	IFHeader* rootHeader;													// The root header that this view should display
}

- (int) displayDepth;														// Retrieves the display depth for this view
- (void) setDisplayDepth: (int) displayDepth;								// Sets the display depth for this view

@end
