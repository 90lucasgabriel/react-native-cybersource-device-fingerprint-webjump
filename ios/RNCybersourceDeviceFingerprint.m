//
//  RNCybersourceDeviceFingerprint.m
//
//  Created by Estuardo Estrada on 12/16/18.
//  Copyright © 2018. All rights reserved.
//

#import "RNCybersourceDeviceFingerprint.h"
#import <React/RCTLog.h>
#import <TMXProfiling/TMXProfiling.h>
#import <TMXProfilingConnections/TMXProfilingConnections.h>

static NSString *const kRejectCode = @"CyberSourceSDKModule";

@implementation RNCybersourceDeviceFingerprint{
    TMXProfiling *_defender;
}

- (dispatch_queue_t)methodQueue{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(
    configure:(NSString *)orgId
    serverURL:(NSString *)serverURL
    resolver:(RCTPromiseResolveBlock)resolve
    rejecter:(RCTPromiseRejectBlock)reject
    ) {
    if (_defender) {
        reject(kRejectCode, @"CyberSource SDK is already initialised", nil);
        return;
    }

    _defender = [TMXProfiling sharedInstance];

    @try {
        [_defender configure:@{
                               TMXOrgID: orgId,
                               TMXFingerprintServer: serverURL,
                               }];
    } @catch (NSException *exception) {
        reject(kRejectCode, @"Invalid parameters", nil);
        return;
    }

    resolve(@YES);
}

RCT_EXPORT_METHOD(
  getSessionID:(NSString *)merchantId
  resolver:(RCTPromiseResolveBlock)resolve
  rejecter:(RCTPromiseRejectBlock)reject
  ) {
  NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
  NSNumber *timeStampObj = [NSNumber numberWithDouble: timeStamp];

  NSString *timeStampText = [NSString stringWithFormat:@"%d", timeStampObj];
  NSArray *attributes = @[timeStampText];

  NSString *sessionId = [NSString stringWithFormat:@"%@%@", merchantId, timeStampText];

  TMXProfileHandle *profileHandle = [[TMXProfiling sharedInstance]
    profileDeviceUsing:@{TMXSessionID : sessionId, TMXCustomAttributes: attributes}

    callbackBlock:^(NSDictionary * _Nullable result) {
    TMXStatusCode statusCode = [[result valueForKey:TMXProfileStatus] integerValue];

    resolve(@{
      @"sessionId": [attributes objectAtIndex:0],
      @"status": @(statusCode),
    });
  }];
}

@end
