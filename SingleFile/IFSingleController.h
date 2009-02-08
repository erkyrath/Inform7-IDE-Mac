//
//  IFSingleController.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/06/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IFSourceFileView.h"


//
// WindowController for a single-file document.
//
@interface IFSingleController : NSWindowController {
	IBOutlet IFSourceFileView*	fileView;						// The textview used to display the document itself
	IBOutlet NSView*			installWarning;					// The view used to warn when a .i7x file is not installed
	IBOutlet NSView*			mainView;						// The 'main view' that fills the window when the install warning is hidden
}

- (IBAction) installFile: (id) sender;							// User wants to install an extension
- (IBAction) cancelInstall: (id) sender;						// User cancelled the install panel

@end
