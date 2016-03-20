package com.freshplanet.ane.AirInAppPurchase
{
    public class InAppPurchaseProduct
    {
        private var _productId:String;
        private var _title:String;
        private var _description:String;
        private var _price:String;

        private var _value:Number;
        private var _priceCurrencyCode:String;
        private var _priceCurrencySymbol:String;

        public function InAppPurchaseProduct() {}

        // Only InAppPurchase can initialize some content.
        // This forces users to use the `InAppPurchase.loadProductsInfo` method.
        static internal function fromJSON(json:Object):InAppPurchaseProduct {
            var ret:InAppPurchaseProduct = new InAppPurchaseProduct();
            if (json.productId) ret._productId = json.productId;
            if (json.title) ret._title = json.title;
            if (json.description) ret._description = json.description;
            if (json.price) ret._price = json.price;
            if (json.price_currency_code) ret._priceCurrencyCode = json.price_currency_code;
            if (json.price_currency_symbol) ret._priceCurrencySymbol = json.price_currency_symbol;
            if (json.value) ret._value = json.value;
            return ret;
        }

        public function toJSON():Object {
            return {
                productId:_productId,
                title:_title,
                description:_description,
                price:_price,
                price_currency_code:_priceCurrencyCode,
                price_currency_symbol:_priceCurrencySymbol,
                value:value
            };
        }

        public function get productId():String { return _productId; }
        public function get title():String { return _title; }
        public function get description():String { return _description; }
        public function get price():String { return _price; }
        public function get priceCurrencyCode():String { return _priceCurrencyCode; }
        public function get priceCurrencySymbol():String { return _priceCurrencySymbol; }
        public function get value():Number { return _value; }
    }
}
