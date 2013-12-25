//
//  IFDocParser.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 28/10/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString* IFDocHtmlTitleAttribute;
extern NSString* IFDocTitleAttribute;
extern NSString* IFDocSectionAttribute;
extern NSString* IFDocSortAttribute;

//
// Very simple HTML parser that deals with document files, extracting the text and any attributes,
// suitable for use in a search.
//
@interface IFDocParser : NSObject {
	// The parse results
	NSString* plainText;									// The plain text version of the HTML document
	NSDictionary* attributes;								// The attributes associated with the HTML document
	NSString* example;										// Text encountered between 'EXAMPLE START' and 'EXAMPLE END'
}

- (id) initWithHtml: (NSString*) html;						// Parses the specified HTML, extracting attributes and the plain text version

- (NSString*) plainText;									// The plain text version of the file that has been parsed
- (NSString*) example;										// The example text for this file
- (NSDictionary*) attributes;								// The attributes from the file that has been parsed

@end
