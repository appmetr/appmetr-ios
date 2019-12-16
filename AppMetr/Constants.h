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
/** Time in seconds for max pause state, after which starts new session */
extern NSTimeInterval const kSessionMaxPauseState;
/** Max batch count for direct upload, stored in memory */
extern NSUInteger const kUploadInMemoryCount;
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
extern NSString *const kActionTrackState;
extern NSString *const kActionIdentify;
extern NSString *const kActionAttachEntityAttributes;
extern NSString *const kActionEntityNameKey;
extern NSString *const kActionEntityValueKey;

extern NSString *const kActionCountryKeyName;
extern NSString *const kActionLanguageKeyName;
extern NSString *const kActionLocaleKeyName;
extern NSString *const kSessionDurationKeyName;

extern NSString *const kPreferencesBatchNumberKeyName;
extern NSString *const kPreferencesFileIndexKeyName;
extern NSString *const kPreferencesFileListKeyName;
extern NSString *const kPreferencesUniqueIdentifierKeyName;
extern NSString *const kPreferencesInstallURLKeyName;
extern NSString *const kPreferencesFirstTrackSessionKeyName;
extern NSString *const kPreferencesSessionDuration;
extern NSString *const kPreferencesSessionDurationCurrent;
extern NSString *const kPreferencesUniqueInstanceIdentifierKeyName;
extern NSString *const kPreferencesUserIdentity;
