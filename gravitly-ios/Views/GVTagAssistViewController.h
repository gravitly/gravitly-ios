//
//  GVTagAssistViewController.h
//  gravitly-ios
//
//  Created by Eli Dela Cruz on 11/4/13.
//  Copyright (c) 2013 Geric Encarnacion. All rights reserved.
//

#import "GVBaseViewController.h"
#import "JSONHelper.h"
#import <CoreLocation/CoreLocation.h>

@protocol TagAssistDelegate <NSObject>

-(void)controllerDidDismissed: (NSArray *)additionalSearchParams;

@end

@interface GVTagAssistViewController : GVBaseViewController <UITableViewDataSource, UITableViewDelegate, JSONHelper, CLLocationManagerDelegate>

@property (assign, nonatomic) id <TagAssistDelegate> delegate;
@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;
@property (strong, nonatomic) IBOutlet UIScrollView *activityScrollView;
@property (strong, nonatomic) IBOutlet UITableView *tagsTableView;

@end
