//
//  IFExtensionPreferences.h
//  Inform
//
//  Created by Andrew Hunter on 02/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFPreferencePane.h"

@interface IFExtensionPreferences : IFPreferencePane {
	// Connections to interface building
	IBOutlet NSOutlineView* naturalExtensionView;
	IBOutlet NSTableView* inform6ExtensionView;
}

// Actions
- (IBAction) addNaturalExtension: (id) sender;
- (IBAction) deleteNaturalExtension: (id) sender;

- (IBAction) addInform6Extension: (id) sender;
- (IBAction) deleteInform6Extension: (id) sender;

@end
