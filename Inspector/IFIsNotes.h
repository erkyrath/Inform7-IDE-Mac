//
//  IFIsNotes.h
//  Inform
//
//  Created by Andrew Hunter on Fri May 07 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IFInspector.h"
#import "IFProject.h"

extern NSString* IFIsNotesInspector;

@interface IFIsNotes : IFInspector {
	IFProject* activeProject;
	
	IBOutlet NSTextView* text;
}

+ (IFIsNotes*) sharedIFIsNotes;

@end
