#if TARGET_OS_IPHONE

#import "NIKFontAwesomeIconFactory.h"
#import "UIColor+MLPFlatColors.h"
#import "UIColor+Colours.h"

@implementation NIKFontAwesomeIconFactory(iOS)

+ (instancetype)generalFactory {
    static NIKFontAwesomeIconFactory *generalFactory = nil;
    
	if (generalFactory == nil) {
		@synchronized(self) {
			if (generalFactory == nil) {
				generalFactory = [NIKFontAwesomeIconFactory new];
                generalFactory.size = 24.0;
                generalFactory.colors = @[ApplicationMainColor];
                generalFactory.edgeInsets = UIEdgeInsetsMake(0, 0, 0, 0.0);
            }
        }
	}
    return generalFactory;
}

+ (instancetype)buttonIconFactory {
    static NIKFontAwesomeIconFactory *buttonFactory = nil;
    
	if (buttonFactory == nil) {
		@synchronized(self) {
			if (buttonFactory == nil) {
				buttonFactory = [NIKFontAwesomeIconFactory new];
                buttonFactory.size = 14.0;
                buttonFactory.colors = @[[NIKColor darkGrayColor]];
                buttonFactory.edgeInsets = UIEdgeInsetsMake(0, 0, 0, 8.0);
            }
        }
	}
    return buttonFactory;
}

+ (instancetype)barButtonItemIconFactory {
    static NIKFontAwesomeIconFactory *barFactory = nil;
    
	if (barFactory == nil) {
		@synchronized(self) {
			if (barFactory == nil) {
				barFactory = [NIKFontAwesomeIconFactory new];
                barFactory.size = 20.0;
                barFactory.colors = @[[NIKColor whiteColor]];
                barFactory.edgeInsets = UIEdgeInsetsMake(0, 0, 0, 0.0);
            }
        }
	}
    return barFactory;
}

+ (instancetype)tabBarItemIconFactory {
    static NIKFontAwesomeIconFactory *tabFactory = nil;
    
	if (tabFactory == nil) {
		@synchronized(self) {
			if (tabFactory == nil) {
				tabFactory = [NIKFontAwesomeIconFactory new];
                tabFactory.size = 20.0;
                tabFactory.edgeInsets = UIEdgeInsetsMake(0, 0, 0, 0.0);
            }
        }
	}
    return tabFactory;
}

@end

#endif
