//
//  DKWeatherCondition.h
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 29/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

@import Foundation;

@interface DKWeatherCondition : NSObject <NSCoding>

+ (instancetype)weatherConditionFromData: (NSDictionary *)data;

- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

@property (nonatomic) float apparentTemperature;
@property (nonatomic) float cloudCover;
@property (nonatomic) float dewPoint;
@property (nonatomic) float humidity;
@property (nonatomic) float ozone;
@property (nonatomic) float precipIntensity;
@property (nonatomic) float precipProbability;
@property (nonatomic) float pressure;
@property (nonatomic) float temperature;
@property (nonatomic) float visibility;
@property (nonatomic) float windBearing;
@property (nonatomic) float windSpeed;

@property (nonatomic) int time;

@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) NSString *precipType;
@property (nonatomic, strong) NSString *summary;
@property (nonatomic, strong) NSString *weatherSymbol;

@end
