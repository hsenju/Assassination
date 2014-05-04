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

@protocol BLECenrtalDelegate
@optional
- (void)didFindTarget;
- (void)didConnectToTarget;
//- (void)didDetectInteraction;
- (void)didReceiveNewRSSI:(int)RSSI;

//- (void)didConnectToListener;
@end

@interface BLECentralController : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    __unsafe_unretained id <BLECenrtalDelegate> _delegate;
}

@property (nonatomic, strong) CBPeripheral *connectedTarget;
@property (assign, nonatomic) id <BLECenrtalDelegate> delegate;
@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, assign) BOOL connected;

+ (id)sharedInstance;
- (void)findTargets;

- (void)startReceivingSignalStrenght;
- (void)disconnectSignalStrength;

- (int)averageSignalStrengths;

@end
