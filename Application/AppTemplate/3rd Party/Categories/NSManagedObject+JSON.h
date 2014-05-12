//
//  NSManagedObject+JSON.h
//  AppTemplate
//
//  Created by Dmitry Klimkin on 1/3/14.
//  Copyright (c) 2014 Dmitry Klimkin. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (JSON)

- (NSDictionary*)toDictionary;
- (NSDictionary *)dictionaryOfAttributes:(NSSet *)excludedKeys;
- (void)updateAttributesFromDictionary:(NSDictionary *)attributesDictionary;

@end
