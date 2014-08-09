//
//  ViewController.m
//  Assassination
//
//  Created by Hikari Senju on 4/20/14.
//  Copyright (c) 2014 Hikari Senju. All rights reserved.
//

#import "ViewController.h"
#import <Parse/Parse.h>
#import "UIImage+ImageEffects.h"

@interface ViewController () <BLECenrtalDelegate>{
    NSMutableData *_imagedata;
}
@property (nonatomic, strong) BLECentralController *bluetoothController;
@property (weak, nonatomic) IBOutlet UIButton *assassinate;
@property (weak, nonatomic) IBOutlet UILabel *tname;
@property (strong, nonatomic) IBOutlet PFImageView *timage;


@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic *mutableCharacteristic;
@property (nonatomic, strong) NSMutableArray *centrals;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //make assassinate button rounded
    self.assassinate.layer.borderWidth = 0.0f;
    self.assassinate.layer.cornerRadius = 20;
    self.navigationController.navigationBarHidden = YES;
    self.assassinate.enabled = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshView:) name:@"refreshView" object:nil];
    
    //find the name and the image of the target and display it
    PFQuery *findtarget = [PFQuery queryWithClassName:@"Targets"];
    [findtarget whereKey:@"assassin" equalTo: [[PFUser currentUser] objectForKey:@"email"]];
    [findtarget getFirstObjectInBackgroundWithBlock:^(PFObject *target, NSError *error) {
        if (!error){
            PFQuery *findtarget = [PFUser query];
            [findtarget whereKey:@"email" equalTo: [target objectForKey:@"target"]];
            [findtarget getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (!error) {
                    self.overlay.hidden = TRUE;
                    self.tname.text = [object objectForKey:@"fullname"];
                    self.timage.file =[object objectForKey:@"picture"];
                    [self.timage loadInBackground];
                }}];
        }}];
   
    //initialize bluetooth to start scouting for the uuid of the target
    _bluetoothController = [BLECentralController sharedInstance];
    _bluetoothController.delegate = self;
    [_bluetoothController startReceivingSignalStrenght];
    
    //emit peripheral signals with its unique id
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    _centrals = [NSMutableArray array];
    
    //initialize heartbeat
    NSTimer *heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(heartbeat) userInfo:nil repeats:YES];
    [heartbeatTimer fire];
    
    //initialize to receive push notification
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
     UIRemoteNotificationTypeAlert|
     UIRemoteNotificationTypeSound];
    
    //if the user hasn't connected their account to facebook, do so. Get the user's facebook id, name and profile picture and save it to parse.
    [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"user"];
    [[PFInstallation currentInstallation] saveEventually];
    if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [PFFacebookUtils linkUser:[PFUser currentUser] permissions:nil block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                
                FBRequest *request = [FBRequest requestForMe];
                [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    if (!error) {
                        NSDictionary *userData = (NSDictionary *)result;
                        NSString *facebookID = userData[@"id"];
                        NSString *name = userData[@"name"];
                        _imagedata = [[NSMutableData alloc] init];
                        NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
                        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                              timeoutInterval:2.0f];
                        [NSURLConnection connectionWithRequest:urlRequest delegate:self];
                        [[PFUser currentUser] setObject:facebookID forKey:@"facebookid"];
                        [[PFUser currentUser] setObject:name forKey:@"fullname"];
                        [[PFUser currentUser] saveInBackground];
                    }
                }];
            }
        }];
    }
    else{
        //if the user has already connected to facebook, download their profile picture because they might have changed it.
        NSURL *profilePictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", [[PFUser currentUser] objectForKey:@"facebookid"]]];
        NSURLRequest *profilePictureURLRequest = [NSURLRequest requestWithURL:profilePictureURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f];
        [NSURLConnection connectionWithRequest:profilePictureURLRequest delegate:self];
    }
}

-(void)refreshView:(NSNotification *) notification {
    //if the assassination is successful, disconnect from the current peripheral and start scouting for the uuid of the target's target
    [_bluetoothController disconnectSignalStrength];
    [_bluetoothController.manager cancelPeripheralConnection:_bluetoothController.connectedTarget];
    _bluetoothController = [BLECentralController sharedInstance];
    _bluetoothController.delegate = self;
    [_bluetoothController startReceivingSignalStrenght];
    
    //upload the new target's image and name
    PFQuery *findtarget = [PFQuery queryWithClassName:@"Targets"];
    [findtarget whereKey:@"assassin" equalTo: [[PFUser currentUser] objectForKey:@"email"]];
    [findtarget getFirstObjectInBackgroundWithBlock:^(PFObject *target, NSError *error) {
        if (!error){
            PFQuery *findtarget = [PFUser query];
            [findtarget whereKey:@"email" equalTo: [target objectForKey:@"target"]];
            [findtarget getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (!error) {
                    self.overlay.hidden = TRUE;
                    self.tname.text = [object objectForKey:@"fullname"];
                    self.timage.file =[object objectForKey:@"picture"];
                    [self.timage loadInBackground];
                }}];
        }}];
}

- (void)heartbeat
{
    //get the strength signal of the connected peripheral
    [[PFUser currentUser] setObject:[[NSDate alloc] init] forKey:@"currentTime"];
    [[PFUser currentUser] saveInBackground];
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // receive image data from facebook
    _imagedata = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // append the image data from facebook to our current version of the image data
    [_imagedata appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // once the facebook profile image has finished loading, save the image to parse.
    UIImage *image = [UIImage imageWithData:_imagedata];
    NSData *mediumImageData = UIImageJPEGRepresentation(image, 0.5);
    PFFile *fileMediumImage = [PFFile fileWithData:mediumImageData];
    [fileMediumImage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [[PFUser currentUser] setObject:fileMediumImage forKey:@"picture"];
            [[PFUser currentUser] saveInBackground];
        }
    }];
}

#pragma mark - CoreBluetooth delegate methods

- (void)didReceiveNewRSSI:(int)RSSI
{
    // if the remote signal strength indicator is strong, allow the player to assassinated the target, else do not
    if (RSSI < 0 && RSSI > -70) {
        [self.assassinate setBackgroundColor:[UIColor redColor]];
        self.assassinate.enabled = YES;
    }
    else {
        [self.assassinate setBackgroundColor:[UIColor grayColor]];
        self.assassinate.enabled = NO;
    }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    //Turn phone into iBeacon. From this point, until the phone is shut down, the phone will be emitting bluetooth low energy signals in the background
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    
    //initialise the characteristic of the service that we will be adding. In this case, our characteristic would be the simple 00000000-0000-0000-0000-000000000000
    self.mutableCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:@"00000000-0000-0000-0000-000000000000"] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    
    //get unique identifier for the current player
    NSString *uuid = [[PFUser currentUser] objectForKey:@"uuid"];
    
    // Here we are adding that unique identifier to the array of Services that the phone would be advertising
    CBMutableService *addedService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:uuid] primary:YES];
    addedService.characteristics = @[self.mutableCharacteristic];
    [self.peripheralManager addService:addedService];
    [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:uuid]], CBAdvertisementDataLocalNameKey : @"HikariBeacon" }];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    //If we find a central that is looking for our peripheral, add that central to our array of centrals that we are currently connected to
    [_centrals addObject:central];
}

- (IBAction)didclick:(id)sender {
    //if the user clicks assassinate, remove the current assassin-target entry from the database, and create a new on with the current player and the target's target
    PFQuery *query = [PFQuery queryWithClassName:@"Targets"];
    [query whereKey:@"assassin" equalTo:[[PFUser currentUser] objectForKey:@"email"]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *targets, NSError *error) {
        if (!error) {
            for (PFObject *target in targets) {
                PFQuery *query = [PFQuery queryWithClassName:@"Targets"];
                [query whereKey:@"assassin" equalTo:[target objectForKey:@"target"]];
                [query findObjectsInBackgroundWithBlock:^(NSArray *targettargets, NSError *error) {
                    if (!error) {
                        for (PFObject *targettarget in targettargets) {
                            PFObject *newtarget = [PFObject objectWithClassName:@"Targets"];
                            [newtarget setObject:[[PFUser currentUser] objectForKey:@"email"] forKey:@"assassin"];
                            [newtarget setObject:[targettarget objectForKey:@"target"] forKey:@"target"];
                            [newtarget saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                if (succeeded) {
                                    //if the assassination is successful, disconnect from the current peripheral and start scouting for the uuid of the target's target
                                    [_bluetoothController disconnectSignalStrength];
                                    [_bluetoothController.manager cancelPeripheralConnection:_bluetoothController.connectedTarget];
                                    _bluetoothController = [BLECentralController sharedInstance];
                                    _bluetoothController.delegate = self;
                                    [_bluetoothController startReceivingSignalStrenght];
                                    
                                    //disenable the assassinate button
                                    [self.assassinate setBackgroundColor:[UIColor grayColor]];
                                    self.assassinate.enabled = NO;

                                    //upload the new target's image and name
                                    PFQuery *findtarget = [PFUser query];
                                    [findtarget whereKey:@"email" equalTo: [targettarget objectForKey:@"target"]];
                                    [findtarget getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                        if (error) {
                                        } else {
                                            self.tname.text = [object objectForKey:@"fullname"];
                                            self.timage.file =[object objectForKey:@"picture"];
                                            [self.timage loadInBackground];
                                        }}];
                                }
                            }];
                            [targettarget deleteEventually];
                        }
                    }
                }];
                
                //send a push notification to the target, notifying them that they have been killed
                PFQuery *userQuery = [PFUser query];
                [userQuery whereKey:@"uuid" equalTo:[target objectForKey:@"target"]];
                PFQuery *pushQuery = [PFInstallation query];
                [pushQuery whereKey:@"user" matchesQuery:userQuery];
                PFPush *push = [[PFPush alloc] init];
                [push setQuery:pushQuery];
                [push setMessage:@"You were assassinated. Good Game."];
                [push sendPushInBackground];
                [target deleteEventually];
            }
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
