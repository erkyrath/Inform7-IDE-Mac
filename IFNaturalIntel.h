//
//  IFNaturalIntel.h
//  Inform
//
//  Created by Andrew Hunter on 05/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFIntelFile.h"
#import "IFSyntaxStorage.h"

//
// Class to gather intelligence data on Natural Inform files
//
@interface IFNaturalIntel : NSObject<IFSyntaxIntelligence> {
	IFSyntaxStorage* highlighter;				// The highlighter that wants us to gather intelligence
}

@end
