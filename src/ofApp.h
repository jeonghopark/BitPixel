#pragma once

#include "ofMain.h"
#include "ofxiOS.h"
#include "ofxiOSExtras.h"

#include "ofxCv.h"
#include "ofxOpenCv.h"
#include "ofxTonic.h"

#include "ScaleSetting.h"


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
    ofxTonicSynth synth7;
    ofxTonicSynth synthMain;
    
    const bool WHITE_VIEW = true;

    
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
    void audioReceived(float * input, int bufferSize, int nChannels);

    
    bool bPlayNote;
    bool bCameraCapturePlay;

    
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
    int oldNoteIndex7;
    void noteTrigger();

    
    // Main
    int screenW, screenH;
    
    
    //openCV
    ofVideoGrabber cam;
    ofImage squareCam;
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
    void drawTrianglePixel();
    int thresholdValue;
    vector<blackWhitePixels> whitePixels;
    vector<blackWhitePixels> blackPixels;
    blackWhitePixels _wPix;
    int pixelCircleSize;
    
    //Video
    int videoGrabberW, videoGrabberH, camSize, changedCamSize;
    float cameraScreenRatio;

    
    // Graphics
    void drawPixelNumbersCircleNotes();
    void drawPlayingShapeNotes();
    
    void drawPlayingShapeNote( vector<int> _vNote, int _scoreCh );
    
    // control Panel
    void drawControlElement();
    void debugControlPDraw();
    float ctrlPnX, ctrlPnY, ctrlPnW, ctrlPnH;
    int guideWidthStepSize, guideHeightStepSize;
    int maxSpeed, minSpeed;
    void controlGuide();

    float stepBasePos;
    
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
    void drawBaseInterface();
    ofPoint base4Pos;
    ofPoint base5Pos;
    ofPoint base6Pos;
    ofPoint base7Pos;
    ofPoint base8Pos;
    ofPoint base9Pos;
    float baseSize;
    void drawShapeCeterLine(ofPoint pos, int base, int size, ofColor _c);
    void drawShapeCeterLineColorRotation(ofPoint pos, int base, int size, ofColor color);
    void drawShape(ofPoint pos, int base, int size);
    void drawPixelAllNoteShape();
    void drawPixelAllNoteShapes( vector<int> _vNote, int _scoreCh );
    void drawPixelShapeColorSize();
    
    
    int baseSelection;
    
    
    ofxCvGrayscaleImage grayImage;
    
    
    // Decimal to N Base
    vector<int> convertDecimalToNBase(int n, int base, int size);

    // Line Score
    void drawLineScore();
    float oldScoreNote1, oldScoreNote2, oldScoreNote3, oldScoreNote4, oldScoreNote5, oldScoreNote6, oldScoreNote7;
    
    vector<int> scoreNote1, scoreNote2, scoreNote3, scoreNote4, scoreNote5, scoreNote6, scoreNote7;
    int lineScoreStepX, lineScoreStepY;
    void scoreMake();
    void noteTrig();
    
    
    int intervalDist;
    
    ScaleSetting scaleSetting;
    
    
    int playOldNote1;
    int drawOldPointNote1;
    int drawOldLineNote1;
    
    
    void drawScoreCircleLine( vector<int> _vNote, int _scoreCh );
    void trigScoreNote( vector<int> _vNote, ofxTonicSynth _synthIn, int _scoreCh );
    
    
    float pixeShapeSize;
    
    ofImage backgroundControPanel;
    
    
    int lineScoreNumber;
    
    bool bIPhone;
    float shiftValueIphoneY;
    
//    ofSoundStream soundStream;
    
    
    float touchDownDefault;
    
    vector<ofVec2f> touchPos;
    vector<bool> ctrlSlider;
    float distS[2];
    float distI[2];
};


