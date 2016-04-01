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
    /** Event of type InAppPurchaseEvent.INIT_ERROR
     * <p>
     * Triggered when the ANE failed to initialize with <code>initialize()</code>.
     * </p>
     * @see com.freshplanet.ane.AirInAppPurchase.InAppPurchase.initialize
     */
	public class InitErrorEvent extends InAppPurchaseEvent
	{
        /** Description of the error in plain english. */
        public function get message():String {
            return data.message;
        }

		public function InitErrorEvent(message:String, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(InAppPurchaseEvent.INIT_ERROR, { message: message }, bubbles, cancelable);
		}
	}
}
