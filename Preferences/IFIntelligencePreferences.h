//
//  IFIntelligencePreferences.h
//  Inform
//
//  Created by Andrew Hunter on 07/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFPreferencePane.h"

@interface IFIntelligencePreferences : IFPreferencePane {
	IBOutlet NSButton* enableSyntaxHighlighting;
	IBOutlet NSButton* indentWrappedLines;

	IBOutlet NSButton* enableIntelligence;
	IBOutlet NSButton* intelligenceIndexInspector;
	IBOutlet NSButton* indentAfterNewline;
	IBOutlet NSButton* autoNumberSections;
}

// Receiving data from/updating the interface
- (IBAction) setPreference: (id) sender;
- (void) reflectCurrentPreferences;

@end
