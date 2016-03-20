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
    /** InAppPurchaseEvent.PURCHASE_DISABLED */
	public class PurchaseDisabledEvent extends InAppPurchaseEvent
	{
		public function PurchaseDisabledEvent(bubbles:Boolean=false, cancelable:Boolean=false) {
			super(InAppPurchaseEvent.PURCHASE_DISABLED, {}, bubbles, cancelable);
		}
	}
}

