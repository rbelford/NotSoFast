//
//  TransportViewController.h
//  TaskTimer
//
//  Created by rbelford on 11/9/12.
//  Copyright (c) 2012 rbelford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVPlayer.h>
#import <MediaPlayer/MediaPlayer.h>
//.#import <AudioToolbox/AudioToolbox.h>
#import "AppDelegate.h"


@interface TransportViewController : UIViewController <AVAudioPlayerDelegate>

{
    
}

@property (nonatomic, retain) IBOutlet UILabel *timeDisplayLabel;
@property (strong, nonatomic) IBOutlet UILabel *titleDisplayLabel;
@property (strong, nonatomic) IBOutlet UILabel *artistDisplayLabel;
@property (strong, nonatomic) IBOutlet UILabel *rateLabel;
@property (strong, nonatomic) IBOutlet UILabel *durationLabel;
@property (nonatomic, retain) IBOutlet UIButton *playPauseButton;
@property (nonatomic, retain) IBOutlet UISlider *positionSlider;
@property (nonatomic, retain) IBOutlet UISlider *rateSlider;
@property (strong, nonatomic) IBOutlet UISlider *volumeSlider;
@property (strong, nonatomic) IBOutlet UILabel *markDisplay;
@property (nonatomic, retain) AVPlayer *audioPlayer;
@property (nonatomic,retain) MPMediaItemCollection	*songQueue;
@property (nonatomic, retain) NSString *transportFilePath; // path to song state file
@property (nonatomic,retain) NSURL *songPath;     // URL to song in iTunes library
@property (nonatomic,retain) NSNumber *songDuration;
@property (nonatomic,retain) NSNumber *saveRate; // Calls to play and pause set rate to 1.0 and 0.0, so we need to save and restore our (potentially altered) rate
@property (nonatomic,retain) NSNumber *markPosition;
@property (nonatomic,retain) NSTimer *displayTimer;
@property  CGFloat sliderIncrement; // each update moves the position slider by this much
@property BOOL playing;
@property BOOL updateSlider; // only if updateTimer isn't because user moved position slider

- (IBAction) playOrPause: (id) sender;
- (IBAction) movedPositionSlider: (id) sender;
- (IBAction) movedRateSlider: (id) sender;
- (IBAction) movedVolumeSlider: (id) sender;
- (IBAction) startFForward: (id) sender;
- (IBAction) endFForward: (id) sender;
- (IBAction) startRewind: (id) sender;
- (IBAction) endRewind: (id) sender;
- (IBAction) toStart: (id) sender;
- (IBAction) fiftyPercent:(id)sender;
- (IBAction) seventyFivePercent:(id)sender;
- (IBAction) hundredPercent:(id)sender;
- (IBAction) plusTenth:(id)sender;
- (IBAction) minusTenth:(id)sender;
- (IBAction) setMark:(id)sender;
- (IBAction) toMark:(id)sender;

- (void)     loadSong: (MPMediaItem*) song;
- (void)     changeVolume: (float) value;
@end

