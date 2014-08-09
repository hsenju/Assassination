//
//  AppDelegate.m
//  Assassination
//
//  Created by Hikari Senju on 4/20/14.
//  Copyright (c) 2014 Hikari Senju. All rights reserved.
//

#import "BLECentralController.h"

@interface BLECentralController ()

@property (nonatomic, strong) NSTimer *readRSSITimer;
@property (nonatomic, strong) NSMutableArray *rssiArray;
@property (nonatomic, assign) int rssiArrayIndex;
@property (nonatomic, strong) NSString* targetuuid;

@end

@implementation BLECentralController

- (id)init {
	self = [super init];
    
	if(self) {
        //initialize the cbcentral manager to start scouting for the uuid of the target and then to connect to it
		self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _rssiArrayIndex = 0;
        _connected = NO;
	}

    
    return self;
}

+ (id)sharedInstance
{
    //initialize the shared instance of this bluetooth low energy central controller
	static BLECentralController *this = nil;
    this = [[BLECentralController alloc] init];
	return this;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    //lookup on parse for the unique identifier of the target. this is the uuid we would be scouting for
    if (central.state == CBCentralManagerStatePoweredOn){
        PFQuery *findtarget = [PFQuery queryWithClassName:@"Targets"];
        [findtarget whereKey:@"assassin" equalTo: [[PFUser currentUser] objectForKey:@"email"]];
        [findtarget getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (error){
            } else {
                PFQuery *finduuid = [PFUser query];
                [finduuid whereKey:@"email" equalTo: [object objectForKey:@"target"]];
                [finduuid getFirstObjectInBackgroundWithBlock:^(PFObject *objectb, NSError *error) {
                    if (error) {
                    } else {
                        self.targetuuid = [objectb objectForKey:@"uuid"];
                        [self findTargets];
                    }}];
            }}];
    }
}

- (void)findTargets;
{
    //start scanning for the unique identifier of the target
    if (self.manager.state == CBCentralManagerStatePoweredOn)
    {
        NSArray *uuidArray = [NSArray arrayWithObjects:[CBUUID UUIDWithString:self.targetuuid], nil];
        NSDictionary *options = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        [self.manager scanForPeripheralsWithServices:uuidArray options:options];
    }
}

#pragma mark - CBCentralManager delegate methods

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    //if we found another phone advertising the uuid that we are looking for, connect to that peripheral
    self.connectedTarget = peripheral;
    [self.manager connectPeripheral:self.connectedTarget options:nil];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //if we are successful in connecting to the peripheral, stop scanning for other peripherals, and see if we can find the service with the unique identifier of the target
    _connected = YES;
    
    [self.manager stopScan];
    peripheral.delegate = self;
    
    [peripheral discoverServices:@[[CBUUID UUIDWithString:self.targetuuid]]];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    //if we are disconnected from the peripheral, reconnect
    id tempDelegate = self.delegate;
    if ([tempDelegate respondsToSelector:@selector(didReceiveNewRSSI:)])
        [self.delegate didReceiveNewRSSI:-100];
    
    _connected = NO;
}

#pragma mark - CBPeripheral delegate methods

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        return;
    }
    
    //once we find the service that we are looking for, look for its dummy characteristic
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:@"00000000-0000-0000-0000-000000000000"]] forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        return;
    }
    
    //after we have found the characteristic, connect to the peripheral so we can start receiving signal strengths from it
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"00000000-0000-0000-0000-000000000000"]]) {
            
            id tempDelegate = self.delegate;
            if ([tempDelegate respondsToSelector:@selector(didConnectToTarget)])
                [self.delegate didConnectToTarget];
            
            [self.connectedTarget setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

- (void)peripheralDidReceiveNewRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    //if we are just initiliazing the array of signal strength, create an array with five copies of the current signal strength
    if (!_rssiArray.count)
        _rssiArray = [[NSMutableArray alloc] initWithArray: @[peripheral.RSSI, peripheral.RSSI, peripheral.RSSI, peripheral.RSSI, peripheral.RSSI]];

    //pop off a signal strength from the array and add the current signal strength to the array. We do this by having a counter to choose the element that we want to remove.
    [_rssiArray replaceObjectAtIndex:_rssiArrayIndex withObject:peripheral.RSSI];
    _rssiArrayIndex ++;
    
    //if our counter in the array is greater than 4, reset it to 0.
    if (_rssiArrayIndex > 4)
        _rssiArrayIndex = 0;
    
    if (self.delegate) {
        //Once we have received a new signal strength indicator, average that strength with the previous strengths to figure out the current signal strength
        id tempDelegate = self.delegate;
        if ([tempDelegate respondsToSelector:@selector(didReceiveNewRSSI:)])
            [self.delegate didReceiveNewRSSI:[self averageSignalStrengths]];
    }
}

- (void)startReceivingSignalStrenght
{
    //receive a signal strength every second
    _readRSSITimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(readPeripheralRSSI) userInfo:nil repeats:YES];
    [_readRSSITimer fire];
}

- (void)disconnectSignalStrength
{
    //stop receiving signal strengths
    [_readRSSITimer invalidate];
    _readRSSITimer = nil;
}

- (void)readPeripheralRSSI
{
    //get the strength signal of the connected peripheral
    [self.connectedTarget readRSSI];
}

- (int)averageSignalStrengths
{
    //average the signal strengths
    int sum = 0;
    
    for (NSNumber *rssi in _rssiArray)
        sum = sum + [rssi intValue];
    
    return (int)sum/5;
}

@end
