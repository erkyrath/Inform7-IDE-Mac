//
//  IFPreferenceController.h
//  Inform
//
//  Created by Andrew Hunter on 12/01/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFPreferencePane.h"

///
/// Preferences are different from settings (settings are per-project, preferences are global)
/// There's some overlap, though. In particular, installed extensions is global, but can be
/// controlled from an individual project's Settings as well as overall.
///
@interface IFPreferenceController : NSWindowController {
	// The toolbar
	NSToolbar* preferenceToolbar;
	NSMutableArray* preferenceViews;
	NSMutableDictionary* toolbarItems;
}

// Construction, etc
+ (IFPreferenceController*) sharedPreferenceController;

// Adding new preference views
- (void) addPreferencePane: (IFPreferencePane*) newPane;

// Choosing a preference pane
- (void) switchToPreferencePane: (NSString*) paneIdentifier;

@end
