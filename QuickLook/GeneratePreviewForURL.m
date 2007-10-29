#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import "IFSyntaxStorage.h"
#import "IFNaturalHighlighter.h"
#import "IFInform6Highlighter.h"

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, 
							   QLPreviewRequestRef preview,
							   CFURLRef cfUrl, 
							   CFStringRef contentTypeUTI, 
							   CFDictionaryRef options)
{	
	// Try to get the file that we're looking at
	NSString* fileName = nil;
	if ([(NSURL*)cfUrl isFileURL]) {
		fileName = [(NSURL*)cfUrl path];
	}
	
	if (!fileName) {
		return noErr;
	}
	
	// Try to get the source code
	BOOL isInform6 = NO;
	NSString* sourceCodeString = nil;
	
	NSString* uti = (NSString*) contentTypeUTI;

	if ([uti isEqualToString: @"org.inform-fiction.source.inform7"]) {
		// ni file
		
		sourceCodeString = [NSString stringWithContentsOfFile: fileName
													 encoding: NSUTF8StringEncoding
														error: nil];

	} else if ([uti isEqualToString: @"org.inform-fiction.source.inform6"]) {
		// inf file
		
		isInform6 = YES;
		sourceCodeString = [NSString stringWithContentsOfFile: fileName
													 encoding: NSUTF8StringEncoding
														error: nil];
		
	} else if ([uti isEqualToString: @"org.inform-fiction.project"]) {
		// project file
		
		isInform6 = NO;
		sourceCodeString = [NSString stringWithContentsOfFile: [[fileName stringByAppendingPathComponent: @"Source"] stringByAppendingPathComponent: @"story.ni"]
													 encoding: NSUTF8StringEncoding
														error: nil];
		
		if (sourceCodeString == nil) {
			sourceCodeString = [NSString stringWithContentsOfFile: [[fileName stringByAppendingPathComponent: @"Source"] stringByAppendingPathComponent: @"main.inf"]
														 encoding: NSUTF8StringEncoding
															error: nil];
			isInform6 = YES;
		}
		
	} else {
		NSLog(@"Unknown UTI: %@", uti);
		return noErr;
	}
	
	if (!sourceCodeString) {
		NSLog(@"No source code");
		return noErr;
	}
	
	// Create a suitable storage object and highlighter
	IFSyntaxStorage* storage = [[[IFSyntaxStorage alloc] initWithString: sourceCodeString] autorelease];
	if (isInform6) {
		[storage setHighlighter: [[[IFInform6Highlighter alloc] init] autorelease]];
	} else {
		[storage setHighlighter: [[[IFNaturalHighlighter alloc] init] autorelease]];		
	}
	
	// Wait until it's all highlighted
	while ([storage highlighterPass]);
	
	// Produce the result
	NSData *theRTF = [storage RTFFromRange:NSMakeRange(0, [storage length]-1) 
						documentAttributes:nil];
	QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)theRTF, kUTTypeRTF, NULL);
	
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
