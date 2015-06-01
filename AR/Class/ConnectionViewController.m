//
//  ConnectionViewController.m
//  AR
//
//  Created by Jiyue Wang on 5/26/15.
//  Copyright (c) 2015 Jiyue Wang. All rights reserved.
//

#import "ConnectionViewController.h"
#import "AppDelegate.h"

static NSString *TAG = @"ConnectionViewController";

@interface ConnectionViewController ()

@property (strong, nonatomic) AppDelegate *appDelegate;

@end

@implementation ConnectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.appDelegate.mpcHandler setupPeerWithDisplayName:[UIDevice currentDevice].name];
    [self.appDelegate.mpcHandler setupSession];
    [self.appDelegate.mpcHandler advertiseSelf:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peerChangedStateWithNotification:)
                                                 name:@"AR_DidChangeStateNotification"
                                               object:nil];
    [self.txtPlayerName setDelegate:self];
    
    //search for players
    if (self.appDelegate.mpcHandler.session != nil) {
        [[self.appDelegate mpcHandler] setupBrowser];
        [[[self.appDelegate mpcHandler] browser] setDelegate:self];
        
        [self presentViewController:self.appDelegate.mpcHandler.browser
                           animated:YES
                         completion:nil];
    }
    NSLog(@"%@:view loaded", TAG);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"%@:memory warning", TAG);
    
}

#pragma mark - browser view controller delegate methods
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    [self.appDelegate.mpcHandler.browser dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    [self.appDelegate.mpcHandler.browser dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - text field delegate methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [self.txtPlayerName resignFirstResponder];
    
    if (self.appDelegate.mpcHandler.peerID != nil) {
        [self.appDelegate.mpcHandler.session disconnect];
        
        self.appDelegate.mpcHandler.peerID = nil;
        self.appDelegate.mpcHandler.session = nil;
    }
    
    [self.appDelegate.mpcHandler setupPeerWithDisplayName:self.txtPlayerName.text];
    [self.appDelegate.mpcHandler setupSession];
    [self.appDelegate.mpcHandler advertiseSelf:YES];
    
    return YES;
}

#pragma mark - Actions
- (IBAction)disconnect:(id)sender {
    [self.appDelegate.mpcHandler.session disconnect];
}

- (IBAction)startGame:(id)sender {
    NSLog(@"%@: start game pressed", TAG);
    [self.entryViewDelegate connectionViewControllerStartGame:self];
    
}

- (IBAction)navigateBack:(id)sender {
    [self.entryViewDelegate connectionViewControllerGoBack:self];
    
}

#pragma mark - Notification Handling
- (void)peerChangedStateWithNotification:(NSNotification *)notification {
    // Get the state of the peer.
    int state = [[[notification userInfo] objectForKey:@"state"] intValue];
    
    // We care only for the Connected and the Not Connected states.
    // The Connecting state will be simply ignored.
    if (state != MCSessionStateConnecting) {
        // We'll just display all the connected peers (players) to the text view.
        NSString *allPlayers = @"Other players connected with:\n\n";
        
        for (int i = 0; i < self.appDelegate.mpcHandler.session.connectedPeers.count; i++) {
            NSString *displayName = [[self.appDelegate.mpcHandler.session.connectedPeers objectAtIndex:i] displayName];
            
            allPlayers = [allPlayers stringByAppendingString:@"\n"];
            allPlayers = [allPlayers stringByAppendingString:displayName];
        }
        
        [self.tvPlayerList setText:allPlayers];
    }
}

#pragma mark - alloc/dealloc
- (void)dealloc {
    
    [_btStartGame release];
    [_btDisconnect release];
    [_btBack release];
    [super dealloc];
}
@end
