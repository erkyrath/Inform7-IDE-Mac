//
//  IFIsSkein.h
//  Inform
//
//  Created by Andrew Hunter on Mon Jul 05 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "IFInspector.h"
#import "IFProject.h"
#import "IFProjectController.h"

#import "ZoomView/ZoomSkein.h"
#import "ZoomView/ZoomSkeinView.h"

extern NSString* IFIsSkeinInspector;

@interface IFIsSkein : IFInspector {
	NSWindow* activeWin;
	IFProject* activeProject;
	IFProjectController* activeController;
	
	IBOutlet ZoomSkeinView* skeinView;
}

+ (IFIsSkein*) sharedIFIsSkein;

@end
