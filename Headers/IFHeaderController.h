//
//  IFHeaderController.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 19/12/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


///
/// Controller class used to manage the header view
///
@interface IFHeaderController : NSObject {
	IFHeader* rootHeader;												// The root of the headers being managed by this object
}

- (void) updateFromIntelligence: (id<IFSyntaxIntelligence>) intel;		// Updates the headers being managed by this controller from the specified intelligence object

@end
