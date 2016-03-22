package com.freshplanet.ane.AirInAppPurchase
{
    /** Types of transaction receipt */
    public class InAppPurchaseReceiptType {

        /** Receipt from the Apple AppStore */
        // value also found in:
        //  - ios/AirInAppPurchase/AirInAppPurchase.m
        public static const APPLE_APP_STORE:String = "AppleAppStore";

        /** Receipt from Google Play */
        // value also found in:
        //  - android/src/com/freshplanet/inapppurchase/activities/BillingActivity.java
        //  - android/src/com/example/android/trivialdrivesample/util/Inventory.java
        public static const GOOGLE_PLAY:String = "GooglePlay";
    }
}
