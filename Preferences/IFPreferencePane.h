//
//  IFPreferencePane.h
//  Inform
//
//  Created by Andrew Hunter on 01/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IFPreferencePane : NSObject {
	IBOutlet NSView* preferenceView;
}

- (id) initWithNibName: (NSString*) nibName;

// Information about the preference window
- (NSImage*)  toolbarImage;
- (NSString*) preferenceName;
- (NSString*) identifier;
- (NSView*)   preferenceView;

@end
