//
//  CVWrapper.m
//  CVOpenTemplate
//
//  Created by Washe on 02/01/2013.
//  Copyright (c) 2013 foundry. All rights reserved.
//

#import "CVWrapper.h"
#import "UIImage+OpenCV.h"
#import "stitching.h"
#import "UIImage+Rotate.h"

#import "opencv2/core/core.hpp"
#import "opencv2/features2d/features2d.hpp"
#import "opencv2/highgui/highgui.hpp"
#import "opencv2/calib3d/calib3d.hpp"
#import "opencv2/nonfree/nonfree.hpp"
#import "opencv2/imgproc/imgproc.hpp"

using namespace cv;

@implementation CVWrapper

+ (UIImage*) processImageWithOpenCV: (UIImage*) inputImage
{
    NSArray* imageArray = [NSArray arrayWithObject:inputImage];
    UIImage* result = [[self class] processWithArray:imageArray];
    return result;
}

+ (UIImage*) processWithOpenCVImage1:(UIImage*)inputImage1 image2:(UIImage*)inputImage2;
{
    NSArray* imageArray = [NSArray arrayWithObjects:inputImage1,inputImage2,nil];
    UIImage* result = [[self class] processWithArray:imageArray];
    return result;
}

+ (UIImage*) processWithArray:(NSArray*)imageArray
{
    if ([imageArray count]==0){
        NSLog (@"imageArray is empty");
        return 0;
    }
    vector<Mat> matImages;
    
    for (id image in imageArray) {
        if ([image isKindOfClass: [UIImage class]]) {
            /*
             All images taken with the iPhone/iPa cameras are LANDSCAPE LEFT orientation. The  UIImage imageOrientation flag is an instruction to the OS to transform the image during display only. When we feed images into openCV, they need to be the actual orientation that we expect them to be for stitching. So we rotate the actual pixel matrix here if required.
             */
            UIImage* rotatedImage = [image rotateToImageOrientation];
            Mat matImage = [rotatedImage CVMat3];
            NSLog (@"matImage: %@",image);
            matImages.push_back(matImage);
        }
    }
    NSLog (@"stitching...");
    Mat stitchedMat = stitch (matImages);
    UIImage* result =  [UIImage imageWithCVMat:stitchedMat];
    return result;
}

+ (UIImage*) check2Images:(UIImage*)inputImage1 image2:(UIImage*)inputImage2;
{
    Mat img_object = [inputImage1 CVMat3];
    Mat img_scene  = [inputImage2 CVMat3];
    
    //-- Step 1: Detect the keypoints using SURF Detector
    int minHessian = 400;
    SurfFeatureDetector detector( minHessian );
    std::vector<KeyPoint> keypoints_object, keypoints_scene;
    detector.detect( img_object, keypoints_object );
    detector.detect( img_scene, keypoints_scene );
    
    //-- Step 2: Calculate descriptors (feature vectors)
    SurfDescriptorExtractor extractor;
    Mat descriptors_object, descriptors_scene;
    extractor.compute( img_object, keypoints_object, descriptors_object );
    extractor.compute( img_scene, keypoints_scene, descriptors_scene );
    
    //-- Step 3: Matching descriptor vectors using FLANN matcher
    FlannBasedMatcher matcher;
    std::vector< DMatch > matches;
    matcher.match( descriptors_object, descriptors_scene, matches );
    double max_dist = 0; double min_dist = 100;
    
    //-- Quick calculation of max and min distances between keypoints
    for( int i = 0; i < descriptors_object.rows; i++ ) { double dist = matches[i].distance;
        if( dist < min_dist ) min_dist = dist;
        if( dist > max_dist ) max_dist = dist;
    }
    printf("-- Max dist : %f \n", max_dist );
    printf("-- Min dist : %f \n", min_dist );
    
    //-- Draw only "good" matches (i.e. whose distance is less than 3*min_dist )
    std::vector< DMatch > good_matches;
    
    for( int i = 0; i < descriptors_object.rows; i++ ) {
        if( matches[i].distance < 3*min_dist ) {
            good_matches.push_back( matches[i]);
        }
    }
    Mat img_matches;
    drawMatches( img_object, keypoints_object, img_scene, keypoints_scene,
                good_matches, img_matches, Scalar::all(-1), Scalar::all(-1),
                vector<char>(), DrawMatchesFlags::NOT_DRAW_SINGLE_POINTS );
    //-- Localize the object
    std::vector<Point2f> obj;
    std::vector<Point2f> scene;
    
    for( int i = 0; i < good_matches.size(); i++ )
    {
        //-- Get the keypoints from the good matches
        obj.push_back( keypoints_object[ good_matches[i].queryIdx ].pt );
        scene.push_back( keypoints_scene[ good_matches[i].trainIdx ].pt );
    }
    Mat H = findHomography( obj, scene, CV_RANSAC );
    //-- Get the corners from the image_1 ( the object to be "detected" )
    std::vector<Point2f> obj_corners(4);
    obj_corners[0] = cvPoint(0,0); obj_corners[1] = cvPoint( img_object.cols, 0 );
    obj_corners[2] = cvPoint( img_object.cols, img_object.rows ); obj_corners[3] = cvPoint( 0, img_object.rows );
    std::vector<Point2f> scene_corners(4);
    
    perspectiveTransform( obj_corners, scene_corners, H);
    
    //-- Draw lines between the corners (the mapped object in the scene - image_2 )
    line( img_matches, scene_corners[0] + Point2f( img_object.cols, 0), scene_corners[1] + Point2f( img_object.cols, 0), cvScalar(0, 255, 0), 4 );
    line( img_matches, scene_corners[1] + Point2f( img_object.cols, 0), scene_corners[2] + Point2f( img_object.cols, 0), cvScalar( 0, 255, 0), 4 );
    line( img_matches, scene_corners[2] + Point2f( img_object.cols, 0), scene_corners[3] + Point2f( img_object.cols, 0), cvScalar( 0, 255, 0), 4 );
    line( img_matches, scene_corners[3] + Point2f( img_object.cols, 0), scene_corners[0] + Point2f( img_object.cols, 0), cvScalar( 0, 255, 0), 4 );
    
    //    //-- Show detected matches
    //    imshow( "Good Matches & Object detection", img_matches );
    return [UIImage imageWithCVMat:img_matches];
}

int maxCorners = 23;
int maxTrackbar = 100;
Mat src, src_gray;
RNG rng(12345);
//char* source_window = "Image";

+ (UIImage*) getRectangleImage:(UIImage*)inputImage1;
{
    src = [inputImage1 CVMat3];
    cvtColor( src, src_gray, CV_BGR2GRAY );
    
    /// Create Trackbar to set the number of corners
//    createTrackbar( "Max  corners:", source_window, &maxCorners, maxTrackbar, goodFeaturesToTrack_Demo );
    
//    imshow( source_window, src );
    
    Mat img_matches = goodFeaturesToTrack_Demo( 0, 0 );
    return [UIImage imageWithCVMat:img_matches];
}

// * @function goodFeaturesToTrack_Demo.cpp
// * @brief Apply Shi-Tomasi corner detector
Mat goodFeaturesToTrack_Demo( int, void* )
{
    if( maxCorners < 1 ) { maxCorners = 1; }
    
    /// Parameters for Shi-Tomasi algorithm
    vector<Point2f> corners;
    double qualityLevel = 0.01;
    double minDistance = 10;
    int blockSize = 3;
    bool useHarrisDetector = false;
    double k = 0.04;
    
    /// Copy the source image
    Mat copy;
    copy = src.clone();
    
    /// Apply corner detection
    goodFeaturesToTrack(src_gray,
                        corners,
                        maxCorners,
                        qualityLevel,
                        minDistance,
                        Mat(),
                        blockSize,
                        useHarrisDetector,
                        k
                        );
    
    /// Draw corners detected
    std::cout<<"** Number of corners detected: "<<corners.size()<<std::endl;
    int r = 4;
    for( int i = 0; i < corners.size(); i++ )
    { circle( copy, corners[i], r, Scalar(rng.uniform(0,255), rng.uniform(0,255),
                                          rng.uniform(0,255)), -1, 8, 0 ); }
    /// Show what you got
//    namedWindow( source_window, CV_WINDOW_AUTOSIZE );
//    imshow( source_window, copy );
    return copy;
}

@end
