//
//  CentralController.h
//  mac_bleTest
//
//  Created by Abue on 2015/02/10.
//  Copyright (c) 2015年 azurelab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>

enum {
    AzufierStateInit = 0,	// State unknown, update imminent.
    AzufierStatePoweredOff,  // Bluetooth is currently powered off.
    AzufierStatePoweredOn,
    AzufierStateUnknown,     // State unknown, update imminent.
    AzufierStateResetting,   // The connection with the system service was momentarily lost, update imminent.
    AzufierStateUnsupported,	// Something wrong, using machine not support BTLE or not power on.
    AzufierStateUnauthorized,// The app is not authorized to use Bluetooth Low Energy.
    AzufierStateDisconnected,//disconnect
    AzufierStateIdle,        // Bluetooth is currently powered on and available to use.
    AzufierStateSearching,	// The Azufier is searching to a device.
    AzufierStateConnecting,	// the Azufier is connecting to a device.
    AzufierStateConnected,	// The Azufier is connected with a device.
    AzufierStateBonded,	    // The Azufier is bondeded (and the connection is encypted) with a device.
};
typedef NSInteger AzufierState;

@protocol AzufierDelegate <NSObject>

-(void)didAzufierReceivedData:(NSString *)data uuid:(CBUUID*)uuid;
-(void)didAzufierUpdateState:(AzufierState)state;

@end

@interface AzufierController : NSObject
{
    id<AzufierDelegate> delegate;
}

@property (retain, nonatomic) id <AzufierDelegate> delegate;

- (void) initCentralController;
- (BOOL) sendValue:(NSString *)str;
- (void) disconnectPeripheral;
- (void) scanNewDevice;
- (BOOL) getCentralState;
- (NSString*)getBondedDevName;

@end
