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
@property (weak, nonatomic) IBOutlet UIImageView *target;


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.assassinate.layer.borderWidth = 0.5f;
    self.assassinate.layer.cornerRadius = 5;
    self.navigationController.navigationBarHidden = YES;
    
    _bluetoothController = [CoreBluetoothController sharedInstance];
    _bluetoothController.delegate = self;
    /*if (!_bluetoothController.isConnected)
     [_bluetoothController findPeripherals];*/
    
    [_bluetoothController startReadingRSSI];
}

#pragma mark - CoreBluetooth delegate methods

- (void)didUpdateRSSI:(int)RSSI
{
    if (RSSI < 0 && RSSI > -50) {
        
        //_infoLabel.text = [NSString stringWithFormat:@"Immediate"];
        NSLog(@"Immediate");
    }
    else if (RSSI <= -50 && RSSI >= -80) {
        
        //_infoLabel.text = [NSString stringWithFormat:@"Near"];
        NSLog(@"Near");
    }
    else if (RSSI < -80) {
        
        //_infoLabel.text = [NSString stringWithFormat:@"Far"];
        NSLog(@"Far");
    }
    else {
        
        //_infoLabel.text = [NSString stringWithFormat:@"Unknown"];
        NSLog(@"Unknown");
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
