/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

#import "Preferences.h"
#import "Constants.h"

@implementation Preferences

@synthesize lastProcessedCommandIdentifier = mLastProcessedCommandID;

#pragma mark - Initializing and cleaning

- (id)init {
    self = [super init];
    if (self) {
        mLastProcessedCommandID = [[[NSUserDefaults standardUserDefaults]
                objectForKey:kPreferencesLastProcessedCommandIdentifier]
                retain];
    }
    return self;
}

- (void)dealloc {
    [mLastProcessedCommandID release];
    [super dealloc];
}

#pragma mark - Properties

- (void)setLastProcessedCommandIdentifier:(NSString *)lastProcessedCommandIdentifier {
    if (lastProcessedCommandIdentifier && ![mLastProcessedCommandID isEqualToString:lastProcessedCommandIdentifier]) {
        [mLastProcessedCommandID autorelease];
        mLastProcessedCommandID = [lastProcessedCommandIdentifier retain];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:mLastProcessedCommandID forKey:kPreferencesLastProcessedCommandIdentifier];
        [defaults synchronize];
    }
}

@end
