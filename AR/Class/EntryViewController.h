//
//  EntryViewController.h
//  AR
//
//  Created by Jiyue Wang on 5/16/15.
//  Copyright (c) 2015 Jiyue Wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConnectionViewController.h"

@interface EntryViewController : UIViewController

@property(nonatomic, strong) IBOutlet UIButton* button_single;
@property(nonatomic, strong) IBOutlet UIButton* button_multi;

- (IBAction)didButtomPressed: (id)sender;

@end
