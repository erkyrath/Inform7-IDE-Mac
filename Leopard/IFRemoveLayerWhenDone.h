//
//  IFRemoveLayerWhenDone.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 17/02/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreAnimation.h>


@interface IFRemoveLayerWhenDone : NSObject {
	NSView* view;										// The view to remove when the animation finishes
}

- (id) initWithView: (NSView*) view;

@end
