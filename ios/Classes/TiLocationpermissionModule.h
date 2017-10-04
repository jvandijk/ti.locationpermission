/**
 * ti.locationpermission
 *
 * Created by Your Name
 * Copyright (c) 2017 Your Company. All rights reserved.
 */

#import "TiModule.h"
#import <CoreLocation/CoreLocation.h>

NSString *const kTiGeolocationUsageDescriptionWhenInUse = @"NSLocationWhenInUseUsageDescription";
NSString *const kTiGeolocationUsageDescriptionAlways = @"NSLocationAlwaysUsageDescription";
NSString *const kTiGeolocationUsageDescriptionAlwaysAndWhenInUse = @"NSLocationAlwaysAndWhenInUseUsageDescription";

@interface TiLocationpermissionModule : TiModule <CLLocationManagerDelegate>
{
    CLLocationManager *locationPermissionManager;
    CLAuthorizationStatus oldStatus;
    KrollCallback *authorizationCallback;
}

@end
