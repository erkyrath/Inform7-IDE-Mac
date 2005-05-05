//
//  IFasProject.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 05/05/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFProject.h"

//
// Applescript functions for an IFProject file
//
@interface IFProject(IFasProject)

// Dealing with source files
- (NSTextStorage*) asSourceFileWithName: (NSString*) name;			// Retrieves a specific source file
- (NSTextStorage*) asPrimarySourceFile;								// Retrieves the 'primary' source file

// Dealing with the compiler

// Dealing with running the game

@end
