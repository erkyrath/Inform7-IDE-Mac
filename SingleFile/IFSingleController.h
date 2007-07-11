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
	// The textview used to display the document itself
	IBOutlet IFSourceFileView* fileView;						
}

@end
