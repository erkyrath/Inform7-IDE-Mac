//
//  IFAppDelegate.h
//  Inform
//
//  Created by Andrew Hunter on Mon Aug 18 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

// Application delegate class

#import <Cocoa/Cocoa.h>


@interface IFAppDelegate : NSObject {
	BOOL haveWebkit;
}

+ (BOOL)isWebKitAvailable;
- (BOOL)isWebKitAvailable;

@end
