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

- (id) initWithContextMatcher: (IFContextMatcher*) matcher {
	self = [super initWithMatcher: matcher];
	
	if (self) {
		regexps		= [matcher->regexps mutableCopyWithZone: [self zone]];
		structures	= [matcher->structures mutableCopyWithZone: [self zone]];
		elements	= [matcher->elements mutableCopyWithZone: [self zone]];
	}
	
	return self;
}

- (void) dealloc {
	[regexps		release];
	[structures		release];
	[elements		release];
	
	[element		release];
	[structure		release];
	[regexpName		release];
	[structureName	release];
	
	[context		release];
	
	[super dealloc];
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

- (void) processCharacters: (NSString*) string {
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
			if (structureName != nil) {
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
	
	if ([elementName isEqualToString: @"linebreak"]) {
		[self processCharacters: @"\n"];
	}
}

- (void)	parser: (NSXMLParser *)parser 
   foundCharacters: (NSString *)string {
	if ([elements count] == 0) return;

	NSString* thisElement = [elements lastObject];
	
	if (![thisElement isEqualToString: @"Match"] && !(regexpName != nil && [thisElement isEqualToString: @"Regexp"])) {
		string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	
	[self processCharacters: string];
}

- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString {
	if ([elements count] == 0) return;

	NSString* thisElement = [elements lastObject];

	// Ignore the ignorable whitespace unless we're in a regexp of some kind
	if ([thisElement isEqualToString: @"Match"] || (regexpName != nil && [thisElement isEqualToString: @"Regexp"])) {
		[self processCharacters: whitespaceString];
	}
}

// = Getting the context for a given position =

- (BOOL) match: (NSArray*) match
	  inString: (NSString*) matchString
		 range: (NSRange) range {
	if (range.location <= contextPosition && range.location + range.length > contextPosition) {
		// This match corresponds to the area that we're looking for
		context = [match retain];
		contextRange = range;
		return NO;
	}
	
	return YES;
}

- (NSArray*) matchSubstringsIn: (NSArray*) contextArray
					withString: (NSString*) fullString
						 range: (NSRange) matchRange
					  position: (int) position {
	// Retaining and autoreleasing the array helps deal with it happening to be our context array
	[[contextArray retain] autorelease];
	
	// Default result is the context array
	NSArray* result = contextArray;
	
	// Prepare the results array and the substring
	NSMutableArray* subcontextResult = [[NSMutableArray alloc] init];
	NSString* substring = [fullString substringWithRange: matchRange];

	// Iterate over the matches in the context array
	NSEnumerator* contextEnum = [contextArray objectEnumerator];
	IFMatcherStructure* matchStructure;

	while (matchStructure = [contextEnum nextObject]) {
		// Skip this structure if it doesn't have a matcher
		if (![matchStructure hasMatcher]) continue;
		
		// Prepare to match against the substring
		[context release];
		context = nil;
		contextPosition = position - matchRange.location;
		
		// Perform the match
		[[matchStructure matcher] setCaseSensitive: NO];
		[[matchStructure matcher] match: substring
						   withDelegate: self];
		
		// Perform any further substring matching that's required
		if (context != nil) {
			context = [[self matchSubstringsIn: context
									withString: substring
										 range: contextRange
									  position: contextPosition] retain];
		}
		
		// Put the results into the subcontext result if there are any
		if (context != nil) {
			[subcontextResult addObjectsFromArray: context];
		}
	}
	
	// Switch the result to the subcontext array if there were any matches there
	if ([subcontextResult count] > 0) result = [[subcontextResult retain] autorelease];
	
	// Tidy up and return
	[subcontextResult release];
	return result;
}

- (NSArray*) getContextAtPoint: (int) position
					  inString: (NSString*) string {
	NSArray* result;
	
	// Prepare to perform the match
	[context release];
	context = nil;
	contextPosition = position;
	
	// Perform the initial match
	[self match: string
   withDelegate: self];
	
	if (context == nil) return [NSArray array];
	
	// Also match against any substrings that might exist within this context
	result = [self matchSubstringsIn: context
						  withString: string
							   range: contextRange
							position: position];
	
	
	// Tidy up and return
	[context release];
	context = nil;
	
	return result;
}

// = NSCopying =

- (id) copyWithZone: (NSZone*) zone {
	id result = [[IFContextMatcher alloc] initWithContextMatcher: self];
	
	return result;
}

@end
