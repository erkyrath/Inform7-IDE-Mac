//
//  IFPreferencePane.m
//  Inform
//
//  Created by Andrew Hunter on 01/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFPreferencePane.h"


@implementation IFPreferencePane


// Information about the preference window
- (NSImage*) toolbarImage {
	return nil;
}

- (NSString*) preferenceName {
	return @"Unnamed preference";
}

- (NSView*) preferenceView {
	return preferenceView;
}

@end
