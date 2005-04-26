//
//  IFInspectorPreferences.h
//  Inform
//
//  Created by Andrew Hunter on 02/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFPreferencePane.h"

@interface IFInspectorPreferences : IFPreferencePane {
	NSArray* inspectors;						// Maps tags to inspectors
	
	IBOutlet NSMatrix* activeInspectors;		// Matrix of active inspector buttons
}

// Receiving data from/updating the interface
- (IBAction) setPreference: (id) sender;
- (void) reflectCurrentPreferences;

@end
