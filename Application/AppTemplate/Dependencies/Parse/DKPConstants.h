//
//  DKPConstants.h
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 22/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

typedef enum {
	DKPHomeTabBarItemIndex = 0,
	DKPEmptyTabBarItemIndex = 1,
	DKPActivityTabBarItemIndex = 2
} DKPTabBarControllerViewControllerIndex;


// Ilya     400680
// James    403902
// Brian    702499
// David    1225726
// Bryan    4806789
// Thomas   6409809
// Ashley   12800553
// Héctor   121800083
// Kevin    500011038
// Chris    558159381
// Henele   721873341
// Matt     723748661
// Andrew   865225242

#define kDKPParseEmployeeAccounts [NSArray arrayWithObjects:@"400680", @"403902", @"702499", @"1225726", @"4806789", @"6409809", @"12800553", @"121800083", @"500011038", @"558159381", @"721873341", @"723748661", @"865225242", nil]

#pragma mark - NSUserDefaults
extern NSString *const kDKPUserDefaultsActivityFeedViewControllerLastRefreshKey;
extern NSString *const kDKPUserDefaultsCacheFacebookFriendsKey;

#pragma mark - Launch URLs

extern NSString *const kDKPLaunchURLHostTakePicture;


#pragma mark - NSNotification
extern NSString *const DKPAppDelegateApplicationDidReceiveRemoteNotification;
extern NSString *const DKPUtilityUserFollowingChangedNotification;
extern NSString *const DKPUtilityUserLikedUnlikedPhotoCallbackFinishedNotification;
extern NSString *const DKPUtilityDidFinishProcessingProfilePictureNotification;
extern NSString *const DKPTabBarControllerDidFinishEditingPhotoNotification;
extern NSString *const DKPTabBarControllerDidFinishImageFileUploadNotification;
extern NSString *const DKPPhotoDetailsViewControllerUserDeletedPhotoNotification;
extern NSString *const DKPPhotoDetailsViewControllerUserLikedUnlikedPhotoNotification;
extern NSString *const DKPPhotoDetailsViewControllerUserCommentedOnPhotoNotification;


#pragma mark - User Info Keys
extern NSString *const DKPPhotoDetailsViewControllerUserLikedUnlikedPhotoNotificationUserInfoLikedKey;
extern NSString *const kDKPEditPhotoViewControllerUserInfoCommentKey;


#pragma mark - Installation Class

// Field keys
extern NSString *const kDKPInstallationUserKey;


#pragma mark - PFObject Activity Class
// Class key
extern NSString *const kDKPActivityClassKey;

// Field keys
extern NSString *const kDKPActivityTypeKey;
extern NSString *const kDKPActivityFromUserKey;
extern NSString *const kDKPActivityToUserKey;
extern NSString *const kDKPActivityContentKey;
extern NSString *const kDKPActivityPhotoKey;

// Type values
extern NSString *const kDKPActivityTypeLike;
extern NSString *const kDKPActivityTypeFollow;
extern NSString *const kDKPActivityTypeComment;
extern NSString *const kDKPActivityTypeJoined;


#pragma mark - PFObject User Class
// Field keys
extern NSString *const kDKPUserDisplayNameKey;
extern NSString *const kDKPUserFacebookIDKey;
extern NSString *const kDKPUserTwitterIDKey;
extern NSString *const kDKPUserPhotoIDKey;
extern NSString *const kDKPUserProfilePicSmallKey;
extern NSString *const kDKPUserProfilePicMediumKey;
extern NSString *const kDKPUserFacebookFriendsKey;
extern NSString *const kDKPUserAlreadyAutoFollowedFacebookFriendsKey;
extern NSString *const kDKPUserEmailKey;
extern NSString *const kDKPUserGenderKey;
extern NSString *const kDKPUserBirthdayKey;
extern NSString *const kDKPUserLocaleKey;
extern NSString *const kDKPUserImageUrlKey;
extern NSString *const kDKPUserNameKey;
extern NSString *const kDKPUserDeviceTokenKey;

#pragma mark - PFObject Photo Class
// Class key
extern NSString *const kDKPPhotoClassKey;

// Field keys
extern NSString *const kDKPPhotoPictureKey;
extern NSString *const kDKPPhotoThumbnailKey;
extern NSString *const kDKPPhotoUserKey;
extern NSString *const kDKPPhotoOpenGraphIDKey;


#pragma mark - Cached Photo Attributes
// keys
extern NSString *const kDKPPhotoAttributesIsLikedByCurrentUserKey;
extern NSString *const kDKPPhotoAttributesLikeCountKey;
extern NSString *const kDKPPhotoAttributesLikersKey;
extern NSString *const kDKPPhotoAttributesCommentCountKey;
extern NSString *const kDKPPhotoAttributesCommentersKey;


#pragma mark - Cached User Attributes
// keys
extern NSString *const kDKPUserAttributesPhotoCountKey;
extern NSString *const kDKPUserAttributesIsFollowedByCurrentUserKey;


#pragma mark - PFPush Notification Payload Keys

extern NSString *const kAPNSAlertKey;
extern NSString *const kAPNSBadgeKey;
extern NSString *const kAPNSSoundKey;

extern NSString *const kDKPPushPayloadPayloadTypeKey;
extern NSString *const kDKPPushPayloadPayloadTypeActivityKey;

extern NSString *const kDKPPushPayloadActivityTypeKey;
extern NSString *const kDKPPushPayloadActivityLikeKey;
extern NSString *const kDKPPushPayloadActivityCommentKey;
extern NSString *const kDKPPushPayloadActivityFollowKey;

extern NSString *const kDKPPushPayloadFromUserObjectIdKey;
extern NSString *const kDKPPushPayloadToUserObjectIdKey;
extern NSString *const kDKPPushPayloadPhotoObjectIdKey;