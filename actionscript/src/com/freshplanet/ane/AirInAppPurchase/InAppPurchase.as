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

    public class InAppPurchase extends EventDispatcher
    {
        private static var _instance:InAppPurchase;

        public var debug:Boolean = true;
        internal function log(...args):void {
            if (debug) {
                args.unshift('[AirInAppPurchase] ');
                trace.apply(null, args);
            }
        }
        
        private var extCtx:*;

        // Convenient access to the InAppPurchaseProducts
        private var _products:InAppPurchaseProducts = new InAppPurchaseProducts();
        public function get products():InAppPurchaseProducts { return _products; }

        // Pending transactions
        private var _pendingReceipts:Vector.<InAppPurchaseReceipt> = new Vector.<InAppPurchaseReceipt>();
        
        public function InAppPurchase() {
            if (_instance)
                throw Error( 'This is a singleton, use getInstance(), do not call the constructor directly');

            log("v0.1.0");
            if (this.isInAppPurchaseSupported) {
                extCtx = ExtensionContext.createExtensionContext("com.freshplanet.AirInAppPurchase", null);
                if (extCtx != null)
                    extCtx.addEventListener(StatusEvent.STATUS, onStatus);
                else
                    log('extCtx is null.');
            }
        }
 
        public static function getInstance():InAppPurchase {
            if (!_instance)
                _instance = new InAppPurchase();
            return _instance;
        }

        public function init(googlePlayKey:String, debug:Boolean = false):void {
            this.debug = debug;
            if (this.isInAppPurchaseSupported) {
                log("Initializing library");
                extCtx.call("initLib", googlePlayKey, debug);
            }
        }
        
        // Internal note: we could only require the productId here,
        // however ios (at least) requires the product to have been loaded before
        // initiating the purchase.
        // Presenting this API forces the user to do so.
        public function makePurchase(product:InAppPurchaseProduct):void
        {
            if (this.isInAppPurchaseSupported) {
                log("Purchasing", product.productId);
                extCtx.call("makePurchase", product.productId);
            } else {
                this.dispatchEvent(new PurchaseErrorEvent(
                    PurchaseErrorEvent.IN_APP_PURCHASE_NOT_SUPPORTED,
                    "InAppPurchase not supported"));
            }
        }
        
        // Once a purchased has been approved, we can finish it.
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
        
        public function loadProducts(productsId:Array, subscriptionIds:Array = null):void
        {
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
        
        
        public function userCanMakeAPurchase():void 
        {
            if (this.isInAppPurchaseSupported)
            {
                log("Checking if user can make a purchase");
                extCtx.call("userCanMakeAPurchase");
            } else
            {
                this.dispatchEvent(new InAppPurchaseEvent(InAppPurchaseEvent.PURCHASE_DISABLED));
            }
        }
            
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


        public function stop():void
        {
            if (Capabilities.manufacturer.indexOf('Android') > -1)
            {
                log("Stopping library");
                extCtx.call("stopLib");
            }
        }

        
        public function get isInAppPurchaseSupported():Boolean
        {
            var value:Boolean = Capabilities.manufacturer.indexOf('iOS') > -1 || Capabilities.manufacturer.indexOf('Android') > -1;
            if (!value) {
                log("In-App Purchase is not supported");
            }
            return value;
        }
        
        private function onStatus(event:StatusEvent):void
        {
            var dataString:String = event.level;
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
            switch(event.code)
            {
                case "DEBUG":
                    log("[NATIVE]", dataString);
                    break;
                case "PRODUCTS_LOADED":
                    _products.fromJSON(data.details);
                    e = new ProductsLoadedEvent(_products);
                    break;
                case "PRODUCTS_LOAD_ERROR":
                    e = new ProductsLoadErrorEvent(data);
                    break;
                case "PURCHASE_APPROVED":
                    receipt = new InAppPurchaseReceipt(data.receiptType, data.receipt, data.productId, data.signature, data.signedData);
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
