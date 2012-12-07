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
    //NSString *filePath;
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
//@synthesize userMediaItemCollection = _userMediaItemCollection;
@synthesize playing = _playing;
@synthesize songDuration = _songDuration;
@synthesize updateSlider =_updateSlider;
@synthesize saveRate = _saveRate;
@synthesize songPath = _songPath;
@synthesize filePath = _filePath;



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
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAmbient error: nil];
    NSError *activationError = nil;
	[[AVAudioSession sharedInstance] setActive: YES error: &activationError];
    
    // inits not dependant on store file
    self.rateSlider.MaximumValue = 1.00;
    self.rateSlider.MinimumValue = 0.5;
    self.volumeSlider.minimumValueImage = [UIImage imageNamed:@"soft-crop.png"];
    self.volumeSlider.maximumValueImage = [UIImage imageNamed:@"loud-crop.png"];
    self.playing = false;

    // Read song data file, if it exists.
    BOOL initWithFile = false;
    NSDictionary *storeDictionary = (NSDictionary *)[NSDictionary dictionaryWithContentsOfFile:self.filePath];
    
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
            self.positionSlider.value = (float)((numerator/denominator)/[self.songDuration floatValue]);
            self.rateSlider.value = [[storeDictionary objectForKey:@"songRate"] floatValue];
            self.rateLabel.text = [NSString stringWithFormat:@"%d%%",(int)(self.rateSlider.value*100)];
            self.saveRate = [storeDictionary objectForKey:@"songRate"];
            self.artistDisplayLabel.text = [storeDictionary objectForKey:@"artistDisplayLabel"];
            self.titleDisplayLabel.text = [storeDictionary objectForKey:@"titleDisplayLabel"];
            self.timeDisplayLabel.text = [storeDictionary objectForKey:@"timeDisplayLabel"];
            self.durationLabel.text = [storeDictionary objectForKey:@"durationLabel"];
            self.sliderIncrement = 1/(10*[self.songDuration doubleValue]);
            [self changeVolume: 0.5];
            
            initWithFile = true;
            
        } else {
            NSLog(@"Didn't get a player");
        }
    } else {
        NSLog(@"No store dictionary.");
    }

    if (!initWithFile) {
        self.positionSlider.value = 0.0;
        self.rateSlider.value = 1.0;
    }
}
/*
NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:position];
NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
[dateFormatter setDateFormat:@"mm:ss"];
[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
NSMutableString *displayString=(NSMutableString *)[dateFormatter stringFromDate:timerDate];
self.timeDisplayLabel.text =[NSString stringWithFormat:@"%@%@",displayString,tenths];
 */
- (void) updateTimer // Called by an NSTimer in playOrPause that fires every 0.1 sec
                     // during playback to update the time display and slider poistion.
{
    float position = (float) self.audioPlayer.currentTime.value/self.audioPlayer.currentTime.timescale;
    //NSTimeInterval position = self.audioPlayer.currentTime.value/self.audioPlayer.currentTime.timescale;
    //if (position < 0) {
    if (position >= [self.songDuration doubleValue]){
        [self toStart:self];
        return;
    }
    NSMutableString *tenths = [NSMutableString stringWithFormat:@"%.1f",position - floor(position)];
    NSRange range = NSMakeRange(0,1);
    [tenths deleteCharactersInRange:range];
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:position];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    NSMutableString *displayString=(NSMutableString *)[dateFormatter stringFromDate:timerDate];
    self.timeDisplayLabel.text =[NSString stringWithFormat:@"%@%@",displayString,tenths];
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
    NSLog(@"In to start");
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
    //NSLog(@"self.positionSlider.value: %f",self.positionSlider.value;
    
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

#pragma mark Media Picker stuff

// Configures and displays the media item picker.
- (IBAction) showMediaPicker: (id) sender {
    
	MPMediaPickerController *picker =
    [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];
	
	picker.delegate						= self;
	picker.allowsPickingMultipleItems	= NO;
	picker.prompt						= NSLocalizedString (@"iTunes Library", @"Prompt to user to choose some songs to play");
    
	[self presentModalViewController: picker animated: YES];
}

// Media Picker delegate protocol

// Responds to the user tapping Done after choosing music.
- (void) mediaPicker: (MPMediaPickerController *) mediaPicker didPickMediaItems: (MPMediaItemCollection *) mediaItemCollection {
    
    [self dismissModalViewControllerAnimated: YES];
    
   // if (self.playing) {
    //    [self playOrPause:self];
    //}
     
    MPMediaItem *song = [mediaItemCollection.items objectAtIndex:0];
    
   
    self.artistDisplayLabel.text = [NSString stringWithFormat:@"%@ - %@",[song valueForProperty:MPMediaItemPropertyArtist],[song valueForProperty:MPMediaItemPropertyAlbumTitle]];
    self.titleDisplayLabel.text = [song valueForProperty:MPMediaItemPropertyTitle];
    
    self.songPath = [song valueForProperty: MPMediaItemPropertyAssetURL];
    self.audioPlayer = [[AVPlayer alloc] initWithURL: self.songPath];
    self.audioPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    self.songDuration =  [song valueForProperty: MPMediaItemPropertyPlaybackDuration];
    
    // all this to format the duration label
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:[self.songDuration floatValue]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    NSString *displayString=[dateFormatter stringFromDate:timerDate];
    self.durationLabel.text = displayString;
    
    self.timeDisplayLabel.text = @"00:00.0";
    self.positionSlider.value = 0.0;
    self.sliderIncrement = 1/(10*[self.songDuration doubleValue]);
    self.playing = false;
    self.rateSlider.value = 1.0;
    self.rateLabel.text = [NSString stringWithFormat:@"100%%"];
    self.saveRate = [NSNumber numberWithFloat:1.0];
    [self changeVolume: 0.5];
    self.volumeSlider.value = 0.5;
}

// Responds to the user tapping done having chosen no music.
- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker {
    
	[self dismissModalViewControllerAnimated: YES];
    
	//[[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque animated:YES];
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
    [super viewDidUnload];
}
@end
