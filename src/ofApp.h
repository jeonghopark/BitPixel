#pragma once

#include "ofMain.h"
#include "ofxiOS.h"
#include "ofxiOSExtras.h"

#include "ofxCv.h"

#include "ofxTonic.h"

struct blackWhitePixels{
    int indexPos;
    int pixelN;
    int firstValue;
    vector<int> numberPixels;
};

struct colorPixels{
    int indexPos;
    int pixelN;
    int firstValue;
    vector<int> numberPixels;
};


using namespace Tonic;


class ofApp : public ofxiOSApp {
    
    ofxTonicSynth synth1;
    ofxTonicSynth synth2;
    ofxTonicSynth synth3;
    ofxTonicSynth synth4;
    ofxTonicSynth synth5;
    ofxTonicSynth synthMain;
    
public:
    void setup();
    void update();
    void draw();
    void exit();
    
    void touchDown(ofTouchEventArgs & touch);
    void touchMoved(ofTouchEventArgs & touch);
    void touchUp(ofTouchEventArgs & touch);
    void touchDoubleTap(ofTouchEventArgs & touch);
    void touchCancelled(ofTouchEventArgs & touch);
    
    void lostFocus();
    void gotFocus();
    void gotMemoryWarning();
    void deviceOrientationChanged(int newOrientation);
    
    void audioRequested (float * output, int bufferSize, int nChannels);

    
    bool bPlayNote;

    
    // ofxTonic
    ofxTonicSynth createSynthVoiceIn();
    ofxTonicSynth controlSynthParameter;
    void synthSetting();
    ControlGenerator bpm;
    ControlGenerator metro;
    ofEvent<float> * metroOut;
    void triggerReceive(float & metro);
    int index;
    int noteIndex;
    int oldNoteIndex1;
    int oldNoteIndex2;
    int oldNoteIndex3;
    int oldNoteIndex4;
    int oldNoteIndex5;
    void noteTrigger1(int _index);

    
    //openCV
    ofVideoGrabber cam;
    ofImage edge;
    ofPixels gray;
    bool camOpen;
    
    //Pixels
    float pixelStepS;
    int changeVideoWidth, changeVideoHeight;
    vector<float> pixelBright;
    void pixelDraw();
    int thresholdValue;
    vector<blackWhitePixels> blackPixels;
    vector<blackWhitePixels> whitePixels;
    blackWhitePixels _wPix;
    int pixelCircleSize;
    
    //Video
    int videoGrabberW, videoGrabberH, camSize, changedCamSize;
    float cameraScreenRatio;


    // DataConvert
    string decimalToBinary(int decimal);
    string binaryString;

    
    
};


