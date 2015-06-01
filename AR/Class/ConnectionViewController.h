//
//  ConnectionViewController.h
//  AR
//
//  Created by Jiyue Wang on 5/26/15.
//  Copyright (c) 2015 Jiyue Wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@class ConnectionViewController;
@protocol ConnectionViewControllerDelegate <NSObject>
- (void)connectionViewControllerStartGame:(ConnectionViewController *)conViewController;
- (void)connectionViewControllerGoBack:(ConnectionViewController *)conViewController;
@end

@interface ConnectionViewController : UIViewController <MCBrowserViewControllerDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *txtPlayerName;
@property (strong, nonatomic) IBOutlet UITextView *tvPlayerList;
@property (retain, nonatomic) IBOutlet UIButton *btBack;
@property (retain, nonatomic) IBOutlet UIButton *btStartGame;
@property (retain, nonatomic) IBOutlet UIButton *btDisconnect;

@property (strong, nonatomic) id<ConnectionViewControllerDelegate> entryViewDelegate;

- (IBAction)disconnect:(id)sender;
- (IBAction)startGame:(id)sender;
- (IBAction)navigateBack:(id)sender;

@end
