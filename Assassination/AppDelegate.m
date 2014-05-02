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

@interface AppDelegate () <CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic *transferCharacteristic;
@property (nonatomic, strong) NSMutableArray *centrals;

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:@"ULvRGjhyJKZ5w7bDMdJuGd4rx8J6XJDhlbd0tp4e" clientKey:@"ZGgO4tIqYDDedRtpTjwHl4cWa7M13kpcGmenGIzd"];
    [PFFacebookUtils initializeFacebook];
    if ([PFUser currentUser]) {
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        ViewController *viewController = (ViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"assassinate"];
        [navigationController pushViewController:viewController animated:YES];

	}
	
	[PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    [TestFlight takeOff:@"357c9af8-5e83-4c6a-b33d-76866d3d15fe"];
    if (application.applicationIconBadgeNumber != 0) {
        application.applicationIconBadgeNumber = 0;
        [[PFInstallation currentInstallation] saveInBackground];
    }
    
    [PFImageView class];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    [PFPush storeDeviceToken:newDeviceToken];
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    [currentInstallation saveInBackground];
    [[PFInstallation currentInstallation] saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[FBSession activeSession] handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}



#pragma mark - CBPeripheral delegate methods

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    
    NSLog(@"PeripheralManager powered on.");
    
    self.transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString: CHARACTERISTIC_UUID] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    
    NSString *uuid = [[PFUser currentUser] objectForKey:@"uuid"];
    
    CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:uuid] primary:YES];
    
    transferService.characteristics = @[self.transferCharacteristic];
    
    [self.peripheralManager addService:transferService];
    
    [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:uuid]], CBAdvertisementDataLocalNameKey : @"HikariBeacon" }];
    
    NSLog(@"PeripheralManager is broadcasting (%@).", uuid);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    [_centrals addObject:central];
}



@end
