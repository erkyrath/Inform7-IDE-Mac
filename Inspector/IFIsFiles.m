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
		//[[activeProject notes] removeLayoutManager: [text layoutManager]];
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
	
	filenames = [[[activeProject sourceFiles] allKeys] sortedArrayUsingFunction: stringComparer
																		context: nil];
	[filenames retain];

	[filesView reloadData];
	
	[self setSelectedFile];
}

- (BOOL) available {
	return activeProject==nil?NO:YES;
}

- (NSString*) key {
	return IFIsFilesInspector;
}

- (void) setSelectedFile {
	IFProjectController* activeController = [activeWin windowController];

	if (activeController && [activeController isKindOfClass: [IFProjectController class]]) {
		int fileRow = [filenames indexOfObject: [[activeController selectedSourceFile] lastPathComponent]];
		
		if (fileRow != NSNotFound) {
			[filesView selectRow: fileRow
			byExtendingSelection: NO];
		} else {
			[filesView deselectAll: self];
		}
	}
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
	if (activeWin == nil) return;
	if ([filenames count] <= 0) return;
	if ([filesView selectedRow] < 0) return;
	
	NSBundle* mB = [NSBundle mainBundle];
	
	NSString* fileToRemove = [filenames objectAtIndex: [filesView selectedRow]];
	if (fileToRemove == nil) return;
	
	NSDictionary* status = [NSDictionary dictionaryWithObjectsAndKeys: 
		fileToRemove, @"fileToRemove", [activeWin windowController], @"windowController", nil];
	
	NSBeginAlertSheet([mB localizedStringForKey: @"FileRemove - Are you sure"
										  value: @"Are you sure you want to remove this file?" 
										  table: nil],
					  [mB localizedStringForKey: @"FileRemove - keep file" 
										  value: @"Keep it" 
										  table: nil],
					  [mB localizedStringForKey: @"FileRemove - delete file" 
										  value: @"Delete it" 
										  table: nil],
					  nil, activeWin,
					  self, 
					  @selector(deleteFileFinished:returnCode:contextInfo:), nil, 
					  [status retain],
					  [mB localizedStringForKey: @"FileRemove - description" 
										  value: @"Are you sure you wish to permanently remove the file '%@' from the project? This action cannot be undone" 
										  table: nil],
					  fileToRemove);
}

- (void) deleteFileFinished: (NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	NSDictionary* fileInfo = contextInfo;
	[fileInfo autorelease];
	
	// Verify that we're all set up to delete the file
	if (activeWin == nil) return;
	if (fileInfo == nil) return;
	
	NSString* filename = [fileInfo objectForKey: @"fileToRemove"];
	IFProjectController* activeController = [fileInfo objectForKey: @"windowController"];
	
	if (filename == nil || activeController == nil) return;
	
	if (![activeController isKindOfClass: [IFProjectController class]]) {
		return;
	}

	if (returnCode == NSAlertAlternateReturn) {
		// Delete this file
		[(IFProject*)[activeController document] removeFile: filename];
	}
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

- (void)tableView:(NSTableView *)aTableView 
   setObjectValue:(id)anObject 
   forTableColumn:(NSTableColumn *)aTableColumn 
			  row:(int)rowIndex {
	NSString* oldFile = [filenames objectAtIndex: rowIndex];
	if (![[aTableColumn identifier] isEqualToString: @"filename"]) return;
	if (oldFile == nil) return;
	
	IFProjectController* activeController = [activeWin windowController];
	
	if (![anObject isKindOfClass: [NSString class]]) return;
	if ([(NSString*)anObject length] <= 0) return;
	if ([[(NSString*)anObject pathComponents] count] != 1) return;
	
	if ([activeController isKindOfClass: [IFProjectController class]]) {
		IFProject* proj = [activeController document];
		
		[proj renameFile: oldFile
			 withNewName: [(NSString*)anObject stringByAppendingPathExtension: [oldFile pathExtension]]];
	}
}

// = Delegation is the key to success, apparently =

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSString* filename = nil;
	
	if ([filesView selectedRow] >= 0)
		filename = [filenames objectAtIndex: [filesView selectedRow]];
	
	if (filename) {
		IFProjectController* activeController = [activeWin windowController];
		
		if ([activeController isKindOfClass: [IFProjectController class]]) {
			[activeController selectSourceFile: filename];
		}
	}
}

@end
