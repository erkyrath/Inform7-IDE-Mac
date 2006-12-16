//
//  IFPreferences.m
//  Inform
//
//  Created by Andrew Hunter on 02/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFPreferences.h"

#import "IFProjectPane.h"

NSString* IFPreferencesDidChangeNotification = @"IFPreferencesDidChangeNotification";
NSString* IFPreferencesChangedEarlierNotification = @"IFPreferencesChangedEarlierNotification";

NSString* IFPreferencesDefault = @"IFApplicationPreferences";

NSString* IFPreferencesBaseFont = @"IFPreferencesBaseFont";
NSString* IFPreferencesBoldFont = @"IFPreferencesBoldFont";
NSString* IFPreferencesItalicFont = @"IFPreferencesItalicFont";
NSString* IFPreferencesHeaderFont = @"IFPreferencesHeaderFont";
NSString* IFPreferencesCommentFont = @"IFPreferencesCommentFont";

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
		
		[self recalculateStyles];
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
	
	[self recalculateStyles];
	
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
				   afterDelay: 2.0];
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

- (float) fontSize {
	NSNumber* fontSize = [preferences objectForKey: @"fontSize"];
	
	if (fontSize)
		return [fontSize floatValue];
	else
		return 1.0;
}

- (float) tabWidth {
	NSNumber* tabWidth = [preferences objectForKey: @"tabWidth"];
	
	if (tabWidth)
		return [tabWidth floatValue];
	else
		return 56.0;
}

- (void) setTabWidth: (float) newTabWidth {
	[preferences setObject: [NSNumber numberWithInt: newTabWidth]
					forKey: @"tabWidth"];
	[self preferencesHaveChanged];
}

- (void) setFontSize: (float) multiplier {
	[preferences setObject: [NSNumber numberWithFloat: multiplier]
					forKey: @"fontSize"];
	[self preferencesHaveChanged];
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

- (NSFont*) fontWithName: (NSString*) name
					size: (float) size {
	NSFont* result = [NSFont fontWithName: name
									 size: size];
	
	if (result == nil) {
		result = [NSFont systemFontOfSize: size];
		NSLog(@"Warning: could not find font '%@'", name);
	}
	
	return result;
}

- (void) recalculateStyles {
	int x;
	
	// Deallocate the caches if they're currently allocated
	if (cacheFontSet)	 [cacheFontSet release];
	if (cacheFontStyles) [cacheFontStyles release];
	if (cacheColourSet)  [cacheColourSet release];
	if (cacheColours)	 [cacheColours release];
	
	if (styles)			 [styles release];
	
	// Allocate the caches
	float fontSize = [self fontSize];
	
	cacheFontSet	= nil;
	cacheFontStyles	= nil;
	cacheColourSet	= nil;
	cacheColours	= nil;
	
	styles			= [[NSMutableDictionary alloc] init];
	
	// Get the fonts to use
	switch ([self fontSet]) {
		default:
		case IFFontSetStandard:
			cacheFontSet = [[NSMutableDictionary dictionaryWithObjectsAndKeys: 
				[NSFont systemFontOfSize: 11*fontSize], IFPreferencesBaseFont,
				[NSFont boldSystemFontOfSize: 11*fontSize], IFPreferencesBoldFont,
				[NSFont systemFontOfSize: 10*fontSize], IFPreferencesItalicFont,
				[NSFont boldSystemFontOfSize: 9*fontSize],  IFPreferencesCommentFont,
				[NSFont boldSystemFontOfSize: 12*fontSize], IFPreferencesHeaderFont,
				nil]
				retain];
			break;
			
		case IFFontSetProgrammer:
			cacheFontSet = [[NSMutableDictionary dictionaryWithObjectsAndKeys: 
				[self fontWithName: @"Monaco" size: 10*fontSize], IFPreferencesBaseFont,
				[self fontWithName: @"Monaco" size: 10*fontSize], IFPreferencesBoldFont,
				[self fontWithName: @"Monaco" size: 9*fontSize], IFPreferencesItalicFont,
				[self fontWithName: @"Monaco" size: 9*fontSize], IFPreferencesCommentFont,
				[self fontWithName: @"Helvetica Bold" size: 12*fontSize], IFPreferencesHeaderFont,
				nil]
				retain];
			break;
			
		case IFFontSetStylised:
			cacheFontSet = [[NSMutableDictionary dictionaryWithObjectsAndKeys: 
				[self fontWithName: @"Gill Sans" size: 12*fontSize], IFPreferencesBaseFont,
				[self fontWithName: @"Gill Sans Bold" size: 12*fontSize], IFPreferencesBoldFont,
				[self fontWithName: @"Gill Sans Italic" size: 10*fontSize], IFPreferencesCommentFont,
				[self fontWithName: @"Gill Sans Italic" size: 12*fontSize], IFPreferencesItalicFont,
				[self fontWithName: @"Gill Sans Bold Italic" size: 14*fontSize], IFPreferencesHeaderFont,
				nil]
				retain];
			break;
	}
	
	// Map font styles to syntax styles
	cacheFontStyles = [[NSMutableArray alloc] init];
	
	// Default is just the base font
	NSFont* baseFont = [cacheFontSet objectForKey: IFPreferencesBaseFont];
	for (x=0; x<256; x++) {
		[cacheFontStyles addObject: baseFont];
	}
	
	switch ([self fontStyling]) {
		default:
		case IFStylingSubtle:
			// Header, comment and bold fonts are allowed
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxComment
									   withObject: [cacheFontSet objectForKey: IFPreferencesCommentFont]];
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxProperty
									   withObject: [cacheFontSet objectForKey: IFPreferencesBoldFont]];
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxAssembly
									   withObject: [cacheFontSet objectForKey: IFPreferencesBoldFont]];
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxEscapeCharacter
									   withObject: [cacheFontSet objectForKey: IFPreferencesBoldFont]];
			
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxGameText
									   withObject: [cacheFontSet objectForKey: IFPreferencesBoldFont]];
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxHeading
									   withObject: [cacheFontSet objectForKey: IFPreferencesHeaderFont]];
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxTitle
									   withObject: [cacheFontSet objectForKey: IFPreferencesHeaderFont]];
			break;
			
		case IFStylingNone:
			// Nothing to do
			break;
			
		case IFStylingOften:
			// Italic font is also allowed now
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxComment
									   withObject: [cacheFontSet objectForKey: IFPreferencesCommentFont]];
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxProperty
									   withObject: [cacheFontSet objectForKey: IFPreferencesBoldFont]];
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxAssembly
									   withObject: [cacheFontSet objectForKey: IFPreferencesBoldFont]];
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxEscapeCharacter
									   withObject: [cacheFontSet objectForKey: IFPreferencesBoldFont]];
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxFunction
									   withObject: [cacheFontSet objectForKey: IFPreferencesItalicFont]];
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxCode
									   withObject: [cacheFontSet objectForKey: IFPreferencesItalicFont]];
			
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxGameText
									   withObject: [cacheFontSet objectForKey: IFPreferencesBoldFont]];
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxHeading
									   withObject: [cacheFontSet objectForKey: IFPreferencesHeaderFont]];
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxTitle
									   withObject: [cacheFontSet objectForKey: IFPreferencesHeaderFont]];
			[cacheFontStyles replaceObjectAtIndex: IFSyntaxSubstitution
									   withObject: [cacheFontSet objectForKey: IFPreferencesItalicFont]];
			break;
	}
	
	// The set of allowable colours
	cacheColourSet = [[NSMutableArray alloc] init];
	
	// Default is black
	NSColor* black = [NSColor blackColor];
	for (x=0; x<256; x++) {
		[cacheColourSet addObject: black];
	}
	
	switch ([self colourSet]) {
		default:
		case IFColoursStandard:
			// Standard colour set
			[cacheColourSet replaceObjectAtIndex: IFSyntaxString
									  withObject: [NSColor colorWithDeviceRed: 0.53
																		green: 0.08
																		 blue: 0.08 
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxComment
									  withObject: [NSColor colorWithDeviceRed: 0.14
																		green: 0.43
																		 blue: 0.14 
																		alpha: 1.0]];
			
			// Inform 6
			[cacheColourSet replaceObjectAtIndex: IFSyntaxDirective
									  withObject: [NSColor colorWithDeviceRed: 0.20
																		green: 0.08
																		 blue: 0.53 
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxProperty
									  withObject: [NSColor colorWithDeviceRed: 0.08
																		green: 0.08
																		 blue: 0.53 
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxFunction
									  withObject: [NSColor colorWithDeviceRed: 0.08
																		green: 0.53
																		 blue: 0.53 
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxCode
									  withObject: [NSColor colorWithDeviceRed: 0.46
																		green: 0.06
																		 blue: 0.31 
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxAssembly
									  withObject: [NSColor colorWithDeviceRed: 0.46
																		green: 0.31
																		 blue: 0.31 
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxCodeAlpha
									  withObject: [NSColor colorWithDeviceRed: 0.4
																		green: 0.4
																		 blue: 0.3
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxEscapeCharacter
									  withObject: [NSColor colorWithDeviceRed: 0.4
																		green: 0.4
																		 blue: 0.3
																		alpha: 1.0]];
			
			// Inform 7
			[cacheColourSet replaceObjectAtIndex: IFSyntaxGameText
									  withObject: [NSColor colorWithDeviceRed: 0.0
																		green: 0.3
																		 blue: 0.6
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxSubstitution
									  withObject: [NSColor colorWithDeviceRed: 0.3
																		green: 0.3
																		 blue: 1.0
																		alpha: 1.0]];
			break;
			
		case IFColoursSubdued:
			// As for standard, but blacker
			[cacheColourSet replaceObjectAtIndex: IFSyntaxString
									  withObject: [NSColor colorWithDeviceRed: 0.25
																		green: 0.04
																		 blue: 0.04 
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxComment
									  withObject: [NSColor colorWithDeviceRed: 0.07
																		green: 0.2
																		 blue: 0.07 
																		alpha: 1.0]];
			
			// Inform 6
			[cacheColourSet replaceObjectAtIndex: IFSyntaxDirective
									  withObject: [NSColor colorWithDeviceRed: 0.10
																		green: 0.04
																		 blue: 0.25 
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxProperty
									  withObject: [NSColor colorWithDeviceRed: 0.04
																		green: 0.04
																		 blue: 0.25 
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxFunction
									  withObject: [NSColor colorWithDeviceRed: 0.04
																		green: 0.25
																		 blue: 0.25 
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxCode
									  withObject: [NSColor colorWithDeviceRed: 0.23
																		green: 0.03
																		 blue: 0.15 
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxAssembly
									  withObject: [NSColor colorWithDeviceRed: 0.23
																		green: 0.15
																		 blue: 0.15 
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxCodeAlpha
									  withObject: [NSColor colorWithDeviceRed: 0.2
																		green: 0.2
																		 blue: 0.15
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxEscapeCharacter
									  withObject: [NSColor colorWithDeviceRed: 0.2
																		green: 0.2
																		 blue: 0.15
																		alpha: 1.0]];
			
			// Inform 7
			[cacheColourSet replaceObjectAtIndex: IFSyntaxGameText
									  withObject: [NSColor colorWithDeviceRed: 0.0
																		green: 0.15
																		 blue: 0.3
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxSubstitution
									  withObject: [NSColor colorWithDeviceRed: 0.15
																		green: 0.15
																		 blue: 0.5
																		alpha: 1.0]];
			break;
			
		case IFColoursPsychedlic:
			// Primary colours only
			[cacheColourSet replaceObjectAtIndex: IFSyntaxString
									  withObject: [NSColor blueColor]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxComment
									  withObject: [NSColor colorWithDeviceRed: 0
																		green: 0.8
																		 blue: 0
																		alpha: 1.0]];
			
			// Inform 6
			[cacheColourSet replaceObjectAtIndex: IFSyntaxDirective
									  withObject: [NSColor colorWithDeviceRed: 0.5
																		green: 0.0
																		 blue: 1.0 
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxProperty
									  withObject: [NSColor colorWithDeviceRed: 0.0
																		green: 0.5
																		 blue: 1.0
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxFunction
									  withObject: [NSColor colorWithDeviceRed: 0.0
																		green: 0.7
																		 blue: 0.7 
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxCode
									  withObject: [NSColor colorWithDeviceRed: 0.8
																		green: 0.3
																		 blue: 0 
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxAssembly
									  withObject: [NSColor colorWithDeviceRed: 1.0
																		green: 0
																		 blue: 0
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxCodeAlpha
									  withObject: [NSColor colorWithDeviceRed: 0
																		green: 0
																		 blue: 0
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxEscapeCharacter
									  withObject: [NSColor colorWithDeviceRed: 0.0
																		green: 0.0
																		 blue: 1.0
																		alpha: 1.0]];
			
			// Inform 7
			[cacheColourSet replaceObjectAtIndex: IFSyntaxGameText
									  withObject: [NSColor colorWithDeviceRed: 0.0
																		green: 0.0
																		 blue: 1.0
																		alpha: 1.0]];
			[cacheColourSet replaceObjectAtIndex: IFSyntaxSubstitution
									  withObject: [NSColor colorWithDeviceRed: 1.0
																		green: 0
																		 blue: 1.0
																		alpha: 1.0]];
			break;
	}
	
	// The set of used colours
	switch ([self changeColours]) {
		case IFChangeColsOften:
			// Colours are the complete set
			cacheColours = [cacheColourSet mutableCopy];
			break;
			
		case IFChangeColsRarely:
			// Colours are not quite the complete set
			cacheColours = [cacheColourSet mutableCopy];
			
			// Code colours are all the same
			NSColor* codeColour = [[[cacheColourSet objectAtIndex: IFSyntaxCodeAlpha] retain] autorelease];
			[cacheColours replaceObjectAtIndex: IFSyntaxCode
									withObject: codeColour];
			[cacheColours replaceObjectAtIndex: IFSyntaxCodeAlpha
									withObject: codeColour];
			[cacheColours replaceObjectAtIndex: IFSyntaxAssembly
									withObject: codeColour];
			
			[cacheColours replaceObjectAtIndex: IFSyntaxProperty
									withObject: [cacheColourSet objectAtIndex: IFSyntaxDirective]];
			
			// Substitutions aren't highlighted
			[cacheColours replaceObjectAtIndex: IFSyntaxSubstitution
									withObject: [cacheColourSet objectAtIndex: IFSyntaxGameText]];
			break;
			
		case IFChangeColsNever:
			// You can have any colour so long as it's black
			cacheColours = [[NSMutableArray alloc] init];
			
			NSColor* black = [NSColor blackColor];
			for (x=0; x<256; x++) {
				[cacheColours addObject: black];
			}
			break;
	}
	
#if 0
	// Natural Inform tab stops
	NSMutableParagraphStyle* tabStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[tabStyle autorelease];
	
	NSMutableArray* tabStops = [NSMutableArray array];
	for (x=0; x<48; x++) {
		NSTextTab* tab = [[NSTextTab alloc] initWithType: NSLeftTabStopType
												location: 64.0*(x+1)];
		[tabStops addObject: tab];
		[tab release];
	}
	[tabStyle setTabStops: tabStops];
#endif
	
	// Finally... build the actual set of styles
	styles = [[NSMutableArray alloc] init];
	
	for (x=0; x<256; x++) {
		[styles addObject:
			[NSDictionary dictionaryWithObjectsAndKeys: 
				[cacheFontStyles objectAtIndex: x], NSFontAttributeName,
				[cacheColours objectAtIndex: x], NSForegroundColorAttributeName,
				//x>=0x80?tabStyle:nil, NSParagraphStyleAttributeName,
				nil]];
	}
}

- (NSArray*) styles {
	return styles;
}

// Inspector preferences
- (BOOL) enableInspector: (IFInspector*) inspector {
	NSDictionary* dict = [preferences objectForKey: @"enableInspector"];
	NSNumber* value = [dict objectForKey: [inspector key]];
	
	if (!value) return YES;
	
	return [value boolValue];
}

- (void) setEnable: (BOOL) enable
	  forInspector: (IFInspector*) inspector {
	NSDictionary* dict = [preferences objectForKey: @"enableInspector"];
	NSMutableDictionary* mutDict;
	
	// Make dict mutable if necessary
	mutDict = [[dict mutableCopy] autorelease];
	
	if (mutDict == nil) mutDict = [NSMutableDictionary dictionary];
	
	// Set the value for the inspector
	[mutDict setObject: [NSNumber numberWithBool: enable]
				forKey: [inspector key]];
	
	// Update the preferences
	[preferences setObject: mutDict
					forKey: @"enableInspector"];
	[self preferencesHaveChanged];
}

// = Intelligence preferences =

- (BOOL) enableSyntaxHighlighting {
	NSNumber* value = [preferences objectForKey: @"enableSyntaxHighlighting"];
	
	if (value)
		return [value boolValue];
	else
		return YES;
}

- (BOOL) indentWrappedLines {
	NSNumber* value = [preferences objectForKey: @"indentWrappedLines"];
	
	if (![self enableSyntaxHighlighting]) return NO;
	
	if (value)
		return [value boolValue];
	else
		return YES;
}

- (BOOL) enableIntelligence {
	NSNumber* value = [preferences objectForKey: @"enableIntelligence"];
	
	if (![self enableSyntaxHighlighting]) return NO;
	
	if (value)
		return [value boolValue];
	else
		return YES;
}

- (BOOL) intelligenceIndexInspector {
	NSNumber* value = [preferences objectForKey: @"intelligenceIndexInspector"];
	
	if (![self enableIntelligence]) return NO;
	
	if (value)
		return [value boolValue];
	else
		return YES;
}

- (BOOL) indentAfterNewline {
	NSNumber* value = [preferences objectForKey: @"indentAfterNewline"];
	
	if (![self enableIntelligence]) return NO;
	
	if (value)
		return [value boolValue];
	else
		return YES;
}

- (BOOL) autoNumberSections {
	NSNumber* value = [preferences objectForKey: @"autoNumberSections"];
	
	if (![self enableIntelligence]) return NO;
	
	if (value)
		return [value boolValue];
	else
		return NO;
}

- (NSString*) longUserName {
	NSString* longuserName = NSFullUserName();
	if ([longuserName length] == 0 || longuserName == nil) longuserName = NSUserName();
	if ([longuserName length] == 0 || longuserName == nil) longuserName = @"Unknown Author";
	
	return longuserName;
}

- (NSString*) newGameAuthorName {
	NSString* value = [preferences objectForKey: @"newGameAuthorName"];
	
	value = [value stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
	
	if (value == nil || [value isEqualToString: @""]) {
		// Use the current OS X user name
		return [self longUserName];
	} else {
		// Use the specified value
		return [[value copy] autorelease];
	}
}


- (void) setEnableSyntaxHighlighting: (BOOL) value {
	[preferences setObject: [NSNumber numberWithBool: value]
					forKey: @"enableSyntaxHighlighting"];
	
	[self preferencesHaveChanged];
}

- (void) setIndentWrappedLines: (BOOL) value {
	[preferences setObject: [NSNumber numberWithBool: value]
					forKey: @"indentWrappedLines"];
	
	[self preferencesHaveChanged];
}

- (void) setEnableIntelligence: (BOOL) value {
	[preferences setObject: [NSNumber numberWithBool: value]
					forKey: @"enableIntelligence"];
	
	[self preferencesHaveChanged];
}

- (void) setIntelligenceIndexInspector: (BOOL) value {
	[preferences setObject: [NSNumber numberWithBool: value]
					forKey: @"intelligenceIndexInspector"];
	
	[self preferencesHaveChanged];
}

- (void) setIndentAfterNewline: (BOOL) value {
	[preferences setObject: [NSNumber numberWithBool: value]
					forKey: @"indentAfterNewline"];
	
	[self preferencesHaveChanged];
}

- (void) setAutoNumberSections: (BOOL) value {
	[preferences setObject: [NSNumber numberWithBool: value]
					forKey: @"autoNumberSections"];
	
	[self preferencesHaveChanged];
}

- (void) setNewGameAuthorName: (NSString*) value {
	if ([[value lowercaseString] isEqualToString: [[self longUserName] lowercaseString]]) {
		// Special case: if the user enters their own username, we go back to tracking that
		value = @"";
	}
	
	[preferences setObject: [[value copy] autorelease]
					forKey: @"newGameAuthorName"];
	
	[self preferencesHaveChanged];
}

// = Skein preferences =

- (float) skeinSpacingHoriz {
	if ([preferences objectForKey: @"skeinSpacingHoriz"] == nil) {
		return 120.0;
	}
	
	return [[preferences objectForKey: @"skeinSpacingHoriz"] floatValue];
}

- (float) skeinSpacingVert {
	if ([preferences objectForKey: @"skeinSpacingVert"] == nil) {
		return 96.0;
	}
	
	return [[preferences objectForKey: @"skeinSpacingVert"] floatValue];	
}

- (void) setSkeinSpacingHoriz: (float) value {
	if (floorf(value) == floorf([self skeinSpacingHoriz])) return;
	
	[preferences setObject: [NSNumber numberWithFloat: value]
					forKey: @"skeinSpacingHoriz"];
	
	[self preferencesHaveChanged];
}

- (void) setSkeinSpacingVert: (float) value {
	if (floorf(value) == floorf([self skeinSpacingVert])) return;
	
	[preferences setObject: [NSNumber numberWithFloat: value]
					forKey: @"skeinSpacingVert"];
	
	[self preferencesHaveChanged];	
}

// = Advanced preferences =

- (BOOL) runBuildSh {
	NSNumber* value = [preferences objectForKey: @"runBuildSh"];
	
	if (value)
		return [value boolValue];
	else
		return NO;
}

- (BOOL) showDebuggingLogs {
	NSNumber* value = [preferences objectForKey: @"showDebuggingLogs"];
	
	if (value)
		return [value boolValue];
	else
		return NO;
}

- (BOOL) cleanProjectOnClose {
	NSNumber* value = [preferences objectForKey: @"cleanProjectOnClose"];
	
	if (value)
		return [value boolValue];
	else
		return YES;
}

- (BOOL) alsoCleanIndexFiles {
	NSNumber* value = [preferences objectForKey: @"alsoCleanIndexFiles"];
	
	if (value)
		return [value boolValue];
	else
		return NO;
}

- (void) setCleanProjectOnClose: (BOOL) value {
	[preferences setObject: [NSNumber numberWithBool: value]
					forKey: @"cleanProjectOnClose"];
	
	[self preferencesHaveChanged];
}

- (void) setAlsoCleanIndexFiles: (BOOL) value {
	[preferences setObject: [NSNumber numberWithBool: value]
					forKey: @"alsoCleanIndexFiles"];
	
	[self preferencesHaveChanged];
}

- (void) setRunBuildSh: (BOOL) value {
	[preferences setObject: [NSNumber numberWithBool: value]
					forKey: @"runBuildSh"];
	
	[self preferencesHaveChanged];
}

- (void) setShowDebuggingLogs: (BOOL) value {
	[preferences setObject: [NSNumber numberWithBool: value]
					forKey: @"showDebuggingLogs"];
	
	[self preferencesHaveChanged];
}

@end
