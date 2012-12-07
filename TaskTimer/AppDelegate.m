//
//  AppDelegate.m
//  TaskTimer
//
//  Created by rbelford on 9/22/12.
//  Copyright (c) 2012 rbelford. All rights reserved.
//

#import "AppDelegate.h"
//#import "PlayListViewController.h"
#import "TransportViewController.h"

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVPlayer.h>

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>



@interface AppDelegate () {
}



@end

NSString *_filePath;
TransportViewController *_mainController;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // get a pointer to the transportViewController, so we can write out its state in 
    // applicationWillResignActive:.
    
    UINavigationController *nav = (UINavigationController *) self.window.rootViewController;
    _mainController = (TransportViewController *) nav.topViewController;
    
    // Put file handle for reading store in the _mainController so it can read the file we write.
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    _filePath = [documentsDirectory stringByAppendingPathComponent:@"nsf"];
    _mainController.filePath = _filePath;
   
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    if (_mainController.playing) {
        //[_mainController.audioPlayer pause];
        //[_mainController playOrPause:self];
    }
    
    // write the app state to disk
    NSDictionary *storeDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                _mainController.songPath.absoluteString, @"songPath",
                _mainController.songDuration, @"songDuration",
                [NSNumber numberWithLongLong:_mainController.audioPlayer.currentTime.value],@"songPositionValue",
                [NSNumber numberWithInt:_mainController.audioPlayer.currentTime.timescale],@"songPositionScale",
                _mainController.saveRate,@"songRate",
                _mainController.artistDisplayLabel.text,@"artistDisplayLabel",
                _mainController.titleDisplayLabel.text,@"titleDisplayLabel",
                // these next 2 are fairly costly to derive.  Let's just store them.
                _mainController.timeDisplayLabel.text,@"timeDisplayLabel",
                _mainController.durationLabel.text,@"durationLabel",
                        nil];
    
    [storeDictionary writeToFile:_filePath atomically:YES];
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
