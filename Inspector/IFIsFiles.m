//
//  IFIsFiles.m
//  Inform
//
//  Created by Andrew Hunter on Mon May 31 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import "IFIsFiles.h"
#import "IFProjectController.h"

NSString* IFIsFilesInspector = @"IFIsFilesInspector";

@implementation IFIsFiles

+ (IFIsFiles*) sharedIFIsFiles {
	static IFIsFiles* files = nil;
	
	if (!files) {
		files = [[IFIsFiles alloc] init];
	}
	
	return files;
}

- (id) init {
	self = [super init];
	
	if (self) {
		[NSBundle loadNibNamed: @"FileInspector"
						 owner: self];
		[self setTitle: [[NSBundle mainBundle] localizedStringForKey: @"Inspector Files"
															   value: @"Files"
															   table: nil]];
		activeProject = nil;
		filenames = nil;
		
		// Set the icon column to NSImageCell
		[[[filesView tableColumns] objectAtIndex: 
			[filesView columnWithIdentifier: @"icon"]] setDataCell: 
			[[[NSImageCell alloc] init] autorelease]];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(updateFiles)
													 name: IFProjectFilesChangedNotification
												   object: nil];
	}
	
	return self;
}

- (void) dealloc {
	if (filenames) [filenames release];
	if (activeProject) [activeProject release];
	[super dealloc];
}

// = Inspecting things =

static int stringComparer(id a, id b, void * context) {
	int cmp = [[(NSString*)a pathExtension] compare: [(NSString*)b pathExtension]];
	
	if (cmp == 0) return [(NSString*)a compare: (NSString*) b];
	return cmp;
}

- (void) inspectWindow: (NSWindow*) newWindow {
	activeWin = newWindow;
	
	if (activeProject) {
		// Need to remove the layout manager to prevent potential weirdness
		[[activeProject notes] removeLayoutManager: [text layoutManager]];
		[activeProject release];
	}
	activeProject = nil;
	
	// Get the active project, if applicable
	NSWindowController* control = [newWindow windowController];
	
	if (control != nil && [control isKindOfClass: [IFProjectController class]]) {
		activeProject = [[control document] retain];
	}
	
	[self updateFiles];
}

- (void) updateFiles {
	if (filenames) {
		[filenames release];
		filenames = nil;
	}
	
	if (!activeProject) return;
	
	IFProjectController* activeController = [activeWin windowController];
	
	filenames = [[[activeProject sourceFiles] allKeys] sortedArrayUsingFunction: stringComparer
																		context: nil];
	[filenames retain];
	
	if (activeController && [activeController isKindOfClass: [IFProjectController class]]) {
		int fileRow = [filenames indexOfObject: [[activeController selectedSourceFile] lastPathComponent]];
			
		if (fileRow != NSNotFound)
		{
			[filesView selectRow: fileRow
			byExtendingSelection: NO];
		}
	}

	[filesView reloadData];
}

- (BOOL) available {
	return activeProject==nil?NO:YES;
}

- (NSString*) key {
	return IFIsFilesInspector;
}

// = Actions =
- (IBAction) addNewFile: (id) sender {
	// Pass this to the active window
	if (activeWin != nil) {
		IFProjectController* contr = [activeWin windowController];
		if ([contr isKindOfClass: [IFProjectController class]])
			[contr addNewFile: self];
	}
}

- (IBAction) removeFile: (id) sender {
}

// = Our life as a data source =

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	if (activeProject == nil) return 0;
	
	return [filenames count];
}

- (id)				tableView:(NSTableView *)aTableView 
	objectValueForTableColumn:(NSTableColumn *)aTableColumn 
						  row:(int)rowIndex {	
	NSString* path = [filenames objectAtIndex: rowIndex];
	NSString* fullPath = [activeProject pathForFile: path];
	
	if (path == nil) return nil;
	if (fullPath == nil) return nil;

	if ([[aTableColumn identifier] isEqualToString: @"filename"]) {
		return [path stringByDeletingPathExtension];
	} else if ([[aTableColumn identifier] isEqualToString: @"icon"]) {
		NSImage* icon;
		
		// Use the icon for the file extension if the path doesn't exist
		if ([[NSFileManager defaultManager] fileExistsAtPath: fullPath]) {
			icon = [[NSWorkspace sharedWorkspace] iconForFile: fullPath];
		} else {
			icon = [[NSWorkspace sharedWorkspace] iconForFileType: [fullPath pathExtension]];
		}

		// Pick the smallest representation of the icon
		NSArray* reps = [icon representations];
		NSEnumerator* repEnum = [reps objectEnumerator];
		NSImageRep* thisRep, *repToUse;
		float smallestSize = 128;
		
		repToUse = nil;
		
		while (thisRep = [repEnum nextObject]) {
			NSSize repSize = [thisRep size];
			
			if (repSize.width < smallestSize) {
				repToUse = thisRep;
				smallestSize = repSize.width;
			}
		}
		
		if (repToUse != nil) {
			NSImage* newImg = [[NSImage alloc] init];
			[newImg addRepresentation: repToUse];
			return [newImg autorelease];
		} else {
			return icon;
		}
	} else {
		return nil;
	}
}

// = Delegation is the key to success, apparently =

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSString* filename = [filenames objectAtIndex: [filesView selectedRow]];
	
	if (filename) {
		IFProjectController* activeController = [activeWin windowController];
		
		if ([activeController isKindOfClass: [IFProjectController class]]) {
			[activeController selectSourceFile: filename];
		}
	}
}

@end
