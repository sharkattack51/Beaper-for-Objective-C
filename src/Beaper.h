//
//  Beaper.h
//  Unity-iPhone
//
//  Created by kasai on 2015/01/01.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol BeaperDelegate <NSObject>

@optional
- (void)foundBeaconImmediate:(int)major minor:(int)minor accuracy:(double)accuracy;

@optional
- (void)foundBeaconNear:(int)major minor:(int)minor accuracy:(double)accuracy;

@optional
- (void)foundBeaconFar:(int)major minor:(int)minor accuracy:(double)accuracy;

@end


@interface Beaper : NSObject <CLLocationManagerDelegate>

@property (nonatomic, retain) NSUUID* proximityUUID;
@property (nonatomic, retain) NSString* regionIdentifier;
@property (nonatomic) BOOL notifyOnEntry;
@property (nonatomic) CLAuthorizationStatus authorizationStatus;
@property (nonatomic, retain) CLLocationManager* locationManager;
@property (nonatomic, retain) CLBeaconRegion* beaconRegion;
@property (nonatomic) BOOL useBeacon;
@property (nonatomic, assign) id<BeaperDelegate> delegate;

- (id)initWithUuid:(NSString*)uuidString regionIdentifier:(NSString*)regionIdentifier notifyOnEntry:(BOOL)notifyOnEntry;
- (void)initBeacon;
- (void)enableBeacon:(BOOL)state;

@end
