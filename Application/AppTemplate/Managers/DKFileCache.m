//
//  DKFileCache.m
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 18/9/13.
//
//

#import "DKFileCache.h"
#import "NSString+MD5Addition.h"
#import "UIImage+animatedGIF.h"
#import "AFNetworking.h"

#define DKFileCacheFolder @"file_cache"

@interface DKFileCache () {
    NSMapTable* itemsObjectPool;
    NSMapTable* activeDownloads;
}

@end

@implementation DKFileCache

@synthesize defaultCacheFolder = _defaultCacheFolder;

+ (instancetype)sharedInstance {
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static DKFileCache *_sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[DKFileCache alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

- (id)init {
    self = [super init];
    
	if (self != nil) {
        
        activeDownloads = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory capacity:10];
        
        self.defaultCacheFolder = DKFileCacheFolder;
	}
	return self;
}

- (NSString *)documentsDirectory {
	static NSString *documentsDirectory= nil;
    
	if (! documentsDirectory) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		documentsDirectory = paths [0];
	}
    
	return documentsDirectory;
}

- (void)setDefaultCacheFolder:(NSString *)defaultCacheFolder {
    _defaultCacheFolder = defaultCacheFolder;
    
    [self createDefaultCacheFolder: defaultCacheFolder];
}

- (void)createDefaultCacheFolder: (NSString *)defaultFolder {
    NSString *documentsDirectory = [self documentsDirectory];
    NSString *cacheDirectory = [documentsDirectory stringByAppendingPathComponent:defaultFolder];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:cacheDirectory] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (NSString *)cachedFilePathForURL: (NSString *)url {
    NSArray *fileParts = [url componentsSeparatedByString:@"."];
    
    if (fileParts.count < 2) {
        return nil;
    }
    NSURL *realUrl = [NSURL URLWithString:url];
    NSString *fileKey = [realUrl.path stringFromMD5];
    NSString *cachedFilePath = [NSString stringWithFormat:@"%@/%@/%@.%@",
                                [self documentsDirectory],
                                self.defaultCacheFolder, fileKey, fileParts[fileParts.count - 1]];
    return cachedFilePath;
}

- (void)cacheData: (NSData *)fileData intoFile: (NSString *)filePath {
    [fileData writeToFile:filePath atomically:YES];
}

- (void)imageForUrl: (NSString *)url withCompleteBlock: (DKFileCacheGetImageBlock)completeBlock {
    
    NSString *cachedFilePath = [self cachedFilePathForURL: url];
    
    if (cachedFilePath == nil) {
        completeBlock (nil);
        return;
    }
        
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachedFilePath]) {
        
        UIImage *newImage = [UIImage imageWithContentsOfFile:cachedFilePath];
        
        completeBlock (newImage);
        return;
    }
    
    [self downloadFile:url filePath:cachedFilePath onCompletion:^(BOOL success) {
        if (success) {
            UIImage *newImage = [UIImage imageWithContentsOfFile:cachedFilePath];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock (newImage);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock (nil);
            });
        }
    }];
}

- (void)animatedImageForUrl: (NSString *)url withCompleteBlock: (DKFileCacheGetAnimatedImageBlock)completeBlock {
    NSString *cachedFilePath = [self cachedFilePathForURL: url];
    
    if (cachedFilePath == nil) {
        completeBlock (nil);
        return;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachedFilePath]) {
        NSURL *fileUrl = [NSURL fileURLWithPath: cachedFilePath];
        
        UIImage *newImage = [UIImage animatedImageWithAnimatedGIFURL:fileUrl];
        
        completeBlock (newImage);
        return;
    }
    
    [self downloadFile:url filePath:cachedFilePath onCompletion:^(BOOL success) {
        if (success) {
            NSURL *fileUrl = [NSURL fileURLWithPath: cachedFilePath];
            UIImage *animatedImage = [UIImage animatedImageWithAnimatedGIFURL:fileUrl];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock (animatedImage);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock (nil);
            });
        }
    }];
}

- (void)audioForUrl: (NSString *)url withCompleteBlock: (DKFileCacheGetAudioBlock)completeBlock {
    
    NSString *cachedFilePath = [self cachedFilePathForURL: url];
    
    if (cachedFilePath == nil) {
        completeBlock (nil);
        return;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachedFilePath]) {
        completeBlock (cachedFilePath);
        return;
    }
    
    [self downloadFile:url filePath:cachedFilePath onCompletion:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                completeBlock (cachedFilePath);
            } else {
                completeBlock (nil);
            }
        });
    }];
}

- (BOOL)isFileCachedForUrl: (NSString *)url {
    NSString *cachedFilePath = [self cachedFilePathForURL: url];

    return ([[NSFileManager defaultManager] fileExistsAtPath:cachedFilePath]);
}

- (void)removeCachedFileForURL: (NSString *)url {
    NSString *cachedFilePath = [self cachedFilePathForURL: url];

    if (cachedFilePath.length > 0) {
        [[NSFileManager defaultManager] removeItemAtPath:cachedFilePath error:nil];
    }
}

- (void)clear {
    
    NSString *cachedFolderPath = [NSString stringWithFormat:@"%@/%@/", [self documentsDirectory], self.defaultCacheFolder];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cachedFolderPath error:nil];

    for (NSString *cachedFilePath in files) {
        [[NSFileManager defaultManager] removeItemAtPath:cachedFilePath error:nil];
    }
}

- (void)cancelAllRequests {
}

- (void)downloadFile:(NSString*)url filePath:(NSString*)filePath onCompletion:(DownloadCompletionBlock)completion {
    @synchronized(activeDownloads) {
        NSMutableArray *completionBlocks = [activeDownloads objectForKey:url];
        if (!completionBlocks) {
            completionBlocks = [[NSMutableArray alloc] init];
            [activeDownloads setObject:completionBlocks forKey:url];
            
            [completionBlocks addObject:completion];

            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            NSString *downloadPath = [NSString stringWithFormat:@"%@/%@/%@", [self documentsDirectory], self.defaultCacheFolder, [NSString uniqueString]];
            operation.outputStream = [NSOutputStream outputStreamToFileAtPath:downloadPath append:NO];
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                [[NSFileManager defaultManager] moveItemAtPath:downloadPath toPath:filePath error:nil];
                
                NSMutableArray *completionBlocks;
                @synchronized(activeDownloads) {
                    completionBlocks = [activeDownloads objectForKey:url];
                    [activeDownloads removeObjectForKey:url];
                }
                
                for (DownloadCompletionBlock completionBlock in completionBlocks) {
                    completionBlock(YES);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSMutableArray *completionBlocks;
                @synchronized(activeDownloads) {
                    completionBlocks = [activeDownloads objectForKey:url];
                    [activeDownloads removeObjectForKey:url];
                }
                
                for (DownloadCompletionBlock completionBlock in completionBlocks) {
                    completionBlock(NO);
                }
            }];
            [operation start];
        } else {
            [completionBlocks addObject:completion];
        }
    }
}

@end
