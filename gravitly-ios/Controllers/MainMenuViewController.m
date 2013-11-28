//
//  MainMenuViewController.m
//  gravitly-ios
//
//  Created by Geric Encarnacion on 8/20/13.
//  Copyright (c) 2013 Geric Encarnacion. All rights reserved.
//

#define REUSE_IDENTIFIER_COLLECTION_CELL @"MapCell"
#define FEED_SIZE 15

#define TAG_GRID_VIEW 111
#define TAG_LIST_VIEW 222

#import "MainMenuViewController.h"
#import "CropPhotoViewController.h"
#import "LogInViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AFNetworking.h>
#import "Feed.h"
#import "AppDelegate.h"
#import <Parse/Parse.h>
#import "GVImageView.h"
#import "PhotoDetailsViewController.h"
#import "SettingsViewController.h"
#import "PhotoFeedCell.h"
#import "SearchResultsViewController.h"
#import "MapViewController.h"

@interface MainMenuViewController ()

@property (nonatomic) UIImage *capturedImaged;
@property (nonatomic) UIImagePickerController *picker;
@property (strong, nonatomic) NSMutableArray *feeds;
@property (strong, nonatomic) NSOperationQueue *queue;
@property (strong, nonatomic) NMPaginator *paginator;
@property (strong, nonatomic) NSCache *cachedImages;
@property (strong, nonatomic) IBOutlet UITableView *feedTableView;
@property (strong, nonatomic) IBOutlet UICollectionView *feedCollectionView;
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;
@property float selectedLatitude;
@property float selectedLongitude;
@property (weak, nonatomic) NSString *selectedLatitudeRef;
@property (weak, nonatomic) NSString *selectedLongitudeRef;

@end

@implementation MainMenuViewController

@synthesize navBar;
@synthesize footerLabel;
@synthesize activityIndicator;

@synthesize feeds = _feeds;
@synthesize queue = _queue;
@synthesize paginator = _paginator;
@synthesize cachedImages = _cachedImages;
@synthesize feedTableView;
@synthesize feedCollectionView;
@synthesize usingNearGeoPointQuery;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.isUsingNearGeoPointQuery)
    {
        [self.paginator reset];
        [self setupPaginator];
        
        CGRect newFrame = self.feedTableView.frame;
        newFrame.size.height = self.view.frame.size.height - navBar.frame.size.height;
        [self.feedTableView setFrame:newFrame];
        [self.feedCollectionView setHidden:YES];
        [self.feedTableView setHidden:NO];
        
        [feedCollectionView reloadData];
        
        NSString *title = [NSString stringWithFormat:@"%f %@, %f %@", self.selectedLatitude, self.selectedLatitudeRef, self.selectedLongitude, self.selectedLongitudeRef];
        
        [self setNavigationBar:navBar title:title];
        [self.navBar.topItem setRightBarButtonItems:nil];
        
        [self setSettingsButton];
        
        //[self.paginator fetchFirstPage];
        
        [self setupTableViewFooter];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNavigationBar:navBar title:[PFUser currentUser].username];
    [self setSettingsButton];
    [self setRightBarButtons];
    
    [self.paginator fetchFirstPage];
    [self setupTableViewFooter];
//    [feedCollectionView setDelegate:self];
//    [feedCollectionView setDataSource:self];
//    [feedTableView setDelegate:self];
//    [feedTableView setDataSource:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Lazy instatiation

- (NSMutableArray *)feeds {
    if (!_feeds) {
        _feeds = [[NSMutableArray alloc] init];
    }
    return _feeds;
}

- (NMPaginator *)paginator {
    if (!_paginator) {
        _paginator = [self setupPaginator];
    }
    return _paginator;
}

- (NSOperationQueue *)queue {
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
    }
    [_queue setMaxConcurrentOperationCount:20]; // set the queue to process a max of 20 images at a time
    return _queue;
}

- (NSCache *)cachedImages
{
    if (!_cachedImages) {
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        _cachedImages = appDelegate.feedImages;
    }
    return _cachedImages;
}

- (IBAction)btnCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)btnGrabIt:(id)sender {
    NSLog(@"taking picture...");
    [self.picker takePicture];
}

- (IBAction)btnCameraRoll:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.picker = picker;
    
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)btnGallery:(id)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    self.picker = picker;
    
    [self presentViewController:picker animated:YES completion:nil];
    
}

- (IBAction)btnLogout:(id)sender {
    if (self.isUsingNearGeoPointQuery) {
        [self.paginator setDelegate:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        NSLog(@"settings page here..");
        SettingsViewController *svc = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
        [self presentViewController:svc animated:YES completion:nil];
    }
}

- (IBAction)cameraTab:(id)sender {
    [self.tabBarController setSelectedIndex:1];
}

- (void)getLatestPhotoFromGallery {
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        // be sure to filter the group so you only get photos
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:group.numberOfAssets - 1] options:0 usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result) {
                ALAssetRepresentation *repr = [result defaultRepresentation];
                UIImage *img = [UIImage imageWithCGImage:[repr fullResolutionImage]];
                NSLog(@"---------------> getting latest image %@", img);
                
                *stop = YES;
            }
        }];
        *stop = NO;
    } failureBlock:^(NSError *error) {
        NSLog(@"fail *error");
    }];
}

#pragma mark - Collection View Controllers

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.feeds.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"CollectionCell";
    
    UICollectionViewCell *cell = (UICollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    UIView *borderView = [[UIView alloc] init];
    [borderView setBackgroundColor:[GVColor redColor]];
    [cell setSelectedBackgroundView:borderView];
    
    GVImageView *feedImageView = (GVImageView *)[cell viewWithTag:TAG_FEED_ITEM_IMAGE_VIEW];
    
    if (cell == nil) {
        cell = [[UICollectionViewCell alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    }
    
    if (self.selectedIndexPath != nil && [indexPath compare:self.selectedIndexPath] == NSOrderedSame) {
        [feedImageView.layer setBorderColor: [[GVColor buttonBlueColor] CGColor]];
        [feedImageView.layer setBorderWidth: 2.0];
    } else {
        [feedImageView.layer setBorderColor: nil];
        [feedImageView.layer setBorderWidth: 0.0];
    }
    
    Feed *feed = [self.feeds objectAtIndex:indexPath.row];
    
    NSString *imageURL = [NSString stringWithFormat:URL_IMAGE, feed.imageFileName];
    
    NSData *data = [self.cachedImages objectForKey:feed.imageFileName] ? [self.cachedImages objectForKey:feed.imageFileName] : nil;
    
    if (!data) {
        [feedImageView setImage:[UIImage imageNamed:@"placeholder.png"]];
        [feedImageView setUrlString:imageURL];
        [feedImageView setImageFilename:feed.imageFileName];
        [feedImageView setCachedImages:self.cachedImages];
        [feedImageView getImageFromNetwork:self.queue];
    } else {
        [feedImageView setImage:[[UIImage alloc] initWithData:data]];
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeMake(320.0f, 320.0f);
    if (!indexPath.row == 0) {
        size = CGSizeMake(100.0f, 100.0f);
    }
    return size;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndexPath = indexPath;
    //[collectionView reloadItemsAtIndexPaths:@[indexPath]];
    [collectionView reloadData];
    [self pushPhotoDetailsViewControllerWithIndex:indexPath.row];
}

#pragma mark - Table view delegates

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Feed *feed = [self.feeds objectAtIndex:indexPath.row];
    
    NSString *tagString = @"";
    for (NSString *tag in feed.hashTags) {
        tagString = [NSString stringWithFormat:@"%@ #%@", tagString, tag];
    }
    tagString = [NSString stringWithFormat:@"%@ %@", feed.caption, tagString];
    
    // To determine the height of each cell
    float lineNumbers = ceilf(tagString.length / 50.0f);
    float height = 17 * (lineNumbers - 1);
    return 436 + height;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.feeds.count;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(PhotoFeedCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Feed *feed = [self.feeds objectAtIndex:indexPath.row];
    UITextView *captionTextView = (UITextView *)[cell viewWithTag:TAG_FEED_CAPTION_TEXT_VIEW];
    UIView *hashTagView = (UIView *)[cell viewWithTag:TAG_FEED_HASH_TAG_VIEW];
    for (NSString *tag in feed.hashTags) {
        NSString *t = [NSString stringWithFormat:@"#%@", tag];
        [self createButtonForHashTag:t inTextView:captionTextView withView:hashTagView];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PhotoFeedCell *cell = (PhotoFeedCell *)[feedTableView dequeueReusableCellWithIdentifier:@"PhotoFeedCell"];
    
    if (cell == nil) {
        cell = (PhotoFeedCell *)[[[NSBundle mainBundle] loadNibNamed:@"PhotoFeedCell" owner:self options:nil] objectAtIndex:0];
    }
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    UILabel *usernameLabel = (UILabel *)[cell viewWithTag:TAG_FEED_USERNAME_LABEL];
    UITextView *captionTextView = (UITextView *)[cell viewWithTag:TAG_FEED_CAPTION_TEXT_VIEW];
    UILabel *dateLabel = (UILabel *)[cell viewWithTag:TAG_FEED_DATE_CREATED_LABEL];
    UILabel *geoLocLabel = (UILabel *)[cell viewWithTag:TAG_FEED_GEO_LOC_LABEL];
    UIButton *locationButton = (UIButton *)[cell viewWithTag:TAG_FEED_LOCATION_BUTTON];
    GVImageView *feedImageView = (GVImageView *)[cell viewWithTag:TAG_FEED_IMAGE_VIEW];
    UIImageView *userImgView = (UIImageView *)[cell viewWithTag:TAG_FEED_USER_IMAGE_VIEW];
    UIImageView *activityIcon = (UIImageView *)[cell viewWithTag:TAG_FEED_ACTIVITY_ICON_IMAGE_VIEW];
    
    if (!self.isUsingNearGeoPointQuery) {
        [locationButton addTarget:self action:@selector(filterLocation:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    //rounded corner
    CALayer * l = [userImgView layer];
    [l setMasksToBounds:YES];
    [l setCornerRadius:userImgView.frame.size.height / 2];
    
    //[imgView setImage:[UIImage imageNamed:@"placeholder.png"]];
    
    Feed *feed = [self.feeds objectAtIndex:indexPath.row];
    NSString *icon = [NSString stringWithFormat:MINI_ICON_FORMAT, feed.activityTagName];
    [activityIcon setImage:[UIImage imageNamed:icon]];
    
//    NSString *tagString = @"";
//    for (NSString *tag in feed.hashTags) {
//        tagString = [NSString stringWithFormat:@"%@ #%@", tagString, tag];
//    }
//    
//    tagString = [NSString stringWithFormat:@"%@ %@", feed.caption, tagString];
    
    [usernameLabel setText:feed.user];
    [geoLocLabel setText:feed.elevation];
    [locationButton setTitle:feed.locationName forState:UIControlStateNormal];
    
    NSDictionary *style = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:feed.captionHashTag attributes:style];
    captionTextView.attributedText = attributedString;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    [dateLabel setText:[dateFormatter stringFromDate:feed.dateUploaded]];
    
    NSData *data = [self.cachedImages objectForKey:feed.imageFileName] ? [self.cachedImages objectForKey:feed.imageFileName] : nil;
    
    if (!data) {
        NSString *imageURL = [NSString stringWithFormat:URL_IMAGE, feed.imageFileName];
        [feedImageView setImage:[UIImage imageNamed:@"placeholder.png"]];
        [feedImageView setUrlString:imageURL];
        [feedImageView setImageFilename:feed.imageFileName];
        [feedImageView setCachedImages:self.cachedImages];
        [feedImageView getImageFromNetwork:self.queue];
        //[feedImageView setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
    } else {
        [feedImageView setImage:[[UIImage alloc] initWithData:data]];
    }
    
    [cell setNeedsUpdateConstraints];
    return cell;
}

- (IBAction)filterLocation:(UIButton *)locationButton
{
    CGPoint buttonPosition = [locationButton convertPoint:CGPointZero toView:feedTableView];
    NSIndexPath *indexPath = [feedTableView indexPathForRowAtPoint:buttonPosition];
    [self pushMainMenuViewControllerWithIndex: indexPath.row];
}

#pragma mark - Requery

- (void)pushMainMenuViewControllerWithIndex: (int)row
{
    Feed *selectedFeed = (Feed *)[self.feeds objectAtIndex:row];

    MainMenuViewController *mmvc = (MainMenuViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MainMenuViewController"];
    [mmvc setUsingNearGeoPointQuery:YES];
    mmvc.selectedLatitude = selectedFeed.latitude;
    mmvc.selectedLongitude = selectedFeed.longitude;
    mmvc.selectedLatitudeRef = selectedFeed.latitudeRef;
    mmvc.selectedLongitudeRef = selectedFeed.longitudeRef;
    
    [self presentViewController:mmvc animated:YES completion:nil];
}


#pragma mark - Photo details method

- (void)pushPhotoDetailsViewControllerWithIndex: (int)row
{
    PhotoDetailsViewController *pdvc = (PhotoDetailsViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"PhotoDetailsViewController"];
    Feed *selectedFeed = (Feed *)[self.feeds objectAtIndex:row];
    [pdvc setFeeds:@[selectedFeed]];
    
    [self presentViewController:pdvc animated:YES completion:nil];
}

#pragma mark - Paginator methods

- (NMPaginator *)setupPaginator {
    NMPaginator *paginator = [[NMPaginator alloc] init];
    if (self.isUsingNearGeoPointQuery) {
        GVNearestPhotoFeedPaginator *npfp = [[GVNearestPhotoFeedPaginator alloc] initWithPageSize:FEED_SIZE delegate:self];
        [npfp setSelectedLatitude:self.selectedLatitude];
        [npfp setSelectedLongitude:self.selectedLongitude];
        paginator = npfp;
    } else {
        GVPhotoFeedPaginator *pfp = [[GVPhotoFeedPaginator alloc] initWithPageSize:FEED_SIZE delegate:self];
        [pfp setParentVC:@"ScoutViewController"];
        paginator = pfp;
    }
    return paginator;
}

- (void)fetchNextPages {
    [self.paginator fetchNextPage];
    [self.activityIndicator startAnimating];
}

- (void)paginator:(id)paginator didReceiveResults:(NSArray *)results
{
    [self updateTableViewFooter];
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    NSInteger i = [self.paginator.results count] - [results count];
    
    for(NSDictionary *result in results)
    {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        i++;
    }
    
    [self.feeds addObjectsFromArray:results];
    
    NSLog(@"paginator:didReceiveResults: - Feed Count: %i", self.feeds.count);
    
    [feedCollectionView reloadData];
    
    [feedTableView beginUpdates];
    [feedTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    [feedTableView endUpdates];
    
    [activityIndicator stopAnimating];
}

- (void)paginatorDidReset:(id)paginator
{
    NSLog(@"ressss");
}

#pragma mark - Scroll view delegates

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // when reaching bottom, load a new page
    if (scrollView.contentOffset.y == scrollView.contentSize.height - scrollView.bounds.size.height)
    {
        // ask next page only if we haven't reached last page
        if (![self.paginator reachedLastPage]) {
            [self fetchNextPages];
        }
    }
}

#pragma mark - footer

- (void)setupTableViewFooter {
    // set up label
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    footerView.backgroundColor = [UIColor clearColor];
    
    GVLabel *label = [[GVLabel alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    [label setLabelStyle:GVRobotoCondensedRegularPaleGrayColor size:kgvFontSize16];
    label.textAlignment = NSTextAlignmentCenter;
    
    self.footerLabel = label;
    [footerView addSubview:label];
    
    // set up activity indicator
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityIndicatorView.center = CGPointMake(40, 22);
    activityIndicatorView.hidesWhenStopped = YES;
    
    self.activityIndicator = activityIndicatorView;
    [footerView addSubview:activityIndicatorView];
    [self.activityIndicator stopAnimating];
    self.feedTableView.tableFooterView = footerView;
}

- (void)updateTableViewFooter
{
    if ([self.paginator.results count] != 0)
    {
        self.footerLabel.text = [NSString stringWithFormat:@"%d results out of %d", [self.paginator.results count], self.paginator.total];
    } else
    {
        self.footerLabel.text = @"";
    }
    
    [self.footerLabel setNeedsDisplay];
}

#pragma mark - Nav bar button methods

- (void)setSettingsButton {
    UIButton *leftBarButton = [[UIButton alloc] init];
    if (self.isUsingNearGeoPointQuery) {
        leftBarButton = [self createButtonWithImageNamed:@"carret.png"];
        [leftBarButton addTarget:self action:@selector(btnLogout:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        leftBarButton = [self createButtonWithImageNamed:@"settings.png"];
        [leftBarButton addTarget:self action:@selector(btnLogout:) forControlEvents:UIControlEventTouchUpInside];
    }
    [self.navBar.topItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:leftBarButton]];
}

- (void)setRightBarButtons {
    UIButton *listButton = [self createButtonWithImageNamed:@"list.png"];
    
    [listButton addTarget:self action:@selector(barButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [listButton setTag:TAG_LIST_VIEW];
    
    UIButton *collectionButton = [self createButtonWithImageNamed:@"collection.png"];
    [collectionButton addTarget:self action:@selector(barButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [collectionButton setTag:TAG_GRID_VIEW];
    
    UIButton *mapPinButton = [self createButtonWithImageNamed:@"map-pin.png"];
    [mapPinButton addTarget:self action:@selector(presentMap:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray *buttons = @[[[UIBarButtonItem alloc] initWithCustomView:mapPinButton], [[UIBarButtonItem alloc] initWithCustomView:listButton], [[UIBarButtonItem alloc] initWithCustomView:collectionButton]];
    
    [self.navBar.topItem setRightBarButtonItems:buttons];
}

-(IBAction)presentMap:(id)sender {
    NSLog(@"mapp button clicked..");
    
    MapViewController *mvc = [self.storyboard instantiateViewControllerWithIdentifier:@"MapViewController"];
    [self presentViewController:mvc animated:YES completion:nil];
}

#pragma mark - switching of view

- (IBAction)barButtonTapped:(UIButton *)barButton {
    if(barButton.tag == TAG_GRID_VIEW) {
        feedCollectionView.hidden = NO;
        feedTableView.hidden = YES;
    } else {
        feedCollectionView.hidden = YES;
        feedTableView.hidden = NO;
    }
}

#pragma mark - AMAttributedLabel delegates

-(void)selectedMention:(NSString *)string
{
    return;
}

-(void)selectedHashtag:(NSString *)string
{
    NSLog(@">>>>>>>>> %@", string);
    return;
}

-(void)selectedLink:(NSString *)string
{
    return;
}

#pragma mark - Clickable Hashtag

- (void)createButtonForHashTag:(NSString *)hashtag inTextView:(UITextView *)textView withView:(UIView *)view
{
    NSMutableAttributedString *attrString = textView.attributedText.mutableCopy;
    NSUInteger count = 0;
    NSUInteger length = [textView.attributedText.string length];
    NSRange range = NSMakeRange(0, length);
    
    while(range.location != NSNotFound)
    {
        range = [attrString.string rangeOfString:hashtag options:0 range:range];
        if(range.location != NSNotFound) {
            
            [attrString addAttribute:NSForegroundColorAttributeName value:[GVColor buttonBlueColor] range:range];
            [textView setAttributedText:attrString];
            
            UITextPosition *Pos2 = [textView positionFromPosition: textView.beginningOfDocument offset: range.location];
            UITextPosition *Pos1 = [textView positionFromPosition: textView.beginningOfDocument offset: range.location + range.length];
            
            UITextRange *textRange = [textView textRangeFromPosition:Pos1 toPosition:Pos2];
            
            CGRect rect = [textView firstRectForRange:(UITextRange *)textRange ];
            
            //NSLog(@"%f, %f", rect.origin.x, rect.origin.y);
            
            UIButton *button = [[UIButton alloc] initWithFrame:rect];
            button.tag = 99;
            //button.backgroundColor = [UIColor greenColor];
            button.titleLabel.text = hashtag;
            [view addSubview:button];
            
            [button addTarget:self action:@selector(hashTagButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
            
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            count++;
        }
    }
}

- (void)hashTagButtonDidClick: (UIButton *)button
{
    SearchResultsViewController *srvc = [self.storyboard instantiateViewControllerWithIdentifier:@"SearchResultsViewController"];
    srvc.title = button.titleLabel.text;
    [self presentViewController:srvc animated:YES completion:nil];
    NSLog(@">>>>>>>>> %@", button.titleLabel.text);
}


@end
