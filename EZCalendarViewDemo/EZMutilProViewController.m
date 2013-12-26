//
//  EZMutilProViewController.m
//  EZCalendarViewDemo
//
//  Created by EZ on 13-12-18.
//  Copyright (c) 2013年 cactus. All rights reserved.
//

#import "EZMutilProViewController.h"

@interface EZMutilProViewController ()
@property (nonatomic,strong) EZCalendarView *calendar ;
@end

@implementation EZMutilProViewController
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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"今天" style:UIBarButtonItemStyleDone
                                                                             target:self action:@selector(todayPress)];
    self.calendar = [[EZCalendarView alloc] initWithFrame:CGRectMake(0, 60,[UIScreen mainScreen].bounds.size.width-100, 0)];
    self.calendar.currentMonthEnable = NO;
    self.calendar.weekdayFont = [UIFont boldSystemFontOfSize:12];
    self.calendar.weekdayColor = [UIColor redColor];
    self.calendar.gridBackgroundColor = [UIColor brownColor];
    self.calendar.selectedDateCellColor = [UIColor purpleColor];
    self.calendar.todayCellColor = [UIColor blackColor];
    self.calendar.dayCellFont = [UIFont systemFontOfSize:18];
    self.calendar.dayCurrntCellColor = [UIColor cyanColor ];
    self.calendar.dayNotCurrntCellColor = [UIColor darkGrayColor];
    self.calendar.arrowColor = [UIColor blueColor];
    self.calendar.delegate=self;
    [self.view addSubview:self.calendar];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)todayPress{
    
    [self.calendar toToday];
}

-(void)calendarView:(EZCalendarView *)calendarView switchedToMonth:(int)month targetHeight:(float)targetHeight animated:(BOOL)animated {
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:NSMonthCalendarUnit fromDate:[NSDate date]];
    //    return [components month];
    if (month==[components month]) {
        NSArray *dates = [NSArray arrayWithObjects:[NSNumber numberWithInt:1],[NSNumber numberWithInt:19], nil];
        //        NSArray *color = [NSArray arrayWithObjects:[UIColor redColor],[UIColor greenColor],nil];
        //        [calendarView markDates:dates withColors:color];
        [calendarView markDates:dates];
    }else{
        NSArray *dates = [NSArray arrayWithObjects:[NSNumber numberWithInt:9],[NSNumber numberWithInt:10], nil];
        //        NSArray *color = [NSArray arrayWithObjects:[UIColor redColor],[UIColor greenColor],nil];
        //        [calendarView markDates:dates withColors:color];
        [calendarView markDates:dates withColors:@[[UIColor blueColor],[UIColor greenColor]]];
    }
}

-(void)calendarView:(EZCalendarView *)calendarView dateSelected:(NSDate *)date {
    NSLog(@"Selected date = %@",date);
}


- (IBAction)buttonAction:(id)sender {
    self.calendar.selectMarkedColor = [UIColor yellowColor];
    self.calendar.selectTodayMarkedColor = [UIColor redColor];
        self.calendar.weekdayColor = [UIColor orangeColor];
    self.calendar.separateLineColor = [UIColor greenColor];
    self.calendar.scrollEnabled = NO;
}
@end