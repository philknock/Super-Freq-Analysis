//
//  SecondViewController.h
//  Super Freq Analysis
//
//  Created by Phil Knock on 10/21/15.
//  Copyright (c) 2015 Phillip Knock. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EZAudio.h"

#define kAudioFilePath @"EZAudioTest.m4a"

@interface SecondViewController : UIViewController <EZAudioPlayerDelegate,EZMicrophoneDelegate,EZRecorderDelegate>



@property (nonatomic,assign) BOOL isRecording;


#pragma mark EZAudio

@property (nonatomic,strong) EZAudioPlayer *player;

@property (nonatomic,strong) EZRecorder *recorder;

@property (nonatomic,weak) IBOutlet EZAudioPlot *playbackAudioPlot;

@property (nonatomic,strong) EZMicrophone *microphone;

@property (nonatomic,weak) IBOutlet EZAudioPlotGL *recordingAudioPlot;

#pragma mark UI Properties

@property (nonatomic,weak) IBOutlet UIButton *playButton;

@property (nonatomic,weak) IBOutlet UILabel *playingStateLabel;

@property (nonatomic,weak) IBOutlet UILabel *recordingStateLabel;

@property (nonatomic,weak) IBOutlet UILabel *microphoneStateLabel;

@property (nonatomic,weak) IBOutlet UILabel *playbackTimeLabel;

@property (weak, nonatomic) IBOutlet UISlider *gainSlider;

@property (nonatomic,weak) UISwitch *recordSwitch;

@property (nonatomic,weak) IBOutlet UISwitch *microphoneSwitch;

@property (weak, nonatomic) IBOutlet UIButton *recordButton;

#pragma mark Actions

- (IBAction)gainAdjusted:(id)sender;

-(IBAction)playFile:(id)sender;

-(IBAction)toggleMicrophone:(id)sender;

-(IBAction)toggleRecording:(id)sender;

- (IBAction)recordButtonPressed:(id)sender;

@end

