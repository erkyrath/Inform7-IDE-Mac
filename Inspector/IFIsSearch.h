//
//  IFIsSearch.h
//  Inform
//
//  Created by Andrew Hunter on 29/01/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFInspector.h"

#import "IFProject.h"
#import "IFProjectController.h"

extern NSString* IFIsSearchInspector;

@interface IFIsSearch : IFInspector {
	NSWindow* activeWin;
	IFProject* activeProject;
	IFProjectController* activeController;	
}

+ (IFIsSearch*) sharedIFIsSearch;

@end
