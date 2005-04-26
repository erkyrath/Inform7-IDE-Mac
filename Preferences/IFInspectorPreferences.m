//
//  IFInspectorPreferences.m
//  Inform
//
//  Created by Andrew Hunter on 02/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFInspectorPreferences.h"

#import "IFPreferences.h"

#import "IFIsNotes.h"
#import "IFIsIndex.h"
#import "IFIsFiles.h"
#import "IFIsSkein.h"
#import "IFIsWatch.h"
#import "IFIsBreakpoints.h"
#import "IFIsSearch.h"

@implementation IFInspectorPreferences

- (id) init {
	self = [super initWithNibName: @"InspectorPreferences"];
	
	if (self) {
		inspectors = [[NSArray arrayWithObjects: 
			[IFIsFiles sharedIFIsFiles], [IFIsNotes sharedIFIsNotes], [IFIsIndex sharedIFIsIndex], 
			[IFIsSkein sharedIFIsSkein], [IFIsWatch sharedIFIsWatch], [IFIsBreakpoints sharedIFIsBreakpoints], 
			[IFIsSearch sharedIFIsSearch], 
			nil] retain];
		
		[self reflectCurrentPreferences];

		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(reflectCurrentPreferences)
													 name: IFPreferencesDidChangeNotification
												   object: [IFPreferences sharedPreferences]];
	}
	
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[inspectors release];
	
	[super dealloc];
}

// = PreferencePane overrides =

- (NSString*) preferenceName {
	return @"Inspectors";
}

- (NSImage*) toolbarImage {
	return [NSImage imageNamed: @"Inspectors"];
}

// = Reflecting the current preference values =

- (void) reflectCurrentPreferences {
	IFPreferences* prefs = [IFPreferences sharedPreferences];
	
	// Tick all the active inspectors
	NSEnumerator* iEnum = [inspectors objectEnumerator];
	IFInspector* inspect;
	
	while (inspect = [iEnum nextObject]) {
		int tag = [inspectors indexOfObjectIdenticalTo: inspect];
		
		if (tag != NSNotFound) {
			BOOL shown = [prefs enableInspector: inspect];
			
			[[activeInspectors cellWithTag: tag] setState: shown?NSOnState:NSOffState];
		}
	}
}

- (IBAction) setPreference: (id) sender {
	IFPreferences* prefs = [IFPreferences sharedPreferences];
	
	// Annoyingly, even if we set individual cells actions, we end up being called with 'sender' set to the NSMatrix
	NSEnumerator* cEnum = [[activeInspectors cells] objectEnumerator];
	NSCell* cell;
	
	while (cell = [cEnum nextObject]) {
		int tag = [cell tag];
		
		if (tag < 0 || tag >= [inspectors count]) { 
			NSLog(@"BUG: Unknown inspector preference found");
			return;
		}
		
		IFInspector* inspect = [inspectors objectAtIndex: tag];
		BOOL shown = [cell state] == NSOnState;
		
		if (shown != [prefs enableInspector: inspect]) {
			[prefs setEnable: shown
				forInspector: inspect];
		}
	}
}

@end
