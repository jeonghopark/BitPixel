#pragma once

#include "ofMain.h"
#include "ofxiOS.h"
#include "ofxiOSExtras.h"

#include "ofxCv.h"
#include "ofxOpenCv.h"

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
    ofxTonicSynth synth6;
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
    int oldNoteIndex6;
    void noteTrigger();

    
    // Main
    int screenW, screenH;
    
    
    //openCV
    ofVideoGrabber cam;
    ofImage edge;
    ofPixels gray;
    bool camOpen;
    float cannyThreshold1;
    float cannyThreshold2;
    float grayThreshold;
    
    ofImage bufferImg;
    
    // Basic Pixels
    float pixelStepS;
    int changeVideoWidth, changeVideoHeight;
    vector<float> pixelBright;
    void pixelTriangleDraw();
    int thresholdValue;
    vector<blackWhitePixels> whitePixels;
    vector<blackWhitePixels> blackPixels;
    blackWhitePixels _wPix;
    int pixelCircleSize;
    
    //Video
    int videoGrabberW, videoGrabberH, camSize, changedCamSize;
    float cameraScreenRatio;

    
    // Graphics
    void playingCircleNotes();
    void playingShapeNotes();
    
    // control Panel
    void controlElementDraw();
    void debugControlPDraw();
    float ctrlPnX, ctrlPnY, ctrlPnW, ctrlPnH;
    int guideWidthStepSize, guideHeightStepSize;
    int maxSpeed, minSpeed;
    void controlGuide();


    float ctrlRectS;

    ofPoint speedCPos;
    float speedCSize;
    bool bSpeedCtrl;
    
    ofPoint thresholdCPos;
    float thresholdCSize;
    bool bthresholdCtrl;
    
    ofPoint intervalPos;
    float intervalSize;
    bool bInterval;
    
    // base Interface
    void baseInterface();
    ofPoint base5Pos;
    ofPoint base6Pos;
    ofPoint base7Pos;
    ofPoint base8Pos;
    float baseSize;
    void drawShapeCeterLine(ofPoint pos, int base, int size);
    void drawShape(ofPoint pos, int base, int size);
    void pixelShapeDraw();
    void pixelShapeColorSizeDraw();
    
    
    int baseSelection;
    
    
    ofxCvGrayscaleImage grayImage;
    
    // Information
    void information();
    ofTrueTypeFont informationText;
    int fontSize;
    
    // Decimal to N Base
    vector<int> convertDecimalToNBase(int n, int base, int size);

    // Line Score
    void lineScoreDraw();
    float oldScoreNote1, oldScoreNote2, oldScoreNote3, oldScoreNote4, oldScoreNote5, oldScoreNote6;
    
    vector<int> scoreNote1, scoreNote2, scoreNote3, scoreNote4, scoreNote5, scoreNote6;
    int lineScoreStepX, lineScoreStepY;
    void scoreMake();
    void noteTrig();
    
    
    // note scale selector
    int noteSelector(int _n, int _index, int _subIndex);
    void scaleChange();

    int intervalDist;
    
};


