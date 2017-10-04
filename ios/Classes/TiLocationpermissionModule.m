/**
 * ti.locationpermission
 *
 * Created by Your Name
 * Copyright (c) 2017 Your Company. All rights reserved.
 */

#import "TiLocationpermissionModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

@implementation TiLocationpermissionModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"1fc6c195-8d20-4733-af97-5d1755a9387a";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"ti.locationpermission";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];

	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably

	// you *must* call the superclass
	[super shutdown:sender];
}

- (CLLocationManager *)locationPermissionManager
{
    // if we don't have an instance, create it
    if (locationPermissionManager == nil) {
        locationPermissionManager = [[CLLocationManager alloc] init];
        locationPermissionManager.delegate = self;
    }
    return locationPermissionManager;
}

#pragma mark Cleanup

-(void)dealloc
{
    RELEASE_TO_NIL(locationPermissionManager);
	// release any resources that have been retained by the module
	[super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

- (void)executeAndReleaseCallbackWithCode:(NSInteger)code andMessage:(NSString *)message
{
    if (authorizationCallback == nil) {
        return;
    }

    NSMutableDictionary *propertiesDict = [TiUtils dictionaryWithCode:code message:message];
    NSArray *invocationArray = [[NSArray alloc] initWithObjects:&propertiesDict count:1];
    [authorizationCallback call:invocationArray thisObject:self];

    [invocationArray release];
    RELEASE_TO_NIL(message);
    RELEASE_TO_NIL(authorizationCallback);
    RELEASE_TO_NIL(locationPermissionManager);
}

#pragma Public APIs

- (NSNumber *)hasLocationPermissions:(id)args
{
    BOOL locationServicesEnabled = [CLLocationManager locationServicesEnabled];
    CLAuthorizationStatus currentPermissionLevel = [CLLocationManager authorizationStatus];
    oldStatus = currentPermissionLevel;
    id value = [args objectAtIndex:0];
    ENSURE_TYPE(value, NSNumber);
    CLAuthorizationStatus requestedPermissionLevel = [TiUtils intValue:value];
    return NUMBOOL(locationServicesEnabled && currentPermissionLevel == requestedPermissionLevel);
}

- (void)requestLocationPermissions:(id)args
{
    id value = [args objectAtIndex:0];
    ENSURE_TYPE(value, NSNumber);

    // Store the authorization callback for later usage
    if ([args count] == 2) {
        RELEASE_TO_NIL(authorizationCallback);
        ENSURE_TYPE([args objectAtIndex:1], KrollCallback);
        authorizationCallback = [[args objectAtIndex:1] retain];
    }

    CLAuthorizationStatus requested = [TiUtils intValue:value];
    CLAuthorizationStatus currentPermissionLevel = [CLLocationManager authorizationStatus];
    oldStatus = currentPermissionLevel;

    if (currentPermissionLevel == kCLAuthorizationStatusAuthorizedWhenInUse && requested == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self executeAndReleaseCallbackWithCode:0 andMessage:nil];
        return;
    } else if (currentPermissionLevel == kCLAuthorizationStatusAuthorizedAlways && requested == kCLAuthorizationStatusAuthorizedAlways) {
        [self executeAndReleaseCallbackWithCode:0 andMessage:nil];
        return;
    } else if (currentPermissionLevel == kCLAuthorizationStatusDenied) {
        NSString *message = @"The user denied access to use location services.";
        [self executeAndReleaseCallbackWithCode:1 andMessage:message];
        return;
    }

    NSString *errorMessage = nil;

    if (requested == kCLAuthorizationStatusAuthorizedWhenInUse) {
        NSLog(@"[DEBUG] %@", @"Requesting when in use authorize");
        if ([[NSBundle mainBundle] objectForInfoDictionaryKey:kTiGeolocationUsageDescriptionWhenInUse]) {
            if (currentPermissionLevel == kCLAuthorizationStatusAuthorizedAlways) {
                errorMessage = @"Cannot change already granted permission from AUTHORIZATION_ALWAYS to AUTHORIZATION_WHEN_IN_USE";
            } else {
                NSLog(@"[DEBUG] %@", @"Requesting when in use authorize with key set");
                TiThreadPerformOnMainThread(^{
                    [[self locationPermissionManager] requestWhenInUseAuthorization];
                },
                                            NO);
            }
        } else {
            errorMessage = [NSString stringWithFormat:@"The %@ key must be defined in your tiapp.xml in order to request this permission", kTiGeolocationUsageDescriptionWhenInUse];
        }
        return;
    }
    if (requested == kCLAuthorizationStatusAuthorizedAlways) {
        NSLog(@"[DEBUG] %@", @"Requesting always authorize");
        if ([[NSBundle mainBundle] objectForInfoDictionaryKey:kTiGeolocationUsageDescriptionAlways] || [[NSBundle mainBundle] objectForInfoDictionaryKey:kTiGeolocationUsageDescriptionAlwaysAndWhenInUse]) {
                NSLog(@"[DEBUG] %@", @"Requesting always authorize with key set");
                TiThreadPerformOnMainThread(^{
                    [[self locationPermissionManager] requestAlwaysAuthorization];
                },
                                            NO);
        } else {
            errorMessage = [NSString stringWithFormat:@"The %@ or %@ key must be defined in your tiapp.xml in order to request this permission.",
                            kTiGeolocationUsageDescriptionAlways, kTiGeolocationUsageDescriptionAlwaysAndWhenInUse];
        }
        return;
    }

    if (errorMessage != nil) {
        NSLog(@"[ERROR] %@", errorMessage);
        [self executeAndReleaseCallbackWithCode:(errorMessage == nil) ? 0 : 1 andMessage:errorMessage];
        RELEASE_TO_NIL(errorMessage);
    }
}

#pragma mark Delegates

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"[DEBUG] %@ : %d", @"Auth changed to", status);

    // The new callback for android parity used inside Ti.Geolocation.requestLocationPermissions()
    if (authorizationCallback != nil && status != kCLAuthorizationStatusNotDetermined && status != oldStatus) {

        int code = 0;
        NSString *errorStr = nil;

        switch (status) {
            case kCLAuthorizationStatusAuthorizedAlways:
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                break;
            default:
                code = 1;
                errorStr = @"The user denied access to use location services.";
        }

        TiThreadPerformOnMainThread(^{
            NSMutableDictionary *propertiesDict = [TiUtils dictionaryWithCode:code message:errorStr];
            [propertiesDict setObject:NUMINT([CLLocationManager authorizationStatus]) forKey:@"authorizationStatus"];
            KrollEvent *invocationEvent = [[KrollEvent alloc] initWithCallback:authorizationCallback eventObject:propertiesDict thisObject:self];
            [[authorizationCallback context] enqueue:invocationEvent];
            RELEASE_TO_NIL(invocationEvent);
        },
                                    YES);

        RELEASE_TO_NIL(authorizationCallback);
        RELEASE_TO_NIL(errorStr);
        RELEASE_TO_NIL(locationPermissionManager);

        oldStatus = status;
    }
}

@end
