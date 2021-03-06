package com.freshplanet.ane.AirInAppPurchase
{
    /** A product for purchase */
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

        /** @private
         *
         * Only InAppPurchase can initialize some content.
         * This forces users to use the `InAppPurchase.loadProducts` method. */
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

        /** Return a JSON representation of the product */
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

        /** Product identifier */
        public function get productId():String { return _productId; }

        /** Localized title */
        public function get title():String { return _title; }

        /** Localized description */
        public function get description():String { return _description; }

        /** Localized price */
        public function get price():String { return _price; }

        /** Currency code */
        public function get priceCurrencyCode():String { return _priceCurrencyCode; }

        /** Currency symbol */
        public function get priceCurrencySymbol():String { return _priceCurrencySymbol; }

        /** Amount of money asked for for this product */
        public function get value():Number { return _value; }
    }
}
