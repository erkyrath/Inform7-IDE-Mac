//
//  IFInform6Extensions.m
//  Inform
//
//  Created by Andrew Hunter on 12/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFInform6Extensions.h"


@implementation IFInform6Extensions

- (id) init {
	return [self initWithNibName: @"Inform6Extensions"];
}

- (id) initWithNibName: (NSString*) nibName {
	self = [super initWithNibName: nibName];
	
	if (self) {
		extensions = nil;
		needRefresh = YES;
		
		activeExtensions = [[NSMutableSet alloc] init];
	}
	
	return self;
}

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Inform 6 Libraries"
												  value: @"Inform 6 Libraries"
												  table: nil];
}

- (void) dealloc {
	if (extensions) [extensions release];
	if (extensionPath) [extensionPath release];
	
	[activeExtensions release];
	
	[super dealloc];
}

// = Meta-information about what to look for =

- (NSArray*) directoriesToSearch {
	NSArray* libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSMutableArray* libraryDirectories = [NSMutableArray array];
	
	// Look for 'Inform 6 Extensions' directories in each library directory
	NSEnumerator* libEnum = [libraries objectEnumerator];
	NSString* libPath;
	
	while (libPath = [libEnum nextObject]) {
		NSString* extnPath = [[libPath stringByAppendingPathComponent: @"Inform"] stringByAppendingPathComponent: @"Inform 6 Extensions"];
		BOOL isDir;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath: extnPath
												 isDirectory: &isDir]) {
			[libraryDirectories addObject: extnPath];
		}
	}
	
	return libraryDirectories;
}

// = Searching the extensions =

- (void) searchForExtensions {
	// Clear out the old extensions
	if (extensions) [extensions release];
	extensions = [[NSMutableArray alloc] init];
	
	if (extensionPath) [extensionPath release];
	extensionPath = [[NSMutableDictionary alloc] init];
	
	// Get the list of extensions
	NSArray* directories = [self directoriesToSearch];
	
	// An extension lives in a directory in one of the directories specified above
	NSEnumerator* dirEnum = [directories objectEnumerator];
	NSString* dir;

	while (dir = [dirEnum nextObject]) {
		// Get the contents of this directory
		NSArray* dirContents = [[NSFileManager defaultManager] directoryContentsAtPath: dir];
		
		if (!dirContents) continue;
		
		// Iterate through: add any directories found as an extension
		NSEnumerator* extnEnum = [dirContents objectEnumerator];
		NSString* extn;
		
		while (extn = [extnEnum nextObject]) {
			NSString* extnPath = [dir stringByAppendingPathComponent: extn];
			BOOL exists, isDir;
			
			exists = [[NSFileManager defaultManager] fileExistsAtPath: extnPath
														  isDirectory: &isDir];
			
			if (!exists || !isDir) continue;
			if ([extensions indexOfObjectIdenticalTo: extn] != NSNotFound) continue;
			
			[extensions addObject: extn];
			[extensionPath setObject: extnPath
							  forKey: extn];
		}
	}
}

- (NSString*) pathForExtension: (NSString*) extension {
	return [extensionPath objectForKey: extension];
}

// = Compiler settings  =

- (NSArray*) includePathForCompiler: (NSString*) compiler {
	if (![compiler isEqualToString: IFCompilerInform6]) return nil;
	
	NSMutableArray* res = [NSMutableArray array];
	
	NSEnumerator* extnEnum = [activeExtensions objectEnumerator];
	NSString* extn;
	
	NSLog(@"%@", activeExtensions);
	
	while (extn = [extnEnum nextObject]) {
		NSString* extnPath = [self pathForExtension: extn];
		
		if (extnPath != nil) {
			NSLog(@"Extension path for %@ is %@", extn, extnPath);
			[res addObject: extnPath];
		} else {
			NSLog(@"No extension path for %@", extn);
		}
	}
	
	NSLog(@"%@", res);
			
	return res;
}

// = Table data source =

- (int)numberOfRowsInTableView: (NSTableView*) tableView {
	if (needRefresh) [self searchForExtensions];
	
	return [extensions count];
}

- (id)				tableView: (NSTableView*) tableView 
	objectValueForTableColumn: (NSTableColumn*) col
						  row: (int) row {
	if ([[col identifier] isEqualToString: @"libname"]) {
		return [extensions objectAtIndex: row];
	} else if ([[col identifier] isEqualToString: @"libactive"]) {
		return [NSNumber numberWithBool: [activeExtensions containsObject: [extensions objectAtIndex: row]]];
	} else {
		return @"UNKNOWN COLUMN";
	}
}

- (void)	tableView: (NSTableView*) aTableView 
	   setObjectValue: (id) anObject 
	   forTableColumn: (NSTableColumn*) col
				  row: (int) rowIndex {
	if ([[col identifier] isEqualToString: @"libname"]) {
		// Do nothing: can't set this
	} else if ([[col identifier] isEqualToString: @"libactive"]) {
		NSString* libname = [extensions objectAtIndex: rowIndex];
		
		if ([anObject boolValue]) {
			[activeExtensions addObject: libname];
		} else {
			[activeExtensions removeObject: libname];
		}
	} else {
		// Nothing to do
	}
}

@end
