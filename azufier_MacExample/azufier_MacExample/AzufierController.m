//
//  CentralController.m
//  mac_bleTest
//
//  Created by Abue on 2015/02/10.
//  Copyright (c) 2015年 azurelab. All rights reserved.
//

#import "AzufierController.h"
#import <IOBluetooth/IOBluetooth.h>

#define SERVICE_UUID @"C14D2C0A-401F-B7A9-841F-E2E93B80F631"
#define CHARACTERISTIC_UUID @"81EB77BD-89B8-4494-8A09-7F83D986DDC7"

@interface AzufierController() <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager      *ccmCentralManager;
@property (strong, nonatomic) CBPeripheral          *prpDiscovered;
@property (strong, nonatomic) CBCharacteristic      *chrDiscoveredChacteristic;
@property (strong, nonatomic) NSData                *mdtSendValue;
@property (nonatomic) AzufierState                  stateNow;
@property (nonatomic) BOOL                          isConnected;
@property (nonatomic) BOOL                          isReadCharFound;
@property (nonatomic) BOOL                          isWriteCharFound;


@end
@implementation AzufierController

@synthesize delegate;
- (void) initCentralController
{
    // CentralManagerの初期化.
    _ccmCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    _mdtSendValue = [[NSMutableData alloc]init];
    _isConnected = NO;
    _isReadCharFound = NO;
    _isWriteCharFound = NO;
    
    
    [self setAzufierState:AzufierStateInit];
    
}
- (BOOL)sendValue:(NSString *)str
{
    @try {
        
        if(_isConnected){
            _mdtSendValue = (NSMutableData *)[[NSString stringWithFormat:@"%@", str] dataUsingEncoding:NSUTF8StringEncoding];
            NSData *valData;
            NSString* sendDataStr = @"asd";
            valData = [NSData dataWithBytes:(void*)[sendDataStr UTF8String] length:sendDataStr.length];
            [_prpDiscovered writeValue:valData forCharacteristic:_chrDiscoveredChacteristic type:CBCharacteristicWriteWithoutResponse];

            return true;
        }else{
            return false;
        }
    }
    @catch (NSException *exception) {
        return false;
    }
}

- (BOOL) getCentralState
{
    return _isConnected;
}

- (void) disconnectPeripheral
{
    if (_prpDiscovered != nil) {
        [_ccmCentralManager cancelPeripheralConnection:_prpDiscovered];
    }
}

- (NSString*)getBondedDevName
{
    return _prpDiscovered.name;
}

#pragma mark CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // BluetoothがOffならリターン.
    switch(central.state){
            case CBCentralManagerStatePoweredOff:
            [self setAzufierState:AzufierStatePoweredOff];
            break;
            
            case CBCentralManagerStatePoweredOn:
            [self setAzufierState:AzufierStatePoweredOn];
            break;
            
            case CBCentralManagerStateResetting:
            [self setAzufierState:AzufierStatePoweredOn];
            break;
            
            case CBCentralManagerStateUnauthorized:
            [self setAzufierState:AzufierStateUnauthorized];
            break;
            
            case CBCentralManagerStateUnknown:
            [self setAzufierState:AzufierStateUnknown];
            break;
            
            case CBCentralManagerStateUnsupported:
            [self setAzufierState:AzufierStateUnsupported];
            break;
            
            default:
            break;
            
    }
    if (central.state != CBCentralManagerStatePoweredOn)
    {
        return;
    }
}
- (void) scanNewDevice
{
    [_ccmCentralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]
                                               options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @NO}];
    
    [self setAzufierState:AzufierStateSearching];

}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (peripheral != _prpDiscovered)
    {
        _prpDiscovered = peripheral;
        
        [_ccmCentralManager connectPeripheral:peripheral options:nil];
        [self setAzufierState:AzufierStateConnecting];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [_ccmCentralManager stopScan];
    _prpDiscovered = peripheral;
    peripheral.delegate = self;
    
    [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"Service Error: %@", [error localizedDescription]);
        return;
    }
    
    
    [self setAzufierState:AzufierStateConnected];
    
    for (CBService *service in peripheral.services)
    {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Characteristics Error: %@", [error localizedDescription]);
        return;
    }
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        _isConnected = YES;
        int val = [characteristic properties];
        
        NSString* foundUUID = [NSString stringWithFormat:@"%@",[characteristic.UUID UUIDString]];
        
        if ([foundUUID isEqual:CHARACTERISTIC_UUID] && (val == 0x12)) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            _isReadCharFound = YES;
        }else if ([foundUUID isEqual:CHARACTERISTIC_UUID] && (val == 0x4)){
            _chrDiscoveredChacteristic = characteristic;
            _isWriteCharFound = YES;
        }
        
        if(_isWriteCharFound && _isReadCharFound && self.stateNow != AzufierStateBonded){
            [self setAzufierState:AzufierStateBonded];
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Set Notift Value Error: %@ %@", [error description], characteristic.UUID);
    }else{
        NSLog(@"set notify success at %@  %ld",characteristic.UUID, [characteristic properties]);
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"UpdateValue Error: %@ ,%@", [error description],characteristic.UUID);
        return;
    }
    NSString* value = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    if ([delegate respondsToSelector:@selector(didAzufierReceivedData:uuid:)]) {
        [delegate didAzufierReceivedData:value uuid:characteristic.UUID];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    _prpDiscovered = nil;
    _isConnected = NO;
    _chrDiscoveredChacteristic = nil;
    _isReadCharFound = NO;
    _isWriteCharFound = NO;
    
    [self setAzufierState:AzufierStateDisconnected];
}

-(void)didAzufierReceivedData:(NSString *)data uuid:(CBUUID *)uuid{
    
}

-(void)setAzufierState:(AzufierState)state
{
    if ([delegate respondsToSelector:@selector(didAzufierUpdateState:)]) {
        [delegate didAzufierUpdateState:state];
        self.stateNow = state;
    }
}
@end
