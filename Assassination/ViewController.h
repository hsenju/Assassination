//
//  ViewController.h
//  Assassination
//
//  Created by Hikari Senju on 4/20/14.
//  Copyright (c) 2014 Hikari Senju. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <FacebookSDK/FacebookSDK.h>
#import "BLECentralController.h"

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *overlay;
@property (weak, nonatomic) IBOutlet UILabel *overlayLabel;

@end
