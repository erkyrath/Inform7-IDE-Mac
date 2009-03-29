//
//  IFPreferences.h
//  Inform
//
//  Created by Andrew Hunter on 02/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFInspector.h"

// Notifications
extern NSString* IFPreferencesDidChangeNotification;
extern NSString* IFPreferencesChangedEarlierNotification;	// Delayed version of the above

// Types of font
extern NSString* IFPreferencesBaseFont;				// Base font
extern NSString* IFPreferencesBoldFont;				// Bold font (only used for 'Subtle' styling or more)
extern NSString* IFPreferencesItalicFont;			// Italic font (only used for 'Often' styling)
extern NSString* IFPreferencesHeaderFont;			// Font used for NI header
extern NSString* IFPreferencesCommentFont;			// Font used for comments

// Choices
enum IFPreferencesFontSet {
	IFFontSetStandard=0,	// SystemFont/boldSystemFont
	IFFontSetProgrammer=1,	// Monaco
	IFFontSetStylised=2,	// Gill Sans
	IFFontSetCustomised=1000,
};

enum IFPreferencesFontStyling {
	IFStylingNone=0,		// Never use bold
	IFStylingSubtle=1,		// Bold comments, some bold keywords, bold headings
	IFStylingOften=2,		// Italic comments, bold keywords, etc
};

enum IFPreferencesColourChanges {
	IFChangeColsNever=0,	// Use the default colour always
	IFChangeColsRarely=1,	// Change for strings and keywords only
	IFChangeColsOften=2,	// Change all the time
};

enum IFPreferencesColourSet {
	IFColoursSubdued=0,		// Subtler version of the 'standard' colours
	IFColoursStandard=1,	// Standard colours, a bit like XCode
	IFColoursPsychedelic=2,	// Colours are as bright and different as possible
	IFColoursCustomised=255,
};

//
// General preferences class
//
// Inform's application preferences are stored here
//
@interface IFPreferences : NSObject {
	// The preferences dictionary
	NSMutableDictionary* preferences;
	
	// Notification flag
	BOOL willNotifyLater;
	
	// Caches
	NSMutableDictionary* cacheFontSet;		// Maps 'font types' to fonts
	NSMutableArray* cacheFontStyles;		// Maps styles to fonts
	NSMutableArray* cacheColourSet;			// Choice of colours
	NSMutableArray* cacheColours;			// Maps styles to colours
	
	NSMutableArray* styles;					// The array of actual styles (array of attribute dictionaries)
}

// Constructing the object
+ (IFPreferences*) sharedPreferences;										// The shared preference object

// Preferences
- (void) preferencesHaveChanged;											// Generates a notification that preferences have changed

// Style preferences
- (NSString*) customFontFamily;												// The custom font family to use
- (enum IFPreferencesFontSet) fontSet;										// The currently active font set
- (enum IFPreferencesFontStyling) fontStyling;								// ... styling
- (float) fontSize;															// ... size
- (enum IFPreferencesColourChanges) changeColours;							// ... colour changes
- (enum IFPreferencesColourSet) colourSet;									// ... colour set
- (float) tabWidth;															// ... tab width

- (void) setCustomFontFamily: (NSString*) customFontFamily;					// Set the custom font family
- (void) setFontSet: (enum IFPreferencesFontSet) newFontSet;				// Set the currently active font set
- (void) setFontStyling: (enum IFPreferencesFontStyling) newFontStyling;	// ... styling
- (void) setFontSize: (float) sizeMultiplier;								// ... size
- (void) setChangeColours: (enum IFPreferencesColourChanges) newColourChanges; // ... colour changes
- (void) setColourSet: (enum IFPreferencesColourSet) newColourSet;			// ... colour set
- (void) setTabWidth: (float) newTabWidth;									// ... tab width

- (void) recalculateStyles;													// Regenerate the array of attribute dictionaries that make up the styles
- (NSArray*) styles;														// Retrieves an array of attribute dictionaries that describe how the styles should be displayed

// Inspector preferences
- (BOOL) enableInspector: (IFInspector*) inspector;							// YES if a given inspector should be enabled
- (void) setEnable: (BOOL) enable											// Sets whether or not a given inspector is enabled
	  forInspector: (IFInspector*) inspector;

// Intelligence preferences
- (BOOL) enableSyntaxHighlighting;											// YES if source code should be displayed with syntax highlighting
- (BOOL) indentWrappedLines;												// ... and indentation
- (BOOL) elasticTabs;														// ... and elastic tabs
- (BOOL) enableIntelligence;												// YES if source should be tracked for important structural elements
- (BOOL) intelligenceIndexInspector;										// ... which is placed in the index
- (BOOL) indentAfterNewline;												// ... which is used to generate indentation
- (BOOL) autoNumberSections;												// ... which is used to auto-type section numbers
- (NSString*) newGameAuthorName;											// The default author to use for new Inform 7 games

- (void) setEnableSyntaxHighlighting: (BOOL) value;
- (void) setIndentWrappedLines: (BOOL) value;
- (void) setElasticTabs: (BOOL) value;
- (void) setEnableIntelligence: (BOOL) value;
- (void) setIntelligenceIndexInspector: (BOOL) value;
- (void) setIndentAfterNewline: (BOOL) value;
- (void) setAutoNumberSections: (BOOL) value;
- (void) setNewGameAuthorName: (NSString*) value;

// Skein preferences
- (float) skeinSpacingHoriz;
- (float) skeinSpacingVert;

- (void) setSkeinSpacingHoriz: (float) value;
- (void) setSkeinSpacingVert: (float) value;

// Advanced preferences
- (BOOL) runBuildSh;														// YES if we should run the build.sh shell script to rebuild Inform 7
- (BOOL) showDebuggingLogs;													// YES if we should show the Inform 7 debugging logs + generated Inform 6 source code
- (BOOL) cleanProjectOnClose;												// YES if we should clean the project when we close it (or when saving)
- (BOOL) alsoCleanIndexFiles;												// YES if we should additionally clean out the index files
- (NSString*) glulxInterpreter;												// The preferred glulx interpreter

- (void) setRunBuildSh: (BOOL) value;
- (void) setShowDebuggingLogs: (BOOL) value;
- (void) setCleanProjectOnClose: (BOOL) value;
- (void) setAlsoCleanIndexFiles: (BOOL) value;
- (void) setGlulxInterpreter: (NSString*) value;

@end
