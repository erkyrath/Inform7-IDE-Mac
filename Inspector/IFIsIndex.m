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
	
		[indexList setDataSource: [[proj document] indexFile]];
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

@end
