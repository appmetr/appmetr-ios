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

- (IBAction)trackEventTouch:(id)sender {
    [AppMetr trackEvent:@"test"];
}

- (IBAction)flushTrack:(id)sender {
    [AppMetr flush];
}
@end
