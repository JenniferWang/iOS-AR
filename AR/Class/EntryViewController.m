//
//  EntryViewController.m
//  AR
//
//  Created by Jiyue Wang on 5/16/15.
//  Copyright (c) 2015 Jiyue Wang. All rights reserved.
//

#import "EntryViewController.h"
#import "GameViewController.h"
#import "ConnectionViewController.h"

static NSString *TAG = @"EntryViewController";

@interface EntryViewController ()<ConnectionViewControllerDelegate> {
    
    GameViewController *gameViewController;
    ConnectionViewController *connectionViewController;
}

@end

@implementation EntryViewController

#pragma mark protocol

- (void)dealloc {
    
    NSLog(@"%@: deallocating...", TAG);
    [gameViewController release];
    [connectionViewController release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    gameViewController = [[GameViewController alloc] initWithNibName:nil bundle:nil];
    NSLog(@"%@: finish view loading", TAG);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark function

- (IBAction)didButtomPressed: (id)sender {
    
    NSLog(@"%@:Button pressed: %@", TAG, [sender currentTitle]);
    if ([[sender currentTitle] isEqualToString: @"Single Mode"]) {
        NSLog(@"%@: start single mode", TAG);
        [self showViewController: gameViewController];
        
    } else if ([[sender currentTitle] isEqualToString: @"Multi Mode"]) {
        NSLog(@"%@: start multi mode", TAG);
        connectionViewController = [[ConnectionViewController alloc] initWithNibName:@"ConnectionViewController" bundle:nil];
        connectionViewController.entryViewDelegate = self;
        [self showViewController:connectionViewController];
    }
    
}

- (void)showViewController:(UIViewController *)vc {
    
    [self addChildViewController:vc];
    [self.view addSubview:vc.view];
    [vc didMoveToParentViewController:self];
    
    vc.view.frame = self.view.bounds;

}

- (void)hideViewController:(UIViewController *)vc {
    
    [vc willMoveToParentViewController:nil];
    [vc removeFromParentViewController];
    
    [vc.view removeFromSuperview];
    
}

#pragma mark - connection delegate 
- (void)connectionViewControllerGoBack:(ConnectionViewController *)conViewController {
    NSLog(@"%@:connection view controller go back", TAG);
    [self hideViewController:conViewController];
    
}

- (void)connectionViewControllerStartGame:(ConnectionViewController *)conViewController {
    [self hideViewController:conViewController];
    [self showViewController:gameViewController];
    [gameViewController setMultiMode];
    [gameViewController startGame];
}

@end
