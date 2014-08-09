//
//  Welcome.m
//  Assassination
//
//  Created by Hikari Senju on 4/21/14.
//  Copyright (c) 2014 Hikari Senju. All rights reserved.
//

#import "Welcome.h"
#import "Login.h"
#import "Register.h"
#import "ViewController.h"


@interface Welcome ()

@end

@implementation Welcome

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
    //make the view pretty
    self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Navigation
@end
