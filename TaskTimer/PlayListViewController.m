//
//  PlayListViewController.m
//  TaskTimer
//
//  Created by rbelford on 12/9/12.
//  Copyright (c) 2012 rbelford. All rights reserved.
//

#import "PlayListViewController.h"
#import "TransportViewController.h"

@interface PlayListViewController ()

@end

@implementation PlayListViewController

@synthesize userMediaItemCollection = _userMediaItemCollection;
@synthesize transport = _transport;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // appDelegate.m reads in a saved playlist, which gets attached to the transport controller on our behalf.
    // Get a pointer to the Transport controller, and then a pointer to that song queue.
    NSArray *viewControllers = self.navigationController.viewControllers;
    self.transport = [viewControllers objectAtIndex:viewControllers.count - 2];
    self.userMediaItemCollection = self.transport.songQueue;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSLog(@"In Number of Sections: %d",[self.userMediaItemCollection count]);
    return [self.userMediaItemCollection count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myCell" ];
    if (cell == nil) {
        
        NSArray *topLevelObjects = [[NSBundle mainBundle]
                                    loadNibNamed:@"myCell"
                                    owner:nil options:nil];
        
        for (id currentObject in topLevelObjects){
            if ([currentObject isKindOfClass:[UITableViewCell class]]){
                cell = (UITableViewCell *) currentObject;
                break;
            }
        }
    }
    MPMediaItem *anItem = (MPMediaItem *)[self.userMediaItemCollection.items objectAtIndex: indexPath.row];
	if (anItem) {
		cell.textLabel.text = [anItem valueForProperty:MPMediaItemPropertyTitle];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@",[anItem valueForProperty:MPMediaItemPropertyAlbumTitle],[anItem valueForProperty:MPMediaItemPropertyArtist]];
	}
    return cell;
}

- (IBAction) choseSong:(UILongPressGestureRecognizer *) gesture {
    if (gesture.state != UIGestureRecognizerStateBegan)
    {
        return;
    }
    // get the long touch spot in the table view, and use it to find row
    CGPoint p = [gesture locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    NSLog(@"row: %d",indexPath.row);
    //[self.navigationController popViewControllerAnimated: YES];
    [self.transport loadSong: [self.userMediaItemCollection.items objectAtIndex:indexPath.row]];
    [self.navigationController popViewControllerAnimated: YES];
}

#pragma mark - Table view delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete a song. Song queue is immutable, so put the queue in a mutable array.
        NSArray* items = [self.userMediaItemCollection items];
        NSMutableArray* array = [NSMutableArray arrayWithCapacity:[items count]];
        [array addObjectsFromArray:items];
        [array removeObjectAtIndex:indexPath.row];
        
        // update the media player queue minus deleted song.  reload table.
        self.userMediaItemCollection = [MPMediaItemCollection collectionWithItems: (NSArray *) array];
        self.transport.songQueue = self.userMediaItemCollection;
        [self.mediaCollectionTable reloadData];   
     } else if (editingStyle == UITableViewCellEditingStyleInsert) {
     // This is for adding a new table entry.  We add with the media picker.
     }
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
	[tableView deselectRowAtIndexPath: indexPath animated: YES];
}

// Configures and displays the media item picker.
- (IBAction) showMediaPicker: (id) sender {
    
	MPMediaPickerController *picker =
    [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];
	
	picker.delegate						= self;
	picker.allowsPickingMultipleItems	= YES;
	picker.prompt						= NSLocalizedString (@"iTunes Library", @"Prompt to user to choose some songs to play");
    
	[self presentModalViewController: picker animated: YES];
}

#pragma mark - media picker delegate

// Responds to the user tapping Done after choosing music.
- (void) mediaPicker: (MPMediaPickerController *) mediaPicker didPickMediaItems: (MPMediaItemCollection *) mediaItemCollection {
    
	[self dismissModalViewControllerAnimated: YES];
	[self updatePlayerQueueWithMediaCollection: mediaItemCollection];
    self.transport.songQueue = self.userMediaItemCollection;
	[self.mediaCollectionTable reloadData];
   }

// Responds to the user tapping done having chosen no music.
- (void) mediaPickerDidCancel: (MPMediaPickerController *) mediaPicker {
	[self dismissModalViewControllerAnimated: YES];
}

// When the user taps Done, invokes the delegate's method that dismisses the table view.
- (IBAction) doneShowingMusicList: (id) sender {
    
	//[self.delegate musicTableViewControllerDidFinish: self];
}

// Invoked by the delegate of the media item picker when the user is finished picking music.
- (void) updatePlayerQueueWithMediaCollection: (MPMediaItemCollection *) mediaItemCollection {
    
	// Configure the music player, but only if the user chose at least one song to play
	if (mediaItemCollection) {
		// If there's no playback queue yet...
		if (self.userMediaItemCollection == nil) {
			// apply the new media item collection as a playback queue for the music player
			[self setUserMediaItemCollection: mediaItemCollection];
            self.transport.songQueue = self.userMediaItemCollection;
            
             [self dismissModalViewControllerAnimated: YES];
		} else { // Combine the previously-existing media item collection with the new one
			NSMutableArray *combinedMediaItems	= [[self.userMediaItemCollection items] mutableCopy];
			NSArray *newMediaItems = [mediaItemCollection items];
			[combinedMediaItems addObjectsFromArray: newMediaItems];
			[self setUserMediaItemCollection: [MPMediaItemCollection collectionWithItems: (NSArray *) combinedMediaItems]];
            self.transport.songQueue = self.userMediaItemCollection;
        }
    }
}
@end
