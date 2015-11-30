//
//  ImpulseInfoViewController.m
//  Super Freq Analysis
//
//  Created by Phil Knock on 11/29/15.
//  Copyright (c) 2015 Phillip Knock. All rights reserved.
//

#import "ImpulseInfoViewController.h"

@interface ImpulseInfoViewController ()

@end

@implementation ImpulseInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)backButtonPressed:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
