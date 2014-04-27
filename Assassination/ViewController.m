//
//  ViewController.m
//  Assassination
//
//  Created by Hikari Senju on 4/20/14.
//  Copyright (c) 2014 Hikari Senju. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <CoreBluetoothDelegate>
@property (nonatomic, strong) CoreBluetoothController *bluetoothController;
@property (weak, nonatomic) IBOutlet UIButton *assassinate;
@property (weak, nonatomic) IBOutlet UILabel *tname;


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
    [findtarget whereKey:@"assassin" equalTo: [[PFUser currentUser] objectForKey:@"uuid"]];
    [findtarget getFirstObjectInBackgroundWithBlock:^(PFObject *target, NSError *error) {
        if (error) {
            //[TestFlight passCheckpoint:@"edit photo error in geo query"];
        } else {
            PFQuery *findtarget = [PFUser query];
            [findtarget whereKey:@"uuid" equalTo: [target objectForKey:@"target"]];
            [findtarget getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (error) {
                    //[TestFlight passCheckpoint:@"edit photo error in geo query"];
                } else {
                    self.tname.text = [object objectForKey:@"username"];
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
    
    NSLog(@"central");
    
}

#pragma mark - CoreBluetooth delegate methods

- (void)didUpdateRSSI:(int)RSSI
{
    if (RSSI < 0 && RSSI > -70) {
        [self.assassinate setBackgroundColor:[UIColor redColor]];
        self.assassinate.enabled = YES;
        //_infoLabel.text = [NSString stringWithFormat:@"Immediate"];
        NSLog(@"Immediate");
    }
    else if (RSSI <= -70 && RSSI >= -80) {
        [self.assassinate setBackgroundColor:[UIColor grayColor]];
        self.assassinate.enabled = NO;
        //_infoLabel.text = [NSString stringWithFormat:@"Near"];
        NSLog(@"Near");
    }
    else if (RSSI < -80) {
        [self.assassinate setBackgroundColor:[UIColor grayColor]];
        self.assassinate.enabled = NO;
        //_infoLabel.text = [NSString stringWithFormat:@"Far"];
        NSLog(@"Far");
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
    PFQuery *query = [PFQuery queryWithClassName:@"Targets"];
    [query whereKey:@"assassin" equalTo:[[PFUser currentUser] objectForKey:@"uuid"]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *targets, NSError *error) {
        if (!error) {
            for (PFObject *target in targets) {
                PFQuery *query = [PFQuery queryWithClassName:@"Targets"];
                [query whereKey:@"assassin" equalTo:[target objectForKey:@"target"]];
                [query findObjectsInBackgroundWithBlock:^(NSArray *targettargets, NSError *error) {
                    if (!error) {
                        for (PFObject *targettarget in targettargets) {
                            PFObject *newtarget = [PFObject objectWithClassName:@"Targets"];
                            [newtarget setObject:[[PFUser currentUser] objectForKey:@"uuid"] forKey:@"assassin"];
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
                                    

                                    PFQuery *findtarget = [PFUser query];
                                    [findtarget whereKey:@"uuid" equalTo: [targettarget objectForKey:@"target"]];
                                    [findtarget getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                                        if (error) {
                                            //[TestFlight passCheckpoint:@"edit photo error in geo query"];
                                        } else {
                                            self.tname.text = [object objectForKey:@"username"];
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
