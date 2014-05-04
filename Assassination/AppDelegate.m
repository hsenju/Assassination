//
//  AppDelegate.m
//  Assassination
//
//  Created by Hikari Senju on 4/20/14.
//  Copyright (c) 2014 Hikari Senju. All rights reserved.
//
#import <Parse/Parse.h>
#import "TestFlight.h"
#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Setting up parse (a backend as a service) and facebook
    [Parse setApplicationId:@"ULvRGjhyJKZ5w7bDMdJuGd4rx8J6XJDhlbd0tp4e" clientKey:@"ZGgO4tIqYDDedRtpTjwHl4cWa7M13kpcGmenGIzd"];
    [PFFacebookUtils initializeFacebook];
    
    //if user already logged in, redirect to main page
    if ([PFUser currentUser]) {
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        ViewController *viewController = (ViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"assassinate"];
        [navigationController pushViewController:viewController animated:YES];

	}
	
    //setup testflight
    [TestFlight takeOff:@"357c9af8-5e83-4c6a-b33d-76866d3d15fe"];

    //initialize the pfimage class for storyboard
    [PFImageView class];
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    //register phone for push notifications
    [PFPush storeDeviceToken:newDeviceToken];
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    [currentInstallation saveInBackground];
    [[PFInstallation currentInstallation] saveInBackground];
}

#pragma mark - CBPeripheral delegate methods

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    //if we receive a remote notification,
    [PFPush handlePush:userInfo];
}

@end
