package com.freshplanet.ane.AirInAppPurchase
{
    /** A list of products for purchase. */
    public class InAppPurchaseProducts
    {
        private var _array:Array = [];
        private var _object:Object = {};

        /** @private */
        public function InAppPurchaseProducts() {}

        /** Number of products in the list. */
        public function get length():int {
            return _array.length;
        }

        /** Return product at given index. */
        public function at(index:int):InAppPurchaseProduct {
            return _array[index];
        }

        /** Return an array of InAppPurchaseProduct.
         *
         * @see InAppPurchaseProduct */
        public function asArray():Array {
            return _array.concat();
        }

        /** Find a product from its identifier (or <i>undefined</i>) */
        public function getProduct(id:String):InAppPurchaseProduct {
            return _object[id];
        }

        /** @private
         *
         * Only InAppPurchase can initialize some content.
         * This forces users to use the <i>InAppPurchase.loadProduct</i> method. */
        internal function fromJSON(json:Object):void {
            for (var id:String in json) {
                if (json.hasOwnProperty(id)) {
                    try {
                        var p:InAppPurchaseProduct = InAppPurchaseProduct.fromJSON(json[id]);
                        _array.push(p);
                        _object[id] = p;
                    }
                    catch (e:Error) {
                        InAppPurchase.getInstance().log("Failed to import product info '" + id + "'");
                        InAppPurchase.getInstance().log(e.message);
                    }
                }
            }
        }

        /** Return a JSON representation of the products */
        public function toJSON():Object {
            var ret:Object = {};
            for (var id:String in _object) {
                if (_object.hasOwnProperty(id)) {
                    ret[id] = _object[id].toJSON();
                }
            }
            return ret;
        }
    }
}

