//
//  IFIsFiles.h
//  Inform
//
//  Created by Andrew Hunter on Mon May 31 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IFInspector.h"
#import "IFProject.h"

extern NSString* IFIsFilesInspector;

@interface IFIsFiles : IFInspector {
	IBOutlet NSTableView* filesView;
	IBOutlet NSButton* addFileButton;
	IBOutlet NSButton* removeFileButton;
	
	IFProject* activeProject;
	NSArray* filenames;
	NSWindow* activeWin;
}

+ (IFIsFiles*) sharedIFIsFiles;

- (IBAction) removeFile: (id) sender;

- (void) updateFiles;

@end
