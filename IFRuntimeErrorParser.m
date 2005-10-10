//
//  IFRuntimeErrorParser.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 10/10/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFRuntimeErrorParser.h"


@implementation IFRuntimeErrorParser

- (void) setDelegate: (id) newDelegate {
	delegate = newDelegate;
}

- (void) outputText: (NSString*) outputText {
	// Scan for '*** Run-time problem XX' at the beginning of a line: this indicates that runtime problem XX
	// has occured (and we should probably be showing file RTP_XX.html)
	NSString* runtimeIndicator = @"*** Run-time problem ";
	NSString* problemType = nil;
	
	int len = [outputText length];
	int pos;
	int indicatorLen = [runtimeIndicator length];
	
	for (pos = 0; pos<len-indicatorLen-1; pos++) {
		unichar chr = [outputText characterAtIndex: pos];
		
		if (chr == '\n') {
			// Characters following pos might be the run-time problem indicator
			NSString* mightMatch = [outputText substringWithRange: NSMakeRange(pos+1, indicatorLen)];
			
			if ([mightMatch isEqualToString: runtimeIndicator]) {
				// We've got a match for the string: find the problem identifier
				pos += indicatorLen+1;
				
				int startOfId = pos;
				for (;pos<len; pos++) {
					chr = [outputText characterAtIndex: pos];
					
					if (chr == ' ' || chr == '\t' || chr == '\n' || chr == '\r') {
						// We've found the end of the ID
						break;
					}
					
					// Copy the problem type
					problemType = [outputText substringWithRange: NSMakeRange(startOfId, pos-startOfId+1)];
				}
				
				break;
			}
		}
	}
	
	if (problemType != nil) {
		// A problem was encountered: inform the delegate
		if (delegate && [delegate respondsToSelector: @selector(runtimeError:)]) {
			[delegate runtimeError: problemType];
		}
	}
}

@end
