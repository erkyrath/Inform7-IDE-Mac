//
//  IFWebUriHandler.h
//  Inform
//
//  Created by Andrew Hunter on 28/04/2012.
//  Copyright (c) 2012 Andrew Hunter. All rights reserved.
//

#import <Foundation/Foundation.h>

///
/// NSURLProtocol handler that supplies the runtime:// URL protocol used to run the game in a browser window
///
/// Individual projects need to (de)register a path in order to have a unique address. A limitation of NSURLProtocol
/// is that it is system-wide, so there's no way to have individual handlers for different web views.
///
@interface IFWebUriProtocol : NSURLProtocol {
    NSURLRequest*           m_Request;                      // The URL request for this object
    NSCachedURLResponse*    m_CachedResponse;               // The cached response for this request
    id<NSURLProtocolClient> m_Client;                       // The client for this request
}

/// Registers a game folder at the specified path. Returns the URL that can be used to access it
+ (NSURL*) registerFolder: (NSString*) name
                   atPath: (NSURL*) path;

/// Unregisters a URL registered by registerFolder
+ (void) deregisterFolder: (NSURL*) prefixUrl;

@end
