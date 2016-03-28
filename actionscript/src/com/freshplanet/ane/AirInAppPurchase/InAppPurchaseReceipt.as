//////////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2016 Fovea (http://fovea.cc)
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
    /** Proof of a transaction.
     *
     * The transaction could be either in progress or finished.
     */
    public class InAppPurchaseReceipt
    {
        public static const TYPE_APP_STORE:String = "AppStore";
        public static const TYPE_GOOGLE_PLAY:String = "GooglePlay";

        private var _type:String;
        private var _data:String;
        private var _productId:String;
        private var _signature:String; // android only
        private var _signedData:Object; // android only
        private var _transactionId:String;
        private var _transactionDate:String; // YYYY-MM-DD HH:MM:SS ±HHMM

        /** @private */
        public function InAppPurchaseReceipt(
            type:String,
            data:String,
            productId:String,
            signature:String,
            signedData:Object,
            transactionId:String,
            transactionDate:String) {
            _type = type;
            _data = data;
            _productId = productId;
            _signature = signature;
            _signedData = signedData;
            _transactionId = transactionId;
            _transactionDate = transactionDate;
        }

        /** @private */
        public function equals(other:InAppPurchaseReceipt):Boolean {
            return type == other.type
                && JSON.stringify(data) == JSON.stringify(other.data)
                && productId == other.productId;
        }

        /** The type of receipt.
         *
         * @see InAppPurchaseReceiptType */
        public function get type():String { return _type; }

        /** Platform dependent internal data of the receipt */
        public function get data():String { return _data; }

        /** Product identifier */
        public function get productId():String { return _productId; }

        /** Signature string */
        public function get signature():String { return _signature; }

        /** Signed data */
        public function get signedData():Object { return _signedData; }

        /** Transaction Identifier */
        public function get transactionId():String { return _transactionId; }

        /** Transaction Date (YYYY-MM-DD HH:MM:SS ±HHMM) */
        public function get transactionDate():String { return _transactionDate; }
    }
}

