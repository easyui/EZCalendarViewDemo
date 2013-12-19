//
//  EZCalendarView.h
//  EZCalendarViewDemo
//
//  Created by NeuLion SH on 13-12-18.
//  Copyright (c) 2013年 cactus. All rights reserved.
//


#import <UIKit/UIKit.h>

@protocol EZCalendarViewDelegate;
@interface EZCalendarView : UIView <UIScrollViewDelegate>{

}

@property (nonatomic, strong) id <EZCalendarViewDelegate> delegate;

@property (nonatomic, strong) UIColor *arrowColor;

@property (nonatomic, strong) NSDate *currentMonth;
@property (nonatomic, strong) UILabel *labelCurrentMonth;
@property (nonatomic, assign) BOOL currentMonthEnable;
@property (nonatomic, strong) NSString * currentMonthFormat;

@property (nonatomic, strong) UIColor *separateLineColor;

@property (nonatomic, strong) NSArray *markedDates;
@property (nonatomic, strong) NSArray *markedColors;
@property (nonatomic, assign) float calendarHeight;
@property (nonatomic, strong) NSDate *selectedDate;

@property (nonatomic, strong) UIColor *markedColor;
@property (nonatomic, strong) UIColor *selectMarkedColor;
@property (nonatomic, strong) UIColor *selectTodayMarkedColor;

@property (nonatomic, strong) UIFont *weekdayFont;
@property (nonatomic, strong) UIColor *weekdayColor;
@property (nonatomic, strong) NSString *weekdayFormat;

@property (nonatomic, strong) UIColor *gridBackgroundColor;
@property (nonatomic, strong) UIColor *selectedDateCellColor;
@property (nonatomic, strong) UIColor *todayCellColor;
@property (nonatomic, strong) UIFont  *dayCellFont;
@property (nonatomic, strong) UIColor *dayNotCurrntCellColor;
@property (nonatomic, strong) UIColor *dayCurrntCellColor;


-(void)markDates:(NSArray *)dates;
-(void)markDates:(NSArray *)dates withColors:(NSArray *)colors;
-(void)showNextMonthAnimated:(BOOL)animated;
-(void)showPreviousMonthAnimated:(BOOL)animated;
-(void)toToday;
-(void)refresh;

@end

@protocol EZCalendarViewDelegate <NSObject>
@required
-(void)calendarView:(EZCalendarView *)calendarView switchedToMonth:(int)month targetHeight:(float)targetHeight animated:(BOOL)animated;
-(void)calendarView:(EZCalendarView *)calendarView dateSelected:(NSDate *)date;
@end










@interface UIScrollView (UITouchEvent)
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event ;
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event ;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event ;
@end
@interface UIColor (UIColor_Expanded)
+ (UIColor *)colorWithHexString:(NSString *)stringToConvert;
@end
@interface UIView (convenience)
@property (nonatomic) CGFloat frameX;
@property (nonatomic) CGFloat frameY;
// Setting these modifies the origin but not the size.
@property (nonatomic) CGFloat frameRight;
@property (nonatomic) CGFloat frameBottom;

@property (nonatomic) CGFloat frameWidth;
@property (nonatomic) CGFloat frameHeight;
-(BOOL) containsSubView:(UIView *)subView;
-(BOOL) containsSubViewOfClassType:(Class)class;
@end
@interface NSDate (Convenience)

-(NSDate *)offsetMonth:(int)numMonths;
-(NSDate *)offsetDay:(int)numDays;
-(NSDate *)offsetHours:(int)hours;
-(int)numDaysInMonth;
-(int)firstWeekDayInMonth;
-(int)year;
-(int)month;
-(int)day;

+(NSDate *)dateStartOfDay:(NSDate *)date;
+(NSDate *)dateStartOfWeek;
+(NSDate *)dateEndOfWeek;

@end