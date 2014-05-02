//
//  AppDelegate.m
//  Assassination
//
//  Created by Hikari Senju on 4/20/14.
//  Copyright (c) 2014 Hikari Senju. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <Parse/Parse.h>

@protocol CoreBluetoothDelegate
@optional
- (void)didFindBeacon;
- (void)didConnectToBeacon;
- (void)didDetectInteraction;
- (void)didUpdateRSSI:(int)RSSI;

- (void)didConnectToListener;
@end

@interface CoreBluetoothController : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    __unsafe_unretained id <CoreBluetoothDelegate> _delegate;
}

@property (nonatomic, strong) CBPeripheral *pairedPeripheral;
@property (assign, nonatomic) id <CoreBluetoothDelegate> delegate;
@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, assign) BOOL isConnected;

+ (id)sharedInstance;
- (void)findPeripherals;

- (void)startReadingRSSI;
- (void)stopReadingRSSI;

- (int)averageFromLastRSSI;

@end
