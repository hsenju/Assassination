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
        //initialize the cbcentral manager to start scouting for the uuid of the target
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
    //if we found another phone advertising using bluetooth low energy, connect to that peripheral
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
    
    // once we find the service that we are looking for, look for its dummy characteristic
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:@"00000000-0000-0000-0000-000000000000"]] forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        return;
    }
    
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
    if (!_rssiArray.count)
        _rssiArray = [[NSMutableArray alloc] initWithArray: @[peripheral.RSSI, peripheral.RSSI, peripheral.RSSI, peripheral.RSSI, peripheral.RSSI]];

    [_rssiArray replaceObjectAtIndex:_rssiArrayIndex withObject:peripheral.RSSI];
    _rssiArrayIndex ++;
    
    if (_rssiArrayIndex > 4)
        _rssiArrayIndex = 0;
    
    if (self.delegate) {
       
        id tempDelegate = self.delegate;
        if ([tempDelegate respondsToSelector:@selector(didReceiveNewRSSI:)])
            [self.delegate didReceiveNewRSSI:[self averageSignalStrengths]];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
}

- (void)startReceivingSignalStrenght
{
    _readRSSITimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(readPeripheralRSSI) userInfo:nil repeats:YES];
    [_readRSSITimer fire];
}

- (void)disconnectSignalStrength
{
    [_readRSSITimer invalidate];
    _readRSSITimer = nil;
}

- (void)readPeripheralRSSI
{
    [self.connectedTarget readRSSI];
}

- (int)averageSignalStrengths
{
    int sum = 0;
    
    for (NSNumber *rssi in _rssiArray)
        sum = sum + [rssi intValue];
    
    return (int)sum/5;
}

@end
