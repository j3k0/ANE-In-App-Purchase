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
    import com.freshplanet.ane.AirInAppPurchase.InAppPurchaseProducts;

    /** Event of type InAppPurchaseEvent.PRODUCTS_LOADED.
     * <p>
     * Triggered when the ANE failed to load product information with <code>loadProducts()</code>.
     * </p><p>
     * <code>products</code> provides access to the loaded <code>InAppPurchaseProducts</code>.
     * </p>
     * @see com.freshplanet.ane.AirInAppPurchase.InAppPurchaseProducts
     * @see com.freshplanet.ane.AirInAppPurchase.InAppPurchase
     */
	public class ProductsLoadedEvent extends InAppPurchaseEvent
	{
        /** List of product information */
        public function get products():InAppPurchaseProducts {
            return data.products;
        }

        /** Constructor */
		public function ProductsLoadedEvent(products:InAppPurchaseProducts, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(InAppPurchaseEvent.PRODUCTS_LOADED, { products: products }, bubbles, cancelable);
		}
	}
}
