//
//  IFasSource.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 06/05/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IFProject.h"

//
// Applescript go-between object for source files
//
// Exists mainly to provide the link between text and name properties
//
@interface IFasSource : NSObject {
	IFProject* project;						// Project this file belongs to
	NSString* name;							// Last known name of this source file
}

// Initialisation
- (id) initWithProject: (IFProject*) proj	// Initialises with the given project and file name
				  name: (NSString*) name;

// Applescript functions
- (NSString*) name;							// Name of this file
- (NSTextStorage*) sourceText;				// Source text for this file
- (NSString*) path;							// Full path for this file
- (IFProject*) project;						// Project this file is contained in
- (BOOL) isTemporary;						// YES if this file is temporary (for example, parserm.h)
- (BOOL) exists;							// YES if this file exists as part of the source

@end
