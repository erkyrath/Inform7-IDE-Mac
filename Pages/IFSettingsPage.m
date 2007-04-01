//
//  IFSettingsPage.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFSettingsPage.h"


@implementation IFSettingsPage

// = Initialisation =

- (id) initWithProjectController: (IFProjectController*) controller {
	self = [super initWithNibName: @"Settings"
				projectController: controller];
	
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(updateSettings)
													 name: IFSettingNotification
												   object: [[parent document] settings]];
		
		[self updateSettings];
	}
	
	return self;
}

- (void) dealloc {
	[super dealloc];
}

// = Details about this view =

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Settings Page Title"
												  value: @"Settings"
												  table: nil];
}

// = Settings =

- (void) updateSettings {
	if (!parent) {
		return; // Nothing to do
	}
	
	[parent willNeedRecompile: nil];
	
	[settingsController setCompilerSettings: [[parent document] settings]];
	[settingsController updateAllSettings];
	
	return;
}

@end
