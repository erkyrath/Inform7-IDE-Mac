//
//  IFContextMatcher.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 27/06/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFContextMatcher.h"


@implementation IFContextMatcher

// = Reading XML =

- (void) readXml: (NSXMLParser*) xmlParser {
	// Set up the structures that record the result of the parse
	if (regexps) [regexps release];
	if (structures) [structures release];
	if (elements) [elements release];
	regexps		= [[NSMutableDictionary alloc] init];
	structures	= [[NSMutableArray alloc] init];
	elements	= [[NSMutableArray alloc] init];
	
	// Parse the XML
	[xmlParser setDelegate: self];
	[xmlParser parse];
}

- (void)	parser: (NSXMLParser*) parser 
   didStartElement: (NSString*) elementName
	  namespaceURI: (NSString*) namespaceURI
	 qualifiedName: (NSString*) qualifiedName
		attributes: (NSDictionary*) attributeDict {
	[elements addObject: elementName];
	
	if ([elementName isEqualToString: @"Structure"]) {
		if (element) {
			[element release];
			element = nil;
		}
		if (structure) [structure release];
		structure = [[IFMatcherStructure alloc] init];
	}
	
	if ([elementName isEqualToString: @"Element"]) {
		if (element) [element release];
		if (structure) [structure release];
		structure = element = [[[IFMatcherElement alloc] init] retain];
	}
}

@end
