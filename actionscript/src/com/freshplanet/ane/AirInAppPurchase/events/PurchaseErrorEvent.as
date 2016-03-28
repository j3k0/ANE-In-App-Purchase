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

package com.freshplanet.ane.AirInAppPurchase.events
{
    /** InAppPurchaseEvent.PURCHASE_ERROR */
	public class PurchaseErrorEvent extends InAppPurchaseEvent
	{
        /** Tried to make a purchase while InAppPurchase isn't supported */
        public static const IN_APP_PURCHASE_NOT_SUPPORTED:int = 1;

        /** Tried to make a subscription while this isn't supported */
        public static const MAKE_SUBSCRIPTION_NOT_SUPPORTED:int = 2;

        /** Platform failed to perform the purchase */
        public static const PLATFORM_ERROR:int = 3;

        public function codeString():String {
            switch(code) {
                case IN_APP_PURCHASE_NOT_SUPPORTED: return "IN_APP_PURCHASE_NOT_SUPPORTED";
                case MAKE_SUBSCRIPTION_NOT_SUPPORTED: return "MAKE_SUBSCRIPTION_NOT_SUPPORTED";
                case PLATFORM_ERROR: return "PLATFORM_ERROR";
            }
            return "UNKNOWN";
        }

        /** Error code. See the constants defined in this class for details. */
        public function get code():int {
            return data.code;
        }

        /** Description of the error in plain english. */
        public function get message():String {
            return data.message;
        }

		public function PurchaseErrorEvent(code:int, message:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(InAppPurchaseEvent.PURCHASE_ERROR, {
                code:code,
                message:message
            }, bubbles, cancelable);
		}
	}
}
