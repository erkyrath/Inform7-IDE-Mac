//
//  IFWebUriProtocol.m
//  Inform
//
//  Created by Andrew Hunter on 28/04/2012.
//  Copyright (c) 2012 Andrew Hunter. All rights reserved.
//

#import "IFWebUriProtocol.h"

/// Maps URL prefixes to game paths
static NSMutableDictionary* s_Folders = nil;

@implementation IFWebUriProtocol

+ (void) init {
    s_Folders = [[NSMutableDictionary alloc] init];
}

///
/// Registers a game folder at the specified path. Returns the URL that can be used to access it
///
+ (NSURL*) registerFolder: (NSString*) name
                   atPath: (NSURL*) path {
    // Generate a unique prefix based on the name
    int index = 0;
    
    for (;;) {
        // Create a prefix for this index
        NSString* prefix;
        
        if (index <= 0) {
            prefix = [[name copy] autorelease];
        } else {
            prefix = [NSString stringWithFormat: @"%@_%i", name, index];
        }
        
        // Turn into a URL
        NSURL* prefixUrl = [NSURL URLWithString: prefix 
                                  relativeToURL: [NSURL URLWithString: @"runtime://"]];
        
        // See if this is already register
        if ([s_Folders objectForKey: prefixUrl] == nil) {
            // Register this folder
            [s_Folders setObject: path
                          forKey: prefixUrl];
            
            // Return as the result
            return prefixUrl;
        }
    }
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	// We respond to 'runtime://Foo' style URLs
	if ([[[request URL] scheme] isEqualToString: @"runtime"]) {
		if ([[request URL] path] != nil)
			return YES;
	}
	return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}

///
/// Unregisters a URL registered by registerFolder
///
+ (void) deregisterFolder: (NSURL*) prefixUrl {
    [s_Folders removeObjectForKey: prefixUrl];
}

///
/// Initialises this object
///
- (id)initWithRequest:(NSURLRequest *)request 
       cachedResponse:(NSCachedURLResponse *)cachedResponse 
               client:(id < NSURLProtocolClient >)client {
    self = [super initWithRequest: request cachedResponse: cachedResponse client: client];
    
    if (self) {
        m_Request           = [request retain];
        m_CachedResponse    = [cachedResponse retain];
        m_Client            = [client retain];
    }
    
    return self;
}

///
/// Finalises this object
///
- (void) dealloc {
    [m_Request          release];
    [m_CachedResponse   release];
    [m_Client           release];
    
    [super dealloc];
}

///
/// The cached response
///
-(NSCachedURLResponse *)cachedResponse {
	return m_CachedResponse;
}

///
/// The client that this will send data to
///
-(id <NSURLProtocolClient>)client {
	return m_Client;
}

///
/// Request to stop loading a particular URL
///
- (void)stopLoading {
    // Nothing to do
}

///
/// Request to start loading from a particular URL
///
- (void) startLoading {
    // Get the prefix and target path URLs
    NSURL*          prefixUrl   = nil;
    NSURL*          targetPath  = nil;
    
    // Fetch the URL path that was requested
    NSString*       urlPath     = [[m_Request URL] path];
    
    // Iterate through the possible prefixes
    NSEnumerator*   prefixEnum  = [s_Folders keyEnumerator];
    NSURL*          testUrl;
    
    while (testUrl = [prefixEnum nextObject]) {
        // Get the path for this URL
        NSString* prefixPath = [testUrl path];
        
        // If the request URL begins with this path, then this is our URL
        if ([urlPath hasPrefix: [prefixPath stringByAppendingString: @"/"]]
            || [urlPath isEqualToString: prefixPath]) {
            // This URL matches this prefix
            prefixUrl   = testUrl;
            targetPath  = [s_Folders objectForKey: prefixUrl];
            break;
        }
    }
    
    // Fail if we didn't find a prefix
    if (!prefixUrl || !targetPath || [[prefixUrl path] length] > [urlPath length]) {
        [m_Client URLProtocol: self
             didFailWithError: [NSError errorWithDomain: NSURLErrorDomain
                                                   code: NSURLErrorCannotOpenFile
                                               userInfo: nil]];
        return;
    }
    
    // Get the relative path by removing the prefix
    NSString* relativePath = [urlPath substringFromIndex: [[prefixUrl path] length]];
    if ([relativePath length] > 0 && [relativePath characterAtIndex: 0] == L'/') {
        relativePath = [relativePath substringFromIndex: 1];
    }
    
    // Use 'index.html' if the relative path is empty
    // TODO: or ends with '/'?
    if ([relativePath length] == 0) {
        relativePath = @"index.html";
    }
    
    // Search the target path
    NSFileManager*  fileManager         = [NSFileManager defaultManager];
    NSURL*          combinedTargetPath  = [targetPath URLByAppendingPathComponent: relativePath];
    NSURL*          loadFrom            = nil;
    
    if ([combinedTargetPath isFileURL]) {
        if ([fileManager fileExistsAtPath: [combinedTargetPath path]]) {
            loadFrom = combinedTargetPath;
        }
    }
    
    // Try inside the application
    if (!loadFrom) {
        NSURL* appUrl = [[NSBundle mainBundle] URLForResource: [relativePath stringByDeletingPathExtension]
                                                withExtension: [relativePath pathExtension]
                                                 subdirectory: @"HtmlRuntime"];
        
        loadFrom = appUrl;
    }
    
    // Error if we could get no URL
    if (!loadFrom) {
        [m_Client URLProtocol: self
             didFailWithError: [NSError errorWithDomain: NSURLErrorDomain
                                                   code: NSURLErrorCannotOpenFile
                                               userInfo: nil]];
        return;        
    }
    
    // Request this URL
    NSData* responseData = [NSData dataWithContentsOfURL: loadFrom];
    if (!responseData) {
        [m_Client URLProtocol: self
             didFailWithError: [NSError errorWithDomain: NSURLErrorDomain
                                                   code: NSURLErrorCannotOpenFile
                                               userInfo: nil]];
        return;                
    }

    // Work out the MIME type
	NSString* ourType = @"text/html";
	if ([[relativePath pathExtension] isEqualToString: @"gif"])
		ourType = @"image/gif";
	else if ([[relativePath pathExtension] isEqualToString: @"jpeg"] ||
			 [[relativePath pathExtension] isEqualToString: @"jpg"])
		ourType = @"image/jpeg";
	else if ([[relativePath pathExtension] isEqualToString: @"png"])
		ourType = @"image/png";
	else if ([[relativePath pathExtension] isEqualToString: @"tiff"] ||
			 [[relativePath pathExtension] isEqualToString: @"tif"])
		ourType = @"image/tiff";

	// Create the response
	NSURLResponse* response = [[NSURLResponse alloc] initWithURL: [m_Request URL]
														MIMEType: ourType
										   expectedContentLength: [responseData length]
												textEncodingName: nil];
	
	[m_Client URLProtocol: self
       didReceiveResponse: [response autorelease]
       cacheStoragePolicy: NSURLCacheStorageAllowedInMemoryOnly];
	
	// We loaded the data
	[m_Client URLProtocol: self
              didLoadData: responseData];
	
	// We finished loading
	[m_Client URLProtocolDidFinishLoading: self];    
}

@end
