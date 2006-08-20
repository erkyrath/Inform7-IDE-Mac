//
//  IFStylePreferences.h
//  Inform
//
//  Created by Andrew Hunter on 01/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFPreferencePane.h"

#import "IFSyntaxStorage.h"

//
// Preference pane that allows the user to select the styles she wants to see
//
@interface IFStylePreferences : IFPreferencePane {
	IBOutlet NSPopUpButton* fontSet;
	IBOutlet NSPopUpButton* fontStyle;
	IBOutlet NSPopUpButton* fontSize;
	IBOutlet NSPopUpButton* changeColours;
	IBOutlet NSPopUpButton* colourSet;
	IBOutlet NSSlider* tabStopSlider;
	IBOutlet NSTextView* previewView;
	IBOutlet NSTextView* tabStopView;
	
	IFSyntaxStorage* previewStorage;
	IFSyntaxStorage* tabStopStorage;
}

// Receiving data from/updating the interface
- (IBAction) styleSetHasChanged: (id) sender;
- (void) reflectCurrentPreferences;

@end
