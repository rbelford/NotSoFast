//
//  AppDelegate.m
//  TaskTimer
//
//  Created by rbelford on 9/22/12.
//  Copyright (c) 2012 rbelford. All rights reserved.
//

#import "AppDelegate.h"
#import "TransportViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVPlayer.h>

@interface AppDelegate () {
}
@end

NSString *_transportFilePath;
NSString *_playlistFilePath;
TransportViewController *_mainController;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // get a pointer to the transportViewController, so we can write out
    // its state in applicationWillResignActive:.
    
    UINavigationController *nav = (UINavigationController *) self.window.rootViewController;
    _mainController = (TransportViewController *) nav.topViewController;
    
    // get the documents folder
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    // Tranport state file is read in the TransportController
    _transportFilePath = [documentsDirectory stringByAppendingPathComponent:@"nsfTransport"];
    // Playlistfile is read below in the applicationWillResignActive: method
    _playlistFilePath = [documentsDirectory stringByAppendingPathComponent:@"nsfPlaylist"];
    
    ///////////////
    // FOR TESTING ///// BE CAREFUL!!!!!!!
    //[[NSFileManager defaultManager] removeItemAtPath: _playlistFilePath error: nil];
    //////// !!!!!!!
    
    // Put file handle for reading store in the _mainController so it can read the file we write.
    _mainController.transportFilePath = _transportFilePath;
    
    // Read in the playlist persistent IDs
    NSArray *storeArray = (NSArray *)[NSArray arrayWithContentsOfFile:_playlistFilePath];
   
    // Use the IDs to construct an MPMediaItemClooection.
    if (storeArray) {
        NSLog(@"Have playlist store.");
        NSMutableArray *queueTemp = [[NSMutableArray alloc] initWithCapacity:[storeArray count]];
        for (NSString *persistentID in storeArray) {
            MPMediaQuery *query = [MPMediaQuery songsQuery];
            MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:persistentID forProperty:MPMediaItemPropertyPersistentID];
            [query addFilterPredicate:predicate];
            NSArray *songs = [query items];
            [queueTemp addObject: [songs objectAtIndex:0]];
        }
        // Attach it to the Transport contrioller
        _mainController.songQueue = [[MPMediaItemCollection alloc] initWithItems:queueTemp];    } else {
        NSLog(@"No playlist store.");
    }
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // write the state of the transport view (the playing song) to disk.
    NSDictionary *storeDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                _mainController.songPath.absoluteString, @"songPath",
                _mainController.songDuration, @"songDuration",
                [NSNumber numberWithLongLong:_mainController.audioPlayer.currentTime.value],@"songPositionValue",
                [NSNumber numberWithInt:_mainController.audioPlayer.currentTime.timescale],@"songPositionScale",
                _mainController.saveRate,@"songRate",
                _mainController.artistDisplayLabel.text,@"artistDisplayLabel",
                _mainController.titleDisplayLabel.text,@"titleDisplayLabel",
                _mainController.markPosition, @"markPosition",
                        nil];
    
    [storeDictionary writeToFile:_transportFilePath atomically:YES];
    
    // save the PersistentIDs of all the media items (songs) on the
    // playlist, so that we can recreate the MPmediaItemCollection of user chosen songs.
    NSMutableArray *persistentIDs = [NSMutableArray arrayWithCapacity:[_mainController.songQueue.items count]];
    
    for (MPMediaItem* song in (NSArray*)_mainController.songQueue.items) {
        [persistentIDs addObject:[song valueForProperty:MPMediaItemPropertyPersistentID]];
    }
    NSArray *storePlaylist = [NSArray arrayWithArray:persistentIDs];
    [storePlaylist writeToFile:_playlistFilePath atomically:YES];
       
    NSLog(@"Saved state");
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
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
