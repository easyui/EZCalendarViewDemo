//
//  EZCalendarView.m
//  EZCalendarViewDemo
//
//  Created by NeuLion SH on 13-12-18.
//  Copyright (c) 2013年 cactus. All rights reserved.
//

#import "EZCalendarView.h"
#import <QuartzCore/QuartzCore.h>

#define kEZCalendarViewTopBarHeight 60
#define kEZCalendarViewWidth        [UIScreen mainScreen].bounds.size.width
#define kEZCalendarViewDayWidth     44
#define kEZCalendarViewDayHeight    44

@interface EZCalendarView ()
@property (nonatomic, assign) BOOL              isAnimating;
@property (nonatomic, assign) BOOL              prepAnimationPreviousMonth;
@property (nonatomic, assign) BOOL              prepAnimationNextMonth;
@property (nonatomic, strong) UIScrollView      *scrollView;
@property (nonatomic, strong) NSMutableArray    *imageViews;
@property (nonatomic, strong) UIImageView       *animationView_A;
@property (nonatomic, strong) UIImageView       *animationView_B;

- (void)selectDate:(int)date;
- (int)numRows;
- (void)updateSize;
- (UIImage *)drawCurrentState;
- (void)reset;

@end
@implementation EZCalendarView

#pragma mark - Init
- (id)init
{
    self = [self initWithFrame:CGRectMake(0, 0, kEZCalendarViewWidth, 0)];

    if (self) {}

    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self) {
        self.contentMode = UIViewContentModeTop;
        self.clipsToBounds = YES;
        self.isAnimating = NO;

        // 初始化标题
        self.labelCurrentMonth = [[UILabel alloc] initWithFrame:CGRectMake(34, 0, kEZCalendarViewWidth - 68, 40)];
        [self addSubview:self.labelCurrentMonth];
        self.labelCurrentMonth.backgroundColor = [UIColor whiteColor];
        self.labelCurrentMonth.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17];
        self.labelCurrentMonth.textColor = [UIColor colorWithHexString:@"0x383838"];
        self.labelCurrentMonth.textAlignment = NSTextAlignmentCenter;
        self.currentMonthEnable = YES;
        self.currentMonthFormat = @"MMMM yyyy";
        // 初始化滚动
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, kEZCalendarViewTopBarHeight, kEZCalendarViewWidth, (kEZCalendarViewDayHeight + 2) * 6 + 1)];
        //        self.scrollView.clipsToBounds = YES;
        self.scrollView.delegate = self;
        self.scrollView.contentSize = CGSizeMake(kEZCalendarViewWidth * 3, self.bounds.size.height);
        self.scrollView.showsHorizontalScrollIndicator = NO;
        [self.scrollView setContentOffset:CGPointMake(kEZCalendarViewWidth, 0) animated:NO];
        self.scrollView.pagingEnabled = YES;
        self.scrollView.backgroundColor = [UIColor clearColor]; // [UIColor colorWithWhite:.5 alpha:.5];
        [self addSubview:self.scrollView];

        //选中圆点
        _markedColor = [UIColor colorWithHexString:@"0x383838"];
        _selectMarkedColor = [UIColor whiteColor];
        _selectTodayMarkedColor = [UIColor whiteColor];

        _weekdayFont = [UIFont fontWithName:@"HelveticaNeue" size:12];
        _weekdayColor = [UIColor colorWithHexString:@"0x383838"];
        _weekdayFormat = @"EEE";
        
        _gridBackgroundColor = [UIColor colorWithHexString:@"0xf3f3f3"];
        _selectedDateCellColor = [UIColor colorWithHexString:@"0x006dbc"];
        _todayCellColor = [UIColor colorWithHexString:@"0x006dbc"];
        _dayCellFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17];
        _dayCurrntCellColor = [UIColor colorWithHexString:@"0x383838"];
        _dayNotCurrntCellColor = [UIColor colorWithHexString:@"0xaaaaaa"];
//         @"0x383838" : @"0xaa0000";
        // 初始化数据
        //        [self performSelector:@selector(reset) withObject:nil afterDelay:0.1]; // so delegate can be set after init and still get called on init
        //        [self reset];
    }

    return self;
}

#pragma mark - Select Date
- (void)selectDate:(int)date
{
    NSCalendar          *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents    *comps = [gregorian components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self.currentMonth];

    [comps setDay:date];
    self.selectedDate = [gregorian dateFromComponents:comps];

    int selectedDateYear = [self.selectedDate year];
    int selectedDateMonth = [self.selectedDate month];
    int currentMonthYear = [self.currentMonth year];
    int currentMonthMonth = [self.currentMonth month];

    if (selectedDateYear < currentMonthYear) {
        [self showPreviousMonth];
    } else if (selectedDateYear > currentMonthYear) {
        [self showNextMonth];
    } else if (selectedDateMonth < currentMonthMonth) {
        [self showPreviousMonth];
    } else if (selectedDateMonth > currentMonthMonth) {
        [self showNextMonth];
    } else {
        [self setNeedsDisplay];
    }

    if ([self.delegate respondsToSelector:@selector(calendarView:dateSelected:)]) {
        [self.delegate calendarView:self dateSelected:self.selectedDate];
    }
}

#pragma mark - Mark Dates
// NSArray can either contain NSDate objects or NSNumber objects with an int of the day.
- (void)markDates:(NSArray *)dates
{
    self.markedDates = dates;
    NSMutableArray *colors = [[NSMutableArray alloc] init];

    for (int i = 0; i < [dates count]; i++) {
        [colors addObject:self.markedColor];
    }

    self.markedColors = [NSArray arrayWithArray:colors];

    [self setNeedsDisplay];
}

// NSArray can either contain NSDate objects or NSNumber objects with an int of the day.
- (void)markDates:(NSArray *)dates withColors:(NSArray *)colors
{
    self.markedDates = dates;
    self.markedColors = colors;

    [self setNeedsDisplay];
}

#pragma mark - Set date to now
- (void)reset
{
    NSCalendar *gregorian = [[NSCalendar alloc]
        initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components =
        [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit |
        NSDayCalendarUnit) fromDate:[NSDate date]];

    self.currentMonth = [gregorian dateFromComponents:components]; // clean month
    //    NSLog(@"self.currentMonth__%@", self.currentMonth);
    [self updateSize];

    //    [self setNeedsDisplay];
    if ([self.delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight:animated:)]) {
        [self.delegate calendarView:self switchedToMonth:[self.currentMonth month] targetHeight:self.calendarHeight animated:NO];
    }
}

#pragma mark - Next & Previous & Today
- (void)showNextMonth
{
    if (self.isAnimating) {
        return;
    }

    self.markedDates = nil;
    self.isAnimating = YES;
    self.prepAnimationNextMonth = YES;

    [self setNeedsDisplay];

    //    int     lastBlock = [self.currentMonth firstWeekDayInMonth] + [self.currentMonth numDaysInMonth] - 1;
    //    int     numBlocks = [self numRows] * 7;
    //    BOOL    hasNextMonthDays = lastBlock < numBlocks;

    // Old month
    float   oldSize = self.calendarHeight;
    UIImage *imageCurrentMonth = [self drawCurrentState];

    // New month
    self.currentMonth = [self.currentMonth offsetMonth:1];

    if ([self.delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight:animated:)]) {
        [self.delegate calendarView:self switchedToMonth:[self.currentMonth month] targetHeight:self.calendarHeight animated:YES];
    }

    self.prepAnimationNextMonth = NO;
    [self setNeedsDisplay];

    UIImage *imageNextMonth = [self drawCurrentState];
    float   targetSize = fmaxf(oldSize, self.calendarHeight);
    UIView  *animationHolder = [[UIView alloc] initWithFrame:CGRectMake(0, kEZCalendarViewTopBarHeight, kEZCalendarViewWidth, targetSize - kEZCalendarViewTopBarHeight)];
    [animationHolder setClipsToBounds:YES];
    [self addSubview:animationHolder];

    // Animate
    self.animationView_A = [[UIImageView alloc] initWithImage:imageCurrentMonth];
    self.animationView_B = [[UIImageView alloc] initWithImage:imageNextMonth];
    [animationHolder addSubview:self.animationView_A];
    [animationHolder addSubview:self.animationView_B];

    self.animationView_B.frameX = kEZCalendarViewWidth;

    /*
     *   if (hasNextMonthDays) {
     *    self.animationView_B.frameY = self.animationView_A.frameY + self.animationView_A.frameHeight - (kEZCalendarViewDayHeight+3);
     *   } else {
     *    self.animationView_B.frameY = self.animationView_A.frameY + self.animationView_A.frameHeight -3;
     *   }
     */

    // Animation
    __weak EZCalendarView *blockSafeSelf = self;
    [UIView animateWithDuration:.0
            animations  :^{
        [self updateSize];
        self.animationView_A.frameX = -kEZCalendarViewWidth;
        self.animationView_B.frameX = 0;

        /*
         *   //blockSafeSelf.frameHeight = 100;
         *   if (hasNextMonthDays) {
         *    self.animationView_A.frameY = -self.animationView_A.frameHeight + kEZCalendarViewDayHeight+3;
         *   } else {
         *    self.animationView_A.frameY = -self.animationView_A.frameHeight + 3;
         *   }
         *   self.animationView_B.frameY = 0;
         */
    }

            completion  :^(BOOL finished) {
        [self.animationView_A removeFromSuperview];
        [self.animationView_B removeFromSuperview];
        blockSafeSelf.animationView_A = nil;
        blockSafeSelf.animationView_B = nil;
        self.isAnimating = NO;
        [animationHolder removeFromSuperview];
    }

    ];
}

- (void)showPreviousMonth
{
    if (self.isAnimating) {
        return;
    }

    self.isAnimating = YES;
    self.markedDates = nil;
    // Prepare current screen
    self.prepAnimationPreviousMonth = YES;
    [self setNeedsDisplay];
    //    BOOL    hasPreviousDays = [self.currentMonth firstWeekDayInMonth] > 1;
    float   oldSize = self.calendarHeight;
    UIImage *imageCurrentMonth = [self drawCurrentState];

    // Prepare next screen
    self.currentMonth = [self.currentMonth offsetMonth:-1];

    if ([self.delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight:animated:)]) {
        [self.delegate calendarView:self switchedToMonth:[self.currentMonth month] targetHeight:self.calendarHeight animated:YES];
    }

    self.prepAnimationPreviousMonth = NO;
    [self setNeedsDisplay];
    UIImage *imagePreviousMonth = [self drawCurrentState];

    float   targetSize = fmaxf(oldSize, self.calendarHeight);
    UIView  *animationHolder = [[UIView alloc] initWithFrame:CGRectMake(0, kEZCalendarViewTopBarHeight, kEZCalendarViewWidth, targetSize - kEZCalendarViewTopBarHeight)];

    [animationHolder setClipsToBounds:YES];
    [self addSubview:animationHolder];

    self.animationView_A = [[UIImageView alloc] initWithImage:imageCurrentMonth];
    self.animationView_B = [[UIImageView alloc] initWithImage:imagePreviousMonth];
    [animationHolder addSubview:self.animationView_A];
    [animationHolder addSubview:self.animationView_B];

    self.animationView_B.frameX = -kEZCalendarViewWidth;

    /*
     *   if (hasPreviousDays) {
     *    self.animationView_B.frameY = self.animationView_A.frameY - (self.animationView_B.frameHeight-kEZCalendarViewDayHeight) + 3;
     *   } else {
     *    self.animationView_B.frameY = self.animationView_A.frameY - self.animationView_B.frameHeight + 3;
     *   }
     */

    __weak EZCalendarView *blockSafeSelf = self;
    [UIView animateWithDuration:.0
            animations:^{
        [self updateSize];
        self.animationView_A.frameX = kEZCalendarViewWidth;
        self.animationView_B.frameX = 0;

        /*
         *   if (hasPreviousDays) {
         *    self.animationView_A.frameY = self.animationView_B.frameHeight-(kEZCalendarViewDayHeight+3);
         *
         *   } else {
         *    self.animationView_A.frameY = self.animationView_B.frameHeight-3;
         *   }
         *
         *   self.animationView_B.frameY = 0;
         */
    } completion:^(BOOL finished) {
        [self.animationView_A removeFromSuperview];
        [self.animationView_B removeFromSuperview];
        blockSafeSelf.animationView_A = nil;
        blockSafeSelf.animationView_B = nil;
        self.isAnimating = NO;
        [animationHolder removeFromSuperview];
    }

    ];
}

- (void)toToday
{
    self.selectedDate = nil;
    self.markedDates = nil;
    self.markedColors = nil;

    [self reset];
}

#pragma mark - update size & row count
- (void)updateSize
{
    self.frameHeight = self.calendarHeight;
    [self setNeedsDisplay];
}

- (float)calendarHeight
{
    return kEZCalendarViewTopBarHeight + [self numRows] * (kEZCalendarViewDayHeight + 2) + 1;
}

- (int)numRows
{
    float lastBlock = [self.currentMonth numDaysInMonth] + ([self.currentMonth firstWeekDayInMonth] - 1);

    return ceilf(lastBlock / 7);
}

#pragma mark - Touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];

    self.selectedDate = nil;

    // Touch a specific day
    if (touchPoint.y > kEZCalendarViewTopBarHeight) {
        float   xLocation = touchPoint.x;
        float   yLocation = touchPoint.y - kEZCalendarViewTopBarHeight;

        int column = floorf(xLocation / (kEZCalendarViewDayWidth + 2));
        int row = floorf(yLocation / (kEZCalendarViewDayHeight + 2));

        int blockNr = (column + 1) + row * 7;
        int firstWeekDay = [self.currentMonth firstWeekDayInMonth] - 1; // -1 because weekdays begin at 1, not 0
        int date = blockNr - firstWeekDay;
        [self selectDate:date];
        return;
    }

    self.markedDates = nil;
    self.markedColors = nil;

    CGRect  rectArrowLeft = CGRectMake(0, 0, 50, 40);
    CGRect  rectArrowRight = CGRectMake(self.frame.size.width - 50, 0, 50, 40);

    // Touch either arrows or month in middle
    if (CGRectContainsPoint(rectArrowLeft, touchPoint)) {
        [self showPreviousMonth];
    } else if (CGRectContainsPoint(rectArrowRight, touchPoint)) {
        [self showNextMonth];
    } else if (CGRectContainsPoint(self.labelCurrentMonth.frame, touchPoint)&&self.currentMonthEnable) {
        // Detect touch in current month
        //        int currentMonthIndex = [self.currentMonth month];
        //        int todayMonth = [[NSDate date] month];
        [self reset];

        /*
         *   //不是一个月要更新的事件
         *   if ((todayMonth != currentMonthIndex) && [self.delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight:animated:)]) {
         *    [self.delegate calendarView:self switchedToMonth:[self.currentMonth month] targetHeight:self.calendarHeight animated:NO];
         *   }
         */
    }
}

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect
{
    int firstWeekDay = [self.currentMonth firstWeekDayInMonth] - 1; // -1 because weekdays begin at 1, not 0

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

    [formatter setDateFormat:self.currentMonthFormat];
    self.labelCurrentMonth.text = [formatter stringFromDate:self.currentMonth];
    [self.labelCurrentMonth sizeToFit];
    self.labelCurrentMonth.frameX = roundf(kEZCalendarViewWidth / 2 - self.labelCurrentMonth.frameWidth / 2);
    self.labelCurrentMonth.frameY = 13;
    [self.currentMonth firstWeekDayInMonth];

    // 设置日历上面的navi的背景
    CGContextClearRect(UIGraphicsGetCurrentContext(), rect);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGRect rectangle = CGRectMake(0, 0, self.frame.size.width, kEZCalendarViewTopBarHeight);
    CGContextAddRect(context, rectangle);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillPath(context);

    // Arrows
    int arrowSize = 12;
    int xmargin = 15;
    int ymargin = 18;

    // Arrow Left
    CGContextBeginPath(context);
//    CGContextMoveToPoint(context, xmargin + arrowSize / 1.5, ymargin);
    CGContextMoveToPoint(context, xmargin + arrowSize / 1.5, ymargin + arrowSize);
    CGContextAddLineToPoint(context, xmargin, ymargin + arrowSize / 2);
    CGContextAddLineToPoint(context, xmargin + arrowSize / 1.5, ymargin);

    CGContextSetFillColorWithColor(context,
        [UIColor blackColor].CGColor);
//      CGContextFillPath(context);
    CGContextStrokePath(context);

    // Arrow right
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, self.frame.size.width - (xmargin + arrowSize / 1.5), ymargin);
    CGContextAddLineToPoint(context, self.frame.size.width - xmargin, ymargin + arrowSize / 2);
    CGContextAddLineToPoint(context, self.frame.size.width - (xmargin + arrowSize / 1.5), ymargin + arrowSize);
//    CGContextAddLineToPoint(context, self.frame.size.width - (xmargin + arrowSize / 1.5), ymargin);

    CGContextSetFillColorWithColor(context,
        [UIColor blackColor].CGColor);
//    CGContextFillPath(context);
    CGContextStrokePath(context);

    // Weekdays
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = self.weekdayFormat;
    // always assume gregorian with monday first
    NSMutableArray *weekdays = [[NSMutableArray alloc] initWithArray:[dateFormatter shortWeekdaySymbols]];
    //    [weekdays moveObjectFromIndex:0 toIndex:6];

    CGContextSetFillColorWithColor(context,
        self.weekdayColor.CGColor);

    for (int i = 0; i < [weekdays count]; i++) {
        NSString *weekdayValue = (NSString *)[weekdays objectAtIndex:i];
        [weekdayValue drawInRect:CGRectMake(i * (kEZCalendarViewDayWidth + 2), 40, kEZCalendarViewDayWidth + 2, 20) withFont:self.weekdayFont lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
    }

    int numRows = [self numRows];

    CGContextSetAllowsAntialiasing(context, NO);

    // Grid background
    float   gridHeight = numRows * (kEZCalendarViewDayHeight + 2) + 1;
    CGRect  rectangleGrid = CGRectMake(0, kEZCalendarViewTopBarHeight, self.frame.size.width, gridHeight);
    CGContextAddRect(context, rectangleGrid);
    CGContextSetFillColorWithColor(context, self.gridBackgroundColor.CGColor);
    CGContextFillPath(context);

    // Grid white lines
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, kEZCalendarViewTopBarHeight + 1);
    CGContextAddLineToPoint(context, kEZCalendarViewWidth, kEZCalendarViewTopBarHeight + 1);

    for (int i = 1; i < 7; i++) {
        // 竖线
        CGContextMoveToPoint(context, i * (kEZCalendarViewDayWidth + 1) + i * 1 - 1, kEZCalendarViewTopBarHeight);
        CGContextAddLineToPoint(context, i * (kEZCalendarViewDayWidth + 1) + i * 1 - 1, kEZCalendarViewTopBarHeight + gridHeight);

        if (i > numRows - 1) {
            continue;
        }

        // 横线
        CGContextMoveToPoint(context, 0, kEZCalendarViewTopBarHeight + i * (kEZCalendarViewDayHeight + 1) + i * 1 + 1);
        CGContextAddLineToPoint(context, kEZCalendarViewWidth, kEZCalendarViewTopBarHeight + i * (kEZCalendarViewDayHeight + 1) + i * 1 + 1);
    }

    CGContextStrokePath(context);

    // Grid dark lines
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithHexString:@"0xcfd4d8"].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, kEZCalendarViewTopBarHeight);
    CGContextAddLineToPoint(context, kEZCalendarViewWidth, kEZCalendarViewTopBarHeight);

    for (int i = 1; i < 7; i++) {
        // columns
        CGContextMoveToPoint(context, i * (kEZCalendarViewDayWidth + 1) + i * 1, kEZCalendarViewTopBarHeight);
        CGContextAddLineToPoint(context, i * (kEZCalendarViewDayWidth + 1) + i * 1, kEZCalendarViewTopBarHeight + gridHeight);

        if (i > numRows - 1) {
            continue;
        }

        // rows
        CGContextMoveToPoint(context, 0, kEZCalendarViewTopBarHeight + i * (kEZCalendarViewDayHeight + 1) + i * 1);
        CGContextAddLineToPoint(context, kEZCalendarViewWidth, kEZCalendarViewTopBarHeight + i * (kEZCalendarViewDayHeight + 1) + i * 1);
    }

    CGContextMoveToPoint(context, 0, gridHeight + kEZCalendarViewTopBarHeight);
    CGContextAddLineToPoint(context, kEZCalendarViewWidth, gridHeight + kEZCalendarViewTopBarHeight);
    CGContextStrokePath(context);

    CGContextSetAllowsAntialiasing(context, YES);

    // Draw days
    CGContextSetFillColorWithColor(context,
        [UIColor greenColor].CGColor);

//    NSLog(@"currentMonth month = %i, first weekday in month = %i", [self.currentMonth month], [self.currentMonth firstWeekDayInMonth]);

    int     numBlocks = numRows * 7;
    NSDate  *previousMonth = [self.currentMonth offsetMonth:-1];
    int     currentMonthNumDays = [self.currentMonth numDaysInMonth];
    int     prevMonthNumDays = [previousMonth numDaysInMonth];

    int selectedDateBlock = ([self.selectedDate day] - 1) + firstWeekDay;

    // prepAnimationPreviousMonth nog wat mee doen

    // prev next month
    BOOL    isSelectedDatePreviousMonth = self.prepAnimationPreviousMonth;
    BOOL    isSelectedDateNextMonth = self.prepAnimationNextMonth;

    if (self.selectedDate != nil) {
        isSelectedDatePreviousMonth = ([self.selectedDate year] == [self.currentMonth year] && [self.selectedDate month] < [self.currentMonth month]) || [self.selectedDate year] < [self.currentMonth year];

        if (!isSelectedDatePreviousMonth) {
            isSelectedDateNextMonth = ([self.selectedDate year] == [self.currentMonth year] && [self.selectedDate month] > [self.currentMonth month]) || [self.selectedDate year] > [self.currentMonth year];
        }
    }

    if (isSelectedDatePreviousMonth) {
        int lastPositionPreviousMonth = firstWeekDay - 1;
        selectedDateBlock = lastPositionPreviousMonth - ([self.selectedDate numDaysInMonth] - [self.selectedDate day]);
    } else if (isSelectedDateNextMonth) {
        selectedDateBlock = [self.currentMonth numDaysInMonth] + (firstWeekDay - 1) + [self.selectedDate day];
    }

    NSDate  *todayDate = [NSDate date];
    int     todayBlock = -1;

    //    NSLog(@"currentMonth month = %i day = %i, todaydate day = %i",[currentMonth month],[currentMonth day],[todayDate month]);

    if (([todayDate month] == [self.currentMonth month]) && ([todayDate year] == [self.currentMonth year])) {
        todayBlock = [todayDate day] + firstWeekDay - 1;
    }

    for (int i = 0; i < numBlocks; i++) {
        int targetDate = i;
        int targetColumn = i % 7;
        int targetRow = i / 7;
        int targetX = targetColumn * (kEZCalendarViewDayWidth + 2);
        int targetY = kEZCalendarViewTopBarHeight + targetRow * (kEZCalendarViewDayHeight + 2);

        // BOOL isCurrentMonth = NO;
        if (i < firstWeekDay) { // previous month
            targetDate = (prevMonthNumDays - firstWeekDay) + (i + 1);
            UIColor *color = (isSelectedDatePreviousMonth) ? self.dayCurrntCellColor : self.dayNotCurrntCellColor;

            CGContextSetFillColorWithColor(context,
                 color.CGColor);
        } else if (i >= (firstWeekDay + currentMonthNumDays)) { // next month
            targetDate = (i + 1) - (firstWeekDay + currentMonthNumDays);
            UIColor *color= (isSelectedDateNextMonth) ? self.dayCurrntCellColor : self.dayNotCurrntCellColor;
            CGContextSetFillColorWithColor(context,
                color.CGColor);
        } else { // current month
            // isCurrentMonth = YES;
            targetDate = (i - firstWeekDay) + 1;
            UIColor *color = (isSelectedDatePreviousMonth || isSelectedDateNextMonth) ? self.dayNotCurrntCellColor : self.dayCurrntCellColor;
            CGContextSetFillColorWithColor(context,
                color.CGColor);
        }

        NSString *date = [NSString stringWithFormat:@"%i", targetDate];

        // draw selected date
        if (self.selectedDate && (i == selectedDateBlock)) {
            CGRect rectangleGrid = CGRectMake(targetX, targetY, kEZCalendarViewDayWidth + 2, kEZCalendarViewDayHeight + 2);
            CGContextAddRect(context, rectangleGrid);
            CGContextSetFillColorWithColor(context, self.selectedDateCellColor.CGColor);
            CGContextFillPath(context);

            CGContextSetFillColorWithColor(context,
                [UIColor whiteColor].CGColor);
        } else if (todayBlock == i) {
            CGRect rectangleGrid = CGRectMake(targetX, targetY, kEZCalendarViewDayWidth + 2, kEZCalendarViewDayHeight + 2);
            CGContextAddRect(context, rectangleGrid);
            CGContextSetFillColorWithColor(context, self.todayCellColor.CGColor);
            CGContextFillPath(context);

            CGContextSetFillColorWithColor(context,
                [UIColor whiteColor].CGColor);
        }

        [date drawInRect:CGRectMake(targetX + 2, targetY + 10, kEZCalendarViewDayWidth, kEZCalendarViewDayHeight) withFont:self.dayCellFont lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
    }

    //    CGContextClosePath(context);

    // Draw markings
    if (!self.markedDates || isSelectedDatePreviousMonth || isSelectedDateNextMonth) {
        return;
    }

    for (int i = 0; i < [self.markedDates count]; i++) {
        id markedDateObj = [self.markedDates objectAtIndex:i];

        int targetDate;

        if ([markedDateObj isKindOfClass:[NSNumber class]]) {
            targetDate = [(NSNumber *)markedDateObj intValue];
        } else if ([markedDateObj isKindOfClass:[NSDate class]]) {
            NSDate *date = (NSDate *)markedDateObj;
            targetDate = [date day];
        } else {
            continue;
        }

        int targetBlock = firstWeekDay + (targetDate - 1);
        int targetColumn = targetBlock % 7;
        int targetRow = targetBlock / 7;

        float   diameter = 5.0f;
        int     targetX = targetColumn * (kEZCalendarViewDayWidth + 2) + (kEZCalendarViewDayWidth - diameter) / 2;
        int     targetY = kEZCalendarViewTopBarHeight + targetRow * (kEZCalendarViewDayHeight + 2) + 38;

        //        CGRect rectangle = CGRectMake(targetX,targetY,32,2);
        //        CGContextAddRect(context, rectangle);
        CGRect rectangle = CGRectMake(targetX, targetY, diameter, diameter);
        CGContextAddEllipseInRect(context, rectangle);

        UIColor *color;

        if (self.selectedDate && (selectedDateBlock == targetBlock)) {
            color = self.selectMarkedColor;
        } else if (todayBlock == targetBlock) {
            color = self.selectTodayMarkedColor;
        } else {
            color = (UIColor *)[self.markedColors objectAtIndex:i];
        }

        //        [@"•" drawInRect: rectangle
        //				withFont: [UIFont boldSystemFontOfSize:18.f]
        //		   lineBreakMode: NSLineBreakByWordWrapping
        //			   alignment: NSTextAlignmentCenter];

        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillPath(context);
    }
}

#pragma mark - Draw image for animation
- (UIImage *)drawCurrentState
{
    float targetHeight = kEZCalendarViewTopBarHeight + [self numRows] * (kEZCalendarViewDayHeight + 2) + 1;

    UIGraphicsBeginImageContext(CGSizeMake(kEZCalendarViewWidth, targetHeight - kEZCalendarViewTopBarHeight));
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(c, 0, -kEZCalendarViewTopBarHeight);
    [self.layer renderInContext:c];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return viewImage;
}

- (void)setScrollImages
{
    self.selectedDate = nil;
    NSArray *arr = @[@(-1), @(2), @(-1)];
    int     count = arr.count;

    if (!self.imageViews) {
        self.imageViews = [[NSMutableArray alloc] initWithCapacity:count];
    }

    for (int i = 0; i < count; i++) {
        //        self.selectedDate=nil;
        //    self.markedDates = nil;
        //    self.markedColors = nil;
        int index = [arr[i] intValue];

        if (i == 0) {
            self.prepAnimationPreviousMonth = YES;
        } else if (i == 1) {
            //            prepAnimationPreviousMonth = NO;
            //            prepAnimationNextMonth = NO;
            self.prepAnimationNextMonth = YES;
        } else if (i == 2) {
            //            prepAnimationNextMonth = YES;
            self.prepAnimationPreviousMonth = NO;
            self.prepAnimationNextMonth = NO;
        }

        //    float oldSize = self.calendarHeight;
        self.currentMonth = [self.currentMonth offsetMonth:index];
        [self updateSize];

        if ([self.delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight:animated:)]) {
            [self.delegate calendarView:self switchedToMonth:[self.currentMonth month] targetHeight:self.calendarHeight animated:YES];
        }

        if (i == 0) {
            self.prepAnimationPreviousMonth = NO;
        } else if (i == 1) {
            //            prepAnimationPreviousMonth = NO;
            //            prepAnimationNextMonth = NO;
            self.prepAnimationNextMonth = NO;
        } else if (i == 2) {
            //            prepAnimationNextMonth = NO;
        }

        [self setNeedsDisplay];

        UIImage *imageMonth = [self drawCurrentState];
        float   targetSize = fmaxf(0, self.calendarHeight);
        float   startX = 0.;

        if (i == 0) {
            startX = 0.;
        } else if (i == 1) {
            startX = 2.;
        } else if (i == 2) {
            startX = 1.;
        }

        UIImageView *imageViewMonth = [[UIImageView alloc] initWithFrame:CGRectMake(kEZCalendarViewWidth * (startX), 0, kEZCalendarViewWidth, targetSize - kEZCalendarViewTopBarHeight)];
        [imageViewMonth setClipsToBounds:YES];
        imageViewMonth.image = imageMonth;
        [self.scrollView addSubview:imageViewMonth];
        [self.imageViews addObject:imageViewMonth];
    }

    self.scrollView.backgroundColor = [UIColor blackColor];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offset = scrollView.contentOffset.x;

    NSLog(@"ss%f", offset);

    if (offset == kEZCalendarViewWidth) {
        return;
    }

    if (offset >= (2 * kEZCalendarViewWidth)) {
        [self showNextMonth];
        //        self.scrollView.backgroundColor = [UIColor clearColor];
        return;
    }

    if (offset <= 0) {
        [self showPreviousMonth];
        //        self.scrollView.backgroundColor = [UIColor clearColor];
        return;
    }

    if (self.imageViews.count == 0) {
        [self setScrollImages];

        for (UIImageView *imageView in self.imageViews) {
            CGFloat scale = 1.f - (fabs(offset) > 0 ? 0.005 : 0);
            imageView.transform = CGAffineTransformMakeScale(scale, 1);
        }
    }
}

/*
 *   - (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
 *   {
 *
 *    if (!decelerate) {
 *        NSLog(@"asdasdasd");
 *        [self.scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width, 0) animated:YES];
 *    }
 *   }
 */

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView
{
    NSLog(@"aaaaa");
    self.scrollView.backgroundColor = [UIColor clearColor];

    for (UIImageView *imageView in self.imageViews) {
        imageView.transform = CGAffineTransformMakeScale(1, 1);
    }

    NSArray *subViews = [_scrollView subviews];

    if ([subViews count] != 0) {
        [subViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.imageViews removeAllObjects];
        self.imageViews = nil;
    }

    [self.scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width, 0) animated:NO];
}


#pragma mark - setting method
- (void)setDelegate:(id <EZCalendarViewDelegate>)delegate
{
    _delegate = delegate;
    [self reset];
}

- (void)setSelectMarkedColor:(UIColor *)selectMarkedColor
{
    _selectMarkedColor = selectMarkedColor;
    [self setNeedsDisplay];
}

- (void)setSelectTodayMarkedColor:(UIColor *)selectTodayMarkedColor
{
    _selectTodayMarkedColor = selectTodayMarkedColor;
    [self setNeedsDisplay];
}

- (void)setWeekdayFont:(UIFont *)weekdayFont
{
    _weekdayFont = weekdayFont;
    [self setNeedsDisplay];
}

-(void)setWeekdayColor:(UIColor *)weekdayColor{
    _weekdayColor = weekdayColor;
    [self setNeedsDisplay];
}

-(void)setGridBackgroundColor:(UIColor *)gridBackgroundColor{
    _gridBackgroundColor = gridBackgroundColor;
    [self setNeedsDisplay];
}

-(void)setSelectedDateCellColor:(UIColor *)selectedDateCellColor{
    _selectedDateCellColor = selectedDateCellColor;
    [self setNeedsDisplay];
}

-(void)setTodayCellColor:(UIColor *)todayCellColor{
    _todayCellColor = todayCellColor;
    [self setNeedsDisplay];
}

-(void)setDayCellFont:(UIFont *)dayCellFont{
    _dayCellFont = dayCellFont;
    [self setNeedsDisplay];
}

-(void)setDayCurrntCellColor:(UIColor *)dayCurrntCellColor{
    _dayCurrntCellColor = dayCurrntCellColor;
 [self setNeedsDisplay];
}
-(void)setDayNotCurrntCellColor:(UIColor *)dayNotCurrntCellColor{
    _dayNotCurrntCellColor = dayNotCurrntCellColor;
 [self setNeedsDisplay];
}
@end

#pragma mark -
#pragma mark -
#pragma mark category
#pragma mark -
#pragma mark -


@implementation UIScrollView (UITouchEvent)

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self nextResponder] touchesBegan:touches withEvent:event];
    //    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self nextResponder] touchesMoved:touches withEvent:event];
    //    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self nextResponder] touchesEnded:touches withEvent:event];
    //    [super touchesEnded:touches withEvent:event];
}

@end

@implementation UIColor (UIColor_Expanded)
+ (UIColor *)colorWithHexString:(NSString *)stringToConvert
{
    NSScanner   *scanner = [NSScanner scannerWithString:stringToConvert];
    unsigned    hexNum;

    if (![scanner scanHexInt:&hexNum]) {
        return nil;
    }

    return [UIColor colorWithRGBHex:hexNum];
}

+ (UIColor *)colorWithRGBHex:(UInt32)hex
{
    int r = (hex >> 16) & 0xFF;
    int g = (hex >> 8) & 0xFF;
    int b = (hex) & 0xFF;

    return [UIColor colorWithRed:r / 255.0f
                    green       :g / 255.0f
                    blue        :b / 255.0f
                    alpha       :1.0f];
}

@end

@implementation UIView (convenience)

- (BOOL)containsSubView:(UIView *)subView
{
    for (UIView *view in [self subviews]) {
        if ([view isEqual:subView]) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)containsSubViewOfClassType:(Class)class
{
    for (UIView *view in [self subviews]) {
        if ([view isMemberOfClass:class]) {
            return YES;
        }
    }

    return NO;
}

- (CGFloat)frameX
{
    return self.frame.origin.x;
}

- (void)setFrameX:(CGFloat)newX
{
    self.frame = CGRectMake(newX, self.frame.origin.y,
            self.frame.size.width, self.frame.size.height);
}

- (CGFloat)frameY
{
    return self.frame.origin.y;
}

- (void)setFrameY:(CGFloat)newY
{
    self.frame = CGRectMake(self.frame.origin.x, newY,
            self.frame.size.width, self.frame.size.height);
}

- (CGFloat)frameRight
{
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setFrameRight:(CGFloat)newRight
{
    self.frame = CGRectMake(newRight - self.frame.size.width, self.frame.origin.y,
            self.frame.size.width, self.frame.size.height);
}

- (CGFloat)frameBottom
{
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setFrameBottom:(CGFloat)newBottom
{
    self.frame = CGRectMake(self.frame.origin.x, newBottom - self.frame.size.height,
            self.frame.size.width, self.frame.size.height);
}

- (CGFloat)frameWidth
{
    return self.frame.size.width;
}

- (void)setFrameWidth:(CGFloat)newWidth
{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
            newWidth, self.frame.size.height);
}

- (CGFloat)frameHeight
{
    return self.frame.size.height;
}

- (void)setFrameHeight:(CGFloat)newHeight
{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
            self.frame.size.width, newHeight);
}

@end

@implementation NSDate (Convenience)

- (int)year
{
    NSCalendar *gregorian = [[NSCalendar alloc]
        initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:NSYearCalendarUnit fromDate:self];

    return [components year];
}

- (int)month
{
    NSCalendar *gregorian = [[NSCalendar alloc]
        initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:NSMonthCalendarUnit fromDate:self];

    return [components month];
}

- (int)day
{
    NSCalendar *gregorian = [[NSCalendar alloc]
        initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:NSDayCalendarUnit fromDate:self];

    return [components day];
}

- (int)firstWeekDayInMonth
{
    NSCalendar *gregorian = [[NSCalendar alloc]
        initWithCalendarIdentifier:NSGregorianCalendar];

    [gregorian setFirstWeekday:1]; // 1代表一周的第一天从星期天开始
    // [gregorian setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"nl_NL"]];

    // Set date to first of month
    NSDateComponents *comps = [gregorian components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self];
    [comps setDay:1];
    NSDate *newDate = [gregorian dateFromComponents:comps];

    return [gregorian ordinalityOfUnit:NSWeekdayCalendarUnit inUnit:NSWeekCalendarUnit forDate:newDate];
}

- (NSDate *)offsetMonth:(int)numMonths
{
    NSCalendar *gregorian = [[NSCalendar alloc]
        initWithCalendarIdentifier:NSGregorianCalendar];

    [gregorian setFirstWeekday:2]; // monday is first day

    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setMonth:numMonths];
    // [offsetComponents setHour:1];
    // [offsetComponents setMinute:30];
    return [gregorian dateByAddingComponents:offsetComponents
           toDate                           :self options:0];
}

- (NSDate *)offsetHours:(int)hours
{
    NSCalendar *gregorian = [[NSCalendar alloc]
        initWithCalendarIdentifier:NSGregorianCalendar];

    [gregorian setFirstWeekday:2]; // monday is first day

    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    // [offsetComponents setMonth:numMonths];
    [offsetComponents setHour:hours];
    // [offsetComponents setMinute:30];
    return [gregorian dateByAddingComponents:offsetComponents
           toDate                           :self options:0];
}

- (NSDate *)offsetDay:(int)numDays
{
    NSCalendar *gregorian = [[NSCalendar alloc]
        initWithCalendarIdentifier:NSGregorianCalendar];

    [gregorian setFirstWeekday:2]; // monday is first day

    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:numDays];
    // [offsetComponents setHour:1];
    // [offsetComponents setMinute:30];

    return [gregorian dateByAddingComponents:offsetComponents
           toDate                           :self options:0];
}

- (int)numDaysInMonth
{
    NSCalendar  *cal = [NSCalendar currentCalendar];
    NSRange     rng = [cal rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:self];
    NSUInteger  numberOfDaysInMonth = rng.length;

    return numberOfDaysInMonth;
}

+ (NSDate *)dateStartOfDay:(NSDate *)date
{
    NSCalendar *gregorian = [[NSCalendar alloc]
        initWithCalendarIdentifier:NSGregorianCalendar];

    NSDateComponents *components =
        [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit |
        NSDayCalendarUnit) fromDate:date];

    return [gregorian dateFromComponents:components];
}

+ (NSDate *)dateStartOfWeek
{
    NSCalendar *gregorian = [[NSCalendar alloc]
        initWithCalendarIdentifier:NSGregorianCalendar];

    [gregorian setFirstWeekday:2]; // monday is first day

    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:[NSDate date]];

    NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
    [componentsToSubtract setDay:-((([components weekday] - [gregorian firstWeekday])
    + 7) % 7)];
    NSDate *beginningOfWeek = [gregorian dateByAddingComponents:componentsToSubtract toDate:[NSDate date] options:0];

    NSDateComponents *componentsStripped = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
        fromDate                                                :beginningOfWeek];

    // gestript
    beginningOfWeek = [gregorian dateFromComponents:componentsStripped];

    return beginningOfWeek;
}

+ (NSDate *)dateEndOfWeek
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:[NSDate date]];

    NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];

    [componentsToAdd setDay:+(((([components weekday] - [gregorian firstWeekday])
    + 7) % 7)) + 6];
    NSDate *endOfWeek = [gregorian dateByAddingComponents:componentsToAdd toDate:[NSDate date] options:0];

    NSDateComponents *componentsStripped = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
        fromDate                                                :endOfWeek];

    // gestript
    endOfWeek = [gregorian dateFromComponents:componentsStripped];
    return endOfWeek;
}

@end