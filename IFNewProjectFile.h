//
//  IFNewProjectFile.h
//  Inform
//
//  Created by Andrew Hunter on Tue Jun 01 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "IFProjectController.h"


@interface IFNewProjectFile : NSWindowController {
	IFProjectController* projectController;
	
	IBOutlet NSPopUpButton* fileType;
	IBOutlet NSTextField*   fileName;
	
	NSString* newFilename;
}

- (id) initWithProjectController: (IFProjectController*) control;

- (IBAction) cancel: (id) sender;
- (IBAction) addFile: (id) sender;

- (NSString*) getNewFilename;

@end
