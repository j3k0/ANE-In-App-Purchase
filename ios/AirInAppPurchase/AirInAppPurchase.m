//////////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2012 Freshplanet (http://freshplanet.com | opensource@freshplanet.com)
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

#import "AirInAppPurchase.h"

FREContext AirInAppCtx = nil;

void *AirInAppRefToSelf;
SKReceiptRefreshRequest *receiptRefreshRequest;
NSMutableArray *pendingTransactions;

void aneDebug(NSString *msg);

#define DEFINE_ANE_FUNCTION(fn) FREObject (fn)(FREContext context, void* functionData, uint32_t argc, FREObject argv[])


@implementation AirInAppPurchase

- (id) init
{
    self = [super init];
    if (self)
    {
        AirInAppRefToSelf = self;
    }
    return self;
}

-(void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    AirInAppRefToSelf = nil;
    [super dealloc];
}

- (void)dispatchEvent:(const char*)eventName withString:(NSString *)str
{
    FREDispatchStatusEventAsync(AirInAppCtx, (uint8_t*)eventName, (uint8_t*)[str UTF8String]);
}

- (NSString*)jsonStringWithDictionary:(NSDictionary*)dictionary
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSString*)jsonStringWithArray:(NSArray*)array
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:0 error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)dispatchEvent:(const char*)eventName withDictionary:(NSMutableDictionary *)json
{
    NSString *jsonString = [self jsonStringWithDictionary:json];
    [self dispatchEvent:eventName withString:jsonString];
}

- (void)dispatchEvent:(const char*)eventName withArray:(NSArray *)json
{
    NSString *jsonString = [self jsonStringWithArray:json];
    [self dispatchEvent:eventName withString:jsonString];
}

- (void)debug:(NSString *)msg
{
    [self dispatchEvent:"DEBUG" withString:msg];
}

- (BOOL) canMakePayment
{
    return [SKPaymentQueue canMakePayments];
}

- (void) registerObserver
{
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [self dispatchEvent:"INIT_FINISHED" withString:@"SUCCESS"];
}

- (void) restoreCompletedTransactions
{
    aneDebug(@"restoreCompletedTransactions");
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}


//////////////////////////////////////////////////////////////////////////////////////
// PRODUCT INFO
//////////////////////////////////////////////////////////////////////////////////////

// get products info
- (void) sendRequest:(SKRequest*)request AndContext:(FREContext*)ctx
{
    request.delegate = self;
    [request start];   
}

// on product info received
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    aneDebug(@"productsRequest");
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *productElement = [[NSMutableDictionary alloc] init];
    
    for (SKProduct* product in [response products])
    {
        NSMutableDictionary *details = [[NSMutableDictionary alloc] init];
        [numberFormatter setLocale:product.priceLocale];
        [details setValue: [numberFormatter stringFromNumber:product.price] forKey:@"price"];
        [details setValue: product.localizedTitle forKey:@"title"];
        [details setValue: product.localizedDescription forKey:@"description"];
        [details setValue: product.productIdentifier forKey:@"productId"];
        [details setValue: [numberFormatter currencyCode] forKey:@"price_currency_code"];
        [details setValue: [numberFormatter currencySymbol] forKey:@"price_currency_symbol"];
        [details setValue: product.price forKey:@"value"];
        [productElement setObject:details forKey:product.productIdentifier];
    }
    
    [dictionary setObject:productElement forKey:@"details"];
    [self dispatchEvent:"PRODUCTS_LOADED" withDictionary:dictionary];
    
    if ([response invalidProductIdentifiers] != nil && [[response invalidProductIdentifiers] count] > 0)
        [self dispatchEvent:"PRODUCTS_LOAD_ERROR" withArray:[response invalidProductIdentifiers]];
}

// on product info finish
- (void)requestDidFinish:(SKRequest *)request
{
    aneDebug(@"requestDidFinish");
    if (request == receiptRefreshRequest) {
        aneDebug(@"it's a receiptRefreshRequest");
        receiptRefreshRequest = nil;
        NSMutableArray *copy = pendingTransactions;
        pendingTransactions = [[NSMutableArray alloc] init];
        for (int i = 0; i < copy.count; ++i)
            [self completeTransaction:[copy objectAtIndex:i]];
    }
}

// on product info error
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    aneDebug(@"requestDidFailWithError");
}


//////////////////////////////////////////////////////////////////////////////////////
// PURCHASE PRODUCT
//////////////////////////////////////////////////////////////////////////////////////

// complete a transaction (item has been purchased, need to check the receipt)
- (void) completeTransaction:(SKPaymentTransaction*)transaction
{
    NSMutableDictionary *data;

    // purchase done
    // dispatch event
    data = [[NSMutableDictionary alloc] init];
    [data setValue:[[transaction payment] productIdentifier] forKey:@"productId"];

    // "transaction.transactionReceipt" is deprecated.
    aneDebug(@"appStoreReceipt:");
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    aneDebug([receiptURL absoluteString]);
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    if (!receiptData) {
        aneDebug(@"No receipt, retrying later...");
        if (!pendingTransactions) {
            pendingTransactions = [[NSMutableArray alloc] init];
        }
        [pendingTransactions addObject:transaction];
        if (!receiptRefreshRequest) {
            receiptRefreshRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:nil];
            receiptRefreshRequest.delegate = self;
            [receiptRefreshRequest start];
        }
        return;
    }
    NSString* receiptString = [receiptData base64EncodedStringWithOptions:0]; //[NSString stringWithUTF8String:[receiptData bytes]];
    // aneDebug(receiptString);
    // NSString* receiptString = [[[NSString alloc] initWithData:receipt encoding:NSUTF8StringEncoding] autorelease];

    NSString* transactionId = [transaction transactionIdentifier];
    NSString* transactionDate = [[transaction transactionDate] descriptionWithLocale:nil];
    [data setValue:@"AppleAppStore" forKey:@"receiptType"];
    [data setValue:receiptString    forKey:@"receipt"];
    [data setValue:transactionId    forKey:@"transactionId"];
    [data setValue:transactionDate  forKey:@"transactionDate"];

    [self dispatchEvent:"PURCHASE_APPROVED" withDictionary:data];
}

// transaction failed, remove the transaction from the queue.
- (void) failedTransaction:(SKPaymentTransaction*)transaction
{
    // purchase failed
    NSMutableDictionary *data;

    [[transaction payment] productIdentifier];
    [[transaction error] code];

    data = [[NSMutableDictionary alloc] init];
    [data setValue:[NSNumber numberWithInteger:[[transaction error] code]]  forKey:@"code"];
    [data setValue:[[transaction error] localizedFailureReason] forKey:@"FailureReason"];
    [data setValue:[[transaction error] localizedDescription] forKey:@"FailureDescription"];
    [data setValue:[[transaction error] localizedRecoverySuggestion] forKey:@"RecoverySuggestion"];
    
    NSString *error = transaction.error.code == SKErrorPaymentCancelled
      ? @"RESULT_USER_CANCELED"
      : [self jsonStringWithDictionary:data];
    
    // conclude the transaction
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    // dispatch event
    [self dispatchEvent:"PURCHASE_ERROR" withString:error];
}

// transaction is being purchasing, logging the info.
- (void) purchasingTransaction:(SKPaymentTransaction*)transaction
{
    // purchasing transaction
    // dispatch event
    [self dispatchEvent:"PURCHASING" withString:[[transaction payment] productIdentifier]];
}

// transaction restored, remove the transaction from the queue.
- (void) restoreTransaction:(SKPaymentTransaction*)transaction
{
    // transaction restored
    // dispatch event
    // [self dispatchEvent:"TRANSACTION_RESTORED" withString:[[transaction error] localizedDescription]];
    [self completeTransaction:transaction];
    
    // conclude the transaction
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}


// list of transactions has been updated.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    NSUInteger nbTransaction = [transactions count];
    NSString* pendingTransactionInformation =
      [NSString stringWithFormat:@"{\"numberOfPendingTransactions\": %@}", [NSNumber numberWithUnsignedInteger:nbTransaction]];
    [self dispatchEvent:"UPDATED_TRANSACTIONS" withString:pendingTransactionInformation];
    
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                aneDebug(@"Transaction 'Purchased'");
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                aneDebug(@"Transaction 'Failed'");
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing:
                aneDebug(@"Transaction 'Purchasing'");
                [self purchasingTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                aneDebug(@"Transaction 'Restored'");
                [self restoreTransaction:transaction];
                break;
            default:
                [self dispatchEvent:"PURCHASE_UNKNOWN" withString:@"Unknown reason"];
                break;
        }
    }
}

// restoring transaction is done.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    aneDebug(@"paymentQueueRestoreCompletedTransactionsFinished");
}

// restoring transaction failed.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    aneDebug(@"paymentQueue restoreCompletedTransactionsFailedWithError");
}

// transaction has been removed.
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    aneDebug(@"removeTransaction");
    // [self dispatchEvent:"TRANSACTIONS_REMOVED" withString:"[]"];
}

- (void)userCanMakeAPurchase
{
    BOOL canMakePayment = [SKPaymentQueue canMakePayments];
    if (canMakePayment) {
        [self dispatchEvent:"PURCHASE_ENABLED" withString:@"Yes"];
 
    } else {
        [self dispatchEvent:"PURCHASE_DISABLED" withString:@"No"];
    }
}

@end


DEFINE_ANE_FUNCTION(AirInAppPurchaseInit)
{
    [(AirInAppPurchase*)AirInAppRefToSelf registerObserver];
    
    return nil;
}

// make a purchase
DEFINE_ANE_FUNCTION(makePurchase)
{
    
    uint32_t stringLength;
    const uint8_t *string1;

    if (FREGetObjectAsUTF8(argv[0], &stringLength, &string1) != FRE_OK)
    {
        return nil;
    }

    NSString *productIdentifier = [NSString stringWithUTF8String:(char*)string1];
    aneDebug(productIdentifier);
    
    // TODO: paymentWithProductIdentifier is deprecated:
    // TODO: Use `paymentWithProduct` using the product fetched with the SKProductsRequest
    SKPayment* payment = [SKPayment paymentWithProductIdentifier:productIdentifier];
    aneDebug([payment productIdentifier]);
    
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    return nil;
}


// check if the user can make a purchase
DEFINE_ANE_FUNCTION(userCanMakeAPurchase)
{
    [(AirInAppPurchase*)AirInAppRefToSelf userCanMakeAPurchase];
    return nil;
}



// make a SKProductsRequest. wait for a SKProductsResponse
// arg : array of string (string = product identifier)
DEFINE_ANE_FUNCTION(getProductsInfo)
{        
    FREObject arr = argv[0]; // array
    uint32_t arr_len; // array length
    
    FREGetArrayLength(arr, &arr_len);

    NSMutableSet* productsIdentifiers = [[NSMutableSet alloc] init];
     
    for(int32_t i=arr_len-1; i>=0;i--){
                
        // get an element at index
        FREObject element;
        FREGetArrayElementAt(arr, i, &element);
        
        // convert it to NSString
        uint32_t stringLength;
        const uint8_t *string;
        FREGetObjectAsUTF8(element, &stringLength, &string);
        NSString *productIdentifier = [NSString stringWithUTF8String:(char*)string];
        
        [productsIdentifiers addObject:productIdentifier];
    }
    
    SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:productsIdentifiers];
    [(AirInAppPurchase*)AirInAppRefToSelf sendRequest:request AndContext:context];
    return nil;
}

DEFINE_ANE_FUNCTION(restoreTransactions)
{
    [(AirInAppPurchase*)AirInAppRefToSelf restoreCompletedTransactions];
    return nil;
}

// remove purchase from queue.
DEFINE_ANE_FUNCTION(removePurchaseFromQueue)
{
    uint32_t stringLength;
    const uint8_t *string1;
    if (FREGetObjectAsUTF8(argv[0], &stringLength, &string1) != FRE_OK)
        return nil;
    
    NSString *productIdentifier = [NSString stringWithUTF8String:(char*)string1];

    aneDebug([NSString stringWithFormat:@"removing purchase from queue %@", productIdentifier]);

    NSArray* transactions = [[SKPaymentQueue defaultQueue] transactions];

    for (SKPaymentTransaction* transaction in transactions)
    {
        aneDebug([[transaction payment] productIdentifier]);

        switch ([transaction transactionState]) {
            case SKPaymentTransactionStatePurchased:
                aneDebug(@"SKPaymentTransactionStatePurchased");
                break;
            case SKPaymentTransactionStateFailed:
                aneDebug(@"SKPaymentTransactionStateFailed");
                break;
            case SKPaymentTransactionStatePurchasing:
                aneDebug(@"SKPaymentTransactionStatePurchasing");
                break;
            case SKPaymentTransactionStateRestored:
                aneDebug(@"SKPaymentTransactionStateRestored");
                break;
            default:
                aneDebug(@"Unknown Reason");
                break;
        }

        if ([transaction transactionState] == SKPaymentTransactionStatePurchased && [[[transaction payment] productIdentifier] isEqualToString:productIdentifier])
        {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            aneDebug(@"Conluding transaction");
            break;
        }
    }
    
    return nil;
}


// ContextInitializer()
//
// The context initializer is called when the runtime creates the extension context instance.
void AirInAppContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, 
                             uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet) 
{    
    // Register the links btwn AS3 and ObjC. (dont forget to modify the nbFuntionsToLink integer if you are adding/removing functions)
    uint32_t nbFuntionsToLink = 6;
    *numFunctionsToTest = nbFuntionsToLink;
    
    FRENamedFunction* func = (FRENamedFunction*) malloc(sizeof(FRENamedFunction) * nbFuntionsToLink);
    
    func[0].name = (const uint8_t*) "initLib";
    func[0].functionData = NULL;
    func[0].function = &AirInAppPurchaseInit;
    
    func[1].name = (const uint8_t*) "makePurchase";
    func[1].functionData = NULL;
    func[1].function = &makePurchase;
    
    func[2].name = (const uint8_t*) "userCanMakeAPurchase";
    func[2].functionData = NULL;
    func[2].function = &userCanMakeAPurchase;
    
    func[3].name = (const uint8_t*) "getProductsInfo";
    func[3].functionData = NULL;
    func[3].function = &getProductsInfo;

    func[4].name = (const uint8_t*) "removePurchaseFromQueue";
    func[4].functionData = NULL;
    func[4].function = &removePurchaseFromQueue;
    
    func[5].name = (const uint8_t*) "restoreTransactions";
    func[5].functionData = NULL;
    func[5].function = &restoreTransactions;
    
    *functionsToSet = func;
    
    AirInAppCtx = ctx;

    if ((AirInAppPurchase*)AirInAppRefToSelf == nil) {
        AirInAppRefToSelf = [[AirInAppPurchase alloc] init];
    }

}

// ContextFinalizer()
//
// Set when the context extension is created.

void AirInAppContextFinalizer(FREContext ctx) { 
    NSLog(@"ContextFinalizer()");
    NSLog(@"Exiting ContextFinalizer()");	
}



// AirInAppInitializer()
//
// The extension initializer is called the first time the ActionScript side of the extension
// calls ExtensionContext.createExtensionContext() for any context.

void AirInAppInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet ) 
{
    NSLog(@"Entering ExtInitializer()");                    
    
	*extDataToSet = NULL;
	*ctxInitializerToSet = &AirInAppContextInitializer; 
	*ctxFinalizerToSet = &AirInAppContextFinalizer;
    
    NSLog(@"Exiting ExtInitializer()"); 
}

void aneDebug(NSString *msg) {
    if (AirInAppRefToSelf)
        [(AirInAppPurchase*)AirInAppRefToSelf debug:msg];
    else
        NSLog(@"%@", msg);
}
