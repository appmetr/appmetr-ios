/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

// Configuration
NSUInteger const kDefaultBatchFileMaxSize = 500;
NSUInteger const kTokenSizeLimit = 50;
NSTimeInterval const kDefaultFlashDataDelay = 1.0 * 60.0;       // 1(minutes) * 60(seconds)
NSTimeInterval const kDefaultUploadDataDelay = 1.5 * 60.0;      // 1.5(minutes) * 60(seconds)
NSTimeInterval const kPullRemoteCommandsDelay = 70.0;           // 70seconds

NSString *const kAppMetrDefaultUrl = @"https://appmetr.com/api";
NSString *const kAppMetrVersionString = @"1.8.1";

// Generic constants

NSString *const kActionKeyName = @"action";
NSString *const kActionAttachProperties = @"attachProperties";
NSString *const kActionTrackSession = @"trackSession";
NSString *const kActionTrackLevel = @"trackLevel";
NSString *const kActionTrackEvent = @"trackEvent";
NSString *const kActionTrackPayment = @"trackPayment";
NSString *const kActionPropertiesKeyName = @"properties";
NSString *const kActionVersionKeyName = @"$version";
NSString *const kActionTrackInstall = @"installBroadcast";
NSString *const kActionTrackGameState = @"trackGameState";
NSString *const kActionTrackInstallURL = @"trackInstallURL";
NSString *const kActionTrackCommand = @"trackCommand";
NSString *const kActionTrackCommandBatch = @"trackCommandBatch";
NSString *const kActionTrackOptions = @"trackOptions";
NSString *const kActionTrackExperiment = @"trackExperiment";
NSString *const kActionTrackState = @"trackState";
NSString *const kActionIdentify = @"identify";

NSString *const kActionCountryKeyName = @"$country";
NSString *const kSessionDurationKeyName = @"$duration";

NSString *const kPreferencesBatchNumberKeyName = @"AppMetr-BatchID";
NSString *const kPreferencesFileIndexKeyName = @"AppMetr-FileIndex";
NSString *const kPreferencesFileListKeyName = @"AppMetr-FileList";
NSString *const kPreferencesUniqueIdentifierKeyName = @"AppMetr-UniqueIdentifier";
NSString *const kPreferencesInstallURLKeyName = @"AppMetr-InstallURLTracked";
NSString *const kPreferencesFirstTrackSessionKeyName = @"AppMetr-FirstTrackSessionSent";
NSString *const kPreferencesProcessedCommandsKeyName = @"AppMetr-ProcessedCommandList";
NSString *const kPreferencesLastProcessedCommandIdentifier = @"AppMetr-LastProcessedCommandID";
NSString *const kPreferencesSessionDuration = @"AppMetr-SessionDuration";
NSString *const kPreferencesUniqueInstanceIdentifierKeyName = @"AppMetr-UniqueInstanceIdentifier";
