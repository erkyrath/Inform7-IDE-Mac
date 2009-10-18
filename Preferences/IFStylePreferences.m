//
//  IFStylePreferences.m
//  Inform
//
//  Created by Andrew Hunter on 01/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFStylePreferences.h"

#import "IFSyntaxStorage.h"
#import "IFNaturalHighlighter.h"

#import "IFPreferences.h"
#import "IFFontChooser.h"

@implementation IFStylePreferences

- (id) init {
	self = [super initWithNibName: @"StylePreferences"];
	
	if (self) {
		[self reflectCurrentPreferences];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(reflectCurrentPreferences)
													 name: IFPreferencesDidChangeNotification
												   object: [IFPreferences sharedPreferences]];
		
		// Switch the preview with a IFInform6Highlighter
		NSTextStorage* oldStorage = [previewView textStorage];
		previewStorage = [[IFSyntaxStorage alloc] initWithString: [oldStorage string]];
		
		[previewStorage setHighlighter: [[[IFNaturalHighlighter alloc] init] autorelease]];
		
		[oldStorage removeLayoutManager: [previewView layoutManager]];
		[previewStorage addLayoutManager: [previewView layoutManager]];

		// ... and the tab preview
		oldStorage = [tabStopView textStorage];
		tabStopStorage = [[IFSyntaxStorage alloc] initWithString: [oldStorage string]];
		
		[tabStopStorage setHighlighter: [[[IFNaturalHighlighter alloc] init] autorelease]];
		
		[oldStorage removeLayoutManager: [tabStopView layoutManager]];
		[tabStopStorage addLayoutManager: [tabStopView layoutManager]];
		
		[tabStopView setTextContainerInset: NSMakeSize(0, 2)];
		
		// Register for notifications about view size changes
		[preferenceView setPostsFrameChangedNotifications: YES];
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(viewWidthChanged:)
													 name: NSViewFrameDidChangeNotification
												   object: preferenceView];
		[tabStopSlider setMaxValue: [tabStopSlider bounds].size.width-12];
	}
	
	return self;
}

// = PreferencePane overrides =

- (NSString*) preferenceName {
	return @"Formatting";
}

- (NSImage*) toolbarImage {
	return [NSImage imageNamed: @"Styles"];
}

- (NSString*) tooltip {
	return [[NSBundle mainBundle] localizedStringForKey: @"Style preferences tooltip"
												  value: @"Style preferences tooltip"
												  table: nil];
}

// = Receiving data from/updating the interface =

- (float) fontSizeForTag: (int) tag {
	switch (tag) {
		case 0:
			return 1.0;
		case 1:
			return 1.25;
		case 2:
			return 1.5;
		case 3:
			return 2.5;
	}
	
	return 1.0;
}

- (int) tagForFontSize: (float) size {
	if (size >= 2.5)
		return 3;
	else if (size >= 1.5)
		return 2;
	else if (size >= 1.25)
		return 1;
	else
		return 0;
}

- (IBAction) chooseCustomFont: (id) sender {
	[fontChooser release];
	fontChooser = [[IFFontChooser alloc] init];
	
	[NSApp beginSheet: [fontChooser window]
	   modalForWindow: [preferenceView window]
		modalDelegate: self
	   didEndSelector: @selector(selectedFont:returnCode:contextInfo:)
		  contextInfo: nil];
}

- (void) selectedFont: (NSWindow*) sheet
		   returnCode: (int) returnCode
		  contextInfo: (void*) context {
	// Nothing to do
}

- (IBAction) styleSetHasChanged: (id) sender {
	IFPreferences* prefs = [IFPreferences sharedPreferences];
	
	if (sender == fontSet && [[sender selectedItem] tag] == 1000) {
		[self chooseCustomFont: sender];
	}
	
	if (sender == enableSyntaxHighlighting) [prefs setEnableSyntaxHighlighting: [enableSyntaxHighlighting state]==NSOnState];
	if (sender == fontSet)			[prefs setFontSet:			[[fontSet selectedItem] tag]];
	if (sender == fontStyle)		[prefs setFontStyling:		[[fontStyle selectedItem] tag]];
	if (sender == fontSize)			[prefs setFontSize:			[self fontSizeForTag: [[fontSize selectedItem] tag]]];
	if (sender == colourSet)		[prefs setColourSet:		[[colourSet selectedItem] tag]];
	if (sender == changeColours)	[prefs setChangeColours:	[[changeColours selectedItem] tag]];
	if (sender == tabStopSlider)	[prefs setTabWidth:			[tabStopSlider floatValue]];
}

- (void) reflectCurrentPreferences {
	IFPreferences* prefs = [IFPreferences sharedPreferences];
	
	[enableSyntaxHighlighting setState: [prefs enableSyntaxHighlighting]?NSOnState:NSOffState];
	[fontSet selectItem:		  [[fontSet menu]		itemWithTag: [prefs fontSet]]];
	[fontStyle selectItem:		  [[fontStyle menu]		itemWithTag: [prefs fontStyling]]];
	[fontSize selectItem:		  [[fontSize menu]		itemWithTag: [self tagForFontSize: [prefs fontSize]]]];
	[colourSet selectItem:		  [[colourSet menu]		itemWithTag: [prefs colourSet]]];
	[changeColours selectItem:	  [[changeColours menu]	itemWithTag: [prefs changeColours]]];
	[tabStopSlider setMaxValue: [tabStopSlider bounds].size.width-12];
	[tabStopSlider setFloatValue: [prefs tabWidth]];
	
	[tabStopStorage preferencesChanged: nil];
	[tabStopStorage highlighterPass];
	[previewStorage preferencesChanged: nil];
	[previewStorage highlighterPass];
}

- (void) viewWidthChanged: (NSNotification*) not {
	// Update the maximum value of the tab slider
	[tabStopSlider setMaxValue: [tabStopSlider bounds].size.width-12];
}

@end
