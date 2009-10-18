//
//  IFAuthorPreferences.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 18/10/2009.
//  Copyright 2009 Andrew Hunter. All rights reserved.
//

#import "IFAuthorPreferences.h"

#import "IFPreferences.h"


@implementation IFAuthorPreferences

- (id) init {
	self = [super initWithNibName: @"AuthorPreferences"];
	
	if (self) {
		[self reflectCurrentPreferences];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(reflectCurrentPreferences)
													 name: IFPreferencesDidChangeNotification
												   object: [IFPreferences sharedPreferences]];
	}
	
	return self;
}

// = Setting ourselves up =

- (void) reflectCurrentPreferences {
	IFPreferences* prefs = [IFPreferences sharedPreferences];

	[newGameName setStringValue: [prefs newGameAuthorName]];
}

- (IBAction) setPreference: (id) sender {
	IFPreferences* prefs = [IFPreferences sharedPreferences];
	
	if (sender == newGameName) [prefs setNewGameAuthorName: [newGameName stringValue]];
}

// = PreferencePane overrides =

- (NSString*) preferenceName {
	return @"Author";
}

- (NSImage*) toolbarImage {
	NSImage* image = [NSImage imageNamed: @"NSUser"];
	if (!image) image = [NSImage imageNamed: @"Inform"];
	return image;
}

- (NSString*) tooltip {
	return [[NSBundle mainBundle] localizedStringForKey: @"Intelligence preferences tooltip"
												  value: @"Intelligence preferences tooltip"
												  table: nil];
}

@end
