//
//  IFNaturalExtensions.m
//  Inform
//
//  Created by Andrew Hunter on 24/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import "IFNaturalExtensions.h"


@implementation IFNaturalExtensions

// = Initialisation =

- (id) init {
	return [self initWithNibName: @"NaturalInformExtensions"];
}


- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Natural Inform Extensions"
												  value: @"Natural Inform Extensions"
												  table: nil];
}

// = Compiler settings  =

- (NSArray*) includePathForCompiler: (NSString*) compiler {
	return nil; // We never affect the include path
}

// = Where to search =

- (NSString*) extensionSubdirectory {
	return @"Extensions";
}

- (NSArray*) directoriesToSearch {
	NSArray* standardDirs = [super directoriesToSearch];
	
	// Add the default directory as well
	NSString* defaultDir = [IFCompilerSettings pathForInform7Library: @"Extensions"];
	
	NSMutableArray* res = [standardDirs mutableCopy];
	[res addObject: defaultDir];
	
	return [res autorelease];
}

// = What we consider a valid extension =

- (BOOL) canAcceptFile: (NSString*) filename {
	// (Directories only)
	BOOL exists, isDir;
	
	exists = [[NSFileManager defaultManager] fileExistsAtPath: filename
												  isDirectory: &isDir];
	
	if (!exists) return NO;				// Can't accept a non-existant file
	if (exists && isDir) return YES;	// We can always accept directories (though they may not be actual extensions, of course)

	return NO;
}

@end
