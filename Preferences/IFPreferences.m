//
//  IFPreferences.m
//  Inform
//
//  Created by Andrew Hunter on 02/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFPreferences.h"

NSString* IFPreferencesDidChangeNotification = @"IFPreferencesDidChangeNotification";
NSString* IFPreferencesChangedEarlierNotification = @"IFPreferencesChangedEarlierNotification";

NSString* IFPreferencesDefault = @"IFApplicationPreferences";

@implementation IFPreferences

// = Constructing the object =

+ (void) initialize {
	[[NSUserDefaults standardUserDefaults] registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys:
		[NSDictionary dictionary], IFPreferencesDefault,
		nil]];
}

+ (IFPreferences*) sharedPreferences {
	static IFPreferences* sharedPrefs = nil;
	
	if (!sharedPrefs) {
		sharedPrefs = [[IFPreferences alloc] init];
	}
	
	return sharedPrefs;
}

- (id) init {
	self = [super init];
	
	if (self) {
		preferences = [[[NSUserDefaults standardUserDefaults] objectForKey: IFPreferencesDefault] mutableCopy];
		
		if (!preferences || ![preferences isKindOfClass: [NSMutableDictionary class]]) {
			preferences = [[NSMutableDictionary alloc] init];
		}
		
		willNotifyLater = NO;
	}
	
	return self;
}

- (void) dealloc {
	[preferences release];
	
	[super dealloc];
}

// = Getting/setting the actual preferences =

- (void) preferencesHaveChanged {
	// Update the user defaults
	[[NSUserDefaults standardUserDefaults] setObject: [[preferences copy] autorelease]
											  forKey: IFPreferencesDefault];
	
	// Send a notification
	[[NSNotificationCenter defaultCenter] postNotificationName: IFPreferencesDidChangeNotification
														object: self];
	
	if (!willNotifyLater) {
		// Send a delayed notification in 10 seconds time. This makes it sensible to change preferences like
		// fonts that might take a long time to take effect.
		
		// FIXME: cancel this if this is called again before the timeout
		willNotifyLater = YES;
		[self performSelector: @selector(preferencesHaveChangedSomeTimeAgo)
				   withObject: nil
				   afterDelay: 10.0];
	}
}

- (void) preferencesHaveChangedSomeTimeAgo {
	[[NSNotificationCenter defaultCenter] postNotificationName: IFPreferencesChangedEarlierNotification
														object: self];
	willNotifyLater = NO;
}

// = Style preferences =

- (enum IFPreferencesFontSet) fontSet {
	NSNumber* fontSet = [preferences objectForKey: @"fontSet"];
	
	if (fontSet)
		return [fontSet intValue];
	else
		return IFFontSetStandard;
}

- (enum IFPreferencesFontStyling) fontStyling {
	NSNumber* fontStyling = [preferences objectForKey: @"fontStyling"];
	
	if (fontStyling)
		return [fontStyling intValue];
	else
		return IFStylingSubtle;
}

- (enum IFPreferencesColourChanges) changeColours {
	NSNumber* changeColours = [preferences objectForKey: @"changeColours"];
	
	if (changeColours)
		return [changeColours intValue];
	else
		return IFChangeColsOften;
}

- (enum IFPreferencesColourSet) colourSet {
	NSNumber* colourSet = [preferences objectForKey: @"colourSet"];
	
	if (colourSet)
		return [colourSet intValue];
	else
		return IFColoursStandard;
}

- (void) setFontSet: (enum IFPreferencesFontSet) newFontSet {
	[preferences setObject: [NSNumber numberWithInt: newFontSet]
					forKey: @"fontSet"];
	[self preferencesHaveChanged];
}

- (void) setFontStyling: (enum IFPreferencesFontStyling) newFontStyling {
	[preferences setObject: [NSNumber numberWithInt: newFontStyling]
					forKey: @"fontStyling"];
	[self preferencesHaveChanged];
}

- (void) setChangeColours: (enum IFPreferencesColourChanges) newChangeColours {
	[preferences setObject: [NSNumber numberWithInt: newChangeColours]
					forKey: @"changeColours"];
	[self preferencesHaveChanged];
}

- (void) setColourSet: (enum IFPreferencesColourSet) newColourSet {
	[preferences setObject: [NSNumber numberWithInt: newColourSet]
					forKey: @"colourSet"];
	[self preferencesHaveChanged];
}

@end
