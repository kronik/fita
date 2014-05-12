#if TARGET_OS_IPHONE

#import "NIKFontAwesomeIconFactory.h"

/** Preconfigured factories for typical iOS image sizes. */
@interface NIKFontAwesomeIconFactory(iOS)

+ (instancetype)generalFactory;
+ (instancetype)buttonIconFactory;
+ (instancetype)barButtonItemIconFactory;
+ (instancetype)tabBarItemIconFactory;

@end

#endif
