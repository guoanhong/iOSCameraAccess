//
//  ViewController.m
//  iOSCameraAccess
//
//  Created by Anhong Guo on 2/26/18.
//  Copyright © 2018 Guo Anhong. All rights reserved.
//

#import "ViewController.h"

#import <opencv2/calib3d.hpp>
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/video.hpp>
#import <opencv2/xfeatures2d.hpp>
#import <AudioToolbox/AudioToolbox.h>

using namespace cv;
using namespace cv::xfeatures2d;

@interface ViewController () <CvVideoCameraDelegate>

// Camera and ImageView
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic) CvVideoCamera *videoCamera;

// Sound
@property (nonatomic) SystemSoundID highBeepSoundID;
@property (nonatomic) SystemSoundID lowBeepSoundID;

@end

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.videoCamera start];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.delegate = self;
    
    // Create 'high beep' sound.
    NSURL *highBeepSoundURL = [[NSBundle mainBundle] URLForResource:@"beep_high" withExtension:@"aif"];
    SystemSoundID highBeepSoundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)highBeepSoundURL, &highBeepSoundID);
    self.highBeepSoundID = highBeepSoundID;
    
    // Create 'low beep' sound.
    NSURL *lowBeepSoundURL = [[NSBundle mainBundle] URLForResource:@"beep_low" withExtension:@"aif"];
    SystemSoundID lowBeepSoundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)lowBeepSoundURL, &lowBeepSoundID);
    self.lowBeepSoundID = lowBeepSoundID;
}

- (void)processImage:(Mat&)rawImageBGRA {
    // Code to process image
    
    // Styles
    Scalar blueColor = Scalar(210, 139, 38, 255);
    Scalar pinkColor = Scalar(130, 54, 211, 255);
    int thickness = 2;
    int fontFace = FONT_HERSHEY_SIMPLEX;
    
    // FPS start
    NSDate *processImageDate = [NSDate date];
    
    // Defines roi
    float widthPercent = 0.2;
    float heightPercent = 0.1;
    cv::Point center(rawImageBGRA.cols/2, rawImageBGRA.rows/2);
    cv::Rect roi(rawImageBGRA.cols/2 * (1-widthPercent/2),
                 rawImageBGRA.rows/2 * (1-heightPercent/2),
                 rawImageBGRA.cols/2 * widthPercent,
                 rawImageBGRA.rows/2 * heightPercent );
    
    // Draws roi
    rectangle(rawImageBGRA, roi, pinkColor, 3);
    
    // Copies input image in roi
    cv::Mat imageRoiBGRA = rawImageBGRA( roi );
    
    // Change color image to gray
    cv::Mat imageRoiGRAY(cv::Size(roi.width, roi.height), CV_8UC1);
    cvtColor(imageRoiBGRA, imageRoiGRAY, CV_BGRA2GRAY);
    
    // Computes mean over roi
    cv::Scalar avgPixelIntensity = cv::mean( imageRoiGRAY );
    
    // Play sound
    // TODO: need to change the sound frequency dynamically with tone generator
    // TODO: need to control the frequency which the sound is played
    //    if (avgPixelIntensity.val[0] > 127) {
    //        AudioServicesPlaySystemSound(self.highBeepSoundID);
    //    } else {
    //        AudioServicesPlaySystemSound(self.lowBeepSoundID);
    //    }
    
    // Draw on screen, .val[0] since image was grayscale
    NSString *intensityString = [NSString stringWithFormat:@"avg over ROI:%.0f", avgPixelIntensity.val[0]];
    putText(rawImageBGRA, intensityString.UTF8String,
            cv::Point(30, rawImageBGRA.rows - 80), fontFace, 1.6, blueColor,
            thickness);
    
    // FPS end, and draw on screen
    double processImageFPS = fabs(1 / [processImageDate timeIntervalSinceNow]);
    NSString *ftpString = [NSString stringWithFormat:@"fps:%.2f", processImageFPS];
    putText(rawImageBGRA, ftpString.UTF8String,
            cv::Point(30, rawImageBGRA.rows - 30), fontFace, 1.6, pinkColor,
            thickness);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    AudioServicesDisposeSystemSoundID(self.highBeepSoundID);
    AudioServicesDisposeSystemSoundID(self.lowBeepSoundID);
}


@end
