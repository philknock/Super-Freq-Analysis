//
//  SecondViewController.h
//  Super Freq Analysis
//
//  Created by Phil Knock on 10/21/15.
//  Copyright (c) 2015 Phillip Knock. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EZAudio.h"

#define kAudioFilePath @"TestImpulseRecording.m4a"

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

@property (weak, nonatomic) IBOutlet UILabel *readyLabel;

@property (weak, nonatomic) IBOutlet UISlider *gainSlider;

@property (weak, nonatomic) IBOutlet UIButton *recordButton;

@property (weak, nonatomic) IBOutlet UITextField *fileNameTextField;

@property (weak, nonatomic) IBOutlet UILabel *dBLabel;

@property (weak, nonatomic) IBOutlet UILabel *rmsLabel;

@property (weak, nonatomic) IBOutlet UILabel *rt60Label;
#pragma mark Actions

- (IBAction)gainAdjusted:(id)sender;

-(IBAction)playFile:(id)sender;

- (IBAction)alertButtonPressed:(id)sender;


- (IBAction)recordButtonPressed:(id)sender;

@end

