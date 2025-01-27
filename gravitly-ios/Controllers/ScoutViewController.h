//
//  ScoutViewController.h
//  gravitly-ios
//
//  Created by Eli Dela Cruz on 9/9/13.
//  Copyright (c) 2013 Geric Encarnacion. All rights reserved.
//

#import "GVBaseViewController.h"
//#import <NMPaginator.h>
#import "GVTagAssistViewController.h"
#import "GVPhotoFeedPaginator.h"
#import "MapLightBoxViewController.h"

@interface ScoutViewController : GVBaseViewController <UIScrollViewDelegate, NMPaginatorDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDelegate, UITableViewDataSource, TagAssistDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;
@property (strong, nonatomic) IBOutlet UIButton *searchButton;
@property (strong, nonatomic) IBOutlet UIView *searchView;

@property (strong, nonatomic) IBOutlet UICollectionView *photoFeedCollectionView;
@property (strong, nonatomic) IBOutlet UITableView *photoFeedTableView;
@property UIActivityIndicatorView *activityIndicator;
@property UILabel *footerLabel;
@property GVPhotoFeedPaginator *paginator;

@property (strong, nonatomic) NSString *parent;

@end
