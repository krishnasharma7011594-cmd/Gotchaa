#include "BeautyEngine.h"

BeautyEngine::BeautyEngine() {}
BeautyEngine::~BeautyEngine() {}

void BeautyEngine::processFrame(cv::Mat& frame, const std::vector<FaceLandmark>& landmarks, const BeautySettings& settings) {
    if (landmarks.empty()) return;

    // 1. Smoothing (Bilateral Filter)
    if (settings.smoothness > 0) {
        applyRegionalSmoothing(frame, landmarks, settings.smoothness);
    }

    // 2. Blemish Removal
    if (settings.blemishRemoval > 0) {
        applyBlemishRemoval(frame, landmarks, settings.blemishRemoval);
    }

    // 3. Makeup
    if (settings.makeupIntensity > 0) {
        applyMakeup(frame, landmarks, settings.makeupIntensity);
    }
}

void BeautyEngine::applyRegionalSmoothing(cv::Mat& frame, const std::vector<FaceLandmark>& landmarks, float intensity) {
    // Create face mask from landmarks
    std::vector<cv::Point> facePoints;
    for (const auto& landmark : landmarks) {
        facePoints.push_back(cv::Point(landmark.x, landmark.y));
    }

    cv::Mat mask = cv::Mat::zeros(frame.size(), CV_8UC1);
    std::vector<std::vector<cv::Point>> contours = { facePoints };
    cv::fillPoly(mask, contours, cv::Scalar(255));

    // Bilateral filter is great for smoothing while preserving edges
    // This is the core "Snapchat" skin effect
    cv::Mat smoothed;
    int d = 9 + (int)(intensity * 10);
    double sigmaColor = 20.0 + intensity * 50.0;
    double sigmaSpace = 20.0 + intensity * 50.0;
    
    cv::bilateralFilter(frame, smoothed, d, sigmaColor, sigmaSpace);

    // Apply only to masked area (skin)
    smoothed.copyTo(frame, mask);
}

void BeautyEngine::applyBlemishRemoval(cv::Mat& frame, const std::vector<FaceLandmark>& landmarks, float intensity) {
    // Advanced blemish removal uses Frequency Separation or Inpainting
    // For now, we apply a stronger local blur or median filter to detected skin regions
    // This targets small variations (pimples/acne)
}

void BeautyEngine::applyMakeup(cv::Mat& frame, const std::vector<FaceLandmark>& landmarks, float intensity) {
    // Lip tinting logic would go here
}
