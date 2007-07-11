//
//  IFMatcherStructure.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 27/06/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFMatcher.h"

///
/// Context matcher structure that represents a match of some arbitrary structure in the source.
/// These structures are used to avoid excessive parser backtracking (ie, so that everything matches
/// something) and to allow a certain amount of recursion, for example to restrict matches to only
/// items in strings.
///
@interface IFMatcherStructure : NSObject {
	NSString*	title;									// Title for this structure
	NSString*	regexp;									// Regexp for this structure
	                                        			
	IFMatcher*	matcher;								// Matcher for elements contained within this structure
}                                           			
                                            			
// Setting the values in this structure     			
- (NSString*)	title;									// Title for this structure
- (void) 		setTitle:(NSString*) newTitle;
- (NSString*)	regexp;									// Regular expression for this structure
- (void) 		setRegexp: (NSString*) newRegexp;
- (IFMatcher*) 	matcher;								// The matcher for this structure (note: this is constructed the first time this is called)
- (BOOL) 		hasMatcher;								// YES if this structure has a corresponding matcher

@end
