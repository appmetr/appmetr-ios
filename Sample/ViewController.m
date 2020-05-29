//
//  Copyright (c) 2013 AppMetr. All rights reserved.
//

#import "ViewController.h"
#import "AppMetr.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)trackSessionTouch:(id)sender {
    [AppMetr trackSession];
}

- (IBAction)trackEventTouch:(id)sender {
    [AppMetr trackEvent:@"test"];
}

- (IBAction)trackAllTouch:(id)sender {
    NSLog(@"Device key = %@", [AppMetr deviceKey]);
    NSDictionary * properties = [NSDictionary dictionaryWithObjectsAndKeys:
            @"value1", @"text",
            @"05.11.2013 15:00:00", @"date",
            [NSNumber numberWithInt:1], @"int",
            [NSNumber numberWithLong:1], @"long",
            [NSNumber numberWithDouble:1.5], @"double",
            [NSDictionary dictionaryWithObjectsAndKeys:
                          @"innerValue", @"value",
                    nil
            ], @"list",
            nil];

    [AppMetr trackSession];
    [AppMetr trackSessionWithProperties:properties];

    [AppMetr trackEvent:@"test"];
    [AppMetr trackEvent:@"test" properties:properties];

    NSDictionary * payment = [NSDictionary dictionaryWithObjectsAndKeys:
            @"USD", @"psUserSpentCurrencyCode",
            [NSNumber numberWithDouble:1.99], @"psUserSpentCurrencyAmount",
            @"test.items.in.test.app", @"orderId",
            [self getUUID], @"transactionId",
            @"appCurrency", @"appCurrencyCode",
            [NSNumber numberWithInt:10], @"appCurrencyAmount",
            @"appstore", @"processor",
            nil];
    [AppMetr trackPayment:payment];
    [AppMetr trackPayment:payment properties:properties];
}

- (IBAction)flushTrack:(id)sender {
    [AppMetr flush];
}

- (IBAction)trackAttachProperties:(id)sender {
    [AppMetr attachProperties];
}


-(NSString *)getUUID {
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    NSString * uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    CFRelease(newUniqueId);

    return uuidString;
}
 
- (void)dealloc {
    [super dealloc];
}
@end
