//
//  TransportViewController.m
//  TaskTimer
//
//  Created by rbelford on 11/9/12.
//  Copyright (c) 2012 rbelford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "TransportViewController.h"
#import <AVFoundation/AVPlayer.h>

@interface TransportViewController (){
}
@end

const float FAST_FORWARD_RATE = 4.0;
const int BILLION = 1000000000;

@implementation TransportViewController

@synthesize positionSlider = _positionSlider;
@synthesize rateSlider = _rateSlider;
@synthesize rateLabel = _rateLabel;
@synthesize volumeSlider = _volumeSlider;
@synthesize audioPlayer = _audioPlayer;
@synthesize playPauseButton = _playPauseButton;
@synthesize timeDisplayLabel = _timeDisplayLabel;
@synthesize titleDisplayLabel = _titleDisplayLabel;
@synthesize artistDisplayLabel = _artistDisplayLabel;
@synthesize displayTimer = _displayTimer;
@synthesize sliderIncrement = _sliderIncrement;
@synthesize songQueue = _songQueue;
@synthesize playing = _playing;
@synthesize songDuration = _songDuration;
@synthesize updateSlider =_updateSlider;
@synthesize saveRate = _saveRate;
@synthesize markPosition = _markPosition;
@synthesize songPath = _songPath;
@synthesize transportFilePath = _transportFilePath;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // FOR TESTING ///// BE CAREFUL!!!!!!!
    //[[NSFileManager defaultManager] removeItemAtPath: self.filePath error: nil];
    //////// !!!!!!!
    
    // set up the audio session
    [[AVAudioSession sharedInstance] setDelegate: self];
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback
                                           error: nil];
                                                 //AVAudioSessionCategoryPlayback
                                                // AVAudioSessionCategoryAmbient
    NSError *activationError = nil;
	[[AVAudioSession sharedInstance] setActive: YES error: &activationError];
    
    // inits not dependant on whether we have a store file
    self.rateSlider.MaximumValue = 1.00;
    self.rateSlider.MinimumValue = 0.5;
    self.volumeSlider.minimumValueImage = [UIImage imageNamed:@"soft-green-20.png"];
    self.volumeSlider.maximumValueImage = [UIImage imageNamed:@"loud-green-20.png"];
    self.playing = false;

    // Read transport state file, if it exists.
    BOOL initWithFile = false;
    NSDictionary *storeDictionary = (NSDictionary *)[NSDictionary dictionaryWithContentsOfFile:self.transportFilePath];
    
    if (storeDictionary) {
        NSLog(@"Have store dictionary.");
        // initalize the audio player with the stored URL
        self.songPath = [NSURL URLWithString: [storeDictionary objectForKey:@"songPath"]];
        self.audioPlayer = [[AVPlayer alloc] initWithURL: self.songPath];
               
        if (self.audioPlayer) {
            
            self.audioPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
            long long numerator = [[storeDictionary objectForKey:@"songPositionValue"] longLongValue];
            int denominator = [[storeDictionary objectForKey:@"songPositionScale"] intValue];
            [self.audioPlayer seekToTime: CMTimeMakeWithSeconds(numerator/BILLION,BILLION)];
            self.songDuration = [storeDictionary objectForKey:@"songDuration"];
            self.durationLabel.text = [self formatTime:[self.songDuration floatValue]];
            self.positionSlider.value = (float)((numerator/denominator)/[self.songDuration floatValue]);
            self.rateSlider.value = [[storeDictionary objectForKey:@"songRate"] floatValue];
            self.rateLabel.text = [NSString stringWithFormat:@"%d%%",(int)(self.rateSlider.value*100)];
            self.saveRate = [storeDictionary objectForKey:@"songRate"];
            self.artistDisplayLabel.text = [storeDictionary objectForKey:@"artistDisplayLabel"];
            self.titleDisplayLabel.text = [storeDictionary objectForKey:@"titleDisplayLabel"];
            self.timeDisplayLabel.text = [self formatTime:(float)((float)numerator/(float)denominator)];
            self.sliderIncrement = 1/(10*[self.songDuration doubleValue]);
            self.markPosition = [storeDictionary objectForKey:@"markPosition"];
            self.markDisplay.text = [self formatTime:[self.markPosition floatValue]];
            [self changeVolume: 0.5];
            
            initWithFile = true;
            
        } else {
            NSLog(@"Didn't get a player");
        }
    } else {
        NSLog(@"No store dictionary.");
    }

    if (!initWithFile) { // no stored state, set defaults
        self.positionSlider.value = 0.0;
        self.rateSlider.value = 1.0;
        self.markPosition = [NSNumber numberWithFloat:0.0];
    }
}

// Convert a time in seconds to a string - XX:XX.X 
- (NSString*) formatTime: (float) timeValue {
     NSMutableString *tenths = [NSMutableString stringWithFormat:@"%.1f",timeValue  -  floor(timeValue)];
     NSRange range = NSMakeRange(0,1);
     [tenths deleteCharactersInRange:range];
     NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeValue];
     NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
     [dateFormatter setDateFormat:@"mm:ss"];
     [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
     NSMutableString *displayString=(NSMutableString *)[dateFormatter stringFromDate:timerDate];
     return[NSString stringWithFormat:@"%@%@",displayString,tenths];
     
} 

- (void) updateTimer { // Called by an NSTimer in playOrPause that fires every 0.1 sec
                       // during playback to update parameters and displays
    float position = (float) self.audioPlayer.currentTime.value/self.audioPlayer.currentTime.timescale;
    if (position >= [self.songDuration doubleValue]) {
        [self toStart:self];
        return;
    }
    if (position > 0) {
        self.timeDisplayLabel.text = [self formatTime: position];
    } else {
        self.timeDisplayLabel.text = @"00:00.0"; // don't rewind display < 0
    }
    if (self.updateSlider) // only if we've come from timer, not slider move.
    {
        self.positionSlider.value += (self.sliderIncrement*self.audioPlayer.rate);
    } else {
        self.updateSlider = true;  // reset to true after slider move
    }
}

- (IBAction) playOrPause: (id) sender {
    if (self.playing) {  //  playing -> paused
        [self.playPauseButton setImage: [UIImage imageNamed:@"play-crop.png"] forState: UIControlStateNormal];
        [self.displayTimer invalidate];
        self.displayTimer = nil;
        self.updateSlider = true;
        [self updateTimer];
        self.saveRate = [NSNumber numberWithFloat: self.audioPlayer.rate];
        [self.audioPlayer pause];
        self.playing = false;
    } else {  // paused -> playing
        if (self.audioPlayer) {
            [self.playPauseButton setImage: [UIImage imageNamed:@"stop-crop.png"] forState: UIControlStateNormal];
            // Create a timer
            self.updateSlider = true;
            // Fire a timer every tenth of a second to update display.
            self.displayTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                             target:self
                                                           selector:@selector(updateTimer)
                                                           userInfo:nil
                                                            repeats:YES];
            [self.audioPlayer play];
            self.audioPlayer.rate = [self.saveRate floatValue];
            self.playing = true;
        }
    }
}

- (IBAction) toStart: (id) sender {
    // Need the block so that we wait for completion of seekToTime:
    [self.audioPlayer seekToTime: CMTimeMakeWithSeconds(0.0,BILLION) completionHandler:^(BOOL finished)
    {
        if (finished) {
            self.positionSlider.value = 0.0;
            self.updateSlider = false;
            [self updateTimer];
        }
    }];
}

- (IBAction) movedPositionSlider: (id) sender
{
    NSTimeInterval newTime = self.positionSlider.value*[self.songDuration floatValue];
    [self.audioPlayer seekToTime: CMTimeMakeWithSeconds(newTime,BILLION)];
    if (!self.playing) { // if the timer is running (playing), it will update us.
        self.updateSlider = false;
        [self updateTimer];
    }
}

- (IBAction)movedRateSlider: (id) sender {
    if (self.playing) {
        self.audioPlayer.rate = self.rateSlider.value;
    } else {
        self.saveRate = [NSNumber numberWithFloat:self.rateSlider.value];
    }
    self.rateLabel.text = [NSString stringWithFormat:@"%d%%",(int)(self.rateSlider.value*100)];
}

- (void) changeVolume: (float) newValue {
    
    // To change the volume we need to dig down into the asset containing the
    // current song, and send setVolume: to its input parameters.  I guess this is
    // the price you pay for wanting to play an iTunes library song through an AVPlayer
    // so that we can change the song rate.
    
    AVAsset *asset = self.audioPlayer.currentItem.asset;
    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams =[AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:newValue atTime:kCMTimeZero];
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }
    AVMutableAudioMix *volumeChangeMix = [AVMutableAudioMix audioMix];
    [volumeChangeMix setInputParameters:allAudioParams];
    [self.audioPlayer.currentItem setAudioMix:volumeChangeMix];
}

- (IBAction)plusTenth:(id)sender {
    if (!self.playing) {
         float position = (float) self.audioPlayer.currentTime.value/self.audioPlayer.currentTime.timescale;
        float newTime = position + 0.1;
        // Need the block so that we wait for completion of seekToTime:
        [self.audioPlayer seekToTime: CMTimeMakeWithSeconds(newTime,BILLION) completionHandler:^(BOOL finished)
         {
             if (finished) {
                 self.positionSlider.value = (float)newTime/[self.songDuration floatValue];
                 self.updateSlider = false;
                 [self updateTimer];
             }
         }];
    }
    self.updateSlider = false;
    [self updateTimer];
}

- (IBAction)minusTenth:(id)sender {
    if (!self.playing) {
        float position = (float) self.audioPlayer.currentTime.value/self.audioPlayer.currentTime.timescale;
        float newTime = position - 0.1;
        [self.audioPlayer seekToTime: CMTimeMakeWithSeconds(newTime,BILLION) completionHandler:^(BOOL finished)
         {
             if (finished) {
                 self.positionSlider.value = (float)newTime/[self.songDuration floatValue];
                 self.updateSlider = false;
                 [self updateTimer];
             }
         }];
    }
    self.updateSlider = false;
    [self updateTimer];
}

- (IBAction)setMark:(id)sender {
    self.markPosition = [NSNumber numberWithFloat:
                         (float) self.audioPlayer.currentTime.value/self.audioPlayer.currentTime.timescale];
    float position = [self.markPosition floatValue];
    self.markDisplay.text = [self formatTime: position];
    //self.markDisplay.text = self.timeDisplayLabel.text;
}

- (IBAction)toMark:(id)sender {
    // Need the block so that we wait for completion of seekToTime:
    [self.audioPlayer seekToTime: CMTimeMakeWithSeconds([self.markPosition floatValue],BILLION) completionHandler:^(BOOL finished)
     {
         if (finished) {
             self.positionSlider.value = (float)[self.markPosition floatValue]/[self.songDuration floatValue];
             self.updateSlider = false;
             [self updateTimer];
         }
     }];
   }

- (IBAction) movedVolumeSlider: (id) sender {
    
    [self changeVolume: self.volumeSlider.value];
}

- (IBAction)startFForward:(id)sender {
    if (self.playing) {
        self.saveRate = [NSNumber numberWithFloat:self.audioPlayer.rate];
        self.audioPlayer.rate = FAST_FORWARD_RATE;
    }
}

- (IBAction)endFForward:(id)sender {
    if (self.playing) {
        self.audioPlayer.rate = [self.saveRate floatValue];
    }
}

- (IBAction)startRewind:(id)sender {
    if (self.playing) {
        self.saveRate = [NSNumber numberWithFloat:self.audioPlayer.rate];
        self.audioPlayer.rate = -FAST_FORWARD_RATE;
    }
}

- (IBAction)endRewind:(id)sender {
    if (self.playing) {
        float position = (float) self.audioPlayer.currentTime.value/self.audioPlayer.currentTime.timescale;
        if (position < 0) {
            [self.audioPlayer seekToTime: CMTimeMakeWithSeconds(0.0,BILLION)];
        }
        self.audioPlayer.rate = [self.saveRate floatValue];
    }
}

- (IBAction)fiftyPercent:(id)sender {
    if (self.playing) {
        self.audioPlayer.rate = 0.5;
    } else {
        self.saveRate = [NSNumber numberWithFloat:0.5];
    }
    self.rateSlider.value = 0.5;
    self.rateLabel.text = [NSString stringWithFormat:@"50%%"];
}

- (IBAction)seventyFivePercent:(id)sender {
    if (self.playing) {
        self.audioPlayer.rate = 0.75;
    } else {
        self.saveRate = [NSNumber numberWithFloat:0.75];
    }
    self.rateSlider.value = 0.75;
     self.rateLabel.text = [NSString stringWithFormat:@"75%%"];
}

- (IBAction)hundredPercent:(id)sender {
    if (self.playing) {
        self.audioPlayer.rate = 1.0;
    } else {
        self.saveRate = [NSNumber numberWithFloat:1.0];
    }
    self.rateSlider.value = 1.0;
     self.rateLabel.text = [NSString stringWithFormat:@"100%%"];
}

// Called when user long presses on a song title in the table view.
- (void) loadSong: (MPMediaItem *) song {
    
    self.artistDisplayLabel.text = [NSString stringWithFormat:@"%@ - %@",[song valueForProperty:MPMediaItemPropertyArtist],[song valueForProperty:MPMediaItemPropertyAlbumTitle]];
    self.titleDisplayLabel.text = [song valueForProperty:MPMediaItemPropertyTitle];
    
    self.songPath = [song valueForProperty: MPMediaItemPropertyAssetURL];
    self.audioPlayer = [[AVPlayer alloc] initWithURL: self.songPath];
    self.audioPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    self.songDuration =  [song valueForProperty: MPMediaItemPropertyPlaybackDuration];
    self.durationLabel.text = [self formatTime: [self.songDuration floatValue]];
    self.timeDisplayLabel.text = @"00:00.0";
    self.positionSlider.value = 0.0;
    self.sliderIncrement = 1/(10*[self.songDuration doubleValue]);
    self.playing = false;
    self.rateSlider.value = 1.0;
    self.rateLabel.text = [NSString stringWithFormat:@"100%%"];
    self.saveRate = [NSNumber numberWithFloat:1.0];
    [self changeVolume: 0.5];
    self.volumeSlider.value = 0.5;
    self.markPosition = [NSNumber numberWithFloat:0.0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewDidUnload {
    [self setVolumeSlider:nil];
    [self setTitleDisplayLabel:nil];
    [self setArtistDisplayLabel:nil];
    [self setRateLabel:nil];
    [self setDurationLabel:nil];
    [self setMarkDisplay:nil];
    [super viewDidUnload];
}
@end
