//
//  IFCollapsableView.h
//  Inform
//
//  Created by Andrew Hunter on 06/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IFCollapsableView : NSView {
	NSMutableArray* views;
	NSMutableArray* titles;
	NSMutableArray* states; // Booleans, indicating if this is shown or not
	
	BOOL rearranging;
	BOOL reiterate;
}

- (void) addSubview: (NSView*) subview
		  withTitle: (NSString*) title;
- (void) removeAllSubviews;
- (void) startRearranging;
- (void) finishRearranging;
- (void) rearrangeSubviews;
- (void) subviewFrameChanged: (NSNotification*) not;

@end
