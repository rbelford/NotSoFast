//
//  PlayListViewController.h
//  TaskTimer
//
//  Created by rbelford on 12/9/12.
//  Copyright (c) 2012 rbelford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "TransportViewController.h"

@protocol PlayListViewControllerDelegate; // forward declaration

@interface PlayListViewController : UITableViewController <MPMediaPickerControllerDelegate,UITableViewDelegate> {
    id 	<PlayListViewControllerDelegate> delegate;
}

@property (strong)  TransportViewController	*transport;


@property (strong, nonatomic) IBOutlet UITableView *mediaCollectionTable;
@property (nonatomic,retain) MPMediaItemCollection	*userMediaItemCollection;

- (IBAction) showMediaPicker: (id) sender;
- (IBAction) doneShowingMusicList: (id) sender;
- (IBAction) choseSong:(UILongPressGestureRecognizer *)gesture;
@end

@protocol PlayListViewControllerDelegate

- (void) updatePlayerQueueWithMediaCollection: (MPMediaItemCollection *) mediaItemCollection;

@end