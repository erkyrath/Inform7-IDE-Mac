//
//  IFOutputSettings.m
//  Inform
//
//  Created by Andrew Hunter on 10/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFOutputSettings.h"


@implementation IFOutputSettings

- (id) init {
	return [self initWithNibName: @"OutputSettings"];
}

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Output Settings"
												  value: @"Output Settings"
												  table: nil];
}

// = Setting up =

- (void) updateFromCompilerSettings: (IFCompilerSettings*) settings {
	// Supported Z-Machine versions
	NSArray* supportedZMachines = [settings supportedZMachines];
	
	NSEnumerator* cellEnum = [[zmachineVersion cells] objectEnumerator];
	NSCell* cell;
	
	while (cell = [cellEnum nextObject]) {
		if (supportedZMachines == nil) {
			[cell setEnabled: YES];
		} else {
			if ([supportedZMachines containsObject: [NSNumber numberWithInt: [cell tag]]]) {
				[cell setEnabled: YES];
			} else {
				[cell setEnabled: NO];
			}
		}
	}
	
	// Selected Z-Machine version
    if ([zmachineVersion cellWithTag: [settings zcodeVersion]] != nil) {
        [zmachineVersion selectCellWithTag: [settings zcodeVersion]];
    } else {
        [zmachineVersion deselectAllCells];
    }
}

- (void) setSettingsFor: (IFCompilerSettings*) settings {
	[settings setZCodeVersion: [[zmachineVersion selectedCell] tag]];
}

@end
