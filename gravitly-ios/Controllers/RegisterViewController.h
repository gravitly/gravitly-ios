//
//  RegisterViewController.h
//  gravitly-ios
//
//  Created by Geric Encarnacion on 8/16/13.
//  Copyright (c) 2013 Geric Encarnacion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GVTextField.h"
#import "GVButton.h"
#import "GVBaseViewController.h"
#import "SocialMediaAccountsController.h"

@interface RegisterViewController : GVBaseViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>


@property (weak, nonatomic) IBOutlet GVTextField *txtUserName;

@property (weak, nonatomic) IBOutlet UITextField *txtPassword;

@property (weak, nonatomic) IBOutlet UITextField *txtEmail;
@property (strong, nonatomic) IBOutlet UITableView *signUpTableView;
@property (strong, nonatomic) IBOutlet GVButton *signUpButton;
@property (strong, nonatomic) IBOutlet UIView *socialMediaAccountsView;
@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;
@property (strong, nonatomic) IBOutlet UIButton *checkButton;

- (IBAction)btnRegister:(id)sender;
- (IBAction)btnAgree:(id)sender;


@end
