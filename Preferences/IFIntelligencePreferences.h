//
//  IFIntelligencePreferences.h
//  Inform
//
//  Created by Andrew Hunter on 07/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFPreferencePane.h"

//
// Preference pane that allows the user to manage how intelligent Inform is
//
@interface IFIntelligencePreferences : IFPreferencePane {
	IBOutlet NSButton* enableSyntaxHighlighting;
	IBOutlet NSButton* indentWrappedLines;

	IBOutlet NSButton* enableIntelligence;
	IBOutlet NSButton* intelligenceIndexInspector;
	IBOutlet NSButton* indentAfterNewline;
	IBOutlet NSButton* autoNumberSections;

	IBOutlet NSTextField* newGameName;					// The preferred name for new Natural Inform games
}

// Receiving data from/updating the interface
- (IBAction) setPreference: (id) sender;
- (void) reflectCurrentPreferences;

@end
