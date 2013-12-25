//
//  IFPreferenceController.m
//  Inform
//
//  Created by Andrew Hunter on 12/01/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFPreferenceController.h"

@implementation IFPreferenceController

// = Construction =

+ (IFPreferenceController*) sharedPreferenceController {
	static IFPreferenceController* sharedPrefController = nil;

	if (sharedPrefController == nil) {
		sharedPrefController = [[IFPreferenceController alloc] init];
	}
	
	return sharedPrefController;
}

// = Initialisation =

- (id) init {
	NSRect mainScreenRect = [[NSScreen mainScreen] frame];
	
	self = [super initWithWindow: [[[NSWindow alloc] initWithContentRect: NSMakeRect(NSMinX(mainScreenRect)+200, NSMaxY(mainScreenRect)-400, 512, 300) 
															   styleMask: NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask
																 backing: NSBackingStoreBuffered 
																   defer: YES] autorelease]];
	
	if (self) {
		// Set up window
		[self setWindowFrameAutosaveName: @"PreferenceWindow"];
		[[self window] setDelegate: self];
		[[self window] setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Inform Preferences"
																		value: @"Inform Preferences"
																		table: nil]];
				
		// Set up preference toolbar
		toolbarItems = [[NSMutableDictionary alloc] init];
		
		// Set up preference views
		preferenceViews = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void) dealloc {
	[preferenceToolbar release];
	[preferenceViews release];
	[toolbarItems release];
	
	[super dealloc];
}

- (IBAction) showWindow: (id) sender {
	// Set up the toolbar while showing the window
	if (preferenceToolbar == nil) {
		preferenceToolbar = [[NSToolbar alloc] initWithIdentifier: @"PreferenceWindowToolbar"];
		
		[preferenceToolbar setAllowsUserCustomization: NO];
		[preferenceToolbar setAutosavesConfiguration: NO];

		[preferenceToolbar setDelegate: self];
		[preferenceToolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
		[[self window] setToolbar: preferenceToolbar];
		[preferenceToolbar setVisible: YES];
		
		[self switchToPreferencePane: [[preferenceViews objectAtIndex: 0] identifier]];
	}

	[super showWindow: sender];	
}

// = Adding new preference views =

- (void) addPreferencePane: (IFPreferencePane*) newPane {
	// Add to the list of preferences view
	[preferenceViews addObject: newPane];
	
	// Add to the toolbar
	NSToolbarItem* newItem = [[NSToolbarItem alloc] initWithItemIdentifier: [newPane identifier]];
	
	[newItem setAction: @selector(switchPrefPane:)];
	[newItem setTarget: self];
	[newItem setImage: [newPane toolbarImage]];
	[newItem setLabel: [newPane preferenceName]];
	[newItem setToolTip: [newPane tooltip]];
	
	[toolbarItems setObject: newItem
					 forKey: [newPane identifier]];
}

// = Toolbar delegate =

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	NSMutableArray* result = [NSMutableArray array];
	NSEnumerator* toolEnum = [preferenceViews objectEnumerator];
	IFPreferencePane* toolId;
	
	while (toolId = [toolEnum nextObject]) {
		[result addObject: [toolId identifier]];
	}
		
	return result;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	NSMutableArray* res = (NSMutableArray*)[self toolbarAllowedItemIdentifiers: toolbar];
	
	[res insertObject: NSToolbarFlexibleSpaceItemIdentifier
			  atIndex: 0];
	[res addObject: NSToolbarFlexibleSpaceItemIdentifier];
	
	return res;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	return [self toolbarAllowedItemIdentifiers: toolbar];
}

- (NSToolbarItem *)toolbar: (NSToolbar*) toolbar 
	 itemForItemIdentifier: (NSString*) itemIdentifier 
 willBeInsertedIntoToolbar: (BOOL)flag {
	return [toolbarItems objectForKey: itemIdentifier];
}

// = Preference switching =

- (IFPreferencePane*) preferencePane: (NSString*) paneIdentifier {
	NSEnumerator* toolEnum = [preferenceViews objectEnumerator];
	IFPreferencePane* toolId;
	
	while (toolId = [toolEnum nextObject]) {
		if ([[toolId identifier] isEqualToString: paneIdentifier])
			break;
	}
	
	return toolId;
}

- (void) switchToPreferencePane: (NSString*) paneIdentifier {
	// Find the preference view that we're using
	NSEnumerator* toolEnum = [preferenceViews objectEnumerator];
	IFPreferencePane* toolId;
	
	while (toolId = [toolEnum nextObject]) {
		if ([[toolId identifier] isEqualToString: paneIdentifier])
			break;
	}
	
	// Switch to that view
	if (toolId) {
		NSView* preferencePane = [toolId preferenceView];
		
		if ([[self window] contentView] == preferencePane) return;
		
		if ([preferenceToolbar respondsToSelector: @selector(setSelectedItemIdentifier:)]) {
			[preferenceToolbar setSelectedItemIdentifier: paneIdentifier];
		}
		
		NSRect currentFrame = [[[self window] contentView] frame];
		NSRect oldFrame = currentFrame;
		NSRect windowFrame = [[self window] frame];
		
		currentFrame.origin.y    -= [preferencePane frame].size.height - currentFrame.size.height;
		currentFrame.size.height  = [preferencePane frame].size.height;
		
		// Grr, complicated, as OS X provides no way to work out toolbar proportions except in 10.3
		windowFrame.origin.x    += (currentFrame.origin.x - oldFrame.origin.x);
		windowFrame.origin.y    += (currentFrame.origin.y - oldFrame.origin.y);
		windowFrame.size.width  += (currentFrame.size.width - oldFrame.size.width);
		windowFrame.size.height += (currentFrame.size.height - oldFrame.size.height);
		
		[[self window] setContentView: [[[NSView alloc] init] autorelease]];
		[[self window] setFrame: windowFrame
						display: YES
						animate: YES];
		[[self window] setContentView: preferencePane];
	}
}

- (void) switchPrefPane: (id) sender {
	[self switchToPreferencePane: [(NSToolbarItem*)sender itemIdentifier]];
}

@end
