//
//  IFInformProtocol.m
//  Inform
//
//  Created by Andrew Hunter on Sat Jun 05 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import "IFInformProtocol.h"


@implementation IFInformProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	// We respond to 'inform:///Foo' style URLs
	if ([[[request URL] scheme] isEqualToString: @"inform"]) {
		if ([[request URL] path] != nil)
			return YES;
		
		NSLog(@"%@ is not a valid inform URL request", request);
	}
	return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	// No idea what this is supposed to do.
	// Docs pretty much say 'whatever you want'
	return request;
}

-(id)initWithRequest:(NSURLRequest *)request 
	  cachedResponse:(NSCachedURLResponse *)cachedResponse 
			  client:(id <NSURLProtocolClient>)client {
	self = [super initWithRequest: request
				   cachedResponse: cachedResponse
						   client: client];
	if (self) {
		theURLRequest = [request retain];
		theCachedResponse = [cachedResponse retain];
		theClient = [client retain];
	}
	
	return self;
}

- (void) dealloc {
	[theURLRequest release];
	[theCachedResponse release];
	[theClient release];
	
	[super dealloc];
}

-(NSCachedURLResponse *)cachedResponse {
	return theCachedResponse;
}

-(id <NSURLProtocolClient>)client {
	return theClient;
}

- (void) startLoading {
	// Might as well load the whole file at once
	NSString* urlPath = [[theURLRequest URL] path];
	NSString* path;
	
	// Try using pathForResource:ofType:
	// Advantage of this is that it will allow for localisation at some point in the future
	// Note: first character will always be '/', hence the 'substring' thing
	path = [[NSBundle mainBundle] pathForResource: [[urlPath substringFromIndex: 1] stringByDeletingPathExtension]
										   ofType: [urlPath pathExtension]];
	if (path == nil) {
		// If that fails, then just append to the resourcePath of the main bundle
		path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString: @"/"] stringByAppendingString: urlPath];
	}

	// Check that this is the right kind of URL for us
	if (path == nil || ![[[theURLRequest URL] scheme] isEqualToString: @"inform"]) {
		// Doh - not a valid inform: URL
		[theClient URLProtocol: self
			  didFailWithError: [NSError errorWithDomain: NSURLErrorDomain
													code: NSURLErrorBadURL
												userInfo: nil]];
		return;
	}
	
	// Check that the file exists and is not a directory
	BOOL isDir = YES;
	if (![[NSFileManager defaultManager] fileExistsAtPath: path
											  isDirectory: &isDir]) {
		isDir = YES;
	}
	
	if (isDir) {
		// Will also happen if the file doesn't exist: see above
		[theClient URLProtocol: self
			  didFailWithError: [NSError errorWithDomain: NSURLErrorDomain
													code: NSURLErrorFileDoesNotExist
												userInfo: nil]];
		// (Yeah, there's technically a difference between NSURLErrorFileDoesNotExist and
		// NSURLErrorFileIsDirectory. But I'm lazy here)
		return;
	}
	
	// Load up the data
	NSData* urlData = [NSData dataWithContentsOfFile: path];
	if (urlData == nil) {
		// Failed to load for some other reason
		[theClient URLProtocol: self
			  didFailWithError: [NSError errorWithDomain: NSURLErrorDomain
													code: NSURLErrorUnknown
												userInfo: nil]];
		return;
	}
		
	// Work out the MIME type
	// Sigh, must be a better way, but it's not obvious
	NSString* ourType = @"text/html";
	if ([[path pathExtension] isEqualToString: @"gif"])
		ourType = @"image/gif";
	else if ([[path pathExtension] isEqualToString: @"jpeg"] ||
			 [[path pathExtension] isEqualToString: @"jpg"])
		ourType = @"image/jpeg";
	else if ([[path pathExtension] isEqualToString: @"png"])
		ourType = @"image/png";
	else if ([[path pathExtension] isEqualToString: @"tiff"] ||
			 [[path pathExtension] isEqualToString: @"tif"])
		ourType = @"image/tiff";

	// Create the response
	NSURLResponse* response = [[NSURLResponse alloc] initWithURL: [theURLRequest URL]
														MIMEType: ourType
										   expectedContentLength: [urlData length]
												textEncodingName: nil];
	
	[theClient URLProtocol: self
		didReceiveResponse: [response autorelease]
		cacheStoragePolicy: NSURLCacheStorageAllowedInMemoryOnly];
	
	// We loaded the data
	[theClient URLProtocol: self
			   didLoadData: urlData];
	
	// We finished loading
	[theClient URLProtocolDidFinishLoading: self];
}

- (void) stopLoading {
}

@end
