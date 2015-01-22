//
//  Beaper.m
//
//  Created by koichi kasai on 2014/11/04.
//  Copyright (c) 2014 koichi kasai. All rights reserved.
//

#import "Beaper.h"

@implementation Beaper

- (id)initWithUuid:(NSString*)uuidString regionIdentifier:(NSString*)regionIdentifier notifyOnEntry:(BOOL)notifyOnEntry {
    
    if (self = [super init]) {
        
        NSUUID* tmpProximityUUID = [[NSUUID alloc] initWithUUIDString:uuidString];
        self.proximityUUID = tmpProximityUUID;
        [tmpProximityUUID release];
        
        self.regionIdentifier = regionIdentifier;
        self.notifyOnEntry = notifyOnEntry;
        
        CLLocationManager* tmpLocationManager = [[CLLocationManager alloc] init];
        self.locationManager = tmpLocationManager;
        [tmpLocationManager release];
        
        self.beaconRegion = nil;
        self.useBeacon = NO;
    }
    
    return self;
}

- (void)dealloc {
    
    [self.proximityUUID release];
    [self.locationManager release];
    [self.beaconRegion release];
    
    [super dealloc];
}

//ビーコンの初期化
- (void)initBeacon {
    
    self.useBeacon = TRUE;
    
    if ([CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        
        self.locationManager.delegate = self;
        
        CLBeaconRegion* tmpBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:self.proximityUUID identifier:self.regionIdentifier];
        self.beaconRegion = tmpBeaconRegion;
        [tmpBeaconRegion release];
        
        //Background通知設定は入域時のみ。AppDelegate内で行う。
        /*************************************************
         - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
         
            if([launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey]) {
                //code
            }
         
            return YES;
         }
        *************************************************/
        self.beaconRegion.notifyOnEntry = self.notifyOnEntry;
        self.beaconRegion.notifyOnExit = NO;
        self.beaconRegion.notifyEntryStateOnDisplay = self.notifyOnEntry;
        
        //iOS8対応:Info.plistに項目を追加する [NSLocationAlwaysUsageDescription]
        
        switch ([CLLocationManager authorizationStatus]) {
                
            case kCLAuthorizationStatusAuthorized:
                
                //ビーコン検出開始
                [self.locationManager startMonitoringForRegion:self.beaconRegion];
                break;
                
            case kCLAuthorizationStatusNotDetermined:
                
                if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
                        
                    //ビーコンの使用許可承認
                    [self.locationManager requestAlwaysAuthorization];
                }
                else {
                        
                    //ビーコン検出開始
                    [self.locationManager startMonitoringForRegion:self.beaconRegion];
                }
                break;
                
            default:
                break;
        }
    }
}

//ビーコンの使用許可承認
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusAuthorized || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        //ビーコン検出開始
        [self.locationManager startMonitoringForRegion:self.beaconRegion];
    }
    else {
        
        if ([CLLocationManager locationServicesEnabled]) {
            NSLog(@"location services not enabled.");
        }
        
        if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
            NSLog(@"location services not authorised.");
        }
    }
}

//リージョン検出
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    
    //リージョンの初期状態確認
    [self.locationManager requestStateForRegion:region];
}

//領域に入った
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        
        //レンジ検出開始
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

//領域から出た
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        
        //レンジ検出停止
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

//状態確認完了
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    
    switch (state) {
            
        case CLRegionStateInside:
            if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
                
                //既にリージョン範囲内の場合にレンジ検出の開始
                [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
            }
            break;
            
        case CLRegionStateOutside:
        case CLRegionStateUnknown:
        default:
            break;
    }
}

//レンジ検出更新
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    
    if (self.useBeacon && beacons.count > 0) {
        
        //CLProximityUnknown以外のビーコンだけを取り出す
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"proximity != %d", CLProximityUnknown];
        NSArray* validBeacons = [beacons filteredArrayUsingPredicate:predicate];
        CLBeacon* nearestBeacon = validBeacons.firstObject;
        
        //検出処理
        switch (nearestBeacon.proximity) {
            
            //すごく近い 50cm以内
            case CLProximityImmediate:
                if ([self.delegate respondsToSelector:@selector(foundBeaconImmediate:minor:accuracy:)]) {
                 
                    [self.delegate foundBeaconImmediate:(int)nearestBeacon.major.intValue
                                                  minor:(int)nearestBeacon.minor.intValue
                                               accuracy:(double)nearestBeacon.accuracy];
                }
                break;
            
            //近い 50cm〜6m
            case CLProximityNear:
                if ([self.delegate respondsToSelector:@selector(foundBeaconNear:minor:accuracy:)]) {
                    
                    [self.delegate foundBeaconNear:(int)nearestBeacon.major.intValue
                                             minor:(int)nearestBeacon.minor.intValue
                                          accuracy:(double)nearestBeacon.accuracy];
                }
                break;
                
            //遠い 6m〜20m
            case CLProximityFar:
                if ([self.delegate respondsToSelector:@selector(foundBeaconFar:minor:accuracy:)]) {
                    
                    [self.delegate foundBeaconFar:(int)nearestBeacon.major.intValue
                                            minor:(int)nearestBeacon.minor.intValue
                                         accuracy:(double)nearestBeacon.accuracy];
                }
                break;
                
            //見つからない
            case CLProximityUnknown:
                break;
                
            default:
                break;
        }
    }
}

//検出失敗
- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    
    NSLog(@"did fail for region - %@", error.localizedDescription);
}

//ビーコン反応の停止
- (void)enableBeacon:(BOOL)state {
    
    self.useBeacon = state;
}

@end
