//
//  Login.m/Users/hsenju/Dropbox/balloonapp/Balloon.xcodeproj
//  Assassination
//
//  Created by Hikari Senju on 4/21/14.
//  Copyright (c) 2014 Hikari Senju. All rights reserved.
//

#import "Login.h"
#import "ViewController.h"

#import <Parse/Parse.h>

@interface Login ()


- (void)loginUser;
- (void)textInputChanged:(NSNotification *)note;
- (BOOL)shouldEnableDoneButton;

@end

@implementation Login

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    //iniitalize storyboard
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //create trigger events if the text inputs to these prompts are changed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:self.email];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:self.password];
    
    //initiliaze the textfields with prompts
	self.done.enabled = NO;
    self.email.placeholder = @"Email";
    self.password.placeholder = @"Password";
    self.password.secureTextEntry = YES;
    
    //make the view pretty
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    window.tintColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    //star the view by prompting the user to fill out their email
	[self.email becomeFirstResponder];
	[super viewWillAppear:animated];
}

-  (void)dealloc {
    //remove these triggers when cleaning up
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.email];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.password];
}

- (IBAction)done:(id)sender {
    //when the user clicks the done button, resign the keyboard, and start logging the user in
	[self.email resignFirstResponder];
	[self.password resignFirstResponder];
	[self loginUser];
}

- (BOOL)shouldEnableDoneButton {
    //check if the done button should be enabled
	BOOL enableDoneButton = NO;
	if (self.email.text != nil &&
		self.email.text.length > 0 &&
		self.password.text != nil &&
		self.password.text.length > 0) {
		enableDoneButton = YES;
	}
	return enableDoneButton;
}

- (void)textInputChanged:(NSNotification *)note {
    //check if the done button should be enabled
	self.done.enabled = [self shouldEnableDoneButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    //if one of the fields is completed, direct user to next field
	if (textField == self.email) {
		[self.password becomeFirstResponder];
	}
	if (textField == self.password) {
		[self.password resignFirstResponder];
		[self loginUser];
	}
	return YES;
}

- (void)loginUser {
    //get the inputs
	NSString *email = self.email.text;
	NSString *password = self.password.text;
	
    self.done.enabled = NO;

    //Log user in
	[PFUser logInWithUsernameInBackground:email password:password block:^(PFUser *user, NSError *error) {
		if (user) {
            //if successful, take the user to the main view
            [self performSegueWithIdentifier: @"LoginDone" sender: self];
		} else {
            //if failure, show error messages and take the user back
			self.done.enabled = [self shouldEnableDoneButton];
			UIAlertView *alertView = nil;
            if (error == nil) {
				alertView = [[UIAlertView alloc] initWithTitle:@"Couldn’t log in:\nThe username or password were wrong." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
			} else {
				alertView = [[UIAlertView alloc] initWithTitle:[[error userInfo] objectForKey:@"error"] message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
			}
			[alertView show];
			[self.email becomeFirstResponder];
		}
	}];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
