//
//  DKPConstants.m
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 22/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKPConstants.h"

NSString *const kDKPUserDefaultsActivityFeedViewControllerLastRefreshKey    = @"com.parse.ThreadWeather.userDefaults.activityFeedViewController.lastRefresh";
NSString *const kDKPUserDefaultsCacheFacebookFriendsKey                     = @"com.parse.ThreadWeather.userDefaults.cache.facebookFriends";


#pragma mark - Launch URLs

NSString *const kDKPLaunchURLHostTakePicture = @"camera";


#pragma mark - NSNotification

NSString *const DKPAppDelegateApplicationDidReceiveRemoteNotification           = @"com.parse.ThreadWeather.appDelegate.applicationDidReceiveRemoteNotification";
NSString *const DKPUtilityUserFollowingChangedNotification                      = @"com.parse.ThreadWeather.utility.userFollowingChanged";
NSString *const DKPUtilityUserLikedUnlikedPhotoCallbackFinishedNotification     = @"com.parse.ThreadWeather.utility.userLikedUnlikedPhotoCallbackFinished";
NSString *const DKPUtilityDidFinishProcessingProfilePictureNotification         = @"com.parse.ThreadWeather.utility.didFinishProcessingProfilePictureNotification";
NSString *const DKPTabBarControllerDidFinishEditingPhotoNotification            = @"com.parse.ThreadWeather.tabBarController.didFinishEditingPhoto";
NSString *const DKPTabBarControllerDidFinishImageFileUploadNotification         = @"com.parse.ThreadWeather.tabBarController.didFinishImageFileUploadNotification";
NSString *const DKPPhotoDetailsViewControllerUserDeletedPhotoNotification       = @"com.parse.ThreadWeather.photoDetailsViewController.userDeletedPhoto";
NSString *const DKPPhotoDetailsViewControllerUserLikedUnlikedPhotoNotification  = @"com.parse.ThreadWeather.photoDetailsViewController.userLikedUnlikedPhotoInDetailsViewNotification";
NSString *const DKPPhotoDetailsViewControllerUserCommentedOnPhotoNotification   = @"com.parse.ThreadWeather.photoDetailsViewController.userCommentedOnPhotoInDetailsViewNotification";


#pragma mark - User Info Keys
NSString *const DKPPhotoDetailsViewControllerUserLikedUnlikedPhotoNotificationUserInfoLikedKey = @"liked";
NSString *const kDKPEditPhotoViewControllerUserInfoCommentKey = @"comment";

#pragma mark - Installation Class

// Field keys
NSString *const kDKPInstallationUserKey = @"user";

#pragma mark - Activity Class
// Class key
NSString *const kDKPActivityClassKey = @"Activity";

// Field keys
NSString *const kDKPActivityTypeKey        = @"type";
NSString *const kDKPActivityFromUserKey    = @"fromUser";
NSString *const kDKPActivityToUserKey      = @"toUser";
NSString *const kDKPActivityContentKey     = @"content";
NSString *const kDKPActivityPhotoKey       = @"photo";

// Type values
NSString *const kDKPActivityTypeLike       = @"like";
NSString *const kDKPActivityTypeFollow     = @"follow";
NSString *const kDKPActivityTypeComment    = @"comment";
NSString *const kDKPActivityTypeJoined     = @"joined";

#pragma mark - User Class
// Field keys
NSString *const kDKPUserDisplayNameKey                          = @"displayName";
NSString *const kDKPUserFacebookIDKey                           = @"facebookId";
NSString *const kDKPUserTwitterIDKey                            = @"twitterId";
NSString *const kDKPUserPhotoIDKey                              = @"photoId";
NSString *const kDKPUserProfilePicSmallKey                      = @"profilePictureSmall";
NSString *const kDKPUserProfilePicMediumKey                     = @"profilePictureMedium";
NSString *const kDKPUserFacebookFriendsKey                      = @"facebookFriends";
NSString *const kDKPUserAlreadyAutoFollowedFacebookFriendsKey   = @"userAlreadyAutoFollowedFacebookFriends";
NSString *const kDKPUserEmailKey                                = @"email";
NSString *const kDKPUserGenderKey                               = @"gender";
NSString *const kDKPUserBirthdayKey                             = @"birthday";
NSString *const kDKPUserLocaleKey                               = @"locale";
NSString *const kDKPUserImageUrlKey                             = @"imageUrl";
NSString *const kDKPUserNameKey                                 = @"username";
NSString *const kDKPUserDeviceTokenKey                          = @"deviceToken";

#pragma mark - Photo Class
// Class key
NSString *const kDKPPhotoClassKey = @"Photo";

// Field keys
NSString *const kDKPPhotoPictureKey         = @"image";
NSString *const kDKPPhotoThumbnailKey       = @"thumbnail";
NSString *const kDKPPhotoUserKey            = @"user";
NSString *const kDKPPhotoOpenGraphIDKey    = @"fbOpenGraphID";


#pragma mark - Cached Photo Attributes
// keys
NSString *const kDKPPhotoAttributesIsLikedByCurrentUserKey = @"isLikedByCurrentUser";
NSString *const kDKPPhotoAttributesLikeCountKey            = @"likeCount";
NSString *const kDKPPhotoAttributesLikersKey               = @"likers";
NSString *const kDKPPhotoAttributesCommentCountKey         = @"commentCount";
NSString *const kDKPPhotoAttributesCommentersKey           = @"commenters";


#pragma mark - Cached User Attributes
// keys
NSString *const kDKPUserAttributesPhotoCountKey                 = @"photoCount";
NSString *const kDKPUserAttributesIsFollowedByCurrentUserKey    = @"isFollowedByCurrentUser";


#pragma mark - Push Notification Payload Keys

NSString *const kAPNSAlertKey = @"alert";
NSString *const kAPNSBadgeKey = @"badge";
NSString *const kAPNSSoundKey = @"sound";

// the following keys are intentionally kept short, APNS has a maximum payload limit
NSString *const kDKPPushPayloadPayloadTypeKey          = @"p";
NSString *const kDKPPushPayloadPayloadTypeActivityKey  = @"a";

NSString *const kDKPPushPayloadActivityTypeKey     = @"t";
NSString *const kDKPPushPayloadActivityLikeKey     = @"l";
NSString *const kDKPPushPayloadActivityCommentKey  = @"c";
NSString *const kDKPPushPayloadActivityFollowKey   = @"f";

NSString *const kDKPPushPayloadFromUserObjectIdKey = @"fu";
NSString *const kDKPPushPayloadToUserObjectIdKey   = @"tu";
NSString *const kDKPPushPayloadPhotoObjectIdKey    = @"pid";