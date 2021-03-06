//
//  IFFakeProjectPane.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 27/10/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFFakeProjectPane.h"
#import "IFSyntaxStorage.h"
#import "IFPreferences.h"


@implementation IFProjectPane

+ (NSDictionary*) attributeForStyle: (IFSyntaxStyle) style {
	return [[[IFPreferences sharedPreferences] styles] objectAtIndex: (unsigned)style];
}

@end
