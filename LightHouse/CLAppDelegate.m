//
//  CLAppDelegate.m
//  LightHouse
//
//  Created by Thomas Pun on 4/13/14.
//  Copyright (c) 2014 Clione Labs. All rights reserved.
//

#import "CLAppDelegate.h"
#import "CLMasterViewController.h"
#import <Firebase/Firebase.h>
#import <AdSupport/AdSupport.h>
@import CoreLocation;

@interface CLAppDelegate () <UIApplicationDelegate, CLLocationManagerDelegate>
@property CLLocationManager *locationManager;
@property (nonatomic) NSUUID *advertisingIdentifier;
@property Firebase *firebase;
@end

@implementation CLAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    CLMasterViewController *controller = (CLMasterViewController *)navigationController.topViewController;
    controller.managedObjectContext = self.managedObjectContext;

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager requestAlwaysAuthorization];
    [self startMonitoringAllRegions];

    self.firebase = [[Firebase alloc] initWithUrl:@"https://looppulse.firebaseio.com/beacon_events"];

    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }

    return YES;
}

- (NSUUID *)advertisingIdentifier
{
    ASIdentifierManager *adManager = [ASIdentifierManager sharedManager];
    return adManager.advertisingIdentifier;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

- (void)notifyLocally:(NSString *)string
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = string;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

#pragma mark - Light House iBeacon stack
- (NSArray *)beaconRegions
{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D"];
    CLBeaconRegion *purple = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
                                                                     major:1213
                                                                     minor:14001
                                                                identifier:@"Purple"];
    CLBeaconRegion *blue   = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
                                                                     major:1908
                                                                     minor:3003
                                                                identifier:@"Blue"];
    CLBeaconRegion *white  = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
                                                                     major:1901
                                                                     minor:102
                                                                identifier:@"White"];
    CLBeaconRegion *yellow = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
                                                                     major:214
                                                                     minor:2104
                                                                identifier:@"Yellow"];
    return [NSArray arrayWithObjects:purple, blue, white, yellow, nil];
}

- (void)startMonitoringAllRegions
{
    for (CLBeaconRegion *region in [self beaconRegions]) {
        if (![self.locationManager.monitoredRegions containsObject:region]) {
            [self.locationManager startMonitoringForRegion:region];
            NSLog(@"Started monitoring: %@", region);
        }
    }

    NSLog(@"Currently monitoring: %@", self.locationManager.monitoredRegions);
}

- (void)startRangingAllRegions
{
    for (CLBeaconRegion *region in [self beaconRegions]) {
        if (![self.locationManager.rangedRegions containsObject:region]) {
            [self.locationManager startRangingBeaconsInRegion:region];
            NSLog(@"Started ranging: %@", region);
        }
    }

    NSLog(@"Currently ranging: %@", self.locationManager.rangedRegions);
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if(state==CLRegionStateInside) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        [self.locationManager startRangingBeaconsInRegion:beaconRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
//    if ([beacons count]==0) {
//        //[self notifyLocally:@"No beacon detected. stopRangingBeaconsInRegion"];
//        [manager stopRangingBeaconsInRegion:region];
//        return;
//    }
//
//    for (CLBeacon *beacon in beacons) {
//        [self updateBeacon:beacon];
//
//        // Monitor specific beacons
//        NSString *identifier = [NSString stringWithFormat:@"LoopPulse-%@:%@", beacon.major, beacon.minor];
//        CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:region.proximityUUID
//                                                                               major:[beacon.major integerValue]
//                                                                               minor:[beacon.minor integerValue]
//                                                                          identifier:identifier];
//        if (![self.locationManager.monitoredRegions containsObject:beaconRegion]) {
//            [self.locationManager startMonitoringForRegion:beaconRegion];
//        }
//    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"entered: %@", region);

    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        if (beaconRegion.major && beaconRegion.minor) {
            [self notifyLocally:[NSString stringWithFormat:@"didEnterRegion %@", [self colorStringForMajor:beaconRegion.major]]];
        } else {
            [self startRangingAllRegions];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"exited: %@", region);

    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        if (beaconRegion.major && beaconRegion.minor) {
            [self notifyLocally:[NSString stringWithFormat:@"didExitRegion %@", [self colorStringForMajor:beaconRegion.major]]];
        }
    }
}

- (void)updateBeacon:(CLBeacon *)beacon
{
    NSLog(@"Major: %@, Minor %@, Proximity: %d", beacon.major, beacon.minor, (int)beacon.proximity);
    if (CLProximityImmediate==beacon.proximity) {
        NSError *error=nil;
        NSManagedObject *beaconEvent = [self latestBeaconEvent:beacon];
        if (beaconEvent) {
            NSDate *nowDate = [NSDate date];
            NSDate *lastSeenAt = [beaconEvent valueForKey:@"lastSeenAt"];
            NSTimeInterval interval = [nowDate timeIntervalSinceDate:lastSeenAt];
            if (interval < 5) {
                [beaconEvent setValue:nowDate forKey:@"lastSeenAt"];
                [self.managedObjectContext save:&error];
            } else {
                [self createBeaconEvent:beacon];
            }
        } else {
            [self createBeaconEvent:beacon];
        }
    }
}

- (NSString *)colorStringForMajor:(NSNumber *)major
{
    NSString *color;
    switch ([major integerValue]) {
        case 1213:
            color = @"Purple";
            break;
        case 1908:
            color = @"Blue";
            break;
        case 1901:
            color = @"White";
            break;
        case 214:
            color = @"Yellow";
            break;
        default:
            color = @"Unknown";
            break;
    }
    return color;
}

- (void)createBeaconEvent:(CLBeacon *)beacon
{
    NSLog(@"createBeaconEvent: %@", beacon);
    NSManagedObject *newBeaconEvent = [NSEntityDescription insertNewObjectForEntityForName:@"BeaconEvent" inManagedObjectContext:self.managedObjectContext];
    [newBeaconEvent setValue:beacon.major forKey:@"major"];
    [newBeaconEvent setValue:beacon.minor forKey:@"minor"];
    NSDate *nowDate = [NSDate date];
    [newBeaconEvent setValue:nowDate forKey:@"createdAt"];
    [newBeaconEvent setValue:nowDate forKey:@"lastSeenAt"];

    NSError *error=nil;
    [self.managedObjectContext save:&error];
}

- (NSManagedObject *)latestBeaconEvent:(CLBeacon *)beacon
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BeaconEvent" inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];

    NSPredicate *majorPredicate = [NSPredicate predicateWithFormat:@"major == %@", beacon.major];
    NSPredicate *minorPredicate = [NSPredicate predicateWithFormat:@"minor == %@", beacon.minor];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[majorPredicate, minorPredicate]];
    [request setPredicate:predicate];

    NSError *error;
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:&error];

    return [result firstObject];
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"LightHouse" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"LightHouse.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
