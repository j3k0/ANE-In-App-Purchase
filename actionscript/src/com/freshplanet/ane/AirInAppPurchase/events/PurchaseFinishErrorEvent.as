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
    /** InAppPurchaseEvent.FINISH_ERROR */
	public class PurchaseFinishErrorEvent extends InAppPurchaseEvent
	{
        /** Tried to make a purchase while InAppPurchase isn't supported */
        public static const TRANSACTION_NOT_FOUND:int = 1;

        /** Error code */
        public function get code():int {
            return data.code;
        }

        /** Error message */
        public function get message():String {
            return data.message;
        }

		public function PurchaseFinishErrorEvent(code:int, message:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(InAppPurchaseEvent.PURCHASE_FINISH_ERROR, {
                code:code,
                message:message
            }, bubbles, cancelable);
		}
	}
}
