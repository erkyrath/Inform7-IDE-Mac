//
//  IFInspectorView.h
//  Inform
//
//  Created by Andrew Hunter on Mon May 03 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "IFIsTitleView.h"
#import "IFIsArrow.h"

@interface IFInspectorView : NSView {
	NSView* innerView;
	
	IFIsTitleView* titleView;
	IFIsArrow*     arrow;
	
	BOOL willLayout;
}

// The view
- (void) setTitle: (NSString*) title;
- (void) setView: (NSView*) innerView;
- (NSView*) view;

- (void) queueLayout;
- (void) layoutViews;

@end
