//
//  PostPhotoViewController.m
//  gravitly-ios
//
//  Created by Eli Dela Cruz on 9/10/13.
//  Copyright (c) 2013 Geric Encarnacion. All rights reserved.
//

#import "PostPhotoViewController.h"
#import "AddActivityViewController.h"

@interface PostPhotoViewController ()

@end

@implementation PostPhotoViewController

@synthesize imageHolder;
@synthesize thumbnailImageView;
@synthesize captionTextView;
@synthesize smaView;
@synthesize activityButton;
@synthesize enhancementsButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationItem setTitle:@"Post"];
    [self setBackButton];
    [self setRightBarButtons];
    [self.captionTextView setText:@"Add Caption"];
    //[self.captionTextView setDelegate:self];
    SocialMediaAccountsController *sma = [self smaView:@"Share to:"];
    [sma setBackgroundColor:[GVColor backgroundDarkColor]];
    [smaView addSubview:sma];   
	[self.thumbnailImageView setImage: self.imageHolder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITextView methods for placeholder

/*- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
{
    captionTextView.text = @"";
    return YES;
}

-(void) textViewDidChange:(UITextView *)textView
{
    
    if(captionTextView.text.length == 0){
        captionTextView.textColor = [UIColor lightGrayColor];
        captionTextView.text = @"shit";
        [captionTextView resignFirstResponder];
    }
}*/

#pragma mark - Nav buttons

- (void)setBackButton
{
    UIButton *backButton =  [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:[UIImage imageNamed:@"carret.png"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [backButton setFrame:CGRectMake(0, 0, 32, 32)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
}

- (void)setRightBarButtons {
    UIButton *lockButton = [self createButtonWithImageNamed:@"lock.png"];
    [lockButton addTarget:self action:@selector(lockTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *proceedButton = [self createButtonWithImageNamed:@"check-big.png"];
    [proceedButton addTarget:self action:@selector(lockTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray *buttons = @[[[UIBarButtonItem alloc] initWithCustomView:proceedButton], [[UIBarButtonItem alloc] initWithCustomView:lockButton]];
    
    self.navigationItem.rightBarButtonItems = buttons;
}

-(IBAction)lockTapped:(id)sender {
    NSLog(@"tinap mo ung lock");
}

- (IBAction)addActivity:(id)sender {
    AddActivityViewController *aavc = [self.storyboard instantiateViewControllerWithIdentifier:@"AddActivityViewController"];
    [self.navigationController  pushViewController:aavc animated:YES];
}

- (IBAction)addEnhancement:(id)sender {
    NSLog(@"asdfasdfasdf");
}
@end