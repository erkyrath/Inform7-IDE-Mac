//
//  IFProjectFile.h
//  Inform
//
//  Created by Andrew Hunter on Fri Sep 12 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

// Confusingly, a FileWrapper, as a project 'file' is really a bundle

#import <Foundation/Foundation.h>
#import "IFCompilerSettings.h"


@interface IFProjectFile : NSFileWrapper {
    NSFileWrapper* sourceDirectory;
    NSFileWrapper* buildDirectory;
}

// = New project creation =
- (id) initWithEmptyProject;
- (void) addSourceFile: (NSString*) filename;
- (void) addSourceFile: (NSString*) filename
          withContents: (NSData*)   contents;
- (void) clearIndex;

- (IFCompilerSettings*) settings;
- (void) setSettings: (IFCompilerSettings*) settings;

@end
