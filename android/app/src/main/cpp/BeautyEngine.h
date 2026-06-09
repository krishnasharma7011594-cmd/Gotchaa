#ifndef BEAUTY_ENGINE_H
#define BEAUTY_ENGINE_H

#include <opencv2/opencv.hpp>
#include <vector>

struct BeautySettings {
    float smoothness;
    float tone;
    float makeupIntensity;
    float blemishRemoval;
};

struct FaceLandmark {
    float x;
    float y;
};

class BeautyEngine {
public:
    BeautyEngine();
    ~BeautyEngine();

    void processFrame(cv::Mat& frame, const std::vector<FaceLandmark>& landmarks, const BeautySettings& settings);

private:
    void applyRegionalSmoothing(cv::Mat& frame, const std::vector<FaceLandmark>& landmarks, float intensity);
    void applyBlemishRemoval(cv::Mat& frame, const std::vector<FaceLandmark>& landmarks, float intensity);
    void applyMakeup(cv::Mat& frame, const std::vector<FaceLandmark>& landmarks, float intensity);
    
    cv::Mat skinMask;
};

#endif // BEAUTY_ENGINE_H
