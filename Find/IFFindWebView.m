//
//  IFFindWebView.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 23/02/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFFindWebView.h"


@implementation WebView(IFFindWebView)

// = Basic interface =

- (BOOL) findNextMatch:	(NSString*) match
				ofType: (IFFindType) type {
	return NO;
}

- (BOOL) findPreviousMatch: (NSString*) match
					ofType: (IFFindType) type {
	return NO;
}

- (BOOL) canUseFindType: (IFFindType) find {
	return YES;
}

- (NSString*) currentSelectionForFind {
}

// = 'Find all' =

- (NSArray*) findAllMatches: (NSString*) match
					 ofType: (IFFindType) type
		   inFindController: (IFFindController*) controller
			 withIdentifier: (id) identifier {
}

- (void) highlightFindResult: (IFFindResult*) result {
}

@end
