//
//  IFSearchResultsController.m
//  Inform
//
//  Created by Andrew Hunter on 29/01/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFSearchResultsController.h"

#define contextLength 12

static NSFont* normalFont;
static NSFont* boldFont;

static NSMutableParagraphStyle* centered;

static NSDictionary* normalAttributes;
static NSDictionary* boldAttributes;

@implementation IFSearchResultsController

// = Initialisation =

+ (void) initialize {
	// We use these fonts while formatting the context
	normalFont = [[NSFont systemFontOfSize: 11] retain];
	boldFont = [[NSFont boldSystemFontOfSize: 11] retain];
	
	// NSMutableParagraphStyle is not well-behaved at all. We can't pass it from one thread to another:
	// it fails to encode or copy correctly. We can only set it in the main thread
	centered = [[NSMutableParagraphStyle alloc] init];
	[centered setAlignment: NSCenterTextAlignment];
	
	// Create the attribute dictionaries
	normalAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
		normalFont, NSFontAttributeName,
		nil] retain];
	boldAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
		boldFont, NSFontAttributeName,
		nil] retain];
}

- (id) init {
	return [self initWithWindowNibName: @"SearchResults"];
}

- (void) dealloc {
	if (searching) NSLog(@"Search: Warning: must not be deallocated while search thread is running!");
	searching = NO; // Slim chance this will abort the inevitable disaster if it's set to YES
	
	if (searchLabelText) [searchLabelText release];
	if (searchPhrase) [searchPhrase release];
	if (searchItems) [searchItems release];

	if (mainThread) [mainThread release];
	if (subThread)  [subThread release];
	if (port1)      {
		[[NSRunLoop currentRunLoop] removePort: port1
									   forMode: NSDefaultRunLoopMode];
		[port1 release];
	}
	if (port2)		[port2 release];
	
	if (searchResults) [searchResults release];
	
	if (delegate) [delegate release];
	
	[super dealloc];
}

- (id) retain {
	return [super retain];
}

// = Waking up =

- (void) windowDidLoad {
	// Set the autosave name for the window
	[self setWindowFrameAutosaveName: @"SearchResults"];
	
	// Set up the interface
	if (searchLabelText) {
		[searchLabel setStringValue: searchLabelText];
	}

	// This window only becomes key if needed
	[(NSPanel*)[self window] setBecomesKeyOnlyIfNeeded: YES];
}

- (void) windowWillClose: (NSNotification*) aNotification {
	// Release on close
	[self stopSearch];
	[self autorelease];
}

// = Controlling the display =

- (void) setSearchLabelText: (NSString*) newSearchLabel {
	[searchLabelText release];
	searchLabelText = [newSearchLabel copy];
	
	if (searchLabel) {
		[searchLabel setStringValue: searchLabelText];
	}
}

- (void) addResultWithType: (NSString*) type
					  file: (NSString*) file
				   context: (NSString*) context {
}

// = Controlling what to search =

- (void) cantChangeSearchAfterStarting {
	if (searching) {
		[NSException raise: @"IFSearchCantChangeOptions" format: @"Unable to change search options after the search has started"];
	}
}

- (void) setSearchPhrase: (NSString*) newSearchPhrase {
	[self cantChangeSearchAfterStarting];
	
	[searchPhrase release];
	searchPhrase = [newSearchPhrase copy];
}

- (void) setSearchType: (int) newSearchType {
	[self cantChangeSearchAfterStarting];
	
	searchType = newSearchType;
}

- (void) setCaseSensitive: (BOOL) newCaseSensitive {
	[self cantChangeSearchAfterStarting];
	
	caseSensitive = newCaseSensitive;
}

- (void) addSearchStorage: (NSString*) storage
			 withFileName: (NSString*) filename
					 type: (NSString*) type {
	[self cantChangeSearchAfterStarting];
	
	if (searchItems == nil) searchItems = [[NSMutableArray alloc] init];
	
	NSDictionary* entry = [NSDictionary dictionaryWithObjectsAndKeys: 
		[[storage copy] autorelease], @"storage",
		filename, @"filename",
		type, @"type",
		nil];
	
	[searchItems addObject: entry];
}

- (void) addSearchFile: (NSString*) filename
				  type: (NSString*) type {
	[self cantChangeSearchAfterStarting];
	
	if (searchItems == nil) searchItems = [[NSMutableArray alloc] init];
	
	NSDictionary* entry = [NSDictionary dictionaryWithObjectsAndKeys: 
		filename, @"filename",
		type, @"type",
		nil];
	
	[searchItems addObject: entry];
}

// = Controlling the search itself =

- (void) startSearch {
	if (searching) return;		// Nothing to do
	
	// Create the communication channels
	port1 = [[NSPort port] retain];
	port2 = [[NSPort port] retain];

	[[NSRunLoop currentRunLoop] addPort: port1
								forMode: NSDefaultRunLoopMode];

	subThread = [[NSConnection allocWithZone: [self zone]] initWithReceivePort: port1
																	  sendPort: port2];
	[subThread setRootObject: self];	
	
	// Fire off the search thread
	searching = YES;
	[progress startAnimation: self];
	
	[self retain]; // Retain until the thread finishes
	[NSThread detachNewThreadSelector: @selector(IFsearchThread)
							 toTarget: self
						   withObject: nil];
	
	// At this point, all of the search status data belongs to the subthread, NOT the main thread
	// It must not be accessed from the main thread again
}

- (void) stopSearch {
	if (subThread && searching) {
		[(IFSearchResultsController*)[subThread rootProxy] abortSearch];
	}
}

- (BOOL) searchRunning {
	return searching;
}

// = The search delegate =

- (void) setDelegate: (id) newDelegate {
	if (delegate) [delegate release];
	delegate = [newDelegate retain];
}

// = Table data source =

- (int)numberOfRowsInTableView: (NSTableView*) aTableView {
	return [searchResults count];
}

- (id)				tableView: (NSTableView*) aTableView 
	objectValueForTableColumn: (NSTableColumn*) aTableColumn
						  row: (int) rowIndex {
	NSString* ident = [aTableColumn identifier];
	NSDictionary* row = [searchResults objectAtIndex: rowIndex];
	
	if ([ident isEqualToString: @"file"]) {
		return [row objectForKey: @"displayname"];
	} else if ([ident isEqualToString: @"type"]) {
		return [row objectForKey: @"type"];
	} else if ([ident isEqualToString: @"context"]) {
		return [row objectForKey: @"context"];
	}

	return nil;
}

- (void)tableViewSelectionDidChange: (NSNotification *)aNotification {
	if ([tableView numberOfSelectedRows] != 1) return;
	
	int selectedRow = [tableView selectedRow];
	
	if (delegate && [delegate respondsToSelector: @selector(searchSelectedItemAtLocation:inFile:type:)]) {
		NSDictionary* row = [searchResults objectAtIndex: selectedRow];
		
		[delegate searchSelectedItemAtLocation: [[row objectForKey: @"location"] intValue] 
										inFile: [row objectForKey: @"filename"]
										  type: [row objectForKey: @"type"]];
	}
}


// = Functions that the search thread uses to communicate with the main thread =

int resultComparator(id a, id b, void* context) {
	NSDictionary* one = a;
	NSDictionary* two = b;
	
	NSString* str1;
	NSString* str2;
	
	NSComparisonResult res;
	
	// First compare types
	str1 = [one objectForKey: @"type"];
	str2 = [two objectForKey: @"type"];
	
	res = [str1 compare: str2];
	if (res != NSEqualToComparison) return res;
	
	// Then compare display names
	str1 = [one objectForKey: @"displayname"];
	str2 = [two objectForKey: @"displayname"];
	
	res = [str1 compare: str2];
	if (res != NSEqualToComparison) return res;
	
	// Finally, compare locations
	NSNumber* num1, *num2;
	
	num1 = [one objectForKey: @"location"];
	num2 = [two objectForKey: @"location"];
	
	return [num1 compare: num2];
}

- (void) threadHasFinishedSearching {
	// Sort the results
	[searchResults sortUsingFunction: resultComparator
							 context: nil];
	
	// Force an update of the table
	[tableView reloadData];
	
	// Stop spinning the progress meter
	[progress stopAnimation: self];
	
	// Get rid of the subthread connection (it retains us)
	[subThread release];
	subThread = nil;
}

- (void) foundMatchInFile: (NSString*) filename
				 location: (int) location
			  displayName: (NSString*) displayname
					 type: (NSString*) type
				  context: (NSAttributedString*) context {
	// Make the context centered (need to do this to work around a bug in NSMutableParagraphStyle)
	NSMutableAttributedString* centeredContext = [[NSMutableAttributedString alloc] initWithAttributedString: context];
	[centeredContext addAttribute: NSParagraphStyleAttributeName
							value: centered
							range: NSMakeRange(0, [centeredContext length])];
	
	// Add a new entry to the search results
	NSDictionary* resultEntry = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithString: filename], @"filename",
		[NSNumber numberWithInt: location], @"location",
		[NSString stringWithString: displayname], @"displayname",
		[NSString stringWithString: type], @"type",
		[centeredContext autorelease], @"context",
		nil];
	
	if (searchResults == nil) searchResults = [[NSMutableArray alloc] init];
	
	[searchResults addObject: resultEntry];
	
	if (!waitingForReload) {
		// Queue a reload of the table for later (allows many matches to come in before wasting time redrawing)
		waitingForReload = YES;
		[self performSelector: @selector(forceReload)
				   withObject: nil
				   afterDelay: 0.25];
	}
}

- (void) forceReload {
	// Sort the results
	[searchResults sortUsingFunction: resultComparator
							 context: nil];

	// Reload the search data
	waitingForReload = NO;
	[tableView reloadData];
}

- (NSString*) loadHTMLFile: (NSString*) filename
				attributes: (NSDictionary**) attributes {
	// NSString initWithHTMLData turns out to be non-threadsafe
	// (I can't imagine a good reason for this, but it's what we have to work with)
	// This is really annoying
	NSData* fileData = [NSData dataWithContentsOfFile: filename];
	NSDictionary* attr = nil;
	
	if (fileData == nil) return nil;
	
	NSAttributedString* str = [[[NSAttributedString alloc] initWithHTML: fileData
													 documentAttributes: &attr] autorelease];
	
	if (attr) *attributes = attr;
	
	// Can't return the attributed version thanks to bugs in NSParagraphStyle
	return [str string];
}

// = Functions that the main thread uses to communicate with the search thread =

- (void) abortSearch {
	searching = NO;
}

// = The search thread itself =

- (NSString*) stripNewlines: (NSString*) stringToStrip {
	// Replace newlines with spaces in stringToStrip
	NSMutableString* res = [[stringToStrip mutableCopy] autorelease];
	
	[res replaceOccurrencesOfString: @"\n"
						 withString: @" "
							options: NSLiteralSearch
							  range: NSMakeRange(0, [res length])];
	
	return res;
}

- (void) IFsearchThread {
	// START
	NSAutoreleasePool* primaryPool = [[NSAutoreleasePool alloc] init];
	
	// Searching is low priority
	[NSThread setThreadPriority: 0.1];
	
	// Complete the connection
	[[NSRunLoop currentRunLoop] addPort: port2
                                forMode: NSDefaultRunLoopMode];
	mainThread = [[NSConnection allocWithZone: [self zone]] initWithReceivePort: port2
																	   sendPort: port1];
	[mainThread setRootObject: self];
	
	// RUN
	
	// Run a runloop so we can receive two-way communication
	NSRunLoop* currentLoop = [NSRunLoop currentRunLoop];
	
	while (searching) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		// Run for a while
		[currentLoop acceptInputForMode: NSDefaultRunLoopMode
							 beforeDate: [[NSDate date] addTimeInterval: 0.01]];
		
		// Get the next search item
		NSDictionary* searchItem = [[[searchItems lastObject] retain] autorelease];
		[searchItems removeLastObject];
		
		// Retrieve an NSString object for it (if we can)
		NSString* storage = [searchItem objectForKey: @"storage"];
		NSString* filename = [searchItem objectForKey: @"filename"];
		NSString* type = [searchItem objectForKey: @"type"];
			
		NSString* displayName = [filename lastPathComponent];
				
		if (storage == nil && filename != nil) {
			// What we do depends on file type
			NSAttributedString* res = nil;
			NSString* extn = [[filename pathExtension] lowercaseString];
			
			// .inf, .h, .ni, .txt and those with no extension are treated as text files
			// .rtf or .rtfd are opened as RTF files
			// .html or .htm are opened as HTML files
			// all other file types are not searched
			if (extn == nil ||
				[extn isEqualToString: @""] ||
				[extn isEqualToString: @"h"] ||
				[extn isEqualToString: @"ni"] ||
				[extn isEqualToString: @"inf"] ||
				[extn isEqualToString: @"txt"]) {
				NSString* fileContents = [NSString stringWithContentsOfFile: filename];
				if (fileContents) res = [[[NSAttributedString alloc] initWithString: fileContents] autorelease];
			} else if ([extn isEqualToString: @"rtf"] ||
					   [extn isEqualToString: @"rtfd"]) {
				res = [[[NSAttributedString alloc] initWithPath: filename 
											 documentAttributes: nil] autorelease];
			} else if ([extn isEqualToString: @"html"] ||
					   [extn isEqualToString: @"htm"]) {
				NSDictionary* attr = nil;
				storage = [(IFSearchResultsController*)[mainThread rootProxy] loadHTMLFile: filename
																				attributes: &attr];
				
				if (storage) {
					// Although it is not documented (for some reason), the @"Title" attribute now contains the
					// document title. We'll take some care and assume this will always be true provided that
					//		- the Title attribute exists
					//		- it's a string
					NSString* title = [attr objectForKey: @"Title"];
					
					if (title && [title isKindOfClass: [NSString class]]) {
						displayName = [[title copy] autorelease];
					}
				}
			}
			
			if (res) {
				storage = [res string];
			}
		}
		
		// storage now contains the string for the file/internal data - search it
		if (storage) {
			// Create the scanner to search the string
			NSScanner* stringScanner = [NSScanner scannerWithString: storage];
			
			[stringScanner setCaseSensitive: caseSensitive];
			
			// Scan until we get no more matches
			while (![stringScanner isAtEnd]) {
				BOOL found = NO;
				
				if (![stringScanner scanUpToString: searchPhrase
										intoString: nil])
					break;
				
				// We've found the phrase
				found = YES;
				int location = [stringScanner scanLocation];
				
				if (location >= [storage length])
					break;		// Oops, actually, we haven't
				
				// If we have to match words, or starts of words, then check for this
				if (searchType == IFSearchStartsWith || searchType == IFSearchWholeWord) {
					found = NO;
					
					// Must be at the start, or preceded by whitespace
					if (location != 0) {
						unichar chr = [storage characterAtIndex: location-1];
						
						if (chr == '\n' || chr == '\t' || chr == ' ' || chr == '\r') {
							// Is preceded by whitespace, so is a word
							found = YES;
						}
					} else {
						// At start: is the start of a word
						found = YES;
					}
				}
				
				if (found && searchType == IFSearchWholeWord) {
					found = NO;
					
					// Must be followed by whitespace, or at the end of the file
					int endLoc = location + [searchPhrase length];
					
					if (endLoc >= [storage length]) {
						// At end
						found = YES;
					} else {
						unichar chr = [storage characterAtIndex: endLoc];
						
						if (chr == '\n' || chr == '\t' || chr == ' ' || chr == '\r') {
							// Is followed by whitespace, so is a word
							found = YES;
						}
					}
				}
				
				// If we've still got a match then send it to the main thread
				if (found) {
					NSString* contextLeft;
					NSString* contextRight;
					
					// Context is contextLength characters either side of the match. Newlines are translated
					int lowContext  = location - contextLength;
					int highContext = location + [searchPhrase length] + contextLength;
					
					if (lowContext < 0) lowContext = 0;
					if (highContext > [storage length]) highContext = [storage length];
					
					// Work out the left and right-hand sides of the context
					contextLeft = [storage substringWithRange: NSMakeRange(lowContext, location - lowContext)];
					contextRight = [storage substringWithRange: NSMakeRange(location, highContext - location)];
					
					contextLeft = [self stripNewlines: contextLeft];
					contextRight = [self stripNewlines: contextRight];
					
					// Create the context string itself
					NSMutableAttributedString* context = [[NSMutableAttributedString alloc] initWithString: contextLeft
																								attributes: normalAttributes];
					[context appendAttributedString: [[[NSAttributedString alloc] initWithString: contextRight
																					  attributes: normalAttributes] autorelease]];
					
					// Bolden the context
					[context addAttributes: boldAttributes
									 range: NSMakeRange([contextLeft length], [searchPhrase length])];
					
					// Store the result
					[(IFSearchResultsController*)[mainThread rootProxy] foundMatchInFile: filename
																				location: location
																			 displayName: displayName
																					type: type 
																				 context: context];
					
					[context release];
				}
				
				// Advance the scan position
				int length = found?[searchPhrase length]:1;
				if (![stringScanner isAtEnd] && location+length < [storage length])
					[stringScanner setScanLocation: location+length];
			}
		}
		
		// Stop searching if we've run out of items
		if ([searchItems count] <= 0)
			searching = NO;
		
		// Clean up
		[pool release];
	}
	
	// Tell the main thread we've finished
	[(IFSearchResultsController*)[mainThread rootProxy] threadHasFinishedSearching];

	// Accept any last orders (hopefully, this avoids a race condition when stopSearch is called from the main thread)
	[currentLoop acceptInputForMode: NSDefaultRunLoopMode
						 beforeDate: [[NSDate date] addTimeInterval: 0.25]];

	// FINISH
	[mainThread autorelease]; mainThread = nil;
	
	[port1 release]; port1 = nil;
	[port2 release]; port2 = nil;

	// Will have been retained when the thread was detached
	[self autorelease];
	
	[primaryPool release];
}

@end
