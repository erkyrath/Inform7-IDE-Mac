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

@interface IFStylePreferences : IFPreferencePane {
	IBOutlet NSPopUpButton* fontSet;
	IBOutlet NSPopUpButton* fontStyle;
	IBOutlet NSPopUpButton* changeColours;
	IBOutlet NSPopUpButton* colourSet;
	IBOutlet NSTextView* previewView;
	
	IFSyntaxStorage* previewStorage;
}

// Receiving data from/updating the interface
- (IBAction) styleSetHasChanged: (id) sender;
- (void) reflectCurrentPreferences;

@end
