//
//  FilterViewController.m
//  gravitly-ios
//
//  Created by Geric Encarnacion on 8/28/13.
//  Copyright (c) 2013 Geric Encarnacion. All rights reserved.
//

//TODO:standard size
#define STANDARD_SIZE 612.0f
#define TAG_MAGIC_NUMBER 10

#import "FilterViewController.h"
#import "GPUImage.h"
#import "CropPhotoViewController.h"
#import "AppDelegate.h"
#import "UIImage+Resize.h"
#import "ActivityViewController.h"

@interface FilterViewController ()

@property (nonatomic, getter = hasContrast) NSInteger contrast;
@property (nonatomic, getter = hasBlur) NSInteger blur;
@property (nonatomic, strong) GPUImageGaussianSelectiveBlurFilter *gaussianBlurFilter;
@property (nonatomic, strong) GPUImageToneCurveFilter *toneCurveFilter;
@property (nonatomic, strong) GPUImageContrastFilter *contrastFilter;
@property (nonatomic) NSUInteger rotationMultiplier;
@property (nonatomic, strong) NSMutableArray *filterButtons;

@end

@implementation FilterViewController {
    NSArray *filters;
    UIImage *croppedImage;
    AppDelegate *appDelegate;
}

@synthesize imageHolder;
@synthesize filterImageView;
@synthesize filterScrollView;
@synthesize zoomScale;
@synthesize cropperScrollView;
@synthesize navBar;
@synthesize meta;
@synthesize contentOffset;
@synthesize contrast = _contrast;
@synthesize rotationMultiplier = _rotationMultiplier;
@synthesize gaussianBlurFilter = _gaussianBlurFilter, toneCurveFilter = _toneCurveFilter, contrastFilter = _contrastFilter;
@synthesize filterButtons = _filterButtons;

#pragma mark - Lazy Instantiations

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [appDelegate createFilterPlaceholders];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setBackButton:navBar];
    [self setProceedButton];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];

    filters = @[@"Normal", @"1977", @"Brannan", @"Gotham", @"Hefe", @"Lord Kelvin", @"Nashville", @"X-PRO II", @"yellow-red", @"aqua", @"crossprocess"];
    
    [self.navigationItem setTitle:@"Edit"];
    
    filterImageView.contentMode = UIViewContentModeScaleAspectFit;
    filterImageView.userInteractionEnabled = YES;
    [filterImageView setImage:imageHolder];
    
    [self fixImageZoomScale];
    
    croppedImage = [croppedImage resizeImageToSize:CGSizeMake(STANDARD_SIZE, STANDARD_SIZE)];
    
    [self setNavigationBar:navBar title:navBar.topItem.title];
    
    
    //image from link works here..
    /*
    NSURL *url = [NSURL URLWithString:@"http://s3.amazonaws.com/gravitly.uploads.dev/e97979b8-6502-4f2b-944f-8313b4bae9ac.jpeg"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *image = [[UIImage alloc] initWithData:data];
    filterImageView.image = image;
    */
    
    
    filterImageView.image = croppedImage;

    
    [filterScrollView setContentSize:CGSizeMake(2090, 0)];
    filterScrollView.translatesAutoresizingMaskIntoConstraints= NO;
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.filterButtons = [[NSMutableArray alloc] init];
    
    for (int x = 10; x < filters.count+TAG_MAGIC_NUMBER; x++) {
        UIButton *button = [[UIButton alloc] init];
        if (x != TAG_MAGIC_NUMBER) {
            NSData *data  = [appDelegate.filterPlaceholders objectForKey:[filters objectAtIndex:(x-TAG_MAGIC_NUMBER)]];
            button = (UIButton *)[filterScrollView viewWithTag:x];
            [button setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
        } else {
            button = (UIButton *)[filterScrollView viewWithTag:x];
            //[button setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
        }
        [self.filterButtons addObject:button];

    }
    
}

#pragma mark - Image manipulations

- (void)fixImageZoomScale {
    CGSize origSize = filterImageView.frame.size;
    
    filterImageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, zoomScale, zoomScale);
    [cropperScrollView setZoomScale:zoomScale];
    
    cropperScrollView.contentSize = origSize;
    [cropperScrollView setContentOffset:contentOffset];
    
    UIGraphicsBeginImageContextWithOptions(cropperScrollView.contentSize, NO, 0.0);
    {
        CGPoint savedContentOffset = cropperScrollView.contentOffset;
        CGRect savedFrame = cropperScrollView.frame;
        cropperScrollView.contentOffset = CGPointZero;
        cropperScrollView.frame = CGRectMake(0, 0, cropperScrollView.contentSize.width, cropperScrollView.contentSize.height);
        [cropperScrollView.layer renderInContext: UIGraphicsGetCurrentContext()];
        croppedImage = UIGraphicsGetImageFromCurrentImageContext();
        cropperScrollView.contentOffset = savedContentOffset;
        cropperScrollView.frame = savedFrame;
    }   
    UIGraphicsEndImageContext();
    
    if (croppedImage != nil) {
        filterImageView.image = croppedImage;
        filterImageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0f, 1.0f);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pushActivityViewController {
    ActivityViewController *avc = [self.storyboard instantiateViewControllerWithIdentifier:@"ActivityViewController"];
    
    UIImage *finalImage = [[UIImage alloc] init];
    
    UIGraphicsBeginImageContextWithOptions(cropperScrollView.contentSize, NO, 0.0);
    {
        CGPoint savedContentOffset = cropperScrollView.contentOffset;
        CGRect savedFrame = cropperScrollView.frame;
        cropperScrollView.contentOffset = CGPointZero;
        cropperScrollView.frame = CGRectMake(0, 0, cropperScrollView.contentSize.width, cropperScrollView.contentSize.height);
        [cropperScrollView.layer renderInContext: UIGraphicsGetCurrentContext()];
        finalImage = UIGraphicsGetImageFromCurrentImageContext();
        cropperScrollView.contentOffset = savedContentOffset;
        cropperScrollView.frame = savedFrame;
    }
    UIGraphicsEndImageContext();
    [avc setImageHolder:finalImage];
    NSLog(@"metatatata %@", meta);
    [avc setMeta:meta];
    [self.navigationController pushViewController:avc animated:YES];
}


- (IBAction)applyFilter:(UIButton *)sender {
    //NSString *buttonTitle = [];//sender.titleLabel.text;
    
    /*
    if ([buttonTitle isEqualToString:@"B&W"]) {
        filterImageView.image = [filterImageView.image saturateImage:0 withContrast:1.05];
    }
    */
    
//    for (int x = 1; x < filters.count; x++) {
//        [sender.layer setBorderColor: nil];
//        [sender.layer setBorderWidth: 0.0];
//    }
//    
//
    
    for (UIButton *f in self.filterButtons) {
        [f.layer setBorderColor: [UIColor clearColor].CGColor];
        [f.layer setBorderWidth: 0.0];
    }
    
    [sender.layer setBorderColor:[[GVColor buttonBlueColor] CGColor]];
    [sender.layer setBorderWidth: 2.0];
    
    GPUImageToneCurveFilter *selectedFilter;
    UIImage *filteredImage =[[UIImage alloc] init];
    NSString *filterString = [filters objectAtIndex:(sender.tag - TAG_MAGIC_NUMBER)];
    
    if ((sender.tag - TAG_MAGIC_NUMBER) != 0) {
        selectedFilter = [[GPUImageToneCurveFilter alloc] initWithACV:filterString];
        self.toneCurveFilter = selectedFilter;
        [self applyEffects];
    } else {
        self.toneCurveFilter = nil;
        [self applyEffects];
    }
    
}


- (IBAction)applyContrast:(id)sender {
    if (self.hasContrast) {
        self.contrastFilter = nil;
        [self setContrast:0];
    } else {
        self.contrastFilter = [[GPUImageContrastFilter alloc] init];
        [self.contrastFilter setContrast:1.5f];
        [self setContrast:1];
    }
    [self applyEffects];
}

- (IBAction)rotate:(id)sender {
    float degrees = (self.rotationMultiplier + 1) * 90.0f;
    filterImageView.transform = CGAffineTransformMakeRotation(degrees * M_PI/180);
    self.rotationMultiplier++;
}

- (IBAction)applyBlur:(id)sender {
    if (self.hasBlur) {
        self.gaussianBlurFilter = nil;
        [self setBlur:0];
    } else {
        self.gaussianBlurFilter = [GPUImageGaussianSelectiveBlurFilter new];
        [self.gaussianBlurFilter setBlurSize:2.0];
        [self.gaussianBlurFilter setExcludeCircleRadius:120.0/320.0];
        [self.gaussianBlurFilter setExcludeCirclePoint:CGPointMake(0.5f, 0.5f)];
        [self setBlur:1];
    }
    [self applyEffects];
}

#pragma mark - GPUImage manipulations

- (void)applyEffects {
    [self resetFilter];
    if (self.gaussianBlurFilter) {
        filterImageView.image = [self.gaussianBlurFilter imageByFilteringImage:filterImageView.image];
    }
    if (self.toneCurveFilter) {
        filterImageView.image = [self.toneCurveFilter imageByFilteringImage:filterImageView.image];
    }
    if (self.contrastFilter) {
        filterImageView.image = [self.contrastFilter imageByFilteringImage:filterImageView.image];
    }
}

- (IBAction)reset:(id)sender {
    [self resetFilter];
}

-(void)resetFilter {
    filterImageView.image = croppedImage;
}

#pragma mark - Nav bar button methods

/*- (void)setBackButton {
    
    UIButton *backButton =  [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:[UIImage imageNamed:@"carret.png"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [backButton setFrame:CGRectMake(0, 0, 32, 32)];
    
    [navBar.topItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:backButton]];
}*/

- (void)backButtonTapped:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)setProceedButton {
    UIButton *proceedButton = [self createButtonWithImageNamed:@"check-big.png"];
    [proceedButton addTarget:self action:@selector(proceedButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [proceedButton setFrame:CGRectMake(-1, 0, 50, 44)];
    [proceedButton setBackgroundColor:[GVColor buttonBlueColor]];
    
    CALayer *rightBorder = [CALayer layer];
    rightBorder.borderColor = [GVColor backgroundDarkColor].CGColor;
    rightBorder.borderWidth = 1.0f;
    rightBorder.frame = CGRectMake(0, 0, 1, CGRectGetHeight(proceedButton.frame));
    [proceedButton.layer addSublayer:rightBorder];
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:proceedButton];
    [barButton setBackgroundVerticalPositionAdjustment:-20.0f forBarMetrics:UIBarMetricsDefault];
    
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 7.0f) {
        negativeSpacer.width = -16;
    } else {
        negativeSpacer.width = -6; //ios 6 below
    }
    
    [navBar.topItem setRightBarButtonItems:[NSArray arrayWithObjects:negativeSpacer, barButton, nil] animated:NO];
}


- (void)proceedButtonTapped:(id)sender
{
    [self performSelector:@selector(pushActivityViewController) withObject:nil];
}


@end
