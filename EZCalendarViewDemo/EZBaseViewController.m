//
//  EZBaseViewController.m
//  EZCalendarViewDemo
//
//  Created by NeuLion SH on 13-12-18.
//  Copyright (c) 2013年 cactus. All rights reserved.
//

#import "EZBaseViewController.h"

@interface EZBaseViewController ()

@end

@implementation EZBaseViewController

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

    
    EZCalendarView *calendar= [[EZCalendarView alloc] initWithFrame:CGRectMake(0, 60, [UIScreen mainScreen].bounds.size.width, 0)];
    calendar.delegate=self;
    [self.view addSubview:calendar];

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)calendarView:(EZCalendarView *)calendarView switchedToMonth:(int)month targetHeight:(float)targetHeight animated:(BOOL)animated {
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:NSMonthCalendarUnit fromDate:[NSDate date]];
    //    return [components month];
    if (month==[components month]) {
        NSArray *dates = [NSArray arrayWithObjects:[NSNumber numberWithInt:1],[NSNumber numberWithInt:18], nil];
        //        NSArray *color = [NSArray arrayWithObjects:[UIColor redColor],[UIColor greenColor],nil];
        //        [calendarView markDates:dates withColors:color];
        [calendarView markDates:dates];
    }else{
        NSArray *dates = [NSArray arrayWithObjects:[NSNumber numberWithInt:9],[NSNumber numberWithInt:10], nil];
        //        NSArray *color = [NSArray arrayWithObjects:[UIColor redColor],[UIColor greenColor],nil];
        //        [calendarView markDates:dates withColors:color];
        [calendarView markDates:dates];
    }
}

-(void)calendarView:(EZCalendarView *)calendarView dateSelected:(NSDate *)date {
    NSLog(@"Selected date = %@",date);
}


@end
