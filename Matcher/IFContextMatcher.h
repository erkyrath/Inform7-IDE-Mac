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
/// Matcher that can work from an XML syntax description file and produce a scanner 
///
@interface IFContextMatcher : IFMatcher {
	// Variables used during parsing
	NSMutableDictionary*	regexps;							// Known named regular expressions
	NSMutableArray*			structures;							// Known structures
	NSMutableArray*			elements;							// The elements that we're currently processing
	
	IFMatcherStructure*		structure;							// The structure that we're currently building
	IFMatcherElement*		element;							// The structure element that we're currently building
}

// Initialising
- (void) readXml: (NSXMLParser*) xmlParser;						// Initialises this matcher using the specified XML

@end
