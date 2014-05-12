//
//  DKSettingsManager.m
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 22/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKSettingsManager.h"
#import "DKLocationManager.h"
#import "FXKeychain.h"

#define kSettingDummyValidationValueKey @"kSettingDummyValidationValueKey"

@interface DKSettingsManager ()

@property (nonatomic, strong) FXKeychain *keychain;
@property (nonatomic) BOOL useSafeStore;

@end

@implementation DKSettingsManager

@synthesize keychain = _keychain;
@synthesize useSafeStore = _useSafeStore;

+ (instancetype)sharedInstance {
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    self = [super init];
    
	if (self != nil) {
//        NSString *service = [[NSBundle mainBundle] bundleIdentifier];
//
//        _keychain = [[FXKeychain alloc] initWithService:service accessGroup:service];
        _keychain = [FXKeychain defaultKeychain];
        
        _useSafeStore = NO;//_keychain[kSettingDummyValidationValueKey] = kSettingDummyValidationValueKey;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserDidLogin:) name:kSuccessLoginNotification object:nil];
    }
    
    return self;
}

- (void)onUserDidLogin: (NSNotification *)notification {
    
}


- (void)setObject:(id)object forKeyedSubscript:(id)key {
    
    if (self.useSafeStore) {
        id data = self.keychain[key];
        
        if (data) {
            [self.keychain removeObjectForKey:key];
        }
        
        if (object) {
            
            if ([key isEqualToString:kSettingLocations]) {
                
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
                
                object = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
            
            [self.keychain setObject:object forKeyedSubscript:key];
        }
    } else {
        if (object && key) {
            [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (void)removeObjectForKey:(id)key {
    if (self.useSafeStore) {
        [self.keychain removeObjectForKey:key];
    } else {
        if (key) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (id)objectForKeyedSubscript:(id)key {
    if (self.useSafeStore) {
        if ([key isEqualToString:kSettingLocations] == NO) {
            return [self.keychain objectForKeyedSubscript:key];
        } else {
            
            NSString *dataAsString = [self.keychain objectForKeyedSubscript:key];
            
            if (dataAsString.length == 0) {
                return nil;
            } else {
                return [NSJSONSerialization JSONObjectWithData:[dataAsString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            }
        }
    } else {
        return [[NSUserDefaults standardUserDefaults] objectForKey:key];
    }
}

- (void)detectCurrentLocation: (DetectLocationBlock)locationDetectedBlock {
    [[DKLocationManager sharedInstance] updateLocation:^(CLLocation *newLocation, CLPlacemark *place) {
        locationDetectedBlock(place);
    } withInteractionAllowed: YES];
}

@end
