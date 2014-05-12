//
//  NSManagedObject+JSON.m
//  AppTemplate
//
//  Created by Dmitry Klimkin on 1/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import "NSManagedObject+JSON.h"

@implementation NSManagedObject (JSON)

- (NSDictionary*) toDictionary {
    NSArray* attributes = [[[self entity] attributesByName] allKeys];
    NSArray* relationships = [[[self entity] relationshipsByName] allKeys];
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity: [attributes count] + [relationships count] + 1];
    
    [dict setObject:[[self class] description] forKey:@"class"];
    
    for (NSString* attr in attributes) {
        NSObject* value = [self valueForKey:attr];
        
        if (value != nil) {
            [dict setObject:value forKey:attr];
        }
    }
    
    for (NSString* relationship in relationships) {
        NSObject* value = [self valueForKey:relationship];
        
        if ([value isKindOfClass:[NSSet class]]) {
            // To-many relationship
            
            // The core data set holds a collection of managed objects
            NSSet* relatedObjects = (NSSet*) value;
            
            // Our set holds a collection of dictionaries
            NSMutableSet* dictSet = [NSMutableSet setWithCapacity:[relatedObjects count]];
            
            for (NSManagedObject* relatedObject in relatedObjects) {
//                if (!relatedObject.traversed) {
                    [dictSet addObject:[relatedObject toDictionary]];
//                }
            }
            
            [dict setObject:dictSet forKey:relationship];
        }
        else if ([value isKindOfClass:[NSManagedObject class]]) {
            // To-one relationship
            
            NSManagedObject* relatedObject = (NSManagedObject*) value;
            
//            if (!relatedObject.traversed) {
                // Call toDictionary on the referenced object and put the result back into our dictionary.
                [dict setObject:[relatedObject toDictionary] forKey:relationship];
//            }
        }
    }
    
    return dict;
}

- (NSDictionary *)dictionaryOfAttributes:(NSSet *)excludedKeys {
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
//    NSDictionary *attributes = [[self entity] attributesByName];
//    
//    for (NSString *key in [attributes allKeys]) {
//        if ([excludedKeys containsObject:key])
//            continue;
//        
//        id value = [self valueForKey:key];
//        
//        if (!value)
//            continue;
//        
//        if ([value isKindOfClass:[NSDate class]]) {
//            value = [(NSDate *)value toJSONDate];
//        }
//        
//        data[key] = value;
//    }
    
    return data;
}

- (void)updateAttributesFromDictionary:(NSDictionary *)attributesDictionary
{
//    for (NSString *key in [attributesDictionary allKeys]) {
//        id value = attributesDictionary[key];
//        
//        if ([value isKindOfClass:[NSString class]]) {
//            NSDate *dateValue = [NSDate fromJSONDate:value];
//            
//            if (dateValue) {
//                value = dateValue;
//            }
//        }
//        
//        [self setValue:value forKey:key];
//    }
}

@end
