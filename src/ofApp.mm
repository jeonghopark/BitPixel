#include "ofApp.h"

using namespace ofxCv;
using namespace cv;


//--------------------------------------------------------------
void ofApp::setup(){
    
    cam.setDeviceID(0);
    
    cam.setup( 480, 360 );
    
    synthSetting();
    
    bpm = synthMain.addParameter("tempo",120).min(50).max(300);
    metro = ControlMetro().bpm(4 * bpm);
    
    metroOut = synthMain.createOFEvent(metro);
    synthMain.setOutputGen(synth1 + synth2 + synth3);

    ofSoundStreamSetup(2, 0, this, 44100, 256, 4);

    
//    cam.setDesiredFrameRate(30);
//    cam.initGrabber( 480, 360 );

//    ofSetOrientation(OF_ORIENTATION_DEFAULT);

//    if ( !cam.isInitialized() ) {
//        return;
//    } else {
//    }

}

//--------------------------------------------------------------
void ofApp::update(){
    
    cam.update();
    
    if(cam.isFrameNew()) {
        convertColor(cam, gray, CV_RGB2GRAY);
        Canny(gray, edge, 120, 120, 3);
        thin(edge);
        edge.update();
    }

}

//--------------------------------------------------------------
void ofApp::draw(){
	
    ofPushStyle();
    ofSetColor( 80 );
    edge.draw(0, 0, 1546, 2048);
    ofPopStyle();

    ofPushStyle();
    ofSetColor( 40 );
    ofDrawRectangle( 0, 1546, 1546, 502 );
    ofPopStyle();

}

//--------------------------------------------------------------
void ofApp::exit(){

    cam.close();
    
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){

}

//--------------------------------------------------------------
void ofApp::gotFocus(){

}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){

}


//--------------------------------------------------------------
void ofApp::audioRequested (float * output, int bufferSize, int nChannels){
    
    synthMain.fillBufferOfFloats(output, bufferSize, nChannels);
    
}

//--------------------------------------------------------------
void ofApp::synthSetting(){
    
    ControlParameter carrierPitch1 = synth1.addParameter("carrierPitch1");
    float amountMod1 = 4;
    ControlGenerator rCarrierFreq1 = ControlMidiToFreq().input(carrierPitch1);
    ControlGenerator rModFreq1 = rCarrierFreq1 * 3.489;
    Generator modulationTone1 = SineWave().freq( rModFreq1 ) * rModFreq1 * amountMod1;
    Generator tone1 = SineWave().freq(rCarrierFreq1 + modulationTone1);
    ControlGenerator envelopTrigger1 = synth1.addParameter("trigger1");
    Generator env1 = ADSR().attack(0.001).decay(0.3).sustain(0).release(0).trigger(envelopTrigger1).legato(false);
    synth1.setOutputGen( tone1 * env1 * 0.75 );
    
    ControlParameter carrierPitch2 = synth2.addParameter("carrierPitch2");
    float amountMod2 = 1;
    ControlGenerator rCarrierFreq2 = ControlMidiToFreq().input(carrierPitch2);
    ControlGenerator rModFreq2 = rCarrierFreq2 * 3.489;
    Generator modulationTone2 = SineWave().freq( rModFreq2 ) * rModFreq2 * amountMod2;
    Generator tone2 = SineWave().freq(rCarrierFreq2 + modulationTone2);
    ControlGenerator envelopTrigger2 = synth2.addParameter("trigger2");
    Generator env2 = ADSR().attack(0.001).decay(0.1).sustain(0).release(0).trigger(envelopTrigger2).legato(false);
    synth2.setOutputGen( tone2 * env2 * 0.75 );
    
    ControlParameter carrierPitch3 = synth3.addParameter("carrierPitch3");
    float amountMod3 = 6;
    ControlGenerator rCarrierFreq3 = ControlMidiToFreq().input(carrierPitch3);
    ControlGenerator rModFreq3 = rCarrierFreq3 * 4.489;
    Generator modulationTone3 = SineWave().freq( rModFreq3 ) * rModFreq3 * amountMod3;
    Generator tone3 = SineWave().freq(rCarrierFreq3 + modulationTone3);
    ControlGenerator envelopTrigger3 = synth3.addParameter("trigger3");
    Generator env3 = ADSR().attack(0.001).decay(0.1).sustain(0).release(0).trigger(envelopTrigger3).legato(false);
    synth3.setOutputGen( tone3 * env3 * 0.75 );
    
    
}

