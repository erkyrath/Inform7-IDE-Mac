//
//  IFIsIndex.m
//  Inform
//
//  Created by Andrew Hunter on Fri May 07 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import "IFIsIndex.h"
#import "IFAppDelegate.h"

#import "IFIndexFile.h"
#import "IFProjectController.h"
#import "IFProject.h"

NSString* IFIsIndexInspector = @"IFIsIndexInspector";

@implementation IFIsIndex

+ (IFIsIndex*) sharedIFIsIndex {
	static IFIsIndex* sharedIndex = nil;
	
	if (sharedIndex == nil && [IFAppDelegate isWebKitAvailable]) {
		sharedIndex = [[IFIsIndex alloc] init];
	}
	
	return sharedIndex;
}

- (id) init {
	self = [super init];
	
	if (self) {
		[self setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Inspector Index"
															   value: @"Index"
															   table: nil]];
		[NSBundle loadNibNamed: @"IndexInspector"
						 owner: self];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(intelFileChanged:)
													 name: IFIntelFileHasChangedNotification
												   object: nil];
	}

	return self;
}

- (void) dealloc {
	[super dealloc];
}

- (NSString*) key {
	return IFIsIndexInspector;
}

- (BOOL) available {
	return canDisplay;
}

- (void) inspectWindow: (NSWindow*) window {
	activeWindow = window;
	
	canDisplay = NO;
	if ([window windowController] != nil) {
		[self updateIndexFrom: [window windowController]];
	}
}

- (void) updateIndexFrom: (NSWindowController*) window {
	if ([window window] != activeWindow) return;
	
	if ([window isKindOfClass: [IFProjectController class]]) {
		IFProjectController* proj = (IFProjectController*)window;
		
		canDisplay = YES;
	
		//[indexList setDataSource: [[proj document] indexFile]];
		[indexList setDataSource: self];
		[indexList reloadData];
	}
}

// = NSOutlineView delegate methods =

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	if (canDisplay) {
		IFProjectController* proj = [activeWindow windowController];
		
		int selectedRow = [indexList selectedRow];
		if (selectedRow < 0) return; // Nothing to do

		id selectedItem = [indexList itemAtRow: selectedRow];
		
		if ([selectedItem isKindOfClass: [IFIntelSymbol class]]) {
			[proj moveToSourceFileLine: [[proj currentIntelligence] lineForSymbol: selectedItem]+1];
		} else {
			IFIndexFile* index = [[proj document] indexFile];
		
			NSString* filename = [index filenameForItem: selectedItem];
			int line = [index lineForItem: selectedItem];
		
			if (filename != nil &&
				[proj selectSourceFile: filename]) {
				if (line >= 0)
					[proj moveToSourceFileLine: line];
			} else {
				NSLog(@"IFIsIndex: Can't select file '%@' (line '%@')", filename, line);
			}
		}
	}
}

// = NSOutlineView data source =

// This will display the real-time data instead of the indexfile data

- (id)outlineView: (NSOutlineView *)outlineView 
			child: (int)childIndex 
		   ofItem: (id)item {
	// Retrieve the intelligence data
	int x;

	if (item == nil) {
		// Root item
		IFProjectController* proj = [activeWindow windowController];
		IFIntelFile* intel = [proj currentIntelligence];

		IFIntelSymbol* child = [intel firstSymbol];
		
		for (x=0; x<childIndex; x++) {
			child = [child sibling];
		}
		
		return child;
	} else {
		// Find the child
		IFIntelSymbol* child = [(IFIntelSymbol*)item child];
		
		for (x=0; x<childIndex; x++) {
			child = [child sibling];
		}
		
		return child;
	}
}

- (BOOL)outlineView: (NSOutlineView *)outlineView
   isItemExpandable: (id)item {
	if ([(IFIntelSymbol*)item child] != nil)
		return YES;
	else
		return NO;
}

- (int)			outlineView:(NSOutlineView *)outlineView 
	 numberOfChildrenOfItem:(id)item {
	int count = 0;
	IFIntelSymbol* child = nil;
	
	if (item == nil) {
		// Root item
		IFProjectController* proj = [activeWindow windowController];
		IFIntelFile* intel = [proj currentIntelligence];
		
		 child = [intel firstSymbol];
	} else {
		// Find the child
		child = [(IFIntelSymbol*)item child];
	}	

	
	while (child != nil) {
		count++;
		child = [child sibling];
	}
	
	return count;
}

- (id)				outlineView:(NSOutlineView *)outlineView 
	  objectValueForTableColumn:(NSTableColumn *)tableColumn
						 byItem:(id)item {
	// Valid column identifiers are 'title' and 'line'
	NSString* identifier = [tableColumn identifier];
	
	if (item == nil) {
		// Root item
		return nil;
	} else {
		if ([identifier isEqualToString: @"title"]) {
			return [item name];
		} else if ([identifier isEqualToString: @"line"]) {
			IFProjectController* proj = [activeWindow windowController];
			IFIntelFile* intel = [proj currentIntelligence];
			
			int line = [intel lineForSymbol: item];
			
			return [NSString stringWithFormat: @"%i", line];
		} else {
			return @"--";
		}
	}
}

- (void) intelFileChanged: (NSNotification*) not {
	[indexList reloadData];
}

@end
