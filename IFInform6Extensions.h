//
//  IFInform6Extensions.h
//  Inform
//
//  Created by Andrew Hunter on 12/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFSetting.h"

@interface IFInform6Extensions : IFSetting {
	// Data on what's available
	NSMutableArray* extensions;
}

// Meta-information about what to look for
- (NSArray*) directoriesToSearch;

// Searching the extensions
- (void) searchForExtensions;

@end
