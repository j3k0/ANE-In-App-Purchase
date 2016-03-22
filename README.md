Air Native Extension for In App Purchases (iOS + Android)
======================================

This is an [Air native extension](http://www.adobe.com/devnet/air/native-extensions-for-air.html) for In-App Purchases.

This ANE supports In-App Purchase for both iOS and Android. It allows to handle consumable types of purchases.

It's a fork of freshplanet's ANE with significant improvements in terms of API. It aims to be:

 * Easier to use
 * Less error-prone
 * Self-documented

Those improvements have been drawn from my experience of developing the [https://github.com/j3k0/cordova-plugin-purchase](cordova in-app-purchase plugin).

Notes
---------

* Android implementation uses [In-app Billing Version 3](http://developer.android.com/google/play/billing/api.html).


Installation
---------

The ANE binary (InAppPurchase.ane) is located in the [releases page](https://github.com/j3k0/ANE-In-App-Purchase/releases). Add it to your application project's Build Path and make sure to package it with your app (more information [here](http://help.adobe.com/en_US/air/build/WS597e5dadb9cc1e0253f7d2fc1311b491071-8000.html)).

On Android:

 * you will need to add the following in your application descriptor:

```xml

<android>
    <manifestAdditions><![CDATA[
        <manifest android:installLocation="auto">

            <activity android:name="com.freshplanet.inapppurchase.activities.BillingActivity" android:theme="@android:style/Theme.Translucent.NoTitleBar.Fullscreen"></activity>

        </manifest>
    ]]></manifestAdditions>
</android>
```

Small example
--------

    var iap:InAppPurchase = InAppPurchase.getInstance();

    iap.addEventListener(InAppPurchaseEvent.PRODUCT_INFO_RECEIVED, function(event:InAppPurchaseEvent):void {
        trace("Products loaded");
        var product1:Object = event.data['cc.fovea.babygoo1'];
        // Do your magic to 
    });

    if (iap.isInAppPurchaseSupported) {
        iap.getProductsInfo(["cc.fovea.babygoo1", "cc.fovea.babygoo2"], ["cc.fovea.subscribe"]);
    }



Build script
---------

Should you need to edit the extension source code and/or recompile it, you will find an ant build script (build.xml) in the *build* folder:

```bash
cd /path/to/the/ane

# Setup build configuration
cd build
cp example.build.config build.config
# Edit build.config file to provide your machine-specific paths

# Build the ANE
ant
```

Notes
------

 * When you develop using Air there is no problem running in debug mode on your device and connecting to the debugger remotely from a connected device.
 * You can see debug and error messages from the ANE using LogCat. It's very easy to use and you can just run it from the command line when you have a connected device. There are some free LogCat tools with GUIs. Many times when there is an exception, you get nothing in Air but by checking the log you can see what's wrong.
 * The user that is used to test in app purchases on the Android device cannot be the user that is the administrator of the app. This is Google's limitation (they say this is because you cannot buy from yourself but come on Google... you solved harder problems!)
 * You can test with the static predefined products that Google have available but you still must consume them to test again! I did not find any way to consume from the admin console, so I suggest you implement consuming before your first test run. But really, the easiest way is just to define some test products and test users.

Authors
------

The original ANE has been written by [Thibaut Crenn](https://github.com/titi-us) and [FreshPlanet Inc.](http://freshplanet.com).

The Fovea flavoured fork has been handled by [Jean-Christophe Hoelt](https://github.com/j3k0) for [Fovea](https://fovea.cc).

It is distributed under the [Apache Licence, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

