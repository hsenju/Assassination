//
//  ViewController.m
//  Assassination
//
//  Created by Hikari Senju on 4/20/14.
//  Copyright (c) 2014 Hikari Senju. All rights reserved.
//

#import "ViewController.h"
#import "MBProgressHUD.h"
#import <Parse/Parse.h>

@interface ViewController () <CoreBluetoothDelegate>{
    NSMutableData *_imagedata;
}
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) CoreBluetoothController *bluetoothController;
@property (weak, nonatomic) IBOutlet UIButton *assassinate;
@property (weak, nonatomic) IBOutlet UILabel *tname;
@property (strong, nonatomic) IBOutlet PFImageView *timage;


@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic *transferCharacteristic;
@property (nonatomic, strong) NSMutableArray *centrals;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.assassinate.layer.borderWidth = 0.0f;
    self.assassinate.layer.cornerRadius = 20;
    self.navigationController.navigationBarHidden = YES;
    self.assassinate.enabled = NO;
    
    PFQuery *findtarget = [PFQuery queryWithClassName:@"Targets"];
    [findtarget whereKey:@"assassin" equalTo: [[PFUser currentUser] objectForKey:@"email"]];
    [findtarget getFirstObjectInBackgroundWithBlock:^(PFObject *target, NSError *error) {
        if (error) {
            //[TestFlight passCheckpoint:@"edit photo error in geo query"];
        } else {
            PFQuery *findtarget = [PFUser query];
            [findtarget whereKey:@"email" equalTo: [target objectForKey:@"target"]];
            [findtarget getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (error) {
                    //[TestFlight passCheckpoint:@"edit photo error in geo query"];
                } else {
                    self.tname.text = [object objectForKey:@"fullname"];
                    
                    self.timage.file =[object objectForKey:@"picture"];
                    [self.timage loadInBackground];
                }}];
        }}];
    
    _bluetoothController = [CoreBluetoothController sharedInstance];
    _bluetoothController.delegate = self;
    /*if (!_bluetoothController.isConnected)
     [_bluetoothController findPeripherals];*/
    
    [_bluetoothController startReadingRSSI];
    
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    _centrals = [NSMutableArray array];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
     UIRemoteNotificationTypeAlert|
     UIRemoteNotificationTypeSound];
    
    [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"user"];
    [[PFInstallation currentInstallation] saveEventually];
    
    if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [PFFacebookUtils linkUser:[PFUser currentUser] permissions:nil block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                FBRequest *request = [FBRequest requestForMe];
                
                // Send request to Facebook
                [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    if (!error) {
                        // result is a dictionary with the user's Facebook data
                        NSDictionary *userData = (NSDictionary *)result;
                        
                        NSString *facebookID = userData[@"id"];
                        NSString *name = userData[@"name"];
                        
                        _imagedata = [[NSMutableData alloc] init];
                        NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
                        NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                              timeoutInterval:2.0f];
                        [NSURLConnection connectionWithRequest:urlRequest delegate:self];
                        // Run network request asynchronously
                        //NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
                        
                        
                        [[PFUser currentUser] setObject:facebookID forKey:@"facebookid"];
                        [[PFUser currentUser] setObject:name forKey:@"fullname"];
                        [[PFUser currentUser] saveInBackground];
                        
                        // Now add the data to the UI elements
                        // ...
                    }
                }];
            }
        }];
    }
    else{
    // Download user's profile picture
        NSURL *profilePictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", [[PFUser currentUser] objectForKey:@"facebookid"]]];
        NSURLRequest *profilePictureURLRequest = [NSURLRequest requestWithURL:profilePictureURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f]; // Facebook profile picture cache policy: Expires in 2 weeks
        [NSURLConnection connectionWithRequest:profilePictureURLRequest delegate:self];
    }
    
    NSLog(@"central");
    
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _imagedata = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_imagedata appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //[PAPUtility processFacebookProfilePictureData:_data];
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

- (void)didUpdateRSSI:(int)RSSI
{
    if (RSSI < 0 && RSSI > -70) {
        [self.assassinate setBackgroundColor:[UIColor redColor]];
        self.assassinate.enabled = YES;
        //_infoLabel.text = [NSString stringWithFormat:@"Immediate"];
        NSLog(@"Really Close");
    }
    else if (RSSI <= -70 && RSSI >= -80) {
        [self.assassinate setBackgroundColor:[UIColor grayColor]];
        self.assassinate.enabled = NO;
        //_infoLabel.text = [NSString stringWithFormat:@"Near"];
        NSLog(@"In the Area");
    }
    else if (RSSI < -80) {
        [self.assassinate setBackgroundColor:[UIColor grayColor]];
        self.assassinate.enabled = NO;
        //_infoLabel.text = [NSString stringWithFormat:@"Far"];
        NSLog(@"Far Away");
    }
    else {
        [self.assassinate setBackgroundColor:[UIColor grayColor]];
        self.assassinate.enabled = NO;
        //_infoLabel.text = [NSString stringWithFormat:@"Unknown"];
        NSLog(@"Unknown");
    }
}


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

- (IBAction)didclick:(id)sender {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view.superview animated:YES];
    self.hud.labelText = NSLocalizedString(@"Assassinating", nil);
    self.hud.dimBackground = YES;
    
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
                                    [_bluetoothController stopReadingRSSI];
                                    [_bluetoothController.manager cancelPeripheralConnection:_bluetoothController.pairedPeripheral];
                                    _bluetoothController = [CoreBluetoothController sharedInstance];
                                    _bluetoothController.delegate = self;
                                    [_bluetoothController startReadingRSSI];
                                    [self.assassinate setBackgroundColor:[UIColor grayColor]];
                                    self.assassinate.enabled = NO;
                                    [MBProgressHUD hideHUDForView:self.view.superview animated:NO];

                                    PFQuery *findtarget = [PFUser query];
                                    [findtarget whereKey:@"email" equalTo: [targettarget objectForKey:@"target"]];
                                    [findtarget getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                        if (error) {
                                            //[TestFlight passCheckpoint:@"edit photo error in geo query"];
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
                
                
                PFQuery *userQuery = [PFUser query];
                [userQuery whereKey:@"uuid" equalTo:[target objectForKey:@"target"]];
                
                // Find devices associated with these users
                PFQuery *pushQuery = [PFInstallation query];
                [pushQuery whereKey:@"user" matchesQuery:userQuery];
                
                // Send push notification to query
                PFPush *push = [[PFPush alloc] init];
                [push setQuery:pushQuery]; // Set our Installation query
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
    // Dispose of any resources that can be recreated.
}

@end
