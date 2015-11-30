////
////  SecondViewController.m
////  Super Freq Analysis
////
////  Created by Phil Knock on 10/21/15.
////  Copyright (c) 2015 Phillip Knock. All rights reserved.
////


#import "SecondViewController.h"
#import "MBProgressHUD.h"



@implementation SecondViewController

NSString* customFileName = kAudioFilePath;
BOOL halfSecondElapsed = NO;
BOOL threesElapsed = NO;
BOOL recordingImpulse = NO;
float dB;
float peakdB;
float startTime;
float elapsedTime;
float rms = 0.0;
float accumulator = 0.0;
float deltaY = 0.0;
float rt60Approx = 0.0;
//float noiseFloor = 0.0;
int count = 0;

//------------------------------------------------------------------------------
#pragma mark - Dealloc
//------------------------------------------------------------------------------

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//------------------------------------------------------------------------------
#pragma mark - Status Bar Style
//------------------------------------------------------------------------------

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

//------------------------------------------------------------------------------
#pragma mark - Setup
//------------------------------------------------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    [self.gainSlider setValue:(1.0/10.0)];
    
    self.isRecording = NO;
    
    //
    // Setup the AVAudioSession. EZMicrophone will not work properly on iOS
    // if you don't do this!
    //
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error)
    {
        NSLog(@"Error setting up audio session category: %@", error.localizedDescription);
    }
    [session setActive:YES error:&error];
    if (error)
    {
        NSLog(@"Error setting up audio session active: %@", error.localizedDescription);
    }
    
    CAGradientLayer *backgroundGradient = [CAGradientLayer layer];
    backgroundGradient.frame = self.view.bounds;
    backgroundGradient.colors = [NSArray arrayWithObjects:
                                 (id)[[UIColor colorWithRed:(44/255.0) green:(44/255.0) blue:(44/255.0) alpha:1.0] CGColor],
                                 (id)[[UIColor colorWithRed:(183/255.0) green:(183/255.0) blue:(183/255.0) alpha:1.0] CGColor], nil];
    [self.view.layer insertSublayer:backgroundGradient atIndex:0];
    
    //
    // Customizing the audio plot that'll show the current microphone input/recording
    //
    //self.recordingAudioPlot.backgroundColor = [UIColor colorWithRed: 0.984 green: 0.71 blue: 0.365 alpha: 1];
    self.recordingAudioPlot.color           = [UIColor colorWithRed:(30/255.0) green:(30/255.0) blue:(30/255.0) alpha:1.0];
    self.recordingAudioPlot.backgroundColor =[UIColor colorWithRed:(183/255.0) green:(183/255.0) blue:(183/255.0) alpha:1.0];
    
    self.recordingAudioPlot.plotType        = EZPlotTypeRolling;
    self.recordingAudioPlot.shouldFill      = YES;
    self.recordingAudioPlot.shouldMirror    = YES;
    
    //
    // Customizing the audio plot that'll show the playback
    //
    self.playbackAudioPlot.color = [UIColor whiteColor];
    self.playbackAudioPlot.plotType = EZPlotTypeRolling;
    self.playbackAudioPlot.shouldFill = YES;
    self.playbackAudioPlot.shouldMirror = YES;
    self.playbackAudioPlot.gain = 2.5f;
    
    // Create an instance of the microphone and tell it to use this view controller instance as the delegate
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
    self.player = [EZAudioPlayer audioPlayerWithDelegate:self];
    
    //
    // Initialize UI components
    //

    self.playButton.enabled = NO;
    [self.playButton setBackgroundColor:[UIColor grayColor]];
    
    self.recordButton.layer.cornerRadius = 10;
    self.recordButton.clipsToBounds = YES;
    
    self.playButton.layer.cornerRadius = 10;
    self.playButton.clipsToBounds = YES;
    
    //
    // Setup notifications
    //
    [self setupNotifications];
    
    //
    // Log out where the file is being written to within the app's documents directory
    //
    NSLog(@"File written to application sandbox's documents directory: %@",[self testFilePathURL]);
    
    //
    // Start the microphone
    //
    [self.microphone startFetchingAudio];
    
    peakdB = -INFINITY;
}


- (void) viewDidAppear:(BOOL)animated{
    
    [self animateReadyLabel];
    
    //[self timingFunction : YES];
    
    NSTimer *halfSecondTimer = [NSTimer scheduledTimerWithTimeInterval: 0.2
                                                  target: self
                                                selector:@selector(halfSecondTick)
                                                userInfo: nil repeats:YES];
    
    // Timer for resetting peak after time interval
    NSTimer *threeTimer = [NSTimer scheduledTimerWithTimeInterval: 3.0
                                                                target: self
                                                              selector:@selector(threeTick)
                                                              userInfo: nil repeats:YES];
    
}

- (void) viewWillDisappear:(BOOL)animated{
    
    //[self timingFunction:NO];
}

//------------------------------------------------------------------------------

- (void)setupNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerDidChangePlayState:)
                                                 name:EZAudioPlayerDidChangePlayStateNotification
                                               object:self.player];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerDidReachEndOfFile:)
                                                 name:EZAudioPlayerDidReachEndOfFileNotification
                                               object:self.player];
}

//------------------------------------------------------------------------------
#pragma mark - Notifications
//------------------------------------------------------------------------------

- (void)playerDidChangePlayState:(NSNotification *)notification
{
    EZAudioPlayer *player = [notification object];
    BOOL isPlaying = [player isPlaying];
    if (isPlaying)
    {
        self.recorder.delegate = nil;
    }

    self.playbackAudioPlot.hidden = !isPlaying;
}

//------------------------------------------------------------------------------

- (void)playerDidReachEndOfFile:(NSNotification *)notification
{
    [self.playbackAudioPlot clear];
    [self.microphone startFetchingAudio];
    
}

//------------------------------------------------------------------------------
#pragma mark - Actions
//------------------------------------------------------------------------------

- (IBAction)gainAdjusted:(id)sender {
    
    [self.recordingAudioPlot setGain:(10 * self.gainSlider.value)];
    [self.playbackAudioPlot setGain:(10 * self.gainSlider.value)];
    
}



- (IBAction)alertButtonPressed:(id)sender {
    NSLog(@"Alert Button Pressed");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"FileName" message:@"Please enter a name for the audio file. Press the info button to see how to access it." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (IBAction)recordButtonPressed:(id)sender {
    
    peakdB = -INFINITY;
    
    [self.player pause];
    
    [self.readyLabel setHidden:YES];
    
    if (self.isRecording) {
        
        // If RT60 is measured from when the user stops recording
        
//        elapsedTime = CACurrentMediaTime() - startTime;
//
//        NSLog(@"Duration: %lf", elapsedTime);
//
        
        [self.recordButton setTitle:@"Record" forState:UIControlStateNormal];
        
        
        [self.playButton setBackgroundColor:[UIColor blueColor]];
        self.playButton.enabled = YES;
        
        [self.microphone stopFetchingAudio];
        //[self.recordingAudioPlot clear];
        
        [self.recorder closeAudioFile];
        
        // Fancy Progress HUD
        
        MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.view.superview];
        [self.view.superview addSubview:HUD];
        
        HUD.delegate = self;
        HUD.labelText = @"Saving File ...";
        HUD.dimBackground = YES;
        
        [HUD showWhileExecuting:@selector(sleepyTime) onTarget:self withObject:nil animated:YES];
        
        elapsedTime = 0.0;
        
        recordingImpulse = NO;
        
        [self.rt60Label setText: [[NSNumber numberWithFloat:rt60Approx] stringValue]];
    }
    else{
        
        [self.recordButton setTitle:@"Stop" forState:UIControlStateNormal];
        
        count = 0;
        accumulator = 0;
        
        //
        // Create the recorder
        //
        [self.recordingAudioPlot clear];
        
        [self.recordingAudioPlot setGain:(10 * self.gainSlider.value)];
        [self.playbackAudioPlot setGain:(10 * self.gainSlider.value)];
        
        self.recordingAudioPlot.color = [UIColor colorWithRed:(223/255.0) green:(53/255.0) blue:(53/255.0) alpha:1.0];
        
        [self.microphone startFetchingAudio];
        self.recorder = [EZRecorder recorderWithURL:[self customURL]
                                       clientFormat:[self.microphone audioStreamBasicDescription]
                                           fileType:EZRecorderFileTypeM4A
                                           delegate:self];
        
        
    }
    
    // Yeah, you toggle that Boolean
    self.isRecording = !self.isRecording;
}

- (void)playFile:(id)sender
{
    [self.recordButton setTitle:@"Record" forState:UIControlStateNormal];
    
    [self.recordingAudioPlot setGain:(10 * self.gainSlider.value)];
    [self.playbackAudioPlot setGain:(10 * self.gainSlider.value)];
    
    //
    // Update microphone state
    //
    [self.microphone stopFetchingAudio];
    
    //
    // Update recording state
    //
    self.isRecording = NO;
    //
    // Close the audio file
    //
    if (self.recorder)
    {
        [self.recorder closeAudioFile];
    }
    
//    EZAudioFile *audioFile = [EZAudioFile audioFileWithURL:[self testFilePathURL]];
//    [self.player playAudioFile:audioFile];

    EZAudioFile *audioFile = [EZAudioFile audioFileWithURL:[self customURL]];
    [self.player playAudioFile:audioFile];
    
    [self.recordingAudioPlot clear];
    
    recordingImpulse = NO;
    
//    [[NSFileManager defaultManager] createFileAtPath:(NSString*)[self customURL]
//                                            contents:(NSData*)audioFile
//                                          attributes:nil];
}




//------------------------------------------------------------------------------




- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    // If user presses "Save" button
    if (buttonIndex == 1) {
        
        customFileName = [[alertView textFieldAtIndex:0] text];
        
        // Ensuring ".m4a" is appended to the filename only if it has to be
        
        NSRange range = [customFileName rangeOfString:@".m4a" options:NSCaseInsensitiveSearch];
        
        if ( !(range.location != NSNotFound &&
            range.location + range.length == [customFileName length] ))
        {
            NSLog(@"%@ doesnt end with .m4a",customFileName);
                    customFileName = [customFileName stringByAppendingString:(@".m4a")];
        }
        

        NSLog(@"Audio File Name: %@" , customFileName);
        
        [self.fileNameTextField setText:customFileName];
        
    }
    
    [self.microphone startFetchingAudio];
}

//------------------------------------------------------------------------------
#pragma mark - EZMicrophoneDelegate
//------------------------------------------------------------------------------

- (void)microphone:(EZMicrophone *)microphone changedPlayingState:(BOOL)isPlaying
{

}

//------------------------------------------------------------------------------

#warning Thread Safety
// Note that any callback that provides streamed audio data (like streaming microphone input) happens on a separate audio thread that should not be blocked. When we feed audio data into any of the UI components we need to explicity create a GCD block on the main thread to properly get the UI to work.
- (void)   microphone:(EZMicrophone *)microphone
     hasAudioReceived:(float **)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels
{
    // Getting audio data as an array of float buffer arrays. What does that mean? Because the audio is coming in as a stereo signal the data is split into a left and right channel. So buffer[0] corresponds to the float* data for the left channel while buffer[1] corresponds to the float* data for the right channel.
    
    // See the Thread Safety warning above, but in a nutshell these callbacks happen on a separate audio thread. We wrap any UI updating in a GCD block on the main thread to avoid blocking that audio flow.
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        // All the audio plot needs is the buffer data (float*) and the size. Internally the audio plot will handle all the drawing related code, history management, and freeing its own resources. Hence, one badass line of code gets you a pretty plot :)
        [weakSelf.recordingAudioPlot updateBuffer:buffer[0]
                                   withBufferSize:bufferSize];
        
        //NSLog(@"Buffer Size: %u", (unsigned int)bufferSize);
        
        
        // dB equation
        dB = 20 * log10f(fabsf(*buffer[0]));
        
        // Measuring Peak dB
        if (dB > peakdB){
            peakdB = dB;
            
            if (self.isRecording){
                // Here we are recording an impulse!
                // Start Timing Now
                startTime = CACurrentMediaTime();
                recordingImpulse = YES;
            }
            
        }
        

//            NSLog(@"Peak: %f" , peakdB);
//            NSLog(@"Delta Y: %f" , deltaY);
//            NSLog(@"Db: %f" , dB);
        
            // Calculating RMS
        
            count ++;
        
            accumulator = accumulator + powf(dB , 2.0);

            rms = sqrtf((accumulator)/count);
        
            
            if (recordingImpulse){
                deltaY = peakdB - dB;
                
            if (deltaY >= 60)
            {
                // True RT60, Not likely to happen
                elapsedTime = CACurrentMediaTime() - startTime;
                
                // Scaling Factor
                rt60Approx = (deltaY/elapsedTime * 0.01);
                NSLog(@"Time to decay 60 dB: %lf", rt60Approx);
                
                
            }
            else if (deltaY >= 30)
                // Otherwise measure against noise floor?
                elapsedTime = 2.0 * (CACurrentMediaTime() - startTime);
                // Scaling Factor
                rt60Approx = (deltaY/elapsedTime * 0.01);
                NSLog(@"Time to decay 30 dB: %lf", rt60Approx);
            
            
        }

        // Update Peak dB and RMS labels
         if (halfSecondElapsed){
             
            [self.dBLabel setText: [[NSNumber numberWithFloat:peakdB] stringValue]];
             
             [self.rmsLabel setText: [[NSNumber numberWithFloat:rms] stringValue]];
             
             halfSecondElapsed = !halfSecondElapsed;
        }

         //Clear Peak dB label after time interval
        if(threesElapsed && !(self.isRecording)){

            [self.dBLabel setText: [[NSNumber numberWithFloat:dB] stringValue]];
            
            peakdB = -INFINITY;
            
            NSLog(@"clear Peak %lf", dB);
            
            threesElapsed = !threesElapsed;
        }

        
        //NSLog(@"Output: %f", dB);
    });
}

//------------------------------------------------------------------------------

- (void)   microphone:(EZMicrophone *)microphone
        hasBufferList:(AudioBufferList *)bufferList
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels
{
    // Getting audio data as a buffer list that can be directly fed into the EZRecorder. This is happening on the audio thread - any UI updating needs a GCD main queue block. This will keep appending data to the tail of the audio file.
    if (self.isRecording)
    {
        [self.recorder appendDataFromBufferList:bufferList
                                 withBufferSize:bufferSize];
    }
}

//------------------------------------------------------------------------------
#pragma mark - EZRecorderDelegate
//------------------------------------------------------------------------------

- (void)recorderDidClose:(EZRecorder *)recorder
{
    recorder.delegate = nil;
}

//------------------------------------------------------------------------------

- (void)recorderUpdatedCurrentTime:(EZRecorder *)recorder
{
    // We don't need to keep track of the current time
    
//    __weak typeof (self) weakSelf = self;
//    NSString *formattedCurrentTime = [recorder formattedCurrentTime];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        weakSelf.playbackTimeLabel.text = formattedCurrentTime;
//    });
}

//------------------------------------------------------------------------------
#pragma mark - EZAudioPlayerDelegate
//------------------------------------------------------------------------------

- (void) audioPlayer:(EZAudioPlayer *)audioPlayer
         playedAudio:(float **)buffer
      withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels
         inAudioFile:(EZAudioFile *)audioFile
{
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.playbackAudioPlot updateBuffer:buffer[0]
                                 withBufferSize:bufferSize];
    });
}

//------------------------------------------------------------------------------

- (void)audioPlayer:(EZAudioPlayer *)audioPlayer
    updatedPosition:(SInt64)framePosition
        inAudioFile:(EZAudioFile *)audioFile
{
//    __weak typeof (self) weakSelf = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        weakSelf.playbackTimeLabel.text = [audioPlayer formattedCurrentTime];
//    });
}

//------------------------------------------------------------------------------
#pragma mark - Utility
//------------------------------------------------------------------------------

- (NSArray *)applicationDocuments
{
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
}

//------------------------------------------------------------------------------

- (NSString *)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

//------------------------------------------------------------------------------

- (NSURL *)testFilePathURL
{
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",
                                   [self applicationDocumentsDirectory],
                                   kAudioFilePath]];
}

- (NSURL *)customURL
{

    
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [self applicationDocumentsDirectory], customFileName]];
}

- (void) animateReadyLabel {

    
//    while (![self.readyLabel isHidden])
//         {
    
//            //NSLog(@"current time: %f", CACurrentMediaTime());
//            
//             float absSineValue = fabsf(sinf(2.0 * M_PI * counter));
//             
//             [self.readyLabel.alpha = absSineValue;
//             
//             //NSLog(@"%f",absSineValue);
//
        
    
             
             [self.readyLabel setAlpha:0.0f];
             
             //fade in
             [UIView animateWithDuration:0.5f animations:^{
                 
                 [self.readyLabel setAlpha:1.0f];
                 
             } completion:^(BOOL finished) {
                 
                 //fade out
                 [UIView animateWithDuration:0.5f animations:^{
                     
                     [self.readyLabel setAlpha:0.0f];
                     
                 } completion:nil];
                 
             }];
    
}

#pragma mark Helper Methods

- (void) halfSecondTick {
    //NSLog(@"One Second %@", halfSecondElapsed ? @"YES" : @"NO");
    halfSecondElapsed = !halfSecondElapsed;
}

- (void) threeTick {
    //NSLog(@"One Second %@", halfSecondElapsed ? @"YES" : @"NO");
    threesElapsed = !threesElapsed;
}


- (void) sleepyTime{
    sleep(1);
    
    // Back to grey color
    [self.recordingAudioPlot clear];
    self.recordingAudioPlot.color           = [UIColor colorWithRed:(30/255.0) green:(30/255.0) blue:(30/255.0) alpha:1.0];
    [self.microphone startFetchingAudio];
}

@end
