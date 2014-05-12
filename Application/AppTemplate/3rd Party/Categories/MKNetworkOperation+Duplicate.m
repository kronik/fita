//
//  BMNetworkOperation.m
//  Bubbly
//
//  Created by Dmitry Klimkin on 10/10/12.
//
//

#import "MKNetworkOperation+Duplicate.h"

@implementation MKNetworkOperation (Duplicate)

- (MKNetworkOperation*) getDupOperationWithNetworkManager: (MKNetworkEngine *)networkManager {
    
    // 1. Extract original URL:
    NSString *originalURL = [[self.url componentsSeparatedByString:@"?"] objectAtIndex:0];
    NSString *originalHTTPMethod = self.HTTPMethod;
    NSArray  *dataToBePosted = [self valueForKey:@"dataToBePosted"];

    // 2. Update parameters with new session and access tokens:
    NSDictionary *originalParameters = [self valueForKey:@"fieldsToBePosted"];
    NSMutableDictionary *newParameters = [originalParameters mutableCopy];

    // 3. Create new operation based on previous operation:
    MKNetworkOperation *dupOperation = [networkManager operationWithURLString: originalURL
                                                                       params: newParameters
                                                                   httpMethod: originalHTTPMethod];
    // 4. Get back all handlers:
    [dupOperation updateHandlersFromOperation: self];
    
    // 5. Add files to upload if any:
    if (dataToBePosted != nil && dataToBePosted.count > 0)
    {
        NSMutableDictionary *dataToSend = [dataToBePosted objectAtIndex:0];

        [dupOperation addData: [dataToSend objectForKey:@"data"]
                       forKey: [dataToSend objectForKey:@"name"]
                     mimeType: [dataToSend objectForKey:@"mimetype"]
                     fileName: [dataToSend objectForKey:@"filename"]];
    }
    
    return dupOperation;
}

- (NSString *)responseContentType {
    NSString *contentType = [[self.readonlyResponse allHeaderFields] valueForKey:@"Content-Type"];
    
    if (contentType.length == 0) {
        contentType = [[self.readonlyResponse allHeaderFields] valueForKey:@"content-type"];
    }
    return contentType;
}


@end

