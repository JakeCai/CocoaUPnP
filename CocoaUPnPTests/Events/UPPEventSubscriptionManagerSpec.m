// CocoaUPnP by A&R Cambridge Ltd, http://www.arcam.co.uk
// Copyright 2015 Arcam. See LICENSE file.

#import "UPPEventSubscriptionManager.h"
#import "OHHTTPStubs.h"
#import "UPPBasicService.h"

#import <OCMock/OCMock.h>
#import "UPPEventSubscription.h"

static NSString * const UPPTestFakeURL = @"http://127.0.0.1:54321/Event";
static NSString * const UPPTestSID = @"uuid:12345678";
static NSString * const UPPTestTimeout = @"Second-1800";

SpecBegin(UPPEventSubscriptionManager)

describe(@"UPPEventSubscriptionManager", ^{

    __block id mockService;
    __block UPPEventSubscriptionManager *sut;
    __block OHHTTPStubsResponseBlock responseBlock;
    __block OHHTTPStubsTestBlock testBlock;
    __block UPPEventSubscription *subscription;

    beforeEach(^{
        sut = [UPPEventSubscriptionManager new];
        mockService = OCMClassMock([UPPBasicService class]);
        NSURL *url = [NSURL URLWithString:UPPTestFakeURL];
        OCMStub([mockService eventSubscriptionURL]).andReturn(url);

        subscription = [UPPEventSubscription subscriptionWithID:UPPTestSID
                                                     expiryDate:nil
                                           eventSubscriptionURL:[NSURL URLWithString:UPPTestFakeURL]];

        responseBlock = ^OHHTTPStubsResponse *(NSURLRequest *request) {
            NSDictionary *headers = @{
                                      @"DATE": @"Fri, 01 Jan 2015 13:00:01 GMT",
                                      @"SERVER": @"IPI/1.0 UPnP/1.0 DLNADOC/1.50",
                                      @"SID": UPPTestSID,
                                      @"TIMEOUT": @"Second-300",
                                      @"CONTENT-LENGTH": @"0",
                                      @"CONNECTION": @"Keep-Alive"
                                      };
            return [OHHTTPStubsResponse responseWithData:[NSData data]
                                              statusCode:200
                                                 headers:headers];
        };
    });

    afterEach(^{
        [OHHTTPStubs removeAllStubs];
    });

    describe(@"when subscribing to service events", ^{

        beforeEach(^{
            testBlock = ^BOOL(NSURLRequest *request) {

                if (![request.HTTPMethod isEqualToString:@"SUBSCRIBE"]) {
                    return NO;
                }

                NSDictionary *headers = request.allHTTPHeaderFields;
                if (![headers[@"HOST"] isEqualToString:UPPTestFakeURL] ||
                    ![headers[@"CALLBACK"] isEqualToString:[[sut callbackURL] absoluteString]] ||
                    ![headers[@"NT"] isEqualToString:@"upnp:event"] ||
                    ![headers[@"TIMEOUT"] isEqualToString:UPPTestTimeout]) {
                    return NO;
                }

                return [request.URL isEqual:[NSURL URLWithString:UPPTestFakeURL]];
            };

            [OHHTTPStubs stubRequestsPassingTest:testBlock withStubResponse:responseBlock];
        });

        it(@"should send a request to the services event subscription URL", ^{
            waitUntil(^(DoneCallback done) {
                [sut subscribeObject:nil toService:mockService completion:^(BOOL success) {
                    expect(success).to.beTruthy();
                    done();
                }];
            });
        });

        xit(@"should create a subscription object", ^{
        });

        xit(@"should reuse a subscription object", ^{
        });
    });

    describe(@"when resubscribing to service events", ^{
        beforeEach(^{
            testBlock = ^BOOL(NSURLRequest *request) {

                if (![request.HTTPMethod isEqualToString:@"SUBSCRIBE"]) {
                    return NO;
                }

                NSDictionary *headers = request.allHTTPHeaderFields;
                if (![headers[@"HOST"] isEqualToString:UPPTestFakeURL] ||
                    ![headers[@"SID"] isEqualToString:UPPTestSID] ||
                    ![headers[@"TIMEOUT"] isEqualToString:UPPTestTimeout]) {
                    return NO;
                }

                return [request.URL isEqual:[NSURL URLWithString:UPPTestFakeURL]];
            };

            [OHHTTPStubs stubRequestsPassingTest:testBlock withStubResponse:responseBlock];
        });
        it(@"should send a request to the services event subscription URL", ^{
            waitUntil(^(DoneCallback done) {
                [sut renewSubscription:subscription completion:^(NSString *subscriptionID, NSDate *expiryDate, NSError *error) {
                    expect(subscriptionID).to.equal(UPPTestSID);
                    NSDate *expectedExpiry = [NSDate dateWithTimeIntervalSinceNow:300];
                    expect([expectedExpiry timeIntervalSinceDate:expiryDate] < 0.01).to.beTruthy();
                    done();
                }];
            });
        });

        xit(@"should update a subscription object", ^{
        });
    });

    describe(@"when unsubscribing to service events", ^{
        beforeEach(^{
            testBlock = ^BOOL(NSURLRequest *request) {

                if (![request.HTTPMethod isEqualToString:@"UNSUBSCRIBE"]) {
                    return NO;
                }

                NSDictionary *headers = request.allHTTPHeaderFields;
                if (![headers[@"HOST"] isEqualToString:UPPTestFakeURL] ||
                    ![headers[@"SID"] isEqualToString:UPPTestSID]) {
                    return NO;
                }

                return [request.URL isEqual:[NSURL URLWithString:UPPTestFakeURL]];
            };

            [OHHTTPStubs stubRequestsPassingTest:testBlock withStubResponse:responseBlock];
        });

        it(@"should send a request to the services event subscription URL", ^{
            waitUntil(^(DoneCallback done) {
                [sut unsubscribe:subscription completion:^(BOOL success) {
                    expect(success).to.beTruthy();
                    done();
                }];
            });
        });

        xit(@"should destroy a subscription object", ^{
        });
    });

    describe(@"when recieving an event", ^{
        xit(@"should parse the XML", ^{
        });

        xit(@"should pass the event object to the subscription object", ^{
        });
    });
});

SpecEnd