//
//  DKSettingsManager.h
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 22/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

@import Foundation;
@import CoreLocation;

typedef void (^DetectLocationBlock)(CLPlacemark *place);

#define kSettingFacebookAccount     @"kSettingFacebookAccount"
#define kSettingFacebookEmail       @"kSettingFacebookEmail"
#define kSettingFacebookDisplayName @"kSettingFacebookDisplayName"
#define kSettingFacebookToken       @"kSettingFacebookToken"
#define kSettingFacebookImageUrl    @"kSettingFacebookImageUrl"

#define kSettingTwitterAccount      @"kSettingTwitterAccount"
#define kSettingTwitterEmail        @"kSettingTwitterEmail"
#define kSettingTwitterDisplayName  @"kSettingTwitterDisplayName"
#define kSettingTwitterToken        @"kSettingTwitterToken"
#define kSettingTwitterSecret       @"kSettingTwitterSecret"
#define kSettingTwitterImageUrl     @"kSettingTwitterImageUrl"

#define kSettingGoogleAccount       @"kSettingGoogleAccount"
#define kSettingGoogleEmail         @"kSettingGoogleEmail"
#define kSettingGoogleDisplayName   @"kSettingGoogleDisplayName"
#define kSettingGoogleToken         @"kSettingGoogleToken"
#define kSettingGoogleRefreshToken  @"kSettingGoogleRefreshToken"
#define kSettingGoogleImageUrl      @"kSettingGoogleImageUrl"

#define kSettingLoggedInUser        @"kSettingLoggedInUser"
#define kSettingLocations           @"kSettingLocations"

#define kSettingsAPNSToken          @"kSettingsAPNSToken"
#define kSettingLastLocation        @"kSettingLastLocation"

#define kLocationFieldTitle      @"title"
#define kLocationFieldLocation   @"location"
#define kLocationFieldLatitude   @"latitude"
#define kLocationFieldLongitude  @"longitude"
#define kLocationFieldData       @"data"

#define kSettingThemes            @"kSettingThemes"
#define kSettingExtendedTimer     @"kSettingExtendedTimer"
#define kSettingExtendedMealList  @"kSettingExtendedMealList"
#define kSettingNoAdvApp          @"kSettingNoAdvApp"
#define kSettingCumulative        @"kSettingCumulative"

#define kSettingApplicationColor @"kSettingApplicationColor"

#define kLocalSettingsWeatherCacheKey  @"kLocalSettingsWeatherCacheKey"

@interface DKSettingsManager : NSObject

+ (instancetype)sharedInstance;

- (void)setObject:(id)object forKeyedSubscript:(id)key;
- (id)objectForKeyedSubscript:(id)key;

- (void)removeObjectForKey:(id)key;

@end
