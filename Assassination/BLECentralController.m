//
//  AppDelegate.m
//  Assassination
//
//  Created by Hikari Senju on 4/20/14.
//  Copyright (c) 2014 Hikari Senju. All rights reserved.
//

#import "BLECentralController.h"
#import "BluetoothServices.h"

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
        
		self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _rssiArrayIndex = 0;
        _isConnected = NO;
	}

    
    return self;
}

+ (id)sharedInstance
{
	static BLECentralController *this = nil;
    
    this = [[BLECentralController alloc] init];
    
	return this;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{    
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
    NSLog(@"%@", peripheral);
        
    self.pairedPeripheral = peripheral;
    [self.manager connectPeripheral:self.pairedPeripheral options:nil];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    _isConnected = YES;
    
    [self.manager stopScan];
    peripheral.delegate = self;
    
    // Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:self.targetuuid]]];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    id tempDelegate = self.delegate;
    if ([tempDelegate respondsToSelector:@selector(didUpdateRSSI:)])
        [self.delegate didUpdateRSSI:-100];
    
    _isConnected = NO;
}

#pragma mark - CBPeripheral delegate methods

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        return;
    }
        
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CHARACTERISTIC_UUID]] forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]]) {
            
            id tempDelegate = self.delegate;
            if ([tempDelegate respondsToSelector:@selector(didConnectToTarget)])
                [self.delegate didConnectToTarget];
            
            [self.pairedPeripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error
{
    // int RSSIvalue = [peripheral.RSSI intValue];
    
    if (!_rssiArray.count)
        _rssiArray = [[NSMutableArray alloc] initWithArray: @[peripheral.RSSI, peripheral.RSSI, peripheral.RSSI, peripheral.RSSI, peripheral.RSSI]];

    [_rssiArray replaceObjectAtIndex:_rssiArrayIndex withObject:peripheral.RSSI];
    _rssiArrayIndex ++;
    
    if (_rssiArrayIndex > 4)
        _rssiArrayIndex = 0;
    
    if (self.delegate) {
       
        id tempDelegate = self.delegate;
        if ([tempDelegate respondsToSelector:@selector(didUpdateRSSI:)])
            [self.delegate didUpdateRSSI:[self averageFromLastRSSI]];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    id tempDelegate = self.delegate;
    if ([tempDelegate respondsToSelector:@selector(didDetectInteraction)])
        [self.delegate didDetectInteraction];
}

- (void)startReadingRSSI
{
    _readRSSITimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(readPeripheralRSSI) userInfo:nil repeats:YES];
    [_readRSSITimer fire];
}

- (void)stopReadingRSSI
{
    [_readRSSITimer invalidate];
    _readRSSITimer = nil;
}

- (void)readPeripheralRSSI
{
    [self.pairedPeripheral readRSSI];
}

- (int)averageFromLastRSSI
{
    int sum = 0;
    
    for (NSNumber *rssi in _rssiArray)
        sum = sum + [rssi intValue];
    
    return (int)sum/5;
}

@end