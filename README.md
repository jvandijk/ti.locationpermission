# Titanium Location Permission 
This module gives you the possibility to shortcircuit the current iOS location permission from Titanium to properly support iOS 11 its new way of location permissions.

## Follow Guide

### Setup

1. Integrate the module into the `modules` folder and define them into the `tiapp.xml` file:

    ```xml
    <modules>
      <module platform="iphone" version="0.1.0">ti.locationpermission</module>
    </modules>
    ```

### Usage
1. Check if you have a location permission

    ```js
    var locationPermission = (OS_IOS) ? require('ti.locationpermission') : Ti.Geolocation;
    
    if (locationPermission.hasLocationPermissions(Ti.Geolocation.AUTHORIZATION_WHEN_IN_USE)) {
       alert('true');
    }
    ```

1. Request or upgrade location permission
   
    ```js
    var locationPermission = (OS_IOS) ? require('ti.locationpermission') : Ti.Geolocation;
    
    locationPermission.requestLocationPermissions(Ti.Geolocation.AUTHORIZATION_WHEN_IN_USE, function(e) {
        alert(e.success);
    });

    locationPermission.requestLocationPermissions(Ti.Geolocation.AUTHORIZATION_ALWAYS, function(e) {
        if (OS_IOS && e.authorizationStatus !== Ti.Geolocation.AUTHORIZATION_ALWAYS) {
            alert('Permission wasn\'t upgraded');
        }
    });
    ```

Cheers!

## Build yourself

### iOS

If you already have Titanium installed, skip the first 2 steps, if not let's install Titanium locally.

1. `brew install yarn --without-node` to install yarn without relying on a specific Node version
1. In the ios directory execute `yarn install`
1. Alter the `titanium.xcconfig` to build with the preferred SDK
1. To build the module execute `rm -rf build && ./node_modules/.bin/ti build -p ios --build-only`
