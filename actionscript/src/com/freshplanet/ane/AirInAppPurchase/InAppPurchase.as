//////////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2012 Freshplanet (http://freshplanet.com | opensource@freshplanet.com)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//////////////////////////////////////////////////////////////////////////////////////

package com.freshplanet.ane.AirInAppPurchase
{
    import flash.events.EventDispatcher;
    import flash.events.StatusEvent;
    import flash.external.ExtensionContext;
    import flash.system.Capabilities;
    import com.freshplanet.ane.AirInAppPurchase.events.*;

    /** AirInAppPurchase's main class */
    public class InAppPurchase extends EventDispatcher
    {
        private static var _instance:InAppPurchase;

        /** Whether to display debug on the console or not */
        public var debug:Boolean = true;

        /** @private
         * Log stuff to the console */
        internal function log(...args):void {
            if (debug) {
                args.unshift('[AirInAppPurchase] ');
                trace.apply(null, args);
            }
        }

        /** ANE's ExtensionContext */
        private var extCtx:*;

        /** Loaded InAppPurchaseProducts */
        private var _products:InAppPurchaseProducts = new InAppPurchaseProducts();

        /** Pending transactions */
        private var _pendingReceipts:Vector.<InAppPurchaseReceipt> = new Vector.<InAppPurchaseReceipt>();

        /** The loaded InAppPurchaseProducts.
        *
        * The ANE maintains a map <code>productIdentifier</code> ⇒ <code>InAppPurchaseProduct</code>.
        *
        * This map is filled when <code>PRODUCTS_LOADED</code> is triggered (it's empty before that).
        *
        * After the <code>PRODUCTS_LOADED</code> event, you can access the details of the products using <code>iap.products.getProduct('my-id')</code>.
        *
        * @see com.freshplanet.ane.AirInAppPurchase.InAppPurchaseProducts
        * @see com.freshplanet.ane.AirInAppPurchase.events.ProductsLoadedEvent
        */
        public function get products():InAppPurchaseProducts { return _products; }

        /** Constructor. Use InAppPurchase.getInstance() instead! */
        public function InAppPurchase() {
            if (_instance)
                throw Error( 'This is a singleton, use getInstance(), do not call the constructor directly');

            log("v1.0.0");
            if (this.isInAppPurchaseSupported) {
                extCtx = ExtensionContext.createExtensionContext("com.freshplanet.AirInAppPurchase", null);
                if (extCtx != null)
                    extCtx.addEventListener(StatusEvent.STATUS, onStatus);
                else
                    log('extCtx is null.');
            }
        }

        /** Return the singleton InAppPurchase instance.
         *
         * Example: <pre><code>
         * var iap:InAppPurchase = InAppPurchase.getInstance();
         * </code></pre>
         */
        public static function getInstance():InAppPurchase {
            if (!_instance)
                _instance = new InAppPurchase();
            return _instance;
        }

        /** Initialize the library.
         *
         * @param googlePlayKey The GOOGLE_PLAY_LICENSE_KEY. It can be found in the Google Play developer console under the Services and APIs section.
         * @param debug Activate logging of debug information
         *
         * <p>NOTE: The initialization process is asynchronous, so make sure you wait enough time for the initialization to complete. (yes, it's ugly)</p>
         *
         * <p>Example:</p><pre><code>
         * iap.initialize("S0M3B4S364D4t4Fr0mG00gL3", true);
         * </code></pre>
         */
        public function initialize(googlePlayKey:String, debug:Boolean = false):void {
            this.debug = debug;
            if (this.isInAppPurchaseSupported) {
                // TODO: add a LIBRARY_INITIALIZED event
                log("Initializing library");
                extCtx.call("initLib", googlePlayKey, debug);
            }
        }

        /** Initiate a purchase request.
         *
         * @param product The product to purchase.
         * Example: <pre><code>
         * iap.makePurchase(iap.products.getProduct('cc.fovea.babygoo1'));
         * </code></pre>
         *
         * You should expect <code>PURCHASE_APPROVED</code> or <code>PURCHASE_ERROR</code> to be triggered.
         *
         * @see com.freshplanet.ane.AirInAppPurchase.events.PurchaseApprovedEvent
         * @see com.freshplanet.ane.AirInAppPurchase.events.PurchaseErrorEvent
         */
        public function requestPurchase(product:InAppPurchaseProduct):void
        {
            // Internal note: we could only require the productId here,
            // however ios (at least) requires the product to have been loaded before
            // initiating the purchase.
            // Presenting this API forces the user to do so.
            if (this.isInAppPurchaseSupported) {
                log("Purchasing", product.productId);
                extCtx.call("makePurchase", product.productId);
            } else {
                this.dispatchEvent(new PurchaseErrorEvent(
                    PurchaseErrorEvent.IN_APP_PURCHASE_NOT_SUPPORTED,
                    "InAppPurchase not supported"));
            }
        }

        /** Finalize a purchase.
         *
         * Once a purchased has been approved and the content delivered to the user,
         * we can finish the purchase.
         *
         * @param receipt The transaction receipt associated with the purchase.
         */
        public function finishPurchase(receipt:InAppPurchaseReceipt):void
        {
            if (this.isInAppPurchaseSupported)
            {
                log("Removing receipt from queue", receipt.productId, receipt.data || receipt.signedData);
                extCtx.call("removePurchaseFromQueue", receipt.productId, receipt.data || receipt.signedData);

                var found:Boolean = false;
                _pendingReceipts = _pendingReceipts.filter(function(pending:InAppPurchaseReceipt, index:int, array:*):Boolean {
                    var equals:Boolean = receipt.equals(pending);
                    found = found || equals;
                    return !equals;
                });

                if (!found) {
                    dispatchEvent(new PurchaseFinishErrorEvent(
                        PurchaseFinishErrorEvent.TRANSACTION_NOT_FOUND,
                        "No transaction to finish for product " + receipt.productId));
                }
            }
        }

        /** Load product information from the platform.
         *
         * @param productsId The list of identifiers of the products
         * to be loaded, as defined in your platform's dashboard \
         * (iTunesConnect or Google Play publisher console).
         *
         * The ANE differenciates between two types of purchases:
         * consumable and subscriptions.
         * <pre><code>
         * iap.loadProducts(["cc.fovea.babygoo1", "cc.fovea.babygoo2"], ["cc.fovea.subscribe"]);
         * </code></pre>
         *
         * You should expect <code>PRODUCTS_LOADED</code> and/or <code>PRODUCTS_LOAD_ERROR</code> events to be triggered,
         * so you'd better setup your listener upfront!
         *
         * Note that it's possible that both events are triggered,
         * in the case where some products are valids and some others
         * are not.
         *
         * @see com.freshplanet.ane.AirInAppPurchase.events.ProductsLoadedEvent
         * @see com.freshplanet.ane.AirInAppPurchase.events.ProductsLoadErrorEvent
         */
        public function loadProducts(token:InAppPurchaseToken, productsId:Array, subscriptionIds:Array = null):void
        {
            if (!token) {
                throw new Error("InAppPurchase.loadProducts() -> missing InAppPurchaseToken");
            }

            if (!subscriptionIds)
                subscriptionIds = [];

            if (this.isInAppPurchaseSupported) {
                log("Loading Products Info");
                extCtx.call("getProductsInfo", productsId, subscriptionIds);
            }
            else {
                this.dispatchEvent(new ProductsLoadErrorEvent(productsId.concat(subscriptionIds)));
            }
        }

        /** Returns true if the user is allowed and able to make purchases */
        public function userCanMakeAPurchase(token:InAppPurchaseToken):void
        {
            if (!token) {
                throw new Error("InAppPurchase.userCanMakeAPurchase() -> missing InAppPurchaseToken");
            }

            if (this.isInAppPurchaseSupported)
            {
                log("Checking if user can make a purchase");
                extCtx.call("userCanMakeAPurchase");
            } else
            {
                this.dispatchEvent(new InAppPurchaseEvent(InAppPurchaseEvent.PURCHASE_DISABLED));
            }
        }

        /*
        public function userCanMakeASubscription():void
        {
            if (Capabilities.manufacturer.indexOf('Android') > -1)
            {
                log("Checking if user can make a subscription");
                extCtx.call("userCanMakeASubscription");
            } else
            {
                this.dispatchEvent(new InAppPurchaseEvent(InAppPurchaseEvent.PURCHASE_DISABLED));
            }
        }

        public function makeSubscription(product:InAppPurchaseProduct):void
        {
            if (Capabilities.manufacturer.indexOf('Android') > -1) {
                log("Making subscription");
                extCtx.call("makeSubscription", product.productId);
            }
            else {
                this.dispatchEvent(new PurchaseErrorEvent(
                    PurchaseErrorEvent.MAKE_SUBSCRIPTION_NOT_SUPPORTED,
                    "InAppPurchase.makeSubscription is only supported on Android"));
            }
        }
        */


        /*
        TODO
        public function restoreTransactions():void
        {
            if (Capabilities.manufacturer.indexOf('Android') > -1)
            {
                extCtx.call("restoreTransaction");
            }
            else if (Capabilities.manufacturer.indexOf("iOS") > -1)
            {
                // TODO: This isn't how it should be implemented...
                dispatchEvent(new RestoreInfoReceivedEvent(_pendingReceipts));
            }
        }
        */

        /** Stop the ANE */
        public function stop(token:InAppPurchaseToken):void
        {
            if (!token) {
                throw new Error("InAppPurchase.stop() -> missing InAppPurchaseToken");
            }

            if (Capabilities.manufacturer.indexOf('Android') > -1)
            {
                log("Stopping library");
                extCtx.call("stopLib");
            }
        }

        /** Returns true if the platform supports In-App Purchases.
         *
         * Example: <pre><code>
         * if (iap.isInAppPurchaseSupported)
         *   // Yay! We can use In-App Purchases!
         *   // Let's make tons of money
         * </code></pre>
         */
        public function get isInAppPurchaseSupported():Boolean
        {
            var value:Boolean = Capabilities.manufacturer.indexOf('iOS') > -1 || Capabilities.manufacturer.indexOf('Android') > -1;
            if (!value) {
                log("In-App Purchase is not supported");
            }
            return value;
        }

        private function approvePurchase(json:Object):void {
            //
            // - Android purchases looks like this:
            // ------------------------------------
            //
            //  "productId":"com.triominos.silver.small",
            //  "receipt":{
            //      "signedData":"stringified-json. see below",
            //      "signature":"bAsE64sTuFf=="
            //  },
            //  "receiptType":"GooglePlay"
            //
            // signedData JSON.parsed:
            //
            //  "orderId":"GPA.4242-4242-4242-42424",
            //  "packageName":"air.nl.goliathgames.triominos",
            //  "productId":"com.triominos.silver.small",
            //  "purchaseTime":1459577352266,
            //  "purchaseState":0,
            //  "purchaseToken":"bAsE64oRsOmEtHiNg"
            //
            // - iOS purchases looks like this:
            // --------------------------------
            //
            //  "receiptType":"AppleAppStore",
            //  "receipt":"bAsE64oRsOmEtHiNg",
            //  "productId":"com.triominos.silver.small",
            //  "transactionId":"100012301",
            //  "transactionDate":1459577352266
            //
            var receipt:InAppPurchaseReceipt;
            if (json && json.receiptType == InAppPurchaseReceiptType.GOOGLE_PLAY) {
                var data:Object = {};
                try {
                    data = JSON.parse(json.receipt.signedData);
                }
                catch (err:Error) {
                    // Can't parse signed data... Probably shouldn't happen,
                    // but it's not so important.
                }
                receipt = new InAppPurchaseReceipt(
                    json.receiptType,
                    '',
                    json.productId,
                    json.receipt.signature || null,
                    json.receipt.signedData || null,
                    data.orderId,
                    data.purchaseTime);
            }
            else if (json && json.receiptType == InAppPurchaseReceiptType.APPLE_APP_STORE) {
                receipt = new InAppPurchaseReceipt(
                    json.receiptType,
                    json.receipt,
                    json.productId,
                    null,
                    null,
                    json.transactionId,
                    json.transactionDate);
            }

            if (receipt) {
                _pendingReceipts.push(receipt);
                dispatchEvent(new PurchaseApprovedEvent(receipt));
            }
        }

        private function approvePurchases(array:Array):void {
            if (!array || !array.length) return;
            for (var i:int = 0; i < array.length; ++i)
                approvePurchase(array[i]);
        }

        /** Handler of events triggered by the native code. */
        private function onStatus(event:StatusEvent):void
        {
            var dataString:String = event.level;
            if (event.code == 'DEBUG') {
                log("[NATIVE]", dataString);
                return;
            }

            log(event.code);
            log(dataString);

            var data:*;
            try {
                data = JSON.parse(dataString);
            }
            catch(err:Error) {
                log("(isn't json)");
            }

            switch (event.code) {
                case "INIT_FINISHED":
                    dispatchEvent(new InitFinishedEvent());
                    break;
                case "INIT_ERROR":
                    dispatchEvent(new InitErrorEvent(dataString));
                    break;
                case "PRODUCTS_LOADED":
                    _products.fromJSON(data.details);
                    dispatchEvent(new ProductsLoadedEvent(_products));
                    approvePurchases(data.purchases);
                    break;
                case "PRODUCTS_LOAD_ERROR":
                    dispatchEvent(new ProductsLoadErrorEvent(data));
                    break;
                case "PURCHASE_APPROVED":
                    approvePurchase(data);
                    break;
                case "PURCHASE_ERROR":
                    dispatchEvent(new PurchaseErrorEvent(PurchaseErrorEvent.PLATFORM_ERROR, dataString));
                    break;
                case "PURCHASE_ENABLED":
                    dispatchEvent(new InAppPurchaseEvent(InAppPurchaseEvent.PURCHASE_ENABLED));
                    break;
                case "PURCHASE_DISABLED":
                    dispatchEvent(new InAppPurchaseEvent(InAppPurchaseEvent.PURCHASE_DISABLED));
                    break;
                /** TODO:
                case "SUBSCRIPTION_ENABLED":
                    e = new SubscriptionEnabledEvent(data);
                    break;
                case "SUBSCRIPTION_DISABLED":
                    e = new SubscriptionDisabledEvent(data);
                    break;
                case "RESTORE_INFO_RECEIVED":
                    e = new RestoreInfoReceivedEvent(data);
                    break;
                */
                default:
            }
        }
    }
}

/*
 Example payloads
 ----------------

 PRODUCTS_LOADED

 {
    "purchases": [{
        "productId":"com.triominos.silver.small",
        "receipt":{
            "signedData":"{\"orderId\":\"GPA.1390-6907-9086-01962\",\"packageName\":\"air.nl.goliathgames.triominos\",\"productId\":\"com.triominos.silver.small\",\"purchaseTime\":1459577352266,\"purchaseState\":0,\"purchaseToken\":\"necmeibbddipnglcldamkffm.AO-J1OwLxpqrntiRrneewF312BWxGqh9NGyZDs8q2KwSNDpGlpynyJn6QUvsL7hD0XcfEOgiPpxaqUKSZqeC1uSwLSSUFrwiTrRzARAo4Nbl5F36Q3KhA9HtY5VOZr70n7t8O3HNhLvEt94nTMzKNYZ875xa6axDCg\"}",
            "signature":"b+h12628gpw6\/8NMORZ+eWddTM3g5AzpLlvQOFvrXsLkjBh5Z0JzrGPHMhgysgCmDaHeKhueHr6dSp5UmFK1umkj1oH7vem6oqRD5+QPMZOe50NpBcC6Gd7SeQFzIgke8V\/GgptEyUjuSz7mYNvI99wqXZ5d66lTdMMzGAa5GPDTJyWRkY9O5zaoGV760QeQgGx5gDOzXfwgT4zNC\/\/Sh5jYfipI6HjM1DIa55T7A0OtVqF0s4W9l23mh1YhkJ1+ZiCmJZYv4+Zs1pXnqmR5\/R6+EosRkHBDyvT\/Fpj4BfZiFItlcmyfngSOzNbDp\/bxL\/lPUQcMzsoTsSnWGeX8Aw=="
        },
        "receiptType":"GooglePlay"
    }],
    "details":{
        "com.triominos.gold.small": {
            "productId":"com.triominos.gold.small",
            "type":"inapp",
            "price":"LBP1,500",
            "price_amount_micros":1500000000,
            "price_currency_code":"LBP",
            "title":"25 Gold (Triominos)",
            "description":"A small pile of gold coins"
        },
        "com.triominos.silver.medium": {
            "productId":"com.triominos.silver.medium",
            "type":"inapp",
            "price":"LBP2,782",
            "price_amount_micros":2782000000,
            "price_currency_code":"LBP",
            "title":"300 Silver (Triominos)",
            "description":"A large pile of silver coins"
        }
    }
}
*/
