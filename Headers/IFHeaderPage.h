//
//  IFHeaderPage.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 02/01/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFHeaderView.h"

///
/// Controller object that manages the headers page
///
@interface IFHeaderPage : NSObject {
	IBOutlet NSView* pageView;								// The main header page view
	IBOutlet IFHeaderView* headerView;						// The header view that this object is managing
	IBOutlet NSSlider* depthSlider;							// The header depth slider
	
	IFHeaderController* controller;							// The header controller that this page is using
}

- (NSView*) pageView;										// The view that should be used to display the headers being managed by this class
- (void) setController: (IFHeaderController*) controller;	// Specifies the header controller that should be used to manage updates to this page

- (IBAction) updateDepthSlider: (id) sender;				// Message sent when the depth slider is changed

@end