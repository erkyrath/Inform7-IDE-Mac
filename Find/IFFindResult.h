//
//  IFFindResult.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 17/02/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


///
/// Result for the 'Find All' pane
///
@interface IFFindResult : NSObject<NSCopying> {
	NSString* matchType;								// The type of match
	NSString* location;									// The description of where the match was found
	NSString* context;									// The context the match was found in
	NSRange	  contextRange;								// The range the match was found in
	id		  data;										// Some data for this match
	
	BOOL hasError;										// YES if there is an error with this item
}

// Initialisation

- (id) initWithMatchType: (NSString*) matchType
				location: (NSString*) locationDescription
				 context: (NSString*) context
			contextRange: (NSRange) highlightRange
					data: (id) data;

// Data

- (NSString*) matchType;								// The type of match (a description)
- (NSString*) location;									// The location of the match
- (NSString*) context;									// The context the match was found in
- (NSAttributedString*) attributedContext;				// The context with the match highlighted
- (NSRange)   contextRange;								// The range in the context of the match
- (id)		  data;										// Some data that can be used to highlight the match in the original text

- (void)	  setError: (BOOL) hasError;				// Sets whether or not an error has occurred with this item

@end
