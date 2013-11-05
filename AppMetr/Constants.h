/**
 * Copyright (c) 2013 AppMetr.
 * All rights reserved.
 */

// Library configuration

#define ENABLDE_DEVICE_UNIQUE_IDENTIFIER 0

/* Max size of a batch on default. Size of created files should not exceed this value. */
extern NSUInteger const kDefaultBatchFileMaxSize;
/** Max size of token for application. */
extern NSUInteger const kTokenSizeLimit;
/** Time in seconds by default after which data is stored to disk. Also known as T1. */
extern NSTimeInterval const kDefaultFlashDataDelay;
/** Time in seconds by default after which data is sent to server. Also known as T2. */
extern NSTimeInterval const kDefaultUploadDataDelay;
/** Time in seconds to query remote commands. */
extern NSTimeInterval const kPullRemoteCommandsDelay;
/** The url string of AppMetr api. */
extern NSString *const kAppMetrDefaultUrl;
/** The version string of AppMetr library. */
extern NSString *const kAppMetrVersionString;

// Generic constants
extern NSString *const kActionKeyName;
extern NSString *const kActionAttachProperties;
extern NSString *const kActionTrackSession;
extern NSString *const kActionTrackLevel;
extern NSString *const kActionTrackEvent;
extern NSString *const kActionTrackPayment;
extern NSString *const kActionPropertiesKeyName;
extern NSString *const kActionVersionKeyName;
extern NSString *const kActionTrackInstall;
extern NSString *const kActionTrackGameState;
extern NSString *const kActionTrackInstallURL;
extern NSString *const kActionTrackCommand;
extern NSString *const kActionTrackCommandBatch;
extern NSString *const kActionTrackOptions;
extern NSString *const kActionTrackExperiment;
extern NSString *const kActionIdentify;

extern NSString *const kActionCountryKeyName;
extern NSString *const kPreferencesBatchNumberKeyName;
extern NSString *const kPreferencesFileIndexKeyName;
extern NSString *const kPreferencesFileListKeyName;
extern NSString *const kPreferencesUniqueIdentifierKeyName;
extern NSString *const kPreferencesInstallURLKeyName;
extern NSString *const kPreferencesFirstTrackSessionKeyName;
extern NSString *const kPreferencesProcessedCommandsKeyName;
extern NSString *const kPreferencesLastProcessedCommandIdentifier;
extern NSString *const kPreferencesUniqueInstanceIdentifierKeyName;
