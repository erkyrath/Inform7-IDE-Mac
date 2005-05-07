//
//  IFasSource.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 06/05/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFasSource.h"


@implementation IFasSource

// = Initialisation =

- (id) initWithProject: (IFProject*) proj
				  name: (NSString*) nm {
	self = [super init];
	
	if (self) {
		project = [proj retain];
		name = [nm copy];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(sourceFileRenamed:)
													 name: IFProjectSourceFileRenamedNotification
												   object: project];
	}
	
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[project release];
	[name release];
	
	[super dealloc];
}

- (void) sourceFileRenamed: (NSNotification*) not {
	NSDictionary* dict = [not userInfo];
	NSString* oldFilename = [dict objectForKey: @"OldFilename"];
	NSString* newFilename = [dict objectForKey: @"NewFilename"];
	
	if ([[oldFilename lowercaseString] isEqualToString: [name lowercaseString]]) {
		[name autorelease];
		name = [newFilename copy];
	}
}

// = Applescript functions (see the .sdef file for more details) =

- (void) setName: (NSString*) newName {
	if (![newName isKindOfClass: [NSString class]]) return;
	
	[project renameFile: name 
			withNewName: newName];
	
	[name autorelease];
	name = [newName retain];
}

- (NSString*) name {
	return name;
}

- (void) setSourceText: (NSObject*) obj {
	NSTextStorage* text = [project storageForFile: name];
	if (text == nil) return;
	
	// FIXME: mucks up the undo buffer (not that the standard methods for editing text don't also do that)
	if ([obj isKindOfClass: [NSString class]]) {
		[[text mutableString] setString: (NSString*)obj];
	} else if ([obj isKindOfClass: [NSAttributedString class]]) {
		[text setAttributedString: (NSAttributedString*)obj];
	} else if (obj != nil) {
		[self setSourceText: [obj description]];
	}
}

- (NSTextStorage*) sourceText {
	return [project storageForFile: name];
}

- (NSString*) path {
	return [project pathForFile: name];
}

- (void) setProject: (IFProject*) proj { }

- (IFProject*) project {
	return project;
}

- (void) setIsTemporary: (BOOL) isTemp { }

- (BOOL) isTemporary {
	return [project fileIsTemporary: name];
}

- (void) setExists: (BOOL) exists { }

- (BOOL) exists {
	return [[project sourceFiles] objectForKey: name] != nil;
}

@end
