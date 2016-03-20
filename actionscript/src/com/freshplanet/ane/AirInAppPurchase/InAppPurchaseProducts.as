package com.freshplanet.ane.AirInAppPurchase
{
    public class InAppPurchaseProducts
    {
        private var _array:Array = [];
        private var _object:Object = {};

        public function InAppPurchaseProducts() {}

        public function get length():int {
            return _array.length;
        }

        public function at(i:int):InAppPurchaseProduct {
            return _array[i];
        }

        public function asArray():Array {
            return _array.concat();
        }

        public function getProduct(id:String):InAppPurchaseProduct {
            return _object[id];
        }

        // Only InAppPurchase can initialize some content.
        // This forces users to use the `InAppPurchase.loadProductsInfo` method.
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

