//
//  IFIndexPage.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IFPage.h"

enum IFIndexTabType {
	IFIndexActions = 1,
	IFIndexContents = 2,
	IFIndexKinds = 3,
	IFIndexPhrasebook = 4,
	IFIndexRules = 5,
	IFIndexScenes = 6,
	IFIndexWorld = 7
};

//
// The 'Index' page
//
@interface IFIndexPage : IFPage {
	BOOL indexAvailable;								// YES if the index tab should be active
	
	NSTabView* indexTabs;								// The tab view containing the various index files
	int indexMachineSelection;							// A reference count - number of 'machine' operations that might be affecting the index tab selection
	NSString* lastUserTab;								// The last tab selected by a user action	
}

// The index view
- (void) updateIndexView;										// Updates the index view with the current files in the index subdirectory
- (BOOL) canSelectIndexTab: (int) whichTab;						// Returns YES if we can select a specific tab in the index pane
- (void) selectIndexTab: (int) whichTab;						// Chooses a specific index tab
- (BOOL) indexAvailable;										// YES if the index tab is available

@end
