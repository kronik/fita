//
//  DKMealViewController.m
//  FitAssist
//
//  Created by Dmitry Klimkin on 17/4/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKMealViewController.h"
#import "DKMealCell.h"
#import "DKSettingsViewController.h"
#import "Meal.h"
#import "DKCircleImageView.h"
#import "DKSettingsViewController.h"
#import "DKDaysViewController.h"
#import "Day+Extra.h"
#import "DKDayCommentCell.h"
#import "DKButtonCell.h"
#import "DKTimePicker.h"

#import "UILabel+WhiteUIDatePickerLabels.h"
#import "NIKFontAwesomeIconFactory.h"
#import "NIKFontAwesomeIconFactory+iOS.h"
#import "Flurry.h"
#import "FXBlurView.h"
#import "MOOPullGestureRecognizer.h"
#import "MOOCreateView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <MessageUI/MessageUI.h>
#import "UIColor+MLPFlatColors.h"

#define UIACTION_SHEET_PHOTO_OPTIONS_TAG 1024
#define DKMealViewControllerCellHeight 60
#define DKMealViewControllerExtraCellHeight 100
#define DKMealViewControllerSuggestionCellHeight 44
#define DKMealViewControllerButtonCellHeight 60

#define DKMealViewControllerCellId @"DKMealViewControllerCellId"
#define DKMealViewControllerSuggestionCellId @"DKMealViewControllerSuggestionCellId"
#define DKMealViewControllerExtraCellId @"DKMealViewControllerExtraCellId"
#define DKMealViewControllerButtonCellId @"DKMealViewControllerButtonCellId"

typedef enum DKMealViewActionType {
    DKMealViewActionTypeNone = 0,
    DKMealViewActionTypeExport,
    DKMealViewActionTypeImage
} DKMealViewActionType;

@interface DKMealViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate,
                                    UITextViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate,
                                    UINavigationControllerDelegate, UIActionSheetDelegate,
                                    MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate,
                                    DKTimePickerDelegate> {
    CGRect keyboardRect;
    CGRect cellRect;
    NSRange lastRange;
}

@property (nonatomic, strong) NSMutableArray *mealEntries;
@property (nonatomic, strong) DKTimePicker *timePicker;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIView *timePickerContainer;
@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIButton *saveShortButton;
@property (nonatomic, strong) UIButton *saveDrinkButton;
@property (nonatomic, strong) UIButton *saveWorkButton;
@property (nonatomic, strong) UIButton *updateButton;
@property (nonatomic, strong) NSArray *mealSuggestions;
@property (nonatomic, strong) NSMutableArray *mealAutocompleteItems;
@property (nonatomic, strong) UITableView *suggestTableView;
@property (nonatomic, strong) UIViewController *messageViewController;
@property (nonatomic, strong) UITextView *commentEditView;

@property (nonatomic, weak) Meal *lastSelectedMeal;
@property (nonatomic, strong) Day *day;
@property (nonatomic) DKMealViewActionType actionType;

@property (nonatomic) BOOL isUpdateMode;
@property (nonatomic) BOOL canAddNewDay;

@end

@implementation DKMealViewController

@synthesize mealEntries = _mealEntries;
@synthesize day = _day;
@synthesize timePicker = _timePicker;
@synthesize timePickerContainer = _timePickerContainer;
@synthesize textView = _textView;
@synthesize imageButton = _imageButton;
@synthesize saveButton = _saveButton;
@synthesize lastSelectedMeal = _lastSelectedMeal;
@synthesize mealSuggestions = _mealSuggestions;
@synthesize mealAutocompleteItems = _mealAutocompleteItems;
@synthesize suggestTableView = _suggestTableView;
@synthesize saveShortButton = _saveShortButton;
@synthesize isUpdateMode = _isUpdateMode;
@synthesize saveDrinkButton = _saveDrinkButton;
@synthesize updateButton = _updateButton;
@synthesize saveWorkButton = _saveWorkButton;
@synthesize actionType = _actionType;
@synthesize messageViewController = _messageViewController;
@synthesize commentEditView = _commentEditView;
@synthesize canAddNewDay = _canAddNewDay;

- (id)initWithDay: (Day *)day canAddNewDay: (BOOL)canAddNewDay {
    self = [super init];
    
    if (self) {
        _day = day;
        _canAddNewDay = canAddNewDay;
        
        _mealEntries = [[[day.meals allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            
            Meal *meal1 = (Meal *)obj1;
            Meal *meal2 = (Meal *)obj2;
            
//            return [meal1.time compare:meal2.time];
            
            NSComparisonResult result = [meal1.time compare:meal2.time];
            
            if (result == NSOrderedAscending) {
                return NSOrderedDescending;
            } else if (result == NSOrderedDescending) {
                return NSOrderedAscending;
            } else {
                return NSOrderedSame;
            }
            
        }] mutableCopy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[UILabel appearanceWhenContainedIn:[UIDatePicker class], nil] setTextColor:[UIColor whiteColor]];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 1)];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = ApplicationMainColor;
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 50;
    self.tableView.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight - ApplicationNavigationAndStatusBarHeight);
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.contentOffset = CGPointMake(0, 0);

    [self.view addSubview: self.tableView];
    
    self.timePickerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, self.view.bounds.size.height)];
    self.timePickerContainer.backgroundColor = ApplicationMainColor;
    self.timePickerContainer.center = CGPointMake(ScreenWidth / 2, -ScreenHeight);
    self.timePickerContainer.clipsToBounds = YES;

    [self.view addSubview: self.timePickerContainer];

    float heightOffset = 0;
    
    if (ScreenHeight > 480.0) {
        heightOffset = 20;
    }
    
    self.timePicker = [[DKTimePicker alloc] initWithFrame:CGRectMake(0, 70 + heightOffset, ScreenWidth, 100)];
    
    self.timePicker.tintColor = [UIColor whiteColor];
    self.timePicker.backgroundColor = ApplicationMainColor;
    self.timePicker.delegate = self;
    
    [self.timePickerContainer addSubview: self.timePicker];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(80, 5, ScreenWidth - 83, DKMealViewControllerCellHeight + 10)];
    
    self.textView.textColor = [UIColor whiteColor];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.tintColor = [UIColor whiteColor];
    self.textView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.textView.layer.borderWidth = 1.0;
    self.textView.layer.cornerRadius = 3;
    self.textView.textAlignment = NSTextAlignmentLeft;
    self.textView.font = [UIFont fontWithName:ApplicationBoldFont size:14];
    self.textView.delegate = self;
    self.textView.returnKeyType = UIReturnKeyDone;
    self.textView.keyboardType = UIKeyboardTypeDefault;
    self.textView.editable = YES;
    self.textView.userInteractionEnabled = YES;
    self.textView.text = @"";

    [self.timePickerContainer addSubview: self.textView];
    
    self.imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    self.imageButton.frame = CGRectMake(2, 5, DKMealViewControllerCellHeight + 16, DKMealViewControllerCellHeight + 10);
    self.imageButton.layer.borderColor = ApplicationMainColor.CGColor;
    self.imageButton.clipsToBounds = YES;
    self.imageButton.layer.cornerRadius = 3;
    
    NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory barButtonItemIconFactory];
    
    factory.colors = @[[UIColor whiteColor]];
    factory.size = 70;

    [self.imageButton setImage:[factory createImageForIcon:NIKFontAwesomeIconCameraRetro] forState:UIControlStateNormal];
    [self.imageButton addTarget:self action:@selector(onSelectImageTap) forControlEvents:UIControlEventTouchUpInside];

    [self.timePickerContainer addSubview: self.imageButton];

    self.updateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    self.updateButton.frame = CGRectZero;
    self.updateButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.updateButton.clipsToBounds = YES;
    self.updateButton.layer.cornerRadius = 10;
    self.updateButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.updateButton.layer.borderWidth = 1.0;
    
    [self.updateButton addTarget:self action:@selector(commonSave) forControlEvents:UIControlEventTouchUpInside];
    
    [self.updateButton setTitle:NSLocalizedString(@"Done", nil) forState:UIControlStateNormal];
    [self.updateButton setTitle:NSLocalizedString(@"Done", nil) forState:UIControlStateSelected];
    [self.updateButton setTitle:NSLocalizedString(@"Done", nil) forState:UIControlStateHighlighted];
    
    [self.updateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.updateButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateSelected];
    [self.updateButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    
    [self.timePickerContainer addSubview: self.updateButton];

    self.saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    self.saveButton.frame = CGRectZero;
    self.saveButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.saveButton.clipsToBounds = YES;
    self.saveButton.layer.cornerRadius = 10;
    self.saveButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.saveButton.layer.borderWidth = 1.0;
    
    [self.saveButton setTitle:kMealTypeRegular forState:UIControlStateNormal];
    [self.saveButton setTitle:kMealTypeRegular forState:UIControlStateSelected];
    [self.saveButton setTitle:kMealTypeRegular forState:UIControlStateHighlighted];

    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateSelected];
    [self.saveButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];

    [self.saveButton addTarget:self action:@selector(onSaveTap) forControlEvents:UIControlEventTouchUpInside];

    [self.timePickerContainer addSubview: self.saveButton];

    self.saveShortButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    self.saveShortButton.frame = CGRectZero;
    self.saveShortButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.saveShortButton.clipsToBounds = YES;
    self.saveShortButton.layer.cornerRadius = 10;
    self.saveShortButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.saveShortButton.layer.borderWidth = 1.0;
    
    [self.saveShortButton addTarget:self action:@selector(onSaveShortTap) forControlEvents:UIControlEventTouchUpInside];
    
    [self.saveShortButton setTitle:kMealTypeSnack forState:UIControlStateNormal];
    [self.saveShortButton setTitle:kMealTypeSnack forState:UIControlStateSelected];
    [self.saveShortButton setTitle:kMealTypeSnack forState:UIControlStateHighlighted];
    
    [self.saveShortButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveShortButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateSelected];
    [self.saveShortButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    
    [self.timePickerContainer addSubview: self.saveShortButton];
    
    self.saveDrinkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    self.saveDrinkButton.frame = CGRectZero;
    self.saveDrinkButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.saveDrinkButton.clipsToBounds = YES;
    self.saveDrinkButton.layer.cornerRadius = 10;
    self.saveDrinkButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.saveDrinkButton.layer.borderWidth = 1.0;
    
    [self.saveDrinkButton addTarget:self action:@selector(onSaveDrinkTap) forControlEvents:UIControlEventTouchUpInside];
    
    [self.saveDrinkButton setTitle:kMealTypeDrink forState:UIControlStateNormal];
    [self.saveDrinkButton setTitle:kMealTypeDrink forState:UIControlStateSelected];
    [self.saveDrinkButton setTitle:kMealTypeDrink forState:UIControlStateHighlighted];
    
    [self.saveDrinkButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveDrinkButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateSelected];
    [self.saveDrinkButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    
    [self.timePickerContainer addSubview: self.saveDrinkButton];
    
    self.saveWorkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    self.saveWorkButton.frame = CGRectZero;
    self.saveWorkButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.saveWorkButton.clipsToBounds = YES;
    self.saveWorkButton.layer.cornerRadius = 10;
    self.saveWorkButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.saveWorkButton.layer.borderWidth = 1.0;
    
    [self.saveWorkButton addTarget:self action:@selector(onSaveWorkTap) forControlEvents:UIControlEventTouchUpInside];
    
    [self.saveWorkButton setTitle:kMealTypeWork forState:UIControlStateNormal];
    [self.saveWorkButton setTitle:kMealTypeWork forState:UIControlStateSelected];
    [self.saveWorkButton setTitle:kMealTypeWork forState:UIControlStateHighlighted];
    
    [self.saveWorkButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.saveWorkButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateSelected];
    [self.saveWorkButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    
    [self.timePickerContainer addSubview: self.saveWorkButton];
    
    __weak typeof(self) this = self;
    
    [self.tableView reloadData];

    dispatch_async(dispatch_get_main_queue(), ^{

        [this reloadAllMealEntries];

        MOOPullGestureRecognizer *recognizer = [[MOOPullGestureRecognizer alloc] initWithTarget:this action:@selector(handleGesture:)];

        // Create cell
        DKMealCell *newCell = [[DKMealCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        
        newCell.backgroundColor = [UIColor clearColor];
        newCell.contentView.backgroundColor = this.tableView.backgroundColor;
        newCell.imageView.image = nil;
        newCell.textLabel.font = [UIFont fontWithName:ApplicationFont size:20];
        newCell.textLabel.textColor = [UIColor whiteColor];
        
        newCell.detailTextLabel.font = [UIFont fontWithName:ApplicationLightFont size:14];
        newCell.detailTextLabel.textColor = [UIColor whiteColor];
        newCell.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setLocale:[NSLocale currentLocale]];

        // Create create view
        MOOCreateView *createView = [[MOOCreateView alloc] initWithCell:newCell];
        
        createView.backgroundColor = ApplicationMainColor;
        
        createView.configurationBlock = ^(MOOCreateView *view, UITableViewCell *cell, MOOPullState state) {
            
            if (![cell isKindOfClass:[UITableViewCell class]]) {
                return;
            }
            
            switch (state) {
                case MOOPullActive:
                case MOOPullTriggered:
                    //                cell.textLabel.text = NSLocalizedString(@"Release to add...", nil);
                    //                break;
                case MOOPullIdle: {
                    
                    cell.textLabel.text = NSLocalizedString(@"Add new meal", nil);
                    cell.detailTextLabel.text = [dateFormatter stringFromDate: [NSDate date]];
                }
                    break;
                    
            }
        };
        
        recognizer.triggerView = createView;
        
        [this.tableView addGestureRecognizer:recognizer];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Meal" ofType:@"txt"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:NO]) {
            this.mealSuggestions = [NSArray arrayWithContentsOfFile:filePath];
        
//        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Meal_ru" ofType:@"txt"];
//        
//        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:NO]) {
//            NSString *fileData = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
//            
//            this.mealSuggestions = [fileData componentsSeparatedByString:@"\n"];
//            
//            NSMutableDictionary *aaa = [NSMutableDictionary new];
//            
//            for (NSString *bb in this.mealSuggestions) {
//                aaa[bb] = @"adf";
//            }
//            
//            NSMutableArray *newAaa = [NSMutableArray new];
//            
//            for (NSString *key in aaa.keyEnumerator) {
//                [newAaa addObject:key];
//            }
//            
//            NSArray *sorted = [newAaa sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
//            
//            NSString *cachedFilePath = [NSString stringWithFormat:@"%@/array.txt", [self documentsDirectory]];
//            
//            [sorted writeToFile:cachedFilePath atomically:YES];
//
//            NSLog(@"Finished");
        }
    });

    self.suggestTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    
    self.suggestTableView.dataSource = self;
    self.suggestTableView.delegate = self;
    self.suggestTableView.tableFooterView = [UIView new];
    self.suggestTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 1)];
    self.suggestTableView.backgroundView = nil;
    self.suggestTableView.backgroundColor = ApplicationMainColor;
    self.suggestTableView.separatorStyle  = UITableViewCellSeparatorStyleSingleLine;
    self.suggestTableView.separatorColor = [UIColor colorWithWhite:1 alpha:0.3];
    self.suggestTableView.frame = self.view.bounds;
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (NSString *)documentsDirectory {
	static NSString *documentsDirectory= nil;
    
	if (! documentsDirectory) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		documentsDirectory = paths [0];
	}
    
	return documentsDirectory;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)keyboardWillShow:(NSNotification *)aNotification {
    keyboardRect = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    __weak typeof(self)this = self;
    
    if (self.commentEditView != nil) {
        float animationDuration = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        UIViewAnimationCurve animationCurve = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
        UIViewAnimationOptions animationOptions = (UIViewAnimationOptions)(animationCurve << 16);
        
        [UIView animateWithDuration:animationDuration delay:0.0 options:animationOptions animations:^{
            
            this.commentEditView.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight - ApplicationNavigationAndStatusBarHeight - keyboardRect.size.height);
            
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
    keyboardRect = CGRectZero;
    
    __weak typeof(self)this = self;

    if (self.commentEditView != nil) {
        float animationDuration = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        UIViewAnimationCurve animationCurve = [[[aNotification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
        UIViewAnimationOptions animationOptions = (UIViewAnimationOptions)(animationCurve << 16);

        [UIView animateWithDuration:animationDuration delay:0.0 options:animationOptions animations:^{
            
            this.commentEditView.frame = CGRectMake(cellRect.origin.x, cellRect.origin.y - 7, cellRect.size.width, cellRect.size.height);
            
        } completion:^(BOOL finished) {
            
            [this.commentEditView removeFromSuperview];
            
            this.commentEditView = nil;
        }];
    }
}

- (void)onSelectImageTap {
    
    [Flurry logEvent:@"Attach meal image tap"];

    Meal *selectedMeal = self.lastSelectedMeal;

    if (selectedMeal == nil) {
        return;
    }
    
    [self.textView resignFirstResponder];

    UIActionSheet *actionSheet;
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                    destructiveButtonTitle:nil
                                         otherButtonTitles: NSLocalizedString(@"Choose existing photo", nil), nil];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                    destructiveButtonTitle:NSLocalizedString(@"Take a photo", nil)
                                         otherButtonTitles:NSLocalizedString(@"Choose existing photo", nil), nil];
    }
    
    actionSheet.tag = UIACTION_SHEET_PHOTO_OPTIONS_TAG;
    
    [actionSheet showInView:self.view];
    
    self.actionType = DKMealViewActionTypeImage;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        self.actionType = DKMealViewActionTypeNone;
        return;
    }
    
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if (self.actionType == DKMealViewActionTypeImage) {
        
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        
        if ([buttonTitle isEqualToString:NSLocalizedString(@"Choose existing photo", nil)]) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        else if([buttonTitle isEqualToString:NSLocalizedString(@"Take a photo", nil)]) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        }
        
        imagePicker.mediaTypes = @[(NSString *) kUTTypeImage];
        imagePicker.delegate = self;
        imagePicker.allowsEditing = YES;
        imagePicker.navigationBar.tintColor = [UIColor whiteColor];
        
        [self presentViewController:imagePicker animated:YES completion: nil];
    } else {
        [self handleExportWithButtonIndex:buttonIndex];
    }
}

- (void)updateUI {
    
    [self.tableView reloadData];
    
    if (self.lastSelectedMeal == nil) {
        return;
    }
    
    float buttonHeight = ScreenHeight > 480.0 ? DKMealViewControllerCellHeight - 20 : DKMealViewControllerCellHeight - 20;
    float heightOffset = 25;
    
    if (ScreenHeight > 480.0) {
        heightOffset = 0;
    }

    if (self.isUpdateMode) {
        self.updateButton.frame = CGRectMake(60, self.timePicker.frame.origin.y + self.timePicker.frame.size.height + 10 - heightOffset,
                                             ScreenWidth - 120, buttonHeight);
        
        self.saveButton.frame = CGRectZero;
        self.saveShortButton.frame = CGRectZero;
        self.saveDrinkButton.frame = CGRectZero;
        self.saveWorkButton.frame = CGRectZero;
        
    } else {
        
        self.updateButton.frame = CGRectZero;
        
        CGFloat xOffset = 3;

        self.saveWorkButton.frame = CGRectMake(xOffset, self.timePicker.frame.origin.y + self.timePicker.frame.size.height + 10 - heightOffset,
                                               (ScreenWidth - 15) / 4, buttonHeight);
        
        xOffset += 3 + (ScreenWidth - 15) / 4;
        
        self.saveShortButton.frame = CGRectMake(xOffset,
                                                self.timePicker.frame.origin.y + self.timePicker.frame.size.height + 10 - heightOffset,
                                                (ScreenWidth - 15) / 4, buttonHeight);

        xOffset += 3 + (ScreenWidth - 15) / 4;

        self.saveDrinkButton.frame = CGRectMake(xOffset,
                                                self.timePicker.frame.origin.y + self.timePicker.frame.size.height + 10 - heightOffset,
                                                (ScreenWidth - 15) / 4, buttonHeight);

        xOffset += 3 + (ScreenWidth - 15) / 4;

        self.saveButton.frame = CGRectMake(xOffset,
                                           self.timePicker.frame.origin.y + self.timePicker.frame.size.height + 10 - heightOffset,
                                           (ScreenWidth - 15) / 4, buttonHeight);
    }
    
    if (self.lastSelectedMeal.picture != nil) {
        [self.imageButton setImage:[UIImage imageWithData: self.lastSelectedMeal.picture] forState:UIControlStateNormal];
    } else {
        
        NIKFontAwesomeIconFactory *factory = [NIKFontAwesomeIconFactory generalFactory];
        
        factory.colors = @[[UIColor whiteColor]];
        factory.size = 70;
        
        [self.imageButton setImage:[factory createImageForIcon:NIKFontAwesomeIconCameraRetro] forState:UIControlStateNormal];
    }
    
    self.textView.text = self.lastSelectedMeal.text;
    self.timePicker.time = self.lastSelectedMeal.time;    
}

- (void)commonSave {
    __weak typeof(self) this = self;
    
    Meal *mealToSave = self.lastSelectedMeal;
    
    self.lastSelectedMeal = nil;

    [self.textView resignFirstResponder];

    mealToSave.text = self.textView.text;
    mealToSave.time = self.timePicker.time;
    
    if (mealToSave.text.length == 0) {
        [mealToSave MR_deleteEntity];
        
        mealToSave = nil;
    }
    
    [self saveChangesAsyncWithBlock:^(BOOL isFailedToSave) {
        [this reloadAllMealEntries];
        [this.tableView reloadData];
        
        if ((this.isUpdateMode == NO) && (mealToSave)) {
            if ([mealToSave.type isEqualToString:kMealTypeRegular] == YES) {
                [this scheduleNextMeal];
            }
            
            if ([mealToSave.type isEqualToString:kMealTypeDrink] == NO) {
                [this scheduleNextWater];
            }
        }

//        [this.navigationController setNavigationBarHidden:NO animated:YES];

        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            this.timePickerContainer.frame = cellRect;
            this.timePickerContainer.alpha = 0;
//            this.timePickerContainer.center = CGPointMake(ScreenWidth / 2, - ScreenHeight);
        } completion:^(BOOL finished) {
            if (this.mealEntries.count == 1) {
                [this startShowItemOptionsTutorial];
            }
        }];
    }];
}

- (void)onSaveWorkTap {
    
    [Flurry logEvent:@"Save work"];
    
    if (self.textView.text.length == 0) {
        self.textView.text = kMealTypeWork;
    }
    
    self.lastSelectedMeal.type = kMealTypeWork;
    
    [self commonSave];
}

- (void)onSaveTap {
    
    [Flurry logEvent:@"Save regular meal"];

    self.lastSelectedMeal.type = kMealTypeRegular;
    
    [self commonSave];
}

- (void)onSaveShortTap {

    [Flurry logEvent:@"Save snack meal"];

    self.lastSelectedMeal.type = kMealTypeSnack;

    [self commonSave];
}

- (void)onSaveDrinkTap {
    
    [Flurry logEvent:@"Save drink"];

    if (self.textView.text.length == 0) {
        self.textView.text = kMealTypeDrink;
    }
    
    self.lastSelectedMeal.type = kMealTypeDrink;
    
    [self commonSave];
}

- (void)timePicker:(DKTimePicker *)timePicker didSelectTime:(NSDate *)time {
    [self.textView resignFirstResponder];
    
    Meal *selectedMeal = self.lastSelectedMeal;
    
    selectedMeal.time = time;
    
    [self.tableView reloadData];
}

//- (void)onTimeChanged {
//    
//    [self.textView resignFirstResponder];
//    
//    Meal *selectedMeal = self.lastSelectedMeal;
//    
//    selectedMeal.time = self.timePicker.date;
//    
//    [self.tableView reloadData];
//}

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        if ([gestureRecognizer conformsToProtocol:@protocol(MOOPullGestureRecognizer)])
            [self _pulledToCreate:(UIGestureRecognizer<MOOPullGestureRecognizer> *)gestureRecognizer];
    }
}

- (void)_pulledToCreate:(UIGestureRecognizer<MOOPullGestureRecognizer> *)pullGestureRecognizer {
    
    self.isUpdateMode = NO;
    
    Meal *newMeal = [Meal MR_createEntity];
    
    newMeal.day = self.day;
    newMeal.time = [NSDate date];
    newMeal.text = @"";
    
    [self.day addMealsObject:newMeal];
    
    [self.mealEntries insertObject:newMeal atIndex:0];
    
    CGPoint contentOffset = self.tableView.contentOffset;
    contentOffset.y -= CGRectGetMinY(pullGestureRecognizer.triggerView.frame);
    
    [self.tableView reloadData];
    self.tableView.contentOffset = contentOffset;
    
    __weak typeof(self) this = self;
    
    [self saveChangesAsyncWithBlock:^(BOOL isFailedToSave) {
        [this reloadAllMealEntries];
        [this startEditMeal: newMeal];
    }];
}

- (void)cancelEditMeal {
    __weak typeof(self) this = self;
    
    Meal *mealToSave = self.lastSelectedMeal;
    
    self.lastSelectedMeal = nil;
    
    [self.textView resignFirstResponder];
    
    if (mealToSave.text.length == 0) {
        [mealToSave MR_deleteEntity];
        
        mealToSave = nil;
    }
    
    [self reloadAllMealEntries];
    [self.tableView reloadData];

    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        this.timePickerContainer.frame = cellRect;
        this.timePickerContainer.alpha = 0;
    } completion:^(BOOL finished) {
        if (this.mealEntries.count == 1) {
            [this startShowItemOptionsTutorial];
        }
    }];
}

- (void)startEditMeal: (Meal *)meal {
    
    __weak typeof(self) this = self;

    self.lastSelectedMeal = meal;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(cancelEditMeal)];
    [self updateUI];
    
//    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    this.timePickerContainer.alpha = 0;

    int mealIndex = 0;
    
    for (int i=0; i<self.mealEntries.count; i++) {
        Meal *existingMeal = self.mealEntries[i];
        
        if (meal == existingMeal) {
            mealIndex = i;
            break;
        }
    }
    
    DKMealCell *mealCell = (DKMealCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:mealIndex inSection:0]];
    
    if (mealCell) {
        cellRect = [self.tableView convertRect:mealCell.frame toView:self.view];
    } else {
        cellRect = CGRectMake(0, -ScreenHeight, ScreenWidth, ScreenHeight);
    }

    this.timePickerContainer.frame = cellRect;

    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        this.timePickerContainer.frame = ScreenRect;
        this.timePickerContainer.alpha = 1.0;
//        this.timePickerContainer.center = CGPointMake(ScreenWidth / 2, ScreenHeight / 2);
    } completion:^(BOOL finished) {
        [this.textView becomeFirstResponder];
    }];
}

- (NSMutableArray *)reloadAllMealEntries {
    
    NSPredicate *dayFilter = [NSPredicate predicateWithFormat:@"day = %@", self.day];
    
    self.mealEntries = [[Meal MR_findAllSortedBy:@"time" ascending:NO withPredicate:dayFilter] mutableCopy];
    
    if (self.mealEntries.count == 0) {
        [self startCreateNewItemTutorialWithInfo:NSLocalizedString(@"Pull down to add new meal", nil)];
        
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                               target:self
                                                                                               action:@selector(exportDay)];
    }
    
    return self.mealEntries;
}

- (void)exportDay {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@""
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Message", nil),
                                  NSLocalizedString(@"Email", nil),
                                  NSLocalizedString(@"Copy", nil), nil];
    
    [actionSheet showInView:self.view];
    
    self.actionType = DKMealViewActionTypeExport;

    [Flurry logEvent:@"Export day"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (tableView == self.tableView) ? (self.canAddNewDay ? 3 : 2) : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        return section == 0 ? self.mealEntries.count : 1;
    } else {
        return self.mealAutocompleteItems.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == self.tableView) {
        if (indexPath.section == 0) {
            DKMealCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DKMealViewControllerCellId];
            
            if (cell == nil) {
                cell = [[DKMealCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:DKMealViewControllerCellId];
                
                cell.userInteractionEnabled = YES;
                
                cell.selectedBackgroundView = nil;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.font = [UIFont fontWithName:ApplicationFont size:20];
                cell.textLabel.textColor = [UIColor whiteColor];
                cell.textLabel.numberOfLines = 1;
                cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                cell.textLabel.textAlignment = NSTextAlignmentLeft;

                cell.detailTextLabel.font = [UIFont fontWithName:ApplicationFont size:16];
                cell.detailTextLabel.textColor = [UIColor whiteColor];
                cell.detailTextLabel.numberOfLines = 1;
                cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
                cell.detailTextLabel.textAlignment = NSTextAlignmentLeft;

                cell.backgroundColor = [UIColor clearColor];
                cell.contentView.backgroundColor = [UIColor clearColor];
                cell.textLabel.backgroundColor = [UIColor clearColor];
            }
            
            Meal *meal = self.mealEntries[indexPath.row];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            
            [dateFormatter setDateStyle:NSDateFormatterNoStyle];
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
            [dateFormatter setLocale:[NSLocale currentLocale]];

            cell.textLabel.text = meal.text;
            cell.detailTextLabel.text = [dateFormatter stringFromDate: meal.time];
            
            if (meal.picture) {
                cell.imageView.image = [UIImage imageWithData: meal.picture];
            } else {
                cell.imageView.image = nil;
            }
            
            BOOL isCorrectTimeForMealAtIndex =  [meal.type isEqualToString:kMealTypeDrink] ? [self isCorrectTimeForWaterAtIndex: indexPath.row] :
                                                                                             [self isCorrectTimeForMealAtIndex: indexPath.row];
            
            if (isCorrectTimeForMealAtIndex && ([meal.type isEqualToString:kMealTypeDrink] == NO) &&
                (meal == self.mealEntries.lastObject)) {
                
                isCorrectTimeForMealAtIndex = NO;
            }
            
            cell.isCorrect = isCorrectTimeForMealAtIndex;
            
            return cell;
        } else if (indexPath.section == 1) {
            DKDayCommentCell *cell = (DKDayCommentCell *)[self.tableView dequeueReusableCellWithIdentifier:DKMealViewControllerExtraCellId];
            
            if (cell == nil) {
                cell = [[DKDayCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DKMealViewControllerExtraCellId];
                
                cell.selectedBackgroundView = nil;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.backgroundColor = [UIColor clearColor];
                cell.contentView.backgroundColor = [UIColor clearColor];
                cell.textLabel.backgroundColor = [UIColor clearColor];
                cell.textLabel.font = [UIFont fontWithName:ApplicationFont size:18];
                cell.textLabel.textColor = [UIColor whiteColor];
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                cell.textLabel.numberOfLines = 4;
            }
            
            cell.textLabel.text = self.day.comment.length == 0 ? NSLocalizedString(@"Add a comment", nil) : self.day.comment;
            cell.textLabel.textAlignment = self.day.comment.length == 0 ? NSTextAlignmentCenter : NSTextAlignmentLeft;

            return cell;
        } else {
            DKButtonCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DKMealViewControllerButtonCellId];
            
            if (cell == nil) {
                cell = [[DKButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DKMealViewControllerButtonCellId];
                
                cell.userInteractionEnabled = YES;
                
                cell.selectedBackgroundView = nil;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.textLabel.font = [UIFont fontWithName:ApplicationFont size:18];
                cell.textLabel.textColor = [UIColor whiteColor];
                cell.textLabel.numberOfLines = 1;
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                
                cell.backgroundColor = [UIColor clearColor];
                cell.contentView.backgroundColor = [UIColor clearColor];
                cell.textLabel.backgroundColor = [UIColor clearColor];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Start next day", nil);
            
            return cell;
        }

    } else {
        UITableViewCell *cell = [self.suggestTableView dequeueReusableCellWithIdentifier:DKMealViewControllerSuggestionCellId];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DKMealViewControllerSuggestionCellId];
            
            cell.userInteractionEnabled = YES;
            
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.textLabel.font = [UIFont fontWithName:ApplicationFont size:14];
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.textLabel.numberOfLines = 1;
            cell.textLabel.textAlignment = NSTextAlignmentRight;
            
            cell.backgroundColor = [UIColor clearColor];
            cell.contentView.backgroundColor = [UIColor clearColor];
            cell.textLabel.backgroundColor = [UIColor clearColor];
        }

        cell.textLabel.text = self.mealAutocompleteItems[indexPath.row];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        [self startEditComment];
        return;
    } else if (indexPath.section > 1) {
        [self switchToNextDay];
        return;
    }
    
    if (tableView == self.tableView) {
        self.isUpdateMode = YES;
        
        [Flurry logEvent:@"Updated meal"];

        [self startEditMeal: self.mealEntries[indexPath.row]];
    } else {
        NSString *selectedSuggestion = self.mealAutocompleteItems[indexPath.row];
        NSString *separator = @", ";
        
        int textLength = 0;
        int currentWordIdx = 0;
        NSString *newText = self.textView.text;
        NSMutableArray *words = [[newText componentsSeparatedByString:separator] mutableCopy];
        
        for (int i=0; i<words.count; i++) {
            NSString *word = words[i];
            
            if (textLength <= lastRange.location) {
                currentWordIdx = i;
                textLength += word.length + separator.length;
            } else {
                break;
            }
        }

        if (words.count > 0) {
            words[currentWordIdx] = selectedSuggestion;
        }
        
        self.textView.text = [words componentsJoinedByString:separator];
        [self hideSuggestions];
        
        [Flurry logEvent:@"Selected suggestion meal"];
    }
}

- (void)switchToNextDay {
    
    Week *currentWeek = self.day.week;
    
    if (currentWeek.days.count >= 7) {
        NSArray *weeks = [Week MR_findAllSortedBy:@"seqNumber" ascending:NO];
        
        currentWeek = [Week MR_createEntity];
        Week *maxWeek = weeks.firstObject;
        
        currentWeek.seqNumber = @([maxWeek.seqNumber intValue] + 1);
        currentWeek.startDate = [NSDate date];
    }
    
    Day *newDay = [Day MR_createEntity];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"EEEE"];
    
    NSArray *days = [[currentWeek.days allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        
        Day *day1 = (Day *)obj1;
        Day *day2 = (Day *)obj2;
        
        NSComparisonResult result = [day1.seqNumber compare:day2.seqNumber];
        
        if (result == NSOrderedAscending) {
            return NSOrderedDescending;
        } else if (result == NSOrderedDescending) {
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    Day *day = days.lastObject;
    
    NSDate *lastDate = day ? day.date : [NSDate date];
    NSDate *nextDate = [lastDate dateByAddingTimeInterval:(60 * 60 * 24) * days.count];
    
    newDay.name = [dateFormatter stringFromDate:nextDate];
    newDay.week = currentWeek;
    newDay.date = nextDate;
    newDay.seqNumber = @(days.count);
    
    [currentWeek addDaysObject:newDay];
    
    self.day = newDay;
    
    self.title = newDay.name;
        
    __weak typeof(self) this = self;
    
    [self saveChangesAsyncWithBlock:^(BOOL isFailedToSave) {
        [this reloadAllMealEntries];
        [this.tableView reloadData];
    }];
}

- (void)startEditComment {
    self.commentEditView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, DKMealViewControllerExtraCellHeight)];
    
    self.commentEditView.textColor = [UIColor whiteColor];
    self.commentEditView.backgroundColor = ApplicationMainColor;
    self.commentEditView.font = [UIFont fontWithName:ApplicationFont size:18];
    self.commentEditView.tintColor = [UIColor whiteColor];
    self.commentEditView.center = CGPointMake(ScreenWidth / 2, ScreenHeight + DKMealViewControllerExtraCellHeight);
    self.commentEditView.delegate = self;
    self.commentEditView.returnKeyType = UIReturnKeyDone;
    self.commentEditView.keyboardType = UIKeyboardTypeDefault;
    self.commentEditView.text = self.day.comment;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    
    if (cell) {
        cellRect = [self.tableView convertRect:cell.frame toView:self.view];
    } else {
        cellRect = CGRectMake(0, ScreenHeight, ScreenWidth, DKMealViewControllerExtraCellHeight);
    }

    self.commentEditView.frame = cellRect;
    
    [self.view addSubview:self.commentEditView];
    [self.commentEditView becomeFirstResponder];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                           target:self
                                                                                           action:@selector(endEditComment)];
}

- (void)endEditComment {
    
    self.day.comment = self.commentEditView.text;
    
    [self.commentEditView resignFirstResponder];
    
    __weak typeof(self) this = self;

    [self saveChangesAsyncWithBlock:^(BOOL isFailedToSave) {
        [this reloadAllMealEntries];
        [this.tableView reloadData];
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return indexPath.section == 0 ? DKMealViewControllerCellHeight : (indexPath.section == 1 ? DKMealViewControllerExtraCellHeight : DKMealViewControllerButtonCellHeight);
    } else {
        return DKMealViewControllerSuggestionCellHeight;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.tableView) {
        return indexPath.section == 0 ? YES : NO;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Meal *meal = self.mealEntries[indexPath.row];
        
        [self.tableView beginUpdates];
        
        [self.mealEntries removeObject: meal];
        
        [meal MR_deleteEntity];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.tableView endUpdates];
        
        __weak typeof(self) this = self;
        
        [self saveChangesAsyncWithBlock:^(BOOL isFailedToSave) {
            [this reloadAllMealEntries];
            [this.tableView reloadData];
        }];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView.pullGestureRecognizer) {
        [scrollView.pullGestureRecognizer scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView.pullGestureRecognizer) {
        [scrollView.pullGestureRecognizer resetPullState];
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {

}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [self hideSuggestions];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    BOOL retVal = YES;
    
    int textLength = 0;
    int currentWordIdx = 0;
    NSString *newText = [textView.text stringByReplacingCharactersInRange: range withString: text];
    NSString *separator = @", ";
    NSArray *words = [newText componentsSeparatedByString:separator];

    for (int i=0; i<words.count; i++) {
        NSString *word = words[i];
        
        if (textLength <= range.location) {
            currentWordIdx = i;
            textLength += word.length + separator.length;
        } else {
            break;
        }
    }
    
    if ([text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound) {
        retVal = NO;
        
        if (textView == self.textView) {
            [textView resignFirstResponder];
        } else {
            [self endEditComment];
        }
    } else {
        if (textView == self.textView) {
//            self.lastSelectedMeal.text = textView.text;
        }
    }
    
    if (textView == self.textView) {
        if (words.count > 0) {
            lastRange = range;
            [self updateSuggestionsForText:words[currentWordIdx]];
        } else {
            [self hideSuggestions];
        }
    } else {
        
    }
    
	return retVal;
}

- (void)hideSuggestions {
    [self.suggestTableView removeFromSuperview];
}

- (void)updateSuggestionsForText: (NSString *)text {
    self.mealAutocompleteItems = [NSMutableArray new];
    
    for (NSString *suggestedText in self.mealSuggestions) {
        
        NSString *lowSuggestedText = [suggestedText lowercaseString];
        NSString *lowText = [text lowercaseString];
        
        if ([lowSuggestedText rangeOfString:lowText].location != NSNotFound) {
            [self.mealAutocompleteItems addObject: suggestedText];
        }
    }
    
    [self.suggestTableView reloadData];
    [self.suggestTableView removeFromSuperview];
    
    if (self.mealAutocompleteItems.count > 0) {
        [self.timePickerContainer addSubview:self.suggestTableView];
        
        self.suggestTableView.frame = CGRectMake(0, self.timePicker.frame.origin.y - 5,
                                                 ScreenWidth,
                                                 ScreenHeight - keyboardRect.size.height - self.timePicker.frame.origin.y - ApplicationNavigationAndStatusBarHeight);
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *editedImage = [info valueForKey:UIImagePickerControllerEditedImage];
    
    if (editedImage != nil) {
        
        Meal *lastMeal = [self lastSelectedMeal];
        
        lastMeal.picture = UIImageJPEGRepresentation(editedImage, 1.0);
        
        [self.imageButton setImage:editedImage forState:UIControlStateNormal];
        
        [self.tableView reloadData];
    }
    
    [picker dismissViewControllerAnimated:YES completion:^(void){[self.view  setNeedsLayout];}];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^(void){[self.view  setNeedsLayout];}];
}

- (UIImage *)imageWithBlackPaddingTopBottom:(UIImage *)source {
    CGSize size = [source size];
    
    if (size.width > size.height) {
        int sizeDif = size.width - size.height;
        size.height += sizeDif;
        
        UIGraphicsBeginImageContext(size);
        [source drawAtPoint:CGPointMake(0, sizeDif/2) blendMode:kCGBlendModeNormal alpha:1.0];
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetRGBStrokeColor(context, 0, 0, 0, 1.0);
        CGContextSetLineWidth(context, sizeDif/2);
        
        //top line
        CGContextMoveToPoint(context, 0, sizeDif/4);
        CGContextAddLineToPoint(context, size.width, sizeDif/4);
        CGContextStrokePath(context);
        
        //bottom line
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 0, size.height - sizeDif/4);
        CGContextAddLineToPoint(context, size.width, size.height - sizeDif/4);
        CGContextStrokePath(context);
        
        
        UIImage *testImg =  UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return testImg;
    }
    
    return source;
}

- (BOOL)isCorrectTimeForWaterAtIndex: (NSInteger)mealIndex {
    
    if ((self.mealEntries.count < 2) || (mealIndex == self.mealEntries.count - 1)) {
        return YES;
    }
    
    Meal *prevMeal = nil;
    Meal *currentMeal = self.mealEntries[mealIndex];
    
    for (NSInteger i=mealIndex + 1; i<self.mealEntries.count; i++) {
        
        Meal *meal = self.mealEntries[i];
        
        if ([meal.type isEqualToString:kMealTypeDrink] == NO) {
            prevMeal = meal;
            break;
        }
    }
    
    if (prevMeal == nil) {
        return YES;
    }
    
    NSTimeInterval interval = [currentMeal.time timeIntervalSinceDate:prevMeal.time];

    if ([currentMeal.type isEqualToString:kMealTypeDrink] && interval < 60 * 30) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isCorrectTimeForMealAtIndex: (NSInteger)mealIndex {
    
    if ((self.mealEntries.count < 2) || (mealIndex == self.mealEntries.count - 1)) {
        return YES;
    }
    
    Meal *prevMeal = nil;
    Meal *currentMeal = self.mealEntries[mealIndex];
    
    for (NSInteger i=mealIndex + 1; i<self.mealEntries.count; i++) {
        
        Meal *meal = self.mealEntries[i];
        
        if ([meal.type isEqualToString:kMealTypeRegular]) {
            prevMeal = meal;
            break;
        }
    }
    
    NSTimeInterval interval;
    
    if (prevMeal != nil) {
        
        interval = [currentMeal.time timeIntervalSinceDate:prevMeal.time];
        
        if ([currentMeal.type isEqualToString:kMealTypeSnack] && (interval < 60 * 30)) {
            return NO;
        }
        
        if ([currentMeal.type isEqualToString:kMealTypeRegular] && ((interval > 60 * 60 * 3) || (interval < 60 * 90))) {
            return NO;
        }
    }
    
    // Check water
    prevMeal = nil;
    
    for (NSInteger i=mealIndex + 1; i<self.mealEntries.count; i++) {
        
        Meal *meal = self.mealEntries[i];
        
        if ([meal.type isEqualToString:kMealTypeDrink]) {
            prevMeal = meal;
            break;
        }
    }
    
    if (prevMeal == nil) {
        return YES;
    }
    
    interval = [currentMeal.time timeIntervalSinceDate:prevMeal.time];
    
    if (([currentMeal.type isEqualToString:kMealTypeSnack] || [currentMeal.type isEqualToString:kMealTypeRegular])
        && (interval < 60 * 30)) {
        
        return NO;
    }

    return YES;
}

- (void)scheduleNextWater {
    
    BOOL reminderDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsRemindersKey];
    
    if (reminderDisabled == YES) {
        return;
    }
    
    Meal *lastMeal = nil;
    
    for (Meal *meal in self.mealEntries) {
        if ([meal.type isEqualToString:kMealTypeDrink] == NO) {
            lastMeal = meal;
            break;
        }
    }
    
    if (lastMeal == nil) {
        return;
    }
    
    [Flurry logEvent:@"Scheduled next water"];

    NSArray *bodyMessages = @[NSLocalizedString(@"Let's grab some water ☕️!", nil),
                              NSLocalizedString(@"It's time to drink a glass of water 💧!", nil),
                              NSLocalizedString(@"I want you to drink 🍵!", nil),
                              NSLocalizedString(@"Drink💧drink💧drink!", nil)];
    
#ifdef TESTING
    NSTimeInterval nextMealInterval1 = 40 * 60; // 00:40
    NSTimeInterval nextMealInterval2 = 60 * 60; // 00:45
#else
    NSTimeInterval nextMealInterval1 = 40 * 60; // 00:40
    NSTimeInterval nextMealInterval2 = 60 * 60; // 00:45
#endif
    NSDate *notificationTime1 = [lastMeal.time dateByAddingTimeInterval:nextMealInterval1];
    NSDate *notificationTime2 = [lastMeal.time dateByAddingTimeInterval:nextMealInterval2];
    
    if ([notificationTime1 timeIntervalSinceDate: [NSDate date]] <= 0) {
        return;
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger comps = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
    
    NSDateComponents *date1Components = [calendar components:comps fromDate: notificationTime1];
    NSDateComponents *date2Components = [calendar components:comps fromDate: lastMeal.time];
    
    NSDate *date1 = [calendar dateFromComponents:date1Components];
    NSDate *date2 = [calendar dateFromComponents:date2Components];
    
    NSComparisonResult result = [date1 compare:date2];
    
    if (result != NSOrderedSame) {
        // New day
        return;
    }
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    
    localNotification.fireDate = notificationTime1;
    localNotification.alertBody = bodyMessages[arc4random() % bodyMessages.count];
    localNotification.alertAction = NSLocalizedString(@"Add a glass of water", nil);
    localNotification.timeZone = [NSTimeZone localTimeZone];
    localNotification.soundName = @"notification.aiff";//UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    UILocalNotification *localNotification2 = [[UILocalNotification alloc] init];
    
    localNotification2.fireDate = notificationTime2;
    localNotification2.alertBody = bodyMessages[arc4random() % bodyMessages.count];
    localNotification2.alertAction = NSLocalizedString(@"Add a glass of water", nil);
    localNotification2.timeZone = [NSTimeZone localTimeZone];
    localNotification2.soundName = @"notification.aiff";//UILocalNotificationDefaultSoundName;
    localNotification2.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification2];
}

- (void)scheduleNextMeal {
    
    BOOL reminderDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:kSettingsRemindersKey];

    if (reminderDisabled == YES) {
        return;
    }
    
    Meal *lastMeal = nil;
    
    for (Meal *meal in self.mealEntries) {
        if ([meal.type isEqualToString:kMealTypeRegular]) {
            lastMeal = meal;
            break;
        }
    }
    
    if (lastMeal == nil) {
        return;
    }
    
    [Flurry logEvent:@"Scheduled next meal"];

    NSArray *bodyMessages = @[NSLocalizedString(@"Let's grab some food 🍗 🍅!", nil),
                              NSLocalizedString(@"It's time to eat something 🍖 🍲 🍅!", nil),
                              NSLocalizedString(@"I want you to eat 🍴!", nil),
                              NSLocalizedString(@"Eat 🍅 eat 🍅 eat!", nil)];
    
#ifdef TESTING
    NSTimeInterval nextMealInterval1 = 60 * (60 + 60 + 45); // 02:55
    NSTimeInterval nextMealInterval2 = 60 * (60 + 60 + 55); // 02:55

#else
    NSTimeInterval nextMealInterval1 = 60 * (60 + 60 + 45); // 02:55
    NSTimeInterval nextMealInterval2 = 60 * (60 + 60 + 55); // 02:55
#endif

    NSDate *notificationTime1 = [lastMeal.time dateByAddingTimeInterval:nextMealInterval1];
    NSDate *notificationTime2 = [lastMeal.time dateByAddingTimeInterval:nextMealInterval2];

    if ([notificationTime1 timeIntervalSinceDate: [NSDate date]] <= 0) {
        return;
    }

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger comps = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
    
    NSDateComponents *date1Components = [calendar components:comps fromDate: notificationTime1];
    NSDateComponents *date2Components = [calendar components:comps fromDate: lastMeal.time];
    
    NSDate *date1 = [calendar dateFromComponents:date1Components];
    NSDate *date2 = [calendar dateFromComponents:date2Components];
    
    NSComparisonResult result = [date1 compare:date2];
    
    if (result != NSOrderedSame) {
        // New day
        return;
    }
    
    NSString *appIconName = @"AppIcon40x40@2x";

    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    
    localNotification.alertLaunchImage = appIconName;
    localNotification.fireDate = notificationTime1;
    localNotification.alertBody = bodyMessages[arc4random() % bodyMessages.count];
    localNotification.alertAction = NSLocalizedString(@"Add new meal", nil);
    localNotification.timeZone = [NSTimeZone localTimeZone];
    localNotification.soundName = @"notification.aiff";//UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    UILocalNotification* localNotification2 = [[UILocalNotification alloc] init];
    
    localNotification2.alertLaunchImage = appIconName;
    localNotification2.fireDate = notificationTime2;
    localNotification2.alertBody = bodyMessages[arc4random() % bodyMessages.count];
    localNotification2.alertAction = NSLocalizedString(@"Add new meal", nil);
    localNotification2.timeZone = [NSTimeZone localTimeZone];
    localNotification2.soundName = @"notification.aiff";//UILocalNotificationDefaultSoundName;
    localNotification2.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification2];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)setLastSelectedMeal:(Meal *)lastSelectedMeal {
    _lastSelectedMeal = lastSelectedMeal;
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (NSString *)textToExport {
    return [self.day fullDescription];
}

- (void)handleExportWithButtonIndex: (NSInteger)buttonIndex {
    NSString *textToShare = [self textToExport];
    
    switch (buttonIndex) {
        case 0: {
            MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
            
            if ([MFMessageComposeViewController canSendText]) {
                
                controller.body = textToShare;
				controller.messageComposeDelegate = self;
                controller.navigationBar.tintColor = [UIColor whiteColor];
                
                self.messageViewController = controller;
                
                [self presentViewController:controller animated:YES completion:nil];
            }
        }
            break;
            
        case 1: {
            MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
            
            controller.subject = [NSString stringWithFormat:@"\n%@ %d %@", NSLocalizedString(@"Week", nil),
                                  [self.day.week.seqNumber intValue], self.day.name];
            controller.mailComposeDelegate = self;
            controller.navigationBar.tintColor = [UIColor whiteColor];
            
            [controller setMessageBody:textToShare isHTML:NO];
            
            self.messageViewController = controller;
            
            [self presentViewController:controller animated:YES completion:nil];
        }
            break;
            
        case 2: {
            [UIPasteboard generalPasteboard].string = textToShare;
            
            [self showCompleteIndicatorWithTitle:NSLocalizedString(@"You copied selected day", nil)];
        }
            break;
            
        default:
            break;
    }
    
    self.actionType = DKMealViewActionTypeNone;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result {
    [self.messageViewController dismissViewControllerAnimated:YES completion:NULL];
    
    self.messageViewController = nil;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self.messageViewController dismissViewControllerAnimated:YES completion:NULL];
    
    self.messageViewController = nil;
}

@end
