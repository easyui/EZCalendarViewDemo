//
//  EZViewController.m
//  EZCalendarViewDemo
//
//  Created by NeuLion SH on 13-12-18.
//  Copyright (c) 2013年 cactus. All rights reserved.
//

#import "EZViewController.h"
#define NameArr @[@"基础",@"多属性设置"]
#define VCArr   @[@"EZBaseViewController",@"EZMutilProViewController"]
@interface EZViewController ()
@property(strong, nonatomic) NSArray    *nameArr;
@property(strong, nonatomic) NSArray    *vcArr;
@end

@implementation EZViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"feature";
    self.nameArr = NameArr;
    self.vcArr = VCArr;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.nameArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Identifier"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Identifier"];
    }
    
    cell.textLabel.text = self.nameArr[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id vc = [[NSClassFromString(self.vcArr[indexPath.row]) alloc] initWithNibName:self.vcArr[indexPath.row] bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}



@end
