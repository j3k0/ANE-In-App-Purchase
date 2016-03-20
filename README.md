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

## API Documentation

### Class InAppPurchase

#### (static) getInstance():InAppPurchase

Access the singleton InAppPurchase instance.

    var iap:InAppPurchase = InAppPurchase.getInstance();

#### init(googlePlayKey:String, debug:Boolean = false):void

Initialize the ANE.

    iap.init("S0M3B4S364D4t4Fr0mG00gL3", true);

#### isInAppPurchaseSupported : Boolean (read-only)

    if (iap.isInAppPurchaseSupported)
        // Yay! We can use In-App Purchases!
        // Let's make tons of money


#### loadProducts(productsId:Array, subscriptionIds:Array):void

Pass the array of product identifiers, as defined in your platform's dashboard (iTunesConnect or Google Play publisher console).

The ANE differenciates between two types of purchases: consumable and subscriptions.

    iap.loadProducts(["cc.fovea.babygoo1", "cc.fovea.babygoo2"], ["cc.fovea.subscribe"]);

You should expect `PRODUCT_INFO_RECEIVED` and/or `PRODUCT_INFO_ERROR` events to be triggered, so you'd better setup your listener upfront!

See [#Events](Events) for details.

Note that it's possible that both events are triggered, in the case where some products are valids and some others are not.

#### products:InAppPurchaseProducts

The ANE maintains a map `productIdentifier` &rArr; [#Class-InAppPurchaseProduct](InAppPurchaseProduct).

This map is filled when `PRODUCT_INFO_RECEIVED` is triggered (it's empty before that).

After the `PRODUCT_INFO_RECEIVED` event, you can access the details of the products using `iap.getProduct('my-id')`.

See [#Class-InAppPurchaseProducts](InAppPurchaseProducts).

#### makePurchase(product:InAppPurchaseProduct):void

Initiate the purchase process.

    iap.makePurchase(iap.getProduct('cc.fovea.babygoo1'));

You should expect `PURCHASE_APPROVED` or `PURCHASE_ERROR` to be triggered. See [#Events](Events) for details.

#### makeSubscription(product:InAppPurchaseProduct):void

#### removePurchaseFromQueue(productId:String, receipt:String):void

#### restoreTransactions():void

#### stop():void

#### userCanMakeAPurchase():void

#### userCanMakeASubscription():void

### Class InAppPurchaseProduct

#### productId:String

#### title:String

#### description:String

#### price:String

#### priceCurrencyCode:String

#### priceCurrencySymbol:String

#### value:Number

### Class InAppPurchaseProducts

A collection of InAppPurchaseProduct.

Self explainatory interface:
 * getProduct(productId:String):InAppPurchaseProduct
 * length:int
 * at(index:int):InAppPurchaseProduct

### Events

Defined in `InAppPurchaseEvent`.

 * `InAppPurchaseEvent.PRODUCT_INFO_ERROR`
   * Failed to load product information with `getProductsInfo()`.
   * The event is a [#ProductInfoErrorEvent](ProductInfoErrorEvent).

 * `InAppPurchaseEvent.PRODUCT_INFO_RECEIVED` -
   * Product information has be loaded by `getProductsInfo()`.
   * __iOS__: `event.data` contains a map `productId` &rArr; [#Class-InAppPurchaseProduct](InAppPurchaseProduct).

 * `InAppPurchaseEvent.PURCHASE_DISABLED`
 * `InAppPurchaseEvent.PURCHASE_ENABLED`
 * `InAppPurchaseEvent.PURCHASE_ERROR`
 * `InAppPurchaseEvent.PURCHASE_APPROVED`
 * `InAppPurchaseEvent.PURCHASE_FINISHED`
 * `InAppPurchaseEvent.RESTORE_INFO_RECEIVED`
 * `InAppPurchaseEvent.SUBSCRIPTION_DISABLED`
 * `InAppPurchaseEvent.SUBSCRIPTION_ENABLED`

### ProductInfoErrorEvent

 * extends InAppPurchaseEvent
 * __iOS__: `event.productIds` contains the array of Ids that failed to load.

### PurchaseErrorEvent

 * extends InAppPurchaseEvent
 * `event.message` contains the description of the error in plain english.
 * `event.code` contains the error code.

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

