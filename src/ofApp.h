#pragma once

#include "ofMain.h"
#include "ofxiOS.h"
#include "ofxiOSExtras.h"

#include "ofxCv.h"
#include "ofxOpenCv.h"
#include "ofxTonic.h"

#include "ScaleSetting.h"

#define NUM_SYNTH_LINE 7

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
    
    ofxTonicSynth synth[NUM_SYNTH_LINE];
    ofxTonicSynth synthMain;
    
    const bool WHITE_VIEW = false;
    
    
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
    int oldNoteIndex[NUM_SYNTH_LINE];
    
    
    // Main
    void setIPad();
    void setIPhone();
    void drawIPad();
    void drawIPhone();
    float screenW, screenH;
    
    float iPhonePreviewSize;
    
    void mainCameraCaptureViewiPhone();
    
    ofImage debugCameraImage;
    
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
    void drawIPhoneTrianglePixel();
    int thresholdValue;
    vector<blackWhitePixels> whitePixels;
    vector<blackWhitePixels> blackPixels;
    blackWhitePixels _wPix;
    int pixelCircleSize;
    
    //Video
    float videoGrabberW, videoGrabberH, camSize, changedCamSize;
    float cameraScreenRatio;
    
    
    // Graphics
    void drawPixelNumbersCircleNotes();
    void drawPlayingShapeNotes();
    
    void drawPlayingShapeNote( vector<int> _vNote, int _scoreCh );
    
    // control Panel
    void drawControlElementIPad();
    void drawControlElementIPhone();
    void debugControlPDraw();
    float ctrlPnX, ctrlPnY, ctrlPnW, ctrlPnH;
    int guideWidthStep, guideHeightStep;
    int maxSpeed, minSpeed;
    
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
    
    void drawShapeWithCenterlines(ofPoint pos, int base, int size, ofColor _c);
    void drawShapeFillColor(ofPoint pos, int base, int size, ofColor _c);

    
    void activeShapeFillColor(ofPoint pos, int base, int size, ofColor _c);
    float activeSpeed;
    float activeFactor;
    
    void drawShapeWithCenterlinesColorRotation(ofPoint pos, int base, int size, ofColor color);
    void drawShape(ofPoint pos, int base, int size);
    void drawPixelAllNoteShape();
    void drawPixelAllNoteShapesIPad( vector<int> _vNote, int _scoreCh );
    void drawPixelAllNoteShapesIPhone( vector<int> _vNote, int _scoreCh );
    
    void drawElemIntervalShape();
    void drawElemSpeedShape();
    
    int baseSelection;
    
    
    ofxCvGrayscaleImage grayImage;
    
    
    // Decimal to N Base
    vector<int> convertDecimalToNBase(int n, int base, int size);
    
    // Line Score
    void drawLineScoreIPad();
    void drawLineScoreIPhone();
    float oldScoreNote[NUM_SYNTH_LINE];
    
    vector<int> scoreNote[NUM_SYNTH_LINE];
    float lineScoreStepX, lineScoreStepY;
    void scoreMake();
    
    int intervalDist;
    
    ScaleSetting scaleSetting;
    
    
    int playOldNote1;
    int drawOldPointNote1;
    int drawOldLineNote1;
    
    
    void drawScoreCircleLineIPad( vector<int> _vNote, int _scoreCh );
    void drawScoreCircleLineIPhone( vector<int> _vNote, int _scoreCh );
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
    
    // iPhone
    float screenPosRightY, screenPosLeftY, screenPosBottom;
    float lineScoreRightX;
    float controlObjectLineWidth;
    
    ofColor colorVar[NUM_SYNTH_LINE];
    ofColor contourLineColor;
    ofColor eventColor;
    ofColor backgroundColor;
    ofColor uiLineColor;
    
    
    void drawCircle(ofColor c, int xNumber,  vector<int> scoreNote, float stepX, float stepY, int scoreCh, int xDefaultPos);
    void drawLine(ofColor c, int xNumber,  vector<int> scoreNote, float stepX, float stepY, int scoreCh, int xDefaultPos);
    
    
    void calculatePixels(ofImage _img);
    
    
    void iPhoneTouchDown(ofTouchEventArgs & touch);
    void iPadTouchDown(ofTouchEventArgs & touch);

    void iPhoneTouchMoved(ofTouchEventArgs & touch);
    void iPadTouchMoved(ofTouchEventArgs & touch);

    void iPhoneTouchUp(ofTouchEventArgs & touch);
    void iPadTouchUp(ofTouchEventArgs & touch);

    
    void menuImgSetup();
    void menuImgDraw(bool playOn);
    
    ofRectangle composingMode;
    ofImage capture;
    
    ofRectangle libaryImport;
    ofImage importImg;
    
    ofRectangle cameraChange;
    ofImage changeCamera;

    ofRectangle returnCapture;
    ofImage returnCaptureMode;

};


