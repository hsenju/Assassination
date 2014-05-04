//
//  Register.m
//  Assassination
//
//  Created by Hikari Senju on 4/21/14.
//  Copyright (c) 2014 Hikari Senju. All rights reserved.
//

#import "Register.h"
#import "ViewController.h"
#import <Parse/Parse.h>

@interface Register ()

- (void)registerUser;
- (void)textInputChanged:(NSNotification *)note;
- (BOOL)shouldEnableDoneButton;

@end

@implementation Register

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    //initialize storyboard
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    //trigger the "textInputChanged" event if any of the textfields change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:self.email];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:self.password];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:self.passwordconfirm];
    
    //initialize the textfields with prompts.
    self.email.placeholder = @"Email";
    self.password.placeholder = @"Password";
    self.passwordconfirm.placeholder = @"Password Again";
    self.password.secureTextEntry = YES;
    self.passwordconfirm.secureTextEntry = YES;
    self.done.enabled = NO;
    
    //other things to make the view pretty
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    window.tintColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    //initialize the view by having the user prompted to fill out the email field
	[self.email becomeFirstResponder];
	[super viewWillAppear:animated];
}

- (void)dealloc {
    //remove the triggered events when cleaning up
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.email];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.password];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.passwordconfirm];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    //if user fills out one field, send them to the next field
	if (textField == self.email) {
		[self.password becomeFirstResponder];
	}
	if (textField == self.password) {
		[self.passwordconfirm becomeFirstResponder];
        [self registerUser];
	}
    
	return YES;
}

#pragma mark - ()

- (BOOL)shouldEnableDoneButton {
    // don't enable the done button unless all the fields are filled
	BOOL enableDoneButton = NO;
	if (self.email.text != nil &&
		self.email.text.length > 0 &&
		self.password.text != nil &&
		self.password.text.length > 0 &&
		self.passwordconfirm.text != nil &&
		self.passwordconfirm.text.length > 0 &&
        [self.password.text compare:self.passwordconfirm.text] == NSOrderedSame) {
		enableDoneButton = YES;
	}
	return enableDoneButton;
}

- (void)textInputChanged:(NSNotification *)note {
    //whenever the user's inputs change, check if the done button should be enabled
	self.done.enabled = [self shouldEnableDoneButton];
}

- (IBAction)done:(id)sender {
    //when the done button is pressed, start processing the entries to register the user
    [self.email resignFirstResponder];
	[self.password resignFirstResponder];
	[self.passwordconfirm resignFirstResponder];
    [self registerUser];
}

- (void)registerUser {
    
    //get the user entries
	NSString *name = self.email.text;
	NSString *password = self.password.text;
	NSString *email = self.email.text;
    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    //initialize and save the user with the corresponding characterisitcs to parse
	PFUser *user = [PFUser user];
	user.username = name;
	user.password = password;
    user.email = email;
    [user setObject:uuid forKey:@"uuid"];
	[user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
		if (error) {
            //if error in saving, show error alert
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[[error userInfo] objectForKey:@"error"] message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
			[alertView show];
			self.done.enabled = [self shouldEnableDoneButton];
			[self.email becomeFirstResponder];
			return;
		}
        
        //if there is not error, proceed to main view
        [self performSegueWithIdentifier: @"RegisterDone" sender: self];
        
	}];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
