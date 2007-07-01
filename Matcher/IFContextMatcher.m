//
//  IFContextMatcher.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 27/06/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFContextMatcher.h"


@implementation IFContextMatcher

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
		regexps		= [[NSMutableDictionary alloc] init];
		structures	= [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

// = Reading XML =

- (void) readXml: (NSXMLParser*) xmlParser {
	// Set up the structures that record the result of the parse
	if (elements)	[elements release];
	elements	= [[NSMutableArray alloc] init];
	
	if (structure)	[structure release];
	if (element)	[element release];
	if (regexpName)	[regexpName release];
	structure = element = nil;
	regexpName = nil;
	
	// Parse the XML
	[xmlParser setDelegate: self];
	[xmlParser parse];
	
	// Start building the final lexer
	[self compileLexer];
}

- (void)	parser: (NSXMLParser*)	parser 
   didStartElement: (NSString*)		elementName
	  namespaceURI: (NSString*)		namespaceURI
	 qualifiedName: (NSString*)		qualifiedName
		attributes: (NSDictionary*) attributeDict {
	// Push this element onto the elements stack
	[elements addObject: elementName];
	
	// If we've got a structure or an element node, then remember the structure name for the node
	if ([elementName isEqualToString: @"Structure"] || [elementName isEqualToString: @"Element"]) {
		if (structureName) [structureName release]; structureName = nil;
		structureName = [[attributeDict objectForKey: @"structure"] retain];
	}
	
	// If we've got a structure or an element node, then create the appropriate structures
	if ([elementName isEqualToString: @"Structure"]) {
		if (element) {
			[element release];
			element = nil;
		}
		if (structure) [structure release];
		structure = [[IFMatcherStructure alloc] init];
	} else if ([elementName isEqualToString: @"Element"]) {
		if (element) [element release];
		if (structure) [structure release];
		structure = element = [[[IFMatcherElement alloc] init] retain];
	} else if ([elementName isEqualToString: @"Regexp"]) {
		if (regexpName) [regexpName release];
		regexpName = [[attributeDict objectForKey: @"name"] copy];
	}
}

- (void)parser: (NSXMLParser*) parser 
 didEndElement: (NSString*)	   elementName 
  namespaceURI: (NSString*)	   namespaceURI 
 qualifiedName: (NSString*)	   qName {
	if ([elements count] == 0) {
		// Oops: bad XML
		NSLog(@"XML parser: found end element with no matching start element");
		[parser abortParsing];
		return;
	}
	
	if (structure != nil && ([elementName isEqualToString: @"Structure"] || [elementName isEqualToString: @"Element"])) {
		if ([structures objectForKey: [structure title]] == nil) {
			// Store the element/structure that we were constructing in the dictionary
			[structures setObject: structure
						   forKey: [structure title]];
			
			// Add the element/structure to the appropriate NDFA
			IFMatcher* matcher = self;
			if (structureName == nil) {
				matcher = [[structures objectForKey: structureName] matcher];
			}
			
			if (matcher == nil) {
				NSLog(@"Warning: while building element '%@' couldn't find structure '%@' to add it to",
					  [structure title], structureName);
			}
			
			[matcher addExpression: [structure regexp]
						withObject: structure];
		} else {
			// Ignore structures that are already in the dictionary
			NSLog(@"Warning: found duplicate structure '%@' (ignoring)", [structure title]);
		}
		
		// Destroy the element/structure that we were constructing
		[element release];
		[structure release];
		[structureName release];
		structure = element = nil;
		structureName = nil;
	}
	
	if (regexpName && [elementName isEqualToString: @"Regexp"]) {
		// Add this as a named regular expression
		[self addNamedExpression: [regexps objectForKey: regexpName]
						withName: regexpName];
	}
	
	// Pop this element from the stack
	[elements removeLastObject];
}

- (void)	parser: (NSXMLParser *)parser 
   foundCharacters: (NSString *)string {
	if ([elements count] == 0) return;

	NSString* thisElement = [elements lastObject];
	
	if ([thisElement isEqualToString: @"Title"]) {
		// Title of an Element or a Structure
		[structure setTitle: [[structure title] stringByAppendingString: string]];
	} else if ([thisElement isEqualToString: @"Match"]) {
		// Match of an Element or a Structure
		[structure setRegexp: [[structure regexp] stringByAppendingString: string]];
	} else if ([thisElement isEqualToString: @"Description"]) {
		// Description of an Element
		[element setElementDescription: [[element elementDescription] stringByAppendingString: string]];
	} else if ([thisElement isEqualToString: @"Link"]) {
		// Link of an Element
		[element setElementLink: [[element elementLink] stringByAppendingString: string]];
	} else if (regexpName != nil && [thisElement isEqualToString: @"Regexp"]) {
		// Regular expression definition
		NSString* oldValue = @"";
		if ([regexps objectForKey: regexpName] != nil) {
			oldValue = [regexps objectForKey: regexpName];
		}
		
		NSString* newValue = [oldValue stringByAppendingString: string];
		[regexps setObject: newValue
					forKey: regexpName];
	}
}

@end
