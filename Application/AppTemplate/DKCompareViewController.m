//
//  DKCompareViewController.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 29/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKCompareViewController.h"
#import "DKTouchScrollView.h"
#import "DKSettingsViewController.h"
#import "DMActivityInstagram.h"

@interface DKCompareViewController () <UIDocumentInteractionControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) DKWeek *firstWeek;
@property (nonatomic, strong) DKWeek *secondWeek;
@property (nonatomic, strong) UIImageView *imageViewLast;
@property (nonatomic, strong) UIImageView *imageViewOriginal;
@property (nonatomic, strong) UIImageView *imageViewSideLast;
@property (nonatomic, strong) UIImageView *imageViewSideOriginal;
@property (nonatomic, strong) UIView *compareView;
@property (nonatomic, strong) UIDocumentInteractionController *dic;
@property (nonatomic, strong) UIImage *imageToShare;

@end

@implementation DKCompareViewController

- (instancetype)initWithFirstWeek: (DKWeek *)firstWeek andSecondWeek: (DKWeek *)secondWeek {
    self = [super init];
    
    if (self) {
        _firstWeek = firstWeek;
        _secondWeek = secondWeek;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.compareView = [[UIView alloc] initWithFrame:CGRectMake(0, 50, ScreenWidth, ScreenWidth)];
    
    self.compareView.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.compareView];
    
    self.imageViewLast = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth / 2, ScreenWidth / 2)];
    self.imageViewLast.backgroundColor = [UIColor blackColor];
    self.imageViewLast.contentMode = UIViewContentModeScaleAspectFit;
    self.imageViewLast.userInteractionEnabled = YES;
    self.imageViewLast.layer.borderColor = [UIColor whiteColor].CGColor;
    self.imageViewLast.layer.borderWidth = 1.0;
    self.imageViewLast.layer.cornerRadius = 1.0;
    
    [self.compareView addSubview:self.imageViewLast];
    
    self.imageViewLast.image = [DKModel imageFromLink:self.secondWeek.image];
    
    self.imageViewSideLast = [[UIImageView alloc] initWithFrame:CGRectMake(ScreenWidth / 2, 0, ScreenWidth / 2, ScreenWidth / 2)];
    self.imageViewSideLast.backgroundColor = [UIColor blackColor];
    self.imageViewSideLast.contentMode = UIViewContentModeScaleAspectFit;
    self.imageViewSideLast.userInteractionEnabled = YES;
    self.imageViewSideLast.layer.borderColor = [UIColor whiteColor].CGColor;
    self.imageViewSideLast.layer.borderWidth = 1.0;
    self.imageViewSideLast.layer.cornerRadius = 1.0;

    [self.compareView addSubview:self.imageViewSideLast];
    
    self.imageViewSideLast.image = [DKModel imageFromLink:self.secondWeek.imageSide];
    
    self.imageViewOriginal = [[UIImageView alloc] initWithFrame:CGRectMake(0, ScreenWidth / 2, ScreenWidth / 2, ScreenWidth / 2)];
    self.imageViewOriginal.backgroundColor = [UIColor blackColor];
    self.imageViewOriginal.contentMode = UIViewContentModeScaleAspectFit;
    self.imageViewOriginal.userInteractionEnabled = YES;
    self.imageViewOriginal.alpha = 1.0;
    self.imageViewOriginal.layer.borderColor = [UIColor whiteColor].CGColor;
    self.imageViewOriginal.layer.borderWidth = 1.0;
    self.imageViewOriginal.layer.cornerRadius = 1.0;

    [self.compareView addSubview:self.imageViewOriginal];
    
    self.imageViewOriginal.image = [DKModel imageFromLink:self.firstWeek.image];

    self.imageViewSideOriginal = [[UIImageView alloc] initWithFrame:CGRectMake(ScreenWidth / 2, ScreenWidth / 2, ScreenWidth / 2, ScreenWidth / 2)];
    self.imageViewSideOriginal.backgroundColor = [UIColor blackColor];
    self.imageViewSideOriginal.contentMode = UIViewContentModeScaleAspectFit;
    self.imageViewSideOriginal.userInteractionEnabled = YES;
    self.imageViewSideOriginal.alpha = 1.0;
    self.imageViewSideOriginal.layer.borderColor = [UIColor whiteColor].CGColor;
    self.imageViewSideOriginal.layer.borderWidth = 1.0;
    self.imageViewSideOriginal.layer.cornerRadius = 1.0;

    [self.compareView addSubview:self.imageViewSideOriginal];
    
    self.imageViewSideOriginal.image = [DKModel imageFromLink:self.firstWeek.imageSide];
    
    int weekShift = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kSettingsWeekKey];
    
    if (weekShift > 0) {
        weekShift --;
    }

    self.title = [NSString stringWithFormat:@"%ld - %ld", self.firstWeek.seqNumber + weekShift,
                  self.secondWeek.seqNumber + weekShift];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                           target:self
                                                                                           action:@selector(exportImages)];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onInstagramExport:)
                                                 name:DMActivityInstagramDidSelectNotification
                                               object:nil];
    
    __weak typeof(self) this = self;

    dispatch_async(dispatch_get_main_queue(), ^{
        this.imageToShare = [this screenshotOfView:this.compareView];
    });
}

- (void)exportImages {
    
    [Flurry logEvent:@"Export image"];

    NSArray *activityItems = @[@"", self.imageToShare];
    
    DMActivityInstagram  *instagram  = [[DMActivityInstagram alloc] init];

    instagram.parentView = self.view;
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                             applicationActivities:@[instagram]];
    
    activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint, UIActivityTypePostToWeibo,
                                         UIActivityTypeAddToReadingList, UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo];
    
    [self presentViewController:activityVC animated:TRUE completion:nil];
}

- (void)onInstagramExport: (NSNotification *)notification {
    
    __weak typeof(self) this = self;
    
    int64_t delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [this exportImageToInstagram];
    });
}

- (void)exportImageToInstagram {
    NSURL *instagramURL = [NSURL URLWithString:@"instagram://"];
    
    if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {

        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* documentsDirectory = [paths objectAtIndex:0];
        
        NSString *imageName = [NSString stringWithFormat:@"ff.igo"];
        
        NSString* fullPathToFile = [documentsDirectory stringByAppendingPathComponent:imageName];
        
        NSData *imageData = UIImageJPEGRepresentation(self.imageToShare, 1.0);
        
        [imageData writeToFile:fullPathToFile atomically:YES];
        
        NSURL *igImageHookFile = [[NSURL alloc] initWithString:[[NSString alloc] initWithFormat:@"file://%@", fullPathToFile]];
        
        self.dic = [UIDocumentInteractionController interactionControllerWithURL:igImageHookFile];
        
        self.dic.UTI = @"com.instagram.exclusivegram";
        self.dic.delegate = self;
        
        self.dic.annotation = @{@"InstagramCaption": self.title};
        
        [self.dic presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];
    }
}

- (UIImage *)screenshotOfView: (UIView *)view {
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        if ([[UIScreen mainScreen] scale] == 2.0) {
            UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 2.0);
        } else {
            UIGraphicsBeginImageContext(view.bounds.size);
        }
    } else {
        UIGraphicsBeginImageContext(view.bounds.size);
    }
    
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    
    UIImage *anImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return anImage;
}

/*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [self.nextResponder touchesBegan:touches withEvent:event];
    
    UIView *touchedView = [[touches anyObject] view];
    
    if (touchedView == self.imageViewLast) {
        __weak typeof(self) this = self;
        
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            this.imageViewLast.alpha = 0.0;
            this.imageViewOriginal.alpha = 1.0;
        } completion:^(BOOL finished) {
        }];
    } else if (touchedView == self.imageViewSideLast) {
        __weak typeof(self) this = self;
        
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            this.imageViewSideLast.alpha = 0.0;
            this.imageViewSideOriginal.alpha = 1.0;
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [self.nextResponder touchesEnded:touches withEvent:event];
    
    UIView *touchedView = [[touches anyObject] view];
    
    if (touchedView == self.imageViewLast) {
        __weak typeof(self) this = self;

        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            this.imageViewOriginal.alpha = 0.0;
            this.imageViewLast.alpha = 1.0;
        } completion:^(BOOL finished) {
        }];
    } else if (touchedView == self.imageViewSideLast) {
        __weak typeof(self) this = self;
        
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            this.imageViewSideOriginal.alpha = 0.0;
            this.imageViewSideLast.alpha = 1.0;
        } completion:^(BOOL finished) {
        }];
    }
}
*/

#ifdef FREE

- (void)updateAdBannerPosition {
    
    self.tableView.tableFooterView = [UIView new];
    
    [self.adBanner removeFromSuperview];
    
    __weak typeof(self) this = self;
    
    [UIView animateWithDuration:0.5 animations:^{
        this.adBanner.alpha = 0.0;
    } completion:^(BOOL finished) {
        this.adBanner.center = CGPointMake(ScreenWidth / 2, this.adBanner.frame.size.height / 2);
        [this.view addSubview:this.adBanner];
        
        [UIView animateWithDuration:0.5 animations:^{
            this.adBanner.alpha = 1.0;
        }];
    }];
}
#endif

@end
