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

## Small example

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


Authors
------

The original ANE has been written by [Thibaut Crenn](https://github.com/titi-us) and [FreshPlanet Inc.](http://freshplanet.com).

The Fovea flavoured fork has been handled by [Jean-Christophe Hoelt](https://github.com/j3k0) for [Fovea](https://fovea.cc).

It is distributed under the [Apache Licence, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

