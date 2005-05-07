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
	}
	
	return self;
}

- (void) dealloc {
	[project release];
	[name release];
	
	[super dealloc];
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
