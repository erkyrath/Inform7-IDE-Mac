//
//  IFIsArrow.h
//  Inform
//
//  Created by Andrew Hunter on Fri Apr 30 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>

// The InSpector arrow

@interface IFIsArrow : NSControl {

}

- (void) setOpen: (BOOL) open;
- (BOOL) open;

- (void) performFlip;

@end
