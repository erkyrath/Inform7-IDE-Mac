//
//  IFContextMatcher.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 27/06/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFMatcher.h"
#import "IFMatcherElement.h"

///
/// Matcher that can work from an XML syntax description file and produce a scanner (or maybe
/// multiple scanners)
///
@interface IFContextMatcher : IFMatcher {
	// Variables used during parsing
	NSMutableDictionary*	regexps;							// Known named regular expressions
	NSMutableDictionary*	structures;							// Known structures
	NSMutableArray*			elements;							// The elements that we're currently processing
	
	IFMatcherStructure*		structure;							// The structure that we're currently building
	IFMatcherElement*		element;							// The structure element that we're currently building
	NSString*				structureName;						// The structure that the structure currently being constructed should be made a substructure of
	NSString*				regexpName;							// The name of the last regular expression that we've encountered
}

// Initialising
- (void) readXml: (NSXMLParser*) xmlParser;						// Initialises this matcher using the specified XML description

@end
