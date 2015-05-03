#include "ofApp.h"

using namespace ofxCv;
using namespace cv;


//--------------------------------------------------------------
void ofApp::setup(){
    
    ofBackground( 30 );
    ofSetFrameRate( 60 );
    
    screenW = ofGetWidth();
    screenH = ofGetHeight();
    
    controlPnX = 0;
    controlPnY = 1536;
    controlPnW = 1536;
    controlPnH = 512;
    
    cam.setDeviceID(0);
    cam.setup( 480, 360 );
    
    synthSetting();
    bpm = synthMain.addParameter("tempo",100).min(50).max(300);
    metro = ControlMetro().bpm(4 * bpm);
    metroOut = synthMain.createOFEvent(metro);
    synthMain.setOutputGen(synth1 + synth2 + synth3 + synth4 + synth5);
    
    ofSoundStreamSetup(2, 0, this, 44100, 256, 4);
    
    pixelStepS = 4;
    camSize = cam.getWidth();
    changedCamSize = camSize / pixelStepS;  // 60
    cameraScreenRatio = ofGetWidth() / cam.getWidth();   // 2.8444451
    thresholdValue = 80;
    
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        pixelCircleSize = 10;
    }else{
        pixelCircleSize = 5;
    }
    
    index = 0;
    noteIndex = 0;
    
    oldNoteIndex1 = 0;
    oldNoteIndex2 = 0;
    oldNoteIndex3 = 0;
    oldNoteIndex4 = 0;
    oldNoteIndex5 = 0;
    
    //    cam.setDesiredFrameRate(30);
    //    cam.initGrabber( 480, 360 );
    
    //    ofSetOrientation(OF_ORIENTATION_DEFAULT);
    
    //    if ( !cam.isInitialized() ) {
    //        return;
    //    } else {
    //    }
 
    ctrlRectS = 80;
    speedCPos = ofPoint( 15 * 96, 1536 + 256 );
    
}

//--------------------------------------------------------------
void ofApp::update(){
    
    cam.update();
    
    if(cam.isFrameNew()) {
        convertColor(cam, gray, CV_RGB2GRAY);
        Canny(gray, edge, 120, 120, 3);
        thin(edge);
        edge.update();
        
        
        if ( bPlayNote ) {
            noteIndex = index;
        } else {
            noteIndex = 0;
            ofImage _tImage;
            
            pixelBright.clear();
            blackPixels.clear();
            whitePixels.clear();
            
            ofPixels _src = edge.getPixels();
            unsigned char * src = _src.getData();
            
            for (int j=0; j<camSize; j+=pixelStepS) {
                for (int i=0; i<camSize; i+=pixelStepS) {
                    int _index = i + j * camSize;
                    float _brightness = src[_index];
                    pixelBright.push_back(_brightness);
                }
            }
            
            int _wCounter = 0;
            int _bCounter = 0;
            
            for (int i=0; i<pixelBright.size(); i++) {
                
                if ( pixelBright[i] == 0 ) {
                    
                    if ( _bCounter==0 ) {
                        blackWhitePixels _bWP;
                        _bWP.indexPos = i;
                        _bWP.pixelN = _wCounter;
                        whitePixels.push_back(_bWP);
                    }
                    _bCounter++;
                    _wCounter = 0;
                    
                } else {
                    
                    if ( _wCounter==0 ) {
                        blackWhitePixels _bWP;
                        _bWP.indexPos = i;
                        _bWP.pixelN = _bCounter;
                        blackPixels.push_back(_bWP);
                    }
                    _wCounter++;
                    _bCounter = 0;
                }
            }
            
        }
        
    }
    
}


//--------------------------------------------------------------
void ofApp::triggerReceive(float & metro){
    
    index++;
    noteIndex = index;
    
    noteTrigger1( noteIndex % blackPixels.size() );
    
    
}


//--------------------------------------------------------------
void ofApp::draw(){
    
    ofPushStyle();
    ofSetColor( 80 );
    edge.draw( 0, 0, screenW, screenH);
    ofPopStyle();
    
    
    ofPushMatrix();
    ofTranslate( 0, 0 );
    pixelDraw();
    crossDraw();
    playingPixel();
    ofPopMatrix();

    
    ofPushStyle();
    ofSetColor( 40 );
    ofDrawRectangle( 0, controlPnY, controlPnW, controlPnH );
    ofPopStyle();

    debugControlPDraw();
    
    controlPanelDraw();
    
}


//--------------------------------------------------------------
void ofApp::controlPanelDraw(){
    
    ofPushStyle();
    ofSetColor( 180 );
    ofDrawRectangle( speedCPos.x - ctrlRectS * 0.5, speedCPos.y - ctrlRectS * 0.5, ctrlRectS, ctrlRectS );
    ofPopStyle();

}



//--------------------------------------------------------------
void ofApp::pixelDraw(){
    
    int _pixelSize = pixelCircleSize;  // 10
    float _ellipseSizeR = 0.7;
    
    ofPushMatrix();
    ofPushStyle();
    ofEnableAntiAliasing();
    
    ofSetColor( 255, 80 );
    
    // Canny
    for (int i=0; i<whitePixels.size(); i++) {
        
        float _x = (whitePixels[i].indexPos % changedCamSize) * pixelStepS * cameraScreenRatio;
        float _y = (int)(whitePixels[i].indexPos / changedCamSize) * pixelStepS * cameraScreenRatio;
        
        ofDrawCircle( _x, _y, _pixelSize * _ellipseSizeR );
        
    }
    
    ofPopStyle();
    ofPopMatrix();

    
}



//--------------------------------------------------------------
void ofApp::playingPixel(){
    
    int _pixelSize = pixelCircleSize;  // 10
    float _ellipseSizeR = 0.7;

    if (bPlayNote) {
        
        ofPushMatrix();
        ofPushStyle();
        ofEnableAntiAliasing();
        ofSetColor( 0, 255, 0, 180 );
        
        int _noteIndex = noteIndex % (whitePixels.size());
        
        float _x = (whitePixels[_noteIndex].indexPos % changedCamSize) * pixelStepS * cameraScreenRatio;
        float _y = (int)(whitePixels[_noteIndex].indexPos / changedCamSize) * pixelStepS * cameraScreenRatio;
        
        ofDrawCircle( _x, _y, _pixelSize * _ellipseSizeR );
        
        ofPopStyle();
        ofPopMatrix();
        
    }
    
}



//--------------------------------------------------------------
void ofApp::crossDraw(){
    
    if (bPlayNote) {
        
        ofPushMatrix();
        ofPushStyle();
        ofEnableAntiAliasing();
        ofSetColor( 0, 255, 0, 70 );
        
        int _noteIndex = noteIndex % (whitePixels.size());
        
        float _x = (whitePixels[_noteIndex].indexPos % changedCamSize) * pixelStepS * cameraScreenRatio;
        float _y = (int)(whitePixels[_noteIndex].indexPos / changedCamSize) * pixelStepS * cameraScreenRatio;
        
        ofDrawLine( _x, 0, _x, 2048);
        ofDrawLine( 0, _y, 1546, _y);
        
        ofPopStyle();
        ofPopMatrix();
        
    }

}


//--------------------------------------------------------------
void ofApp::debugControlPDraw(){
    
    ofPushMatrix();

    for (int i=0; i<15; i++){
        float _x1 = i * 96 + 96;
        ofDrawLine( _x1, 1536, _x1, 2048 );
    }
    
    for (int j=0; j<7; j++){
        float _y1 = j * 64 + 64;
        ofDrawLine( 0, _y1 + 1536, 1536, _y1 + 1536 );
    }
    
    ofPopMatrix();
    
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
    
    if ((touch.x>0)&&(touch.x<controlPnW)&&(touch.y<controlPnY)&&(touch.y>0)) {
        if ( touch.id==0 ) {
            bPlayNote = !bPlayNote;
        }
        
        if ( !bPlayNote ) {
            index = 0;
            ofRemoveListener(* metroOut, this, &ofApp::triggerReceive);
        } else {
            noteIndex = index;
            ofAddListener(* metroOut, this, &ofApp::triggerReceive);
        }
    }
    
    
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
    
    ControlParameter carrierPitch4 = synth4.addParameter("carrierPitch4");
    float amountMod4 = 6;
    ControlGenerator rCarrierFreq4 = ControlMidiToFreq().input(carrierPitch4);
    ControlGenerator rModFreq4 = rCarrierFreq4 * 4.489;
    Generator modulationTone4 = SineWave().freq( rModFreq4 ) * rModFreq4 * amountMod4;
    Generator tone4 = SineWave().freq(rCarrierFreq4 + modulationTone4);
    ControlGenerator envelopTrigger4 = synth4.addParameter("trigger4");
    Generator env4 = ADSR().attack(0.001).decay(0.1).sustain(0).release(0).trigger(envelopTrigger4).legato(false);
    synth4.setOutputGen( tone4 * env4 * 0.75 );

    ControlParameter carrierPitch5 = synth5.addParameter("carrierPitch5");
    float amountMod5 = 6;
    ControlGenerator rCarrierFreq5 = ControlMidiToFreq().input(carrierPitch5);
    ControlGenerator rModFreq5 = rCarrierFreq5 * 1.489;
    Generator modulationTone5 = SineWave().freq( rModFreq5 ) * rModFreq5 * amountMod5;
    Generator tone5 = SineWave().freq(rCarrierFreq5 + modulationTone5);
    ControlGenerator envelopTrigger5 = synth5.addParameter("trigger5");
    Generator env5 = ADSR().attack(0.001).decay(0.1).sustain(0).release(0).trigger(envelopTrigger5).legato(false);
    synth5.setOutputGen( tone5 * env5 * 0.75 );

}


//--------------------------------------------------------------
void ofApp::noteTrigger1(int _index){
    
    int _scale1[8] = {-12, 0, 2, 4, 7, 9, 12, 14};
    int _scale2[8] = {-12, 0, 7, 12, 14, 16, 19, 21};
    int _scale3[8] = {0, 2, 4, 5, 7, 9, 11, 12};
    int _scale4[8] = {0, 2, 4, 5, 7, 9, 11, 12};
    int _scale5[8] = {0, 2, 4, 5, 7, 9, 11, 12};
    
    int _noteIndexLoopForNote = _index;
    
    string _sNote = ofToBinary( blackPixels[_noteIndexLoopForNote].pixelN );
    
    int _1Note = ofToInt( ofToString(_sNote.at(29)) ) * 4 + ofToInt( ofToString(_sNote.at(30)) ) * 2 + ofToInt( ofToString(_sNote.at(31)) );

    int _2Note = ofToInt( ofToString(_sNote.at(26)) ) * 4 + ofToInt( ofToString(_sNote.at(27)) ) * 2 + ofToInt( ofToString(_sNote.at(28)) );

    int _3Note = ofToInt( ofToString(_sNote.at(23)) ) * 4 + ofToInt( ofToString(_sNote.at(24)) ) * 2 + ofToInt( ofToString(_sNote.at(25)) );

    int _4Note = ofToInt( ofToString(_sNote.at(20)) ) * 4 + ofToInt( ofToString(_sNote.at(21)) ) * 2 + ofToInt( ofToString(_sNote.at(22)) );

    int _5Note = ofToInt( ofToString(_sNote.at(17)) ) * 4 + ofToInt( ofToString(_sNote.at(18)) ) * 2 + ofToInt( ofToString(_sNote.at(19)) );

//    cout << _5Note << " " << _4Note << " " << _3Note << " " << _2Note  << " " << _1Note << endl;

    
    if ((_1Note - oldNoteIndex1)!=0) {
        synth1.setParameter("trigger1", 1);
        synth1.setParameter("carrierPitch1", _scale1[_1Note] + 60);
    }
    oldNoteIndex1 = _1Note;

    if ((_2Note - oldNoteIndex2)!=0) {
        synth2.setParameter("trigger2", 1);
        synth2.setParameter("carrierPitch2", _scale2[_2Note] + 72);
    }
    oldNoteIndex2 = _2Note;

    if ((_3Note - oldNoteIndex3)!=0) {
        synth3.setParameter("trigger3", 1);
        synth3.setParameter("carrierPitch3", _scale3[_3Note] + 84);
    }
    oldNoteIndex3 = _3Note;

    if ((_4Note - oldNoteIndex4)!=0) {
        synth4.setParameter("trigger4", 1);
        synth4.setParameter("carrierPitch4", _scale4[_4Note] + 48);
    }
    oldNoteIndex4 = _4Note;

    if ((_5Note - oldNoteIndex5)!=0) {
        synth5.setParameter("trigger5", 1);
        synth5.setParameter("carrierPitch5", _scale5[_5Note] + 36);
    }
    oldNoteIndex5 = _5Note;

    
}

