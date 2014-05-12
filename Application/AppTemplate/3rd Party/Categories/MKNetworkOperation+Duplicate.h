//
//  BMNetworkOperation.h
//  Bubbly
//
//  Created by Dmitry Klimkin on 10/10/12.
//
//

#import "MKNetworkOperation.h"
#import "MKNetworkEngine.h"

@interface MKNetworkOperation (Duplicate)

- (MKNetworkOperation*) getDupOperationWithNetworkManager: (MKNetworkEngine *)networkManager;
- (NSString *)responseContentType;

@end
