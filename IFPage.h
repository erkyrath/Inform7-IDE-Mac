//
//  IFPage.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//
// Class that represents a page in a project pane
//
@interface IFPage : NSObject {

}

// Page properties
- (NSString*) title;						// The name of the tab this page appears under
- (NSView*) view;							// The view that should be used to display this page

// TODO: page-specific toolbar items (NSCells?)

@end
