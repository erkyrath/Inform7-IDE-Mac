//
//  IFFontChooser.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 07/01/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFFontChooser.h"
#import "IFPreferences.h"
#import "IFSyntaxStorage.h"
#import "IFNaturalHighlighter.h"

@implementation IFFontChooser

// = Initialisation =

- (id) init {
	self = [self initWithWindowNibName: @"FontChooser"];
	
	if (self) {
		
	}
	
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[fontSource release];
	[previewStorage release];
	
	[super dealloc];
}

// = Actions =

- (IBAction) useFont: (id) sender {
	[NSApp endSheet: [self window]];
	[[self window] orderOut: self];
}

// = Table view convenience methods =

- (void) refreshAllTables {
	IFPreferences* prefs = [IFPreferences sharedPreferences];
	
	NSString* newCollection = [fontSource tableView: collections
						  objectValueForTableColumn: nil
												row: [collections selectedRow]];
	[fontSource setCollection: newCollection];
	
	[collections reloadData];
	[family reloadData];
	
	[collections selectRow: [fontSource rowForCollection: newCollection]
	  byExtendingSelection: NO];
	[family selectRow: [fontSource rowForFamily: [prefs customFontFamily]]
 byExtendingSelection: NO];
}

- (void) windowDidLoad {
	// Register for notifications
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(reflectCurrentPreferences)
												 name: IFPreferencesDidChangeNotification
											   object: [IFPreferences sharedPreferences]];

	// Set up the table views
	[fontSource release];
	fontSource = [[IFFontTableSource alloc] init];
	
	[collections setDataSource: fontSource];
	[family setDataSource: fontSource];
	
	[collections setDelegate: self];
	[family setDelegate: self];
	
	[self refreshAllTables];
	
	[collections scrollRowToVisible: [collections selectedRow]];
	[family scrollRowToVisible: [family selectedRow]];
	
	// Switch the preview with a IFInform6Highlighter
	NSTextStorage* oldStorage = [preview textStorage];
	previewStorage = [[IFSyntaxStorage alloc] initWithString: [oldStorage string]];
	
	[previewStorage setHighlighter: [[[IFNaturalHighlighter alloc] init] autorelease]];
	
	[oldStorage removeLayoutManager: [preview layoutManager]];
	[previewStorage addLayoutManager: [preview layoutManager]];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	IFPreferences* prefs = [IFPreferences sharedPreferences];
	
	// Update the font collection
	if ([aNotification object] == collections) {
		[self refreshAllTables];
	} else if ([aNotification object] == family) {
		NSString* newFamily = [fontSource tableView: family
						  objectValueForTableColumn: nil
												row: [family selectedRow]];
		
		if (newFamily != nil) [prefs setCustomFontFamily: newFamily];
	}
}

- (void) reflectCurrentPreferences {
	[previewStorage preferencesChanged: nil];
	[previewStorage highlighterPass];
}

@end
