//
//  DKFileCache.h
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 18/9/13.
//
//

@import Foundation;

typedef void (^DKFileCacheGetImageBlock)(UIImage *image);
typedef void (^DKFileCacheGetAnimatedImageBlock)(UIImage *image);
typedef void (^DKFileCacheGetAudioBlock)(NSString *audioFilePath);
typedef void (^DownloadCompletionBlock)(BOOL success);

@interface DKFileCache : NSObject

@property (nonatomic, strong) NSString *defaultCacheFolder;

+ (instancetype)sharedInstance;

- (void)imageForUrl: (NSString *)url withCompleteBlock: (DKFileCacheGetImageBlock)completeBlock;
- (void)animatedImageForUrl: (NSString *)url withCompleteBlock: (DKFileCacheGetAnimatedImageBlock)completeBlock;
- (void)audioForUrl: (NSString *)url withCompleteBlock: (DKFileCacheGetAudioBlock)completeBlock;

- (void)removeCachedFileForURL: (NSString *)url;
- (void)clear;
- (void)cancelAllRequests;
- (BOOL)isFileCachedForUrl: (NSString *)url;

- (void)downloadFile:(NSString*)url filePath:(NSString*)filePath onCompletion:(DownloadCompletionBlock)completion;

@end
