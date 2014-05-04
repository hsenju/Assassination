//
//  Login.m
//  Assassination
//
//  Created by Hikari Senju on 4/21/14.
//  Copyright (c) 2014 Hikari Senju. All rights reserved.
//

#import "Login.h"
#import "ViewController.h"
#import "MBProgressHUD.h"
#import <Parse/Parse.h>

@interface Login ()

@property (nonatomic, strong) MBProgressHUD *hud;

- (void)processFieldEntries;
- (void)textInputChanged:(NSNotification *)note;
- (BOOL)shouldEnableDoneButton;

@end

@implementation Login

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:self.name];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:self.password];
	self.done.enabled = NO;
    self.name.placeholder = @"Email";
    self.password.placeholder = @"Password";
    self.password.secureTextEntry = YES;
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    window.tintColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
	[self.name becomeFirstResponder];
	[super viewWillAppear:animated];
}

-  (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.name];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.password];
}

- (IBAction)done:(id)sender {
	[self.name resignFirstResponder];
	[self.password resignFirstResponder];
	[self processFieldEntries];
}

- (BOOL)shouldEnableDoneButton {
	BOOL enableDoneButton = NO;
	if (self.name.text != nil &&
		self.name.text.length > 0 &&
		self.password.text != nil &&
		self.password.text.length > 0) {
		enableDoneButton = YES;
	}
	return enableDoneButton;
}

- (void)textInputChanged:(NSNotification *)note {
	self.done.enabled = [self shouldEnableDoneButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == self.name) {
		[self.password becomeFirstResponder];
	}
	if (textField == self.password) {
		[self.password resignFirstResponder];
		[self processFieldEntries];
	}
	return YES;
}

- (void)processFieldEntries {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view.superview animated:YES];
    self.hud.labelText = NSLocalizedString(@"Logging in", nil);
    self.hud.dimBackground = YES;
	NSString *username = self.name.text;
	NSString *password = self.password.text;
	NSString *noUsernameText = @"username";
	NSString *noPasswordText = @"password";
	NSString *errorText = @"No ";
	NSString *errorTextJoin = @" or ";
	NSString *errorTextEnding = @" entered";
	BOOL textError = NO;
	if (username.length == 0 || password.length == 0) {
		textError = YES;
		if (password.length == 0) {
			[self.password becomeFirstResponder];
		}
		if (username.length == 0) {
			[self.name becomeFirstResponder];
		}
	}
	if (username.length == 0) {
		textError = YES;
		errorText = [errorText stringByAppendingString:noUsernameText];
	}
	if (password.length == 0) {
		textError = YES;
		if (username.length == 0) {
			errorText = [errorText stringByAppendingString:errorTextJoin];
		}
		errorText = [errorText stringByAppendingString:noPasswordText];
	}
	if (textError) {
		errorText = [errorText stringByAppendingString:errorTextEnding];
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:errorText message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
		[alertView show];
		return;
	}
	self.done.enabled = NO;    UIActivityIndicatorView *activityView=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.center=self.view.center;
    [activityView startAnimating];
    [self.view addSubview:activityView];
	[PFUser logInWithUsernameInBackground:username password:password block:^(PFUser *user, NSError *error) {
		[activityView stopAnimating];
        [MBProgressHUD hideHUDForView:self.view.superview animated:NO];
		if (user) {
            [self performSegueWithIdentifier: @"LoginDone" sender: self];
		} else {
			NSLog(@"%s didn't get a user!", __PRETTY_FUNCTION__);
			self.done.enabled = [self shouldEnableDoneButton];
			UIAlertView *alertView = nil;
            if (error == nil) {
				alertView = [[UIAlertView alloc] initWithTitle:@"Couldn’t log in:\nThe username or password were wrong." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
			} else {
				alertView = [[UIAlertView alloc] initWithTitle:[[error userInfo] objectForKey:@"error"] message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
			}
			[alertView show];
			[self.name becomeFirstResponder];
		}
	}];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];}

@end
