//
//  IFIsTitleView.h
//  Inform
//
//  Created by Andrew Hunter on Mon May 03 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface IFIsTitleView : NSView {
	NSAttributedString* title;
	
	NSString* keyEquiv;
	NSString* modifiers;
}

- (void) setTitle: (NSString*) title;

@end
