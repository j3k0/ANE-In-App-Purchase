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

            log("v0.2.0");
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
                log("Removing receipt from queue", receipt.productId, receipt.data);
                extCtx.call("removePurchaseFromQueue", receipt.productId, receipt.data);

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

            var receipt:InAppPurchaseReceipt;
            var e:InAppPurchaseEvent;
            switch (event.code) {
                case "INIT_FINISHED":
                    e = new InitFinishedEvent();
                    break;
                case "INIT_ERROR":
                    e = new InitErrorEvent(dataString);
                    break;
                case "PRODUCTS_LOADED":
                    _products.fromJSON(data.details);
                    e = new ProductsLoadedEvent(_products);
                    break;
                case "PRODUCTS_LOAD_ERROR":
                    e = new ProductsLoadErrorEvent(data);
                    break;
                case "PURCHASE_APPROVED":
                    receipt = new InAppPurchaseReceipt(data.receiptType, data.receipt, data.productId, data.signature, data.signedData, data.transactionId, data.transactionDate);
                    _pendingReceipts.push(receipt);
                    e = new PurchaseApprovedEvent(receipt);
                    break;
                case "PURCHASE_ERROR":
                    e = new PurchaseErrorEvent(PurchaseErrorEvent.PLATFORM_ERROR, dataString);
                    break;
                case "PURCHASE_ENABLED":
                    e = new InAppPurchaseEvent(InAppPurchaseEvent.PURCHASE_ENABLED);
                    break;
                case "PURCHASE_DISABLED":
                    e = new InAppPurchaseEvent(InAppPurchaseEvent.PURCHASE_DISABLED);
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
            if (e) {
                this.dispatchEvent(e);
            }
        }
    }
}
