//
//  FilterViewController.h
//  gravitly-ios
//
//  Created by Geric Encarnacion on 8/28/13.
//  Copyright (c) 2013 Geric Encarnacion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GVBaseViewController.h"
#import "Metadata.h"

@interface FilterViewController : GVBaseViewController

@property (weak, nonatomic) IBOutlet UIImageView *filterImageView;

@property (strong, nonatomic) UIImage *imageHolder;
@property float zoomScale;
@property CGPoint contentOffset;
@property (strong, nonatomic) IBOutlet UIScrollView *filterScrollView;
@property (strong, nonatomic) IBOutlet UIScrollView *cropperScrollView;
@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;
@property (strong, nonatomic) IBOutlet UIView *filterUIView;
@property (strong, nonatomic) IBOutlet UIButton *rotateButton;
@property (strong, nonatomic) IBOutlet UIButton *blurButton;
@property (strong, nonatomic) IBOutlet UIButton *contrastButton;
@property (strong, nonatomic) Metadata *meta;
@property (nonatomic) BOOL saveToGallery;


- (IBAction)applyFilter:(id)sender;

- (IBAction)reset:(id)sender;

@end
