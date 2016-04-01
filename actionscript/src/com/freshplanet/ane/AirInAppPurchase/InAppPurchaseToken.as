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
    /** A token necessary to perform API calls.
     *
     * Ensures that you initialized the lib before doing anything else.
     *
     * @see com.freshplanet.ane.AirInAppPurchase.InAppPurchase.initialize
     */
	public class InAppPurchaseToken {
		public function InAppPurchaseToken(calledBy:String) {

            // If you're reading this, it's probably because you wonder how to get this
            // InAppPurchaseToken.
            //
            // DON'T CREATE AN InAppPurchaseToken MANUALLY!
            //
            // You should use the instance returned by InitFinishedEvent,
            // InitFinishedEvent gets triggered when InAppPurchase.initialize() finished successfully.

            // There's no way to make a constructor internal or private... So we go for a hack.
            if (calledBy != "InitFinishedEvent") {
                throw new Error("InAppPurchaseToken should only be created by the InitFinishedEvent class.");
            }
        }
	}
}
