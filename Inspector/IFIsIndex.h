//
//  IFIsIndex.h
//  Inform
//
//  Created by Andrew Hunter on Fri May 07 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>

#import "IFInspector.h"

extern NSString* IFIsIndexInspector;

@interface IFIsIndex : IFInspector {
	IBOutlet NSOutlineView* indexList;
	
	BOOL canDisplay;
	NSWindow* activeWindow;
	
	NSMutableArray* itemCache;
}

+ (IFIsIndex*) sharedIFIsIndex;

- (void) updateIndexFrom: (NSWindowController*) window;

@end
