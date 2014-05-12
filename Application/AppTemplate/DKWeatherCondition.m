//
//  DKWeatherCondition.m
//  ThreadWeather
//
//  Created by Dmitry Klimkin on 29/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "DKWeatherCondition.h"

@interface DKWeatherCondition ()

@end

@implementation DKWeatherCondition

+ (instancetype)weatherConditionFromData: (NSDictionary *)data {
    
    DKWeatherCondition *weatherCondition = nil;
    
    if (data == nil) {
        return nil;
    }
    
    weatherCondition = [DKWeatherCondition new];
    
    weatherCondition.apparentTemperature = [data[@"apparentTemperature"] floatValue];
    weatherCondition.cloudCover = [data[@"cloudCover"] floatValue];
    weatherCondition.dewPoint = [data[@"dewPoint"] floatValue];
    weatherCondition.humidity = [data[@"humidity"] floatValue];
    weatherCondition.ozone = [data[@"ozone"] floatValue];
    weatherCondition.precipIntensity = [data[@"precipIntensity"] floatValue];
    weatherCondition.precipProbability = [data[@"precipProbability"] floatValue];
    weatherCondition.pressure = [data[@"pressure"] floatValue];
    weatherCondition.temperature = [data[@"temperature"] floatValue];
    weatherCondition.visibility = [data[@"visibility"] floatValue];
    weatherCondition.windBearing = [data[@"windBearing"] floatValue];
    weatherCondition.windSpeed = [data[@"windSpeed"] floatValue];

    weatherCondition.time = [data[@"time"] intValue];

    weatherCondition.icon = data[@"icon"];
    weatherCondition.precipType = data[@"precipType"];
    weatherCondition.summary = data[@"summary"];
    
    [weatherCondition updateTemperature];
    
    return weatherCondition;
}

- (void)updateTemperature {
    NSLocale *locale = [NSLocale currentLocale];
    BOOL usesMetric = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
    
    //If usesMetric is YES, I would use Celsius; otherwise, I'd use Fahrenheit.
    if (usesMetric) {
        _weatherSymbol = @"℃";
        _temperature = 5.0f/9.0f * (_temperature - 32.0f);
        _apparentTemperature = 5.0f/9.0f * (_apparentTemperature - 32.0f);
        _dewPoint = 5.0f/9.0f * (_dewPoint - 32.0f);
    } else {
        _weatherSymbol = @"℉";
    }
}

- (id) init {
	self = [super init];
	if (self != nil) {
	}
	return self;
}

- (void) dealloc {
}

- (id)initWithCoder:(NSCoder *)decoder {
    
    self = [super init];
    if (self) {
        
        _apparentTemperature = [decoder decodeFloatForKey:@"apparentTemperature"];
        _cloudCover          = [decoder decodeFloatForKey:@"cloudCover"];
        _dewPoint            = [decoder decodeFloatForKey:@"dewPoint"];
        _humidity            = [decoder decodeFloatForKey:@"humidity"];
        _ozone               = [decoder decodeFloatForKey:@"ozone"];
        _precipIntensity     = [decoder decodeFloatForKey:@"precipIntensity"];
        _precipProbability   = [decoder decodeFloatForKey:@"precipProbability"];
        _pressure            = [decoder decodeFloatForKey:@"pressure"];
        _temperature         = [decoder decodeFloatForKey:@"temperature"];
        _visibility          = [decoder decodeFloatForKey:@"visibility"];
        _windBearing         = [decoder decodeFloatForKey:@"windBearing"];
        _windSpeed           = [decoder decodeFloatForKey:@"windSpeed"];
        
        _time                = [decoder decodeInt32ForKey:@"time"];
        
        _icon                = [decoder decodeObjectForKey:@"icon"];
        _precipType          = [decoder decodeObjectForKey:@"precipType"];
        _summary             = [decoder decodeObjectForKey:@"summary"];
        _weatherSymbol       = [decoder decodeObjectForKey:@"weatherSymbol"];

    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    [encoder encodeFloat:_apparentTemperature forKey:@"apparentTemperature"];
    [encoder encodeFloat:_cloudCover          forKey:@"cloudCover"];
    [encoder encodeFloat:_dewPoint            forKey:@"dewPoint"];
    [encoder encodeFloat:_humidity            forKey:@"humidity"];
    [encoder encodeFloat:_ozone               forKey:@"ozone"];
    [encoder encodeFloat:_precipIntensity     forKey:@"precipIntensity"];
    [encoder encodeFloat:_precipProbability   forKey:@"precipProbability"];
    [encoder encodeFloat:_pressure            forKey:@"pressure"];
    [encoder encodeFloat:_temperature         forKey:@"temperature"];
    [encoder encodeFloat:_visibility          forKey:@"visibility"];
    [encoder encodeFloat:_windBearing         forKey:@"windBearing"];
    [encoder encodeFloat:_windSpeed           forKey:@"windSpeed"];
    
    [encoder encodeInt32:_time                forKey:@"time"];
    
    [encoder encodeObject:_icon               forKey:@"icon"];
    [encoder encodeObject:_precipType         forKey:@"precipType"];
    [encoder encodeObject:_summary            forKey:@"summary"];
    [encoder encodeObject:_weatherSymbol      forKey:@"weatherSymbol"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: %.2f %@\n%@: %.2f\n%@: %.2f %@\n%@: %.2f\n%@: %.2f\n%@: %.2f\n%@: %.2f\n%@: %.2f\n%@: %.2f\n%@: %.2f\n%@: %.2f\n%@: %@\n", NSLocalizedString(@"Feels like", nil), _apparentTemperature, _weatherSymbol, NSLocalizedString(@"Cloud cover", nil), _cloudCover, NSLocalizedString(@"Dew point", nil), _dewPoint, _weatherSymbol, NSLocalizedString(@"Humidity", nil), _humidity, NSLocalizedString(@"Ozone", nil), _ozone, NSLocalizedString(@"Precip intensity", nil), _precipIntensity, NSLocalizedString(@"Precip probability", nil), _precipProbability, NSLocalizedString(@"Pressure", nil), _pressure, NSLocalizedString(@"Visibility", nil), _visibility, NSLocalizedString(@"Wind bearing", nil), _windBearing, NSLocalizedString(@"Wind speed", nil), _windSpeed, NSLocalizedString(@"Summary", nil), _summary];
}

@end
