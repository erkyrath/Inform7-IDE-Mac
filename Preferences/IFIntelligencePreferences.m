//
//  IFIntelligencePreferences.m
//  Inform
//
//  Created by Andrew Hunter on 07/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFIntelligencePreferences.h"

#import "IFPreferences.h"

@implementation IFIntelligencePreferences

- (id) init {
	self = [super initWithNibName: @"IntelligencePreferences"];
	
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
	
	[enableSyntaxHighlighting setState: [prefs enableSyntaxHighlighting]?NSOnState:NSOffState];
	[indentWrappedLines setState: [prefs indentWrappedLines]?NSOnState:NSOffState];
	
	[enableIntelligence setState: [prefs enableIntelligence]?NSOnState:NSOffState];
	[intelligenceIndexInspector setState: [prefs intelligenceIndexInspector]?NSOnState:NSOffState];
	[indentAfterNewline setState: [prefs indentAfterNewline]?NSOnState:NSOffState];
	[autoNumberSections setState: [prefs autoNumberSections]?NSOnState:NSOffState];
	
	if (![prefs enableSyntaxHighlighting]) {
		[indentWrappedLines setEnabled: NO];
		[enableIntelligence setEnabled: NO];
	} else {
		[indentWrappedLines setEnabled: YES];
		[enableIntelligence setEnabled: YES];
	}
	
	if (![prefs enableIntelligence] || ![prefs enableSyntaxHighlighting]) {
		[intelligenceIndexInspector setEnabled: NO];
		[indentAfterNewline setEnabled: NO];
		[autoNumberSections setEnabled: NO];
	} else {
		[intelligenceIndexInspector setEnabled: YES];
		[indentAfterNewline setEnabled: YES];
		[autoNumberSections setEnabled: YES];
	}
	
	[newGameName setStringValue: [prefs newGameAuthorName]];
}

- (IBAction) setPreference: (id) sender {
	IFPreferences* prefs = [IFPreferences sharedPreferences];
	
	if (sender == enableSyntaxHighlighting) [prefs setEnableSyntaxHighlighting: [enableSyntaxHighlighting state]==NSOnState];
	if (sender == indentWrappedLines) [prefs setIndentWrappedLines: [indentWrappedLines state]==NSOnState];
	
	if (sender == enableIntelligence) [prefs setEnableIntelligence: [enableIntelligence state]==NSOnState];
	if (sender == intelligenceIndexInspector) [prefs setIntelligenceIndexInspector: [intelligenceIndexInspector state]==NSOnState];
	if (sender == indentAfterNewline) [prefs setIndentAfterNewline: [indentAfterNewline state]==NSOnState];
	if (sender == autoNumberSections) [prefs setAutoNumberSections: [autoNumberSections state]==NSOnState];
	
	if (sender == newGameName) [prefs setNewGameAuthorName: [newGameName stringValue]];
}

// = PreferencePane overrides =

- (NSString*) preferenceName {
	return @"Intelligence";
}

- (NSImage*) toolbarImage {
	return [NSImage imageNamed: @"Intelligence"];
}

- (NSString*) tooltip {
	return [[NSBundle mainBundle] localizedStringForKey: @"Intelligence preferences tooltip"
												  value: @"Intelligence preferences tooltip"
												  table: nil];
}

@end
