//
//  Activity.m
//  gravitly-ios
//
//  Created by Eli Dela Cruz on 10/8/13.
//  Copyright (c) 2013 Geric Encarnacion. All rights reserved.
//
#define CLASS_NAME_ACTIVITY @"Category"

#import "Activity.h"


@implementation Activity

@synthesize objectId;
@synthesize name;
@synthesize tagName;

+ (void)findAll: (ResultBlock)block {
    [iOSCoreParseHelper findAll:CLASS_NAME_ACTIVITY :^(NSArray *objects, NSError *error) {
        NSMutableArray *activities = [NSMutableArray array];
        for (PFObject *obj in objects) {
            [activities addObject:[self convert:obj]];
        }
        block(activities, error);
    }];
}

+ (void)findAllInBackground: (ResultBlock )block {
        @try {
            PFQuery *query = [PFQuery queryWithClassName:CLASS_NAME_ACTIVITY];
            query.cachePolicy = kPFCachePolicyCacheElseNetwork;
            [query orderByAscending:@"order"];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                NSMutableArray *activities = [NSMutableArray array];
                for (PFObject *obj in objects) {
                    NSString *name = [obj objectForKey:@"name"];
                    NSNumber *order = [obj objectForKey:@"order"];
                    if (![order isEqualToNumber:[NSNumber numberWithInt:0]]) {
                        [activities addObject:[self convert:obj]];
                    }
                }
                block(activities, error);
            }];
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
}

+ (Activity *)convert: (PFObject *)object {
    Activity *act = [[Activity alloc] init];
    
    [act setObjectId:[object objectId]];
    [act setName:[object objectForKey:@"name"]];
    [act setTagName:[object objectForKey:@"tagName"]];
    
    return act;
}


@end
