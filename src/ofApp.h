#pragma once

#include "ofMain.h"
#include "ofxiOS.h"
#include "ofxiOSExtras.h"

#include "ofxCv.h"

#include "ofxTonic.h"

using namespace Tonic;



class ofApp : public ofxiOSApp {
    
    ofxTonicSynth synth1;
    ofxTonicSynth synth2;
    ofxTonicSynth synth3;
    ofxTonicSynth synth4;
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

    
    // ofxTonic
    ofxTonicSynth createSynthVoiceIn();
    ofxTonicSynth controlSynthParameter;
    void synthSetting();
    ControlGenerator bpm;
    ControlGenerator metro;
    ofEvent<float> * metroOut;

    
    //openCV
    ofVideoGrabber cam;
    ofImage edge;
    ofPixels gray;
    bool camOpen;
    
    
};


