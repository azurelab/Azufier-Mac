//
//  ViewController.m
//  azufier_MacExample
//
//  Created by Abue on 2015/10/15.
//  Copyright (c) 2015年 azurelab. All rights reserved.
//

#import "ViewController.h"

@interface ViewController()
{
    NSAppleScript *key;
}


@property (strong) IBOutlet NSTextField *deviceStateLabel;
@property (strong, nonatomic) AzufierController     *azufier;
- (IBAction)upBtnAction:(id)sender;
- (IBAction)downBtnAction:(id)sender;
- (IBAction)leftBtnAction:(id)sender;
- (IBAction)rightBtnAction:(id)sender;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    // Initallize iGate
    _azufier = [[AzufierController alloc] init];
    [_azufier initCentralController];
    _azufier.delegate = self;
    
    [_azufier scanNewDevice];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

-(void) showDesktop{
    
    NSDictionary*   errors;
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
                                   @"\
                                   tell application \"System Events\"\n\
                                   key code 125 using {control down}\n\
                                   end tell"];
    [scriptObject executeAndReturnError:&errors];
}

-(void) openMissionControl{
    
    NSDictionary*   errors;
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
                                   @"\
                                   tell application \"System Events\"\n\
                                   key code 126 using {control down}\n\
                                   end tell"];
    [scriptObject executeAndReturnError:&errors];
}

-(void) swipeRightSpace{
    
    NSDictionary*   errors;
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
                                   @"\
                                   tell application \"System Events\"\n\
                                   key code 124 using {control down}\n\
                                   end tell"];
    [scriptObject executeAndReturnError:&errors];
}

-(void) swipeLeftSpace{
    
    NSDictionary*   errors;
    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:
                                   @"\
                                   tell application \"System Events\"\n\
                                   key code 123 using {control down}\n\
                                   end tell"];
    [scriptObject executeAndReturnError:&errors];
}


-(void)didAzufierReceivedData:(NSString *)data uuid:(CBUUID *)uuid{
    NSLog(@"%@, %@",data,[uuid UUIDString]);
    
    if([data isEqualToString:@"Left"]){
        [self swipeLeftSpace];
    }else if([data isEqualToString:@"Right"]){
        [self swipeRightSpace];
    }else if([data isEqualToString:@"Up"]){
        [self openMissionControl];
    }else if([data isEqualToString:@"Down"]){
        [self showDesktop];
    }
}

-(void)didAzufierUpdateState:(AzufierState)state{
    switch (state) {
            
        case AzufierStatePoweredOff:
            NSLog(@"Bluetooth Power off");
            [self.deviceStateLabel setStringValue:@"Bluetooth Power off"];
            break;
            
        case AzufierStateSearching:
            NSLog(@"Searching..");
            [self.deviceStateLabel setStringValue:@"Searching"];
            break;
            
        case AzufierStateConnecting:
            NSLog(@"Connecting..");
            [self.deviceStateLabel setStringValue:@"Connecting"];
            break;
            
        case AzufierStateConnected:
            NSLog(@"Connected..");
            [self.deviceStateLabel setStringValue:@"Connected"];
            break;
            
        case AzufierStateBonded:
            NSLog(@"Bonded %@",[_azufier getBondedDevName]);
            [self.deviceStateLabel setStringValue:[NSString stringWithFormat:@"Bonded %@",[_azufier getBondedDevName]]];
            break;
            
        case AzufierStateDisconnected:
            NSLog(@"Disconnected..");
            [self.deviceStateLabel setStringValue:@"Disconnected"];

            break;
            
        default:
            break;
    }
}
- (IBAction)upBtnAction:(id)sender {
    [self openMissionControl];
}

- (IBAction)downBtnAction:(id)sender {
    [self showDesktop];
}

- (IBAction)leftBtnAction:(id)sender {
    [self swipeLeftSpace];
}

- (IBAction)rightBtnAction:(id)sender {
    [self swipeRightSpace];
}
@end
