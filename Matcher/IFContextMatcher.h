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
	// Variables used during parsing the XML
	NSMutableDictionary*	regexps;							// Known named regular expressions
	NSMutableDictionary*	structures;							// Known structures
	NSMutableArray*			elements;							// The elements that we're currently processing
	
	IFMatcherStructure*		structure;							// The structure that we're currently building
	IFMatcherElement*		element;							// The structure element that we're currently building
	NSString*				structureName;						// The structure that the structure currently being constructed should be made a substructure of
	NSString*				regexpName;							// The name of the last regular expression that we've encountered
	
	// Variables used while finding context
	NSArray*				context;							// The context produced in the last run through of the parser
	NSRange					contextRange;						// The range of the context in the string
	int						contextPosition;					// The position that we're searching for
}

// Initialising
- (void) readXml: (NSXMLParser*) xmlParser;						// Initialises this matcher using the specified XML description

// Getting the context for a given position
- (NSArray*) getContextAtPoint: (int) position					// Gives a list of structures that apply at the specified character position
					  inString: (NSString*) string;

@end
