//
//  IFSetting.h
//  Inform
//
//  Created by Andrew Hunter on 06/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IFSetting : NSObject {
	NSView* settingView;
}

- (id) initWithNibName: (NSString*) nibName;

// Setting up the view
- (NSView*) settingView;
- (IBOutlet) setSettingView: (NSView*) settingView;

@end
