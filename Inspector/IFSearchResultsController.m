//
//  IFSearchResultsController.m
//  Inform
//
//  Created by Andrew Hunter on 29/01/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFSearchResultsController.h"

#import "IFAppDelegate.h"

#define contextLength 12

// Objects used for display
static NSFont* normalFont;
static NSFont* boldFont;

static NSMutableParagraphStyle* centered;

static NSDictionary* normalAttributes;
static NSDictionary* boldAttributes;

// SearchKit
// NOTE: the SearchKit index is created under 10.3 but not used, as SearchKit under 10.3 is intolerably buggy. The '10.3' search code will only actually work under 10.4, so it's dead for the moment.
static SKIndexRef searchIndex = nil;							// The global search index for things that request to use SearchKit
static NSDate* indexDate = nil;									// The date on the search index
static NSString* indexName = @"IFSearchResultsControllerIndex";	// The index name
static NSMutableSet* indexedFiles = nil;						// Set of filenames that we've already added the SK index

@implementation IFSearchResultsController

// = Initialisation =

+ (void) initialize {
	// We use these fonts while formatting the context
	normalFont = [[NSFont systemFontOfSize: 11] retain];
	boldFont = [[NSFont boldSystemFontOfSize: 11] retain];
	
	// NSMutableParagraphStyle is not well-behaved at all. We can't pass it from one thread to another:
	// it fails to encode or copy correctly. We can only set it in the main thread
	centered = [[NSMutableParagraphStyle alloc] init];
	[centered setAlignment: NSJustifiedTextAlignment];
	
	// Create the attribute dictionaries
	normalAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
		normalFont, NSFontAttributeName,
		nil] retain];
	boldAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
		boldFont, NSFontAttributeName,
		nil] retain];
	
	// Create the global search index
	SKLoadDefaultExtractorPlugIns();
	NSString* indexFile = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
	
	// (Yes, Application Support is localized. It's a huge pain to take account of this, though, so I don't at the moment)
	indexFile = [indexFile stringByAppendingPathComponent: @"Application Support"];
	if (![[NSFileManager defaultManager] fileExistsAtPath: indexFile]) {
		[[NSFileManager defaultManager] createDirectoryAtPath: indexFile
												   attributes: nil];
	}
	indexFile = [indexFile stringByAppendingPathComponent: @"Inform"];
	if (![[NSFileManager defaultManager] fileExistsAtPath: indexFile]) {
		[[NSFileManager defaultManager] createDirectoryAtPath: indexFile
												   attributes: nil];
	}
	
	indexFile = [indexFile stringByAppendingPathComponent: @"SearchIndex.SKindex"];
	
	if (![[NSFileManager defaultManager] fileExistsAtPath: indexFile]) {
		// Create the index file
		searchIndex = SKIndexCreateWithURL((CFURLRef)[NSURL fileURLWithPath: indexFile],
										   (CFStringRef)indexName,
										   kSKIndexInvertedVector,
										   NULL);

		// Get the index date
		indexDate = [[[NSFileManager defaultManager] fileAttributesAtPath: indexFile
															 traverseLink: YES] objectForKey: NSFileModificationDate];
	} else {
		// Get the index date
		indexDate = [[[NSFileManager defaultManager] fileAttributesAtPath: indexFile
															 traverseLink: YES] objectForKey: NSFileModificationDate];

		// Open the index file
		searchIndex = SKIndexOpenWithURL((CFURLRef)[NSURL fileURLWithPath: indexFile],
										 (CFStringRef)indexName,
										 YES);
		CFRetain(searchIndex);
	}
	
	indexedFiles = [[NSMutableSet alloc] init];
	
	[indexDate retain];
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
	
	if (searchTypes) [searchTypes release];

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
		[NSNumber numberWithBool: NO], @"searchkit",
		nil];
	
	[searchItems addObject: entry];
	
	if (searchTypes == nil) searchTypes = [[NSMutableSet alloc] init];
	[searchTypes addObject: type];
}

- (void) addSearchFile: (NSString*) filename
				  type: (NSString*) type
		  useSearchKit: (BOOL) useSearchKit {
	[self cantChangeSearchAfterStarting];
	
	if (searchItems == nil) searchItems = [[NSMutableArray alloc] init];
	if (NSAppKitVersionNumber < 824.0) {
		// OS X version 10.3 has a version of SearchKit that is too buggy to be used. Therefore, support must be disabled.
		// There is also no constant for the AppKit supplied in 10.4: 824.0 seems to be accurate enough however.
		useSearchKit = NO;
	}
	
	NSDictionary* entry = [NSDictionary dictionaryWithObjectsAndKeys: 
		filename, @"filename",
		type, @"type",
		[NSNumber numberWithBool: useSearchKit], @"searchkit",
		nil];
	
	[searchItems addObject: entry];
	
	if (searchTypes == nil) searchTypes = [[NSMutableSet alloc] init];
	[searchTypes addObject: type];
}

// = Controlling the search itself =

- (void) startSearch {
	if (searching) return;		// Nothing to do
	
	// Remove columns from the table as required
	if ([searchItems count] < 2) {
		// If there's only one place to look, then we don't need to show the file names
		[tableView removeTableColumn: [tableView tableColumnWithIdentifier: @"file"]];
	}
	
	if ([[searchTypes allObjects] count] < 2) {
		// If we're only searching across one type of document, then we don't need to show the document types
		[tableView removeTableColumn: [tableView tableColumnWithIdentifier: @"type"]];
	}
	
	[tableView sizeLastColumnToFit];
	
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
		// Localise the type name
		NSString* key = [@"SearchType " stringByAppendingString: [row objectForKey: @"type"]];
		
		return [[NSBundle mainBundle] localizedStringForKey: key
													  value: key
													  table: nil];
	} else if ([ident isEqualToString: @"context"]) {
		return [row objectForKey: @"context"];
	}

	return nil;
}

- (void)tableViewSelectionDidChange: (NSNotification *)aNotification {
	if ([tableView numberOfSelectedRows] != 1) return;
	
	int selectedRow = [tableView selectedRow];
	
	if (delegate && [delegate respondsToSelector: @selector(searchSelectedItemAtLocation:phrase:inFile:type:)]) {
		NSDictionary* row = [searchResults objectAtIndex: selectedRow];
		
		[delegate searchSelectedItemAtLocation: [[row objectForKey: @"location"] intValue] 
										phrase: searchPhrase
										inFile: [row objectForKey: @"filename"]
										  type: [row objectForKey: @"type"]];
	}
}

// = Functions that the search thread uses to communicate with the main thread =

static NSString* startingNumber(NSString* string) {
	// Returns an empty string if string doesn't begin with a number
	int pos = 0;
	int length = [string length];
	
	// Skip initial whitespace (actually, only spaces, but this should do for our purposes
	while (pos < length && [string characterAtIndex: pos] == ' ') pos++;
	
	// Read a number of the form xx.xx
	BOOL gotDecimal = NO;
	
	int startPos = pos;
	
	while (pos < length) {
		unichar chr = [string characterAtIndex: pos];
		
		if (chr == '.' && gotDecimal)  {
			break;
		}
		if (chr == '.') {
			gotDecimal = YES;
			pos++;
			continue;
		}
		
		if (chr > 127 || !isdigit(chr)) {
			break;
		}
		
		pos++;
	}
	
	if (pos == startPos) return nil; // No number at start
	if (gotDecimal && pos == startPos+1) return nil; // String would be just '.' which isn't a number
	
	// startPos - pos is a decimal number
	return [string substringWithRange: NSMakeRange(startPos, pos - startPos)];
}

static int resultComparator(id a, id b, void* context) {
	NSDictionary* one = a;
	NSDictionary* two = b;
	
	NSString* str1;
	NSString* str2;
	
	NSComparisonResult res;
	
	// First compare types
	str1 = [one objectForKey: @"type"];
	str2 = [two objectForKey: @"type"];
	
	res = [str1 compare: str2];
	if (res != NSOrderedSame) return res;
	
	// Then compare display names
	str1 = [one objectForKey: @"displayname"];
	str2 = [two objectForKey: @"displayname"];
	
	// If str1 and str2 both begin with a number, then compare numerically (floating-point)
	NSString* num1 = startingNumber(str1);
	NSString* num2 = startingNumber(str2);
		
	if (num1 && num2) {
		// Section ordering. IE, 10.1 < 10.14 here
		NSArray* nums1 = [num1 componentsSeparatedByString: @"."];
		NSArray* nums2 = [num2 componentsSeparatedByString: @"."];
		
		int pos = 0;
		
		while (pos < [nums1 count] && pos < [nums2 count]) {
			int v1 = [[nums1 objectAtIndex: pos] intValue];
			int v2 = [[nums2 objectAtIndex: pos] intValue];
			
			if (v1 < v2)
				return NSOrderedAscending;
			else if (v1 > v2)
				return NSOrderedDescending;
			
			pos++;
		}
	}
	
	// Otherwise compare alphanumerically
	res = [str1 caseInsensitiveCompare: str2];
	if (res != NSOrderedSame) return res;
	
	// Finally, compare locations
	NSNumber* loc1, *loc2;
	
	loc1 = [one objectForKey: @"location"];
	loc2 = [two objectForKey: @"location"];
	
	return [loc1 compare: loc2];
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
	if (filename == nil) filename = @"NO FILE!";
	if (displayname == nil) displayname = @"NO DISPLAY!";
	if (type == nil) type = @"BUG";
	
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

- (void) searchInIndex: (SKIndexRef) index
		withController: (IFSearchResultsController*) resultsDest {
	// Search a SearchKit index for results
#if 0
	if (NSAppKitVersionNumber >= 824.0) {
		// Use 10.4 async search and summarisation tools
		SKSearchRef search = SKSearchCreate(index,
											(CFStringRef)searchPhrase,
											searchType==IFSearchWholeWord?0:kSKSearchOptionFindSimilar);
		
		// Search for matches
		const int maxMatches = 5;
		
		SKDocumentID resultDocID[maxMatches];
		float resultScore[maxMatches];
		CFIndex numFound;
		BOOL needAnotherFlush = NO;
		
		while (SKSearchFindMatches(search, maxMatches, resultDocID, resultScore, 0.1, &numFound)) {
			// Process the matches
			int match;
			
			for (match=0; match < numFound; match++) {
				// Get the indexed document
				SKDocumentRef docRef = SKIndexCopyDocumentForDocumentID(searchIndex,
																		resultDocID[match]);
								
				// Get the attributes for this document
				NSDictionary* docProps = (NSDictionary*)SKIndexCopyDocumentProperties(searchIndex,
																					  docRef);
				NSURL* docURL = (NSURL*)SKDocumentCopyURL(docRef);
				
				// Summarize the document
				NSString* summary = [docProps objectForKey: @"summary"];
				
				if (summary == nil) {
					// Create the summary
					NSDictionary* attr = nil;
					NSString* docString = [resultsDest loadHTMLFile: [docURL path]
														 attributes: &attr];
					
					SKSummaryRef docSummary = nil;
					if (docString) docSummary = SKSummaryCreateWithString((CFStringRef)docString);
					
					// Store the summary in the properties for this document					
					if (docSummary) {
						// Summarise the document as a single paragraph
						summary = (NSString*)SKSummaryCopySentenceSummaryString(docSummary, 2);
						
						[summary autorelease];
						CFRelease(docSummary);
						
						// Store the summary in the index
						NSMutableDictionary* newDocProps = nil;
						
						if (docProps != nil) newDocProps = [[NSMutableDictionary alloc] initWithDictionary: docProps];
						if (newDocProps == nil) newDocProps = [[NSMutableDictionary alloc] init];
						
						[newDocProps setObject: summary
										forKey: @"summary"];
						
						SKIndexSetDocumentProperties(searchIndex,
													 docRef,
													 (CFDictionaryRef)[NSDictionary dictionaryWithDictionary: newDocProps]);
						
						needAnotherFlush = YES;
						[newDocProps release];
					}
				}
				
				if (summary == nil) summary = @"";
				
				// Send to the main thread
				if ([docURL isFileURL]) {
					[resultsDest foundMatchInFile: [docURL path]
										 location: 0
									  displayName: [docProps objectForKey: @"title"]
											 type: [docProps objectForKey: @"type"]
										  context: [[[NSAttributedString alloc] initWithString: summary] autorelease]];
				}
								
				// Clean up
				[docProps release];
				[docURL release];				
				CFRelease(docRef);
			}
		}
		
		if (needAnotherFlush) {
			SKIndexFlush(searchIndex);
		}
		
		SKSearchCancel(search);
		CFRelease(search);
	} 
	else
	{
		// Use 10.3 synchronous search (sadly, this causes a crash under 10.3 itself: SearchKit in 10.3 seems far too buggy to be used)
		
		// Create the search group
		SKSearchGroupRef group = SKSearchGroupCreate((CFArrayRef)[NSArray arrayWithObject: (NSObject*)index]);
		
		// Get the results
		SKSearchResultsRef results = SKSearchResultsCreateWithQuery(group, 
																	(CFStringRef)searchPhrase, 
																	searchType==IFSearchWholeWord?kSKSearchRanked:kSKSearchPrefixRanked,
																	128,
																	NULL,
																	NULL);
		
		// Pass the results to the main thread
		CFIndex resultsCount = SKSearchResultsGetCount(results);
		CFIndex resultNum;
		const int processCount = 5;
		
		// Process results 5 at a time
		for (resultNum=0; resultNum<resultsCount; resultNum += processCount) {
			CFIndex x;

			SKDocumentRef resultDoc[processCount];
			SKDocumentID resultDocID[processCount];
			SKIndexRef resultIndex[processCount];
			NSString* resultName[processCount];
			float resultScore[processCount];
			
			CFRange range;
			
			range.location = resultNum;
			range.length = processCount;
			if (resultNum+processCount >= resultsCount) range.length = resultsCount-resultNum;
			
			// Extract the results
			CFIndex resultCount = SKSearchResultsGetInfoInRange(results,
																range,
																resultDoc,
																resultIndex,
																resultScore);
			
			// Get the document IDs
			for (x=0; x<resultCount; x++) {
				resultDocID[x] = SKIndexGetDocumentID(searchIndex,resultDoc[x]);
			}
			
			// Get the document names
			SKIndexCopyInfoForDocumentIDs(searchIndex,
										  resultCount,
										  resultDocID,
										  (CFStringRef*)resultName,
										  NULL);
			
			// Send to the main thread
			for (x=0; x<resultCount; x++) {
				NSDictionary* docProps = (NSDictionary*)SKIndexCopyDocumentProperties(resultIndex[x],
																					  resultDoc[x]);
				NSURL* docURL = (NSURL*)SKDocumentCopyURL(resultDoc[x]);
				
				if ([docURL isFileURL]) {
					[resultsDest foundMatchInFile: [docURL path]
										 location: 0
									  displayName: [docProps objectForKey: @"title"]
											 type: [docProps objectForKey: @"type"]
										  context: [[[NSAttributedString alloc] initWithString: @""] autorelease]];
				}
				
				[docProps release];
				[docURL release];
			}
		}
		
		CFRelease(results);
		CFRelease(group);
	}
#endif
}

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
	
	BOOL willUseSearchKit = NO;
	
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
		
		NSDate* lastSearchInterval = [[NSDate date] addTimeInterval: 0.02];

		while (searching && [(NSDate*)[NSDate date] compare: lastSearchInterval] < 0) {
			// Get the next search item
			NSDictionary* searchItem = [[[searchItems lastObject] retain] autorelease];
			[searchItems removeLastObject];
			
			// Retrieve an NSString object for it (if we can)
			NSString* storage = [searchItem objectForKey: @"storage"];
			NSString* filename = [searchItem objectForKey: @"filename"];
			NSString* type = [searchItem objectForKey: @"type"];
			NSNumber* useSearchKit = [searchItem objectForKey: @"searchkit"];
				
			NSString* displayName = [filename lastPathComponent];
					
			if (storage == nil && filename != nil) {
				// What we do depends on file type
				NSAttributedString* res = nil;
				NSString* extn = [[filename pathExtension] lowercaseString];
				
				// Files marked for SearchKit are added to the global index
				// Storage marked for SearchKit isn't dealt with yet
				// .inf, .h, .ni, .txt and those with no extension are treated as text files
				// .rtf or .rtfd are opened as RTF files
				// .html or .htm are opened as HTML files
				// all other file types are not searched
				if (filename != nil && [useSearchKit boolValue]) {
					// We can replace the document in the index if fileDate is greater than the index date
					// (Not ideal: searching extensions might cause a missed documentation update this way)
					willUseSearchKit = YES;
					
					if (![indexedFiles containsObject: filename]) {
						[indexedFiles addObject: filename];
						NSDate* fileDate = [[[NSFileManager defaultManager] fileAttributesAtPath: filename
																					traverseLink: YES] objectForKey: NSFileModificationDate];
						
						// Work out a likely mime type based on the extension
						NSString* mimeType = @"text/plain";

						if ([extn isEqualToString: @"htm"] ||
							[extn isEqualToString: @"html"]) {
							mimeType = @"text/html";
						} else if ([extn isEqualToString: @"pdf"]) {
							mimeType = @"text/pdf";
						} else if ([extn isEqualToString: @"rtf"]) {
							mimeType = @"text/rtf";
						}
						
						// Create a document reference
						SKDocumentRef docRef = SKDocumentCreateWithURL((CFURLRef)[NSURL fileURLWithPath: filename]);
						
						// Get the old properties, if they exist
						// NOTE: Under 10.3 SearchKit has a bug that causes Inform to die here. SearchKit is disabled in 10.3 partly for this reason
						NSDate* lastDate = nil;
						NSDictionary* oldAttr = (NSDictionary*)SKIndexCopyDocumentProperties(searchIndex,
																							 docRef);
						
						if (oldAttr) {
							lastDate = [oldAttr objectForKey: @"fileDate"];
						}
						
						[oldAttr release];
						
						// Only add if the dates are different
						if (lastDate == nil || [lastDate compare: fileDate] < 0) {
							NSString* title = [filename lastPathComponent];

							// Load as HTML if we can. SearchKit can do this for us, but it discards the title, 
							// which we want to keep. In addition, SearchKit calls the HTML loader, which is not
							// always thread safe.
							NSDictionary* attr = nil;
							NSString* htmlStorage = nil;
							
							if ([mimeType isEqualToString: @"text/html"]) {
								htmlStorage = [(IFSearchResultsController*)[mainThread rootProxy] loadHTMLFile: filename
																									attributes: &attr];
							}
							
							if (htmlStorage) {
								// Get the title
								title = [attr objectForKey: @"NSTitleDocumentAttribute"];
								if (title == nil) title = [attr objectForKey: @"Title"];
								if (title == nil) title = [filename lastPathComponent];
																
								// Add the document from the file we just loaded
								SKIndexAddDocumentWithText(searchIndex,
														   docRef,
														   (CFStringRef)htmlStorage,
														   YES);
							} else {
								// Add the document to searchkit, and mark ourselves as wanting to continue searching with SearchKit
								SKIndexAddDocument(searchIndex, docRef, (CFStringRef)mimeType, YES);
							}
							
							// Add attributes to the document
							NSDictionary* docAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
								fileDate, @"fileDate",
								filename, @"filename",
								type, @"type",
								title, @"title",
								nil];
							SKIndexSetDocumentProperties(searchIndex,
														 docRef,
														 (CFDictionaryRef)docAttributes);
						}
						
						// Clear the docRef
						CFRelease(docRef); docRef = nil;
					}
				} else if (extn == nil ||
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
						NSString* title = [attr objectForKey: @"NSTitleDocumentAttribute"];		// Under 10.4 (but can't weak-link to constants)
						if (title == nil) title = [attr objectForKey: @"Title"];				// Undocumented under 10.3
						
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
		}
		
		// Clean up
		[pool release];
	}
		
	if (willUseSearchKit) {
		// Search a SearchKit index
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		// Flush the index
		SKIndexFlush(searchIndex);
		SKIndexCompact(searchIndex);
		
		// Search it
		// NOTE: 10.3 SearchKit has a bug that seems to cause stack corruption while searching. Therefore, SearchKit support is disabled under 10.3
		[self searchInIndex: searchIndex
			 withController: (IFSearchResultsController*)[mainThread rootProxy]];
		
		// Clear the pool
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

// = Adding specific groups of files =

- (void) addDocumentation {
	// Find the documents to search
	NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
	
	// Get all .htm and .html documents from the resources
	NSDirectoryEnumerator* dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: resourcePath];
	NSString* path;
	
	while (path = [dirEnum nextObject]) {
		NSString* extension = [path pathExtension];
		NSString* description = [[[path lastPathComponent] stringByDeletingPathExtension] lowercaseString];
		
		// Must be an html file...
		// and must be the index or a docxxx file
		if ([description isEqualToString: @"index"] ||
			([description length] > 3 && [[description substringToIndex: 3] isEqualToString: @"doc"])) {
			if ([extension isEqualToString: @"html"] ||
				[extension isEqualToString: @"htm"]) {
				[self addSearchFile: [resourcePath stringByAppendingPathComponent: path]
							   type: @"Documentation"
					   useSearchKit: NO];
			}
		}
	}
}

- (void) addExtensions {
	// Search all the extensions that the app delegate returns
	NSArray* extensions = [[NSApp delegate] directoriesToSearch: @"Extensions"];
	NSEnumerator* extnEnum = [extensions objectEnumerator];
	
	NSString* extnDirectory = nil;
	
	// Iterate through all the various places extensions can be hidden
	while (extnDirectory = [extnEnum nextObject]) {
		// Get all the files from the extensions
		NSDirectoryEnumerator* dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: extnDirectory];
		NSString* path;
		
		while (path = [dirEnum nextObject]) {
			NSString* extnPath = [extnDirectory stringByAppendingPathComponent: path];
			BOOL isDir;
			
			if ([[NSFileManager defaultManager] fileExistsAtPath: extnPath 
													 isDirectory: &isDir]) {
				if (!isDir) {
					[self addSearchFile: extnPath
								   type: @"Extension File"
						   useSearchKit: NO];
				}
			}
		}
	}
}

- (void) addFilesFromProject: (IFProject*) project {
	NSDictionary* sourceFiles = [project sourceFiles];
	NSTextStorage* file;
	NSString* filename;
	NSEnumerator* fileEnum = [sourceFiles keyEnumerator];
	
	while (filename = [fileEnum nextObject]) {
		file = [sourceFiles objectForKey: filename];
		
		[self addSearchStorage: [file string]
				  withFileName: filename
						  type: @"Source File"];
	}
}

@end
