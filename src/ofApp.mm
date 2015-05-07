// http://www.translatorscafe.com/cafe/units-converter/numbers/calculator/octal-to-decimal/

int scale1[8] = {0, 2, 4, 7, 9, 12, 14, 16};
int scale2[8] = {-12, 0, 7, 12, 14, 16, 19, 21};
int scale3[8] = {0, 2, 4, 5, 7, 9, 11, 12};
int scale4[8] = {0, 2, 4, 5, 7, 9, 11, 12};
int scale5[8] = {0, 2, 4, 5, 7, 9, 11, 12};


#include "ofApp.h"

using namespace ofxCv;
using namespace cv;


//--------------------------------------------------------------
void ofApp::setup(){
    
    for (int i=0; i<8; i++){
        scale1[i] = scale1[i] + 64;
        scale2[i] = scale2[i] + 72;
        scale3[i] = scale3[i] + 84;
        scale4[i] = scale4[i] + 48;
        scale5[i] = scale5[i] + 36;
    }
    
    
    ofBackground( 255 );
    ofSetFrameRate( 60 );
    
    screenW = ofGetWidth();
    screenH = ofGetHeight();
    
    ctrlPnX = 0;
    ctrlPnY = screenW;
    ctrlPnW = screenW;
    ctrlPnH = screenH - screenW;
    
    cam.setDeviceID(0);
    cam.setup( 480, 360 );
    
    bufferImg.allocate(screenW, screenW, OF_IMAGE_GRAYSCALE);
    
    synthSetting();
    maxSpeed = 250;
    minSpeed = 30;
    bpm = synthMain.addParameter("tempo",100).min(minSpeed).max(maxSpeed);
    metro = ControlMetro().bpm(4 * bpm);
    metroOut = synthMain.createOFEvent(metro);
    synthMain.setOutputGen(synth1 + synth2 + synth3 + synth4 + synth5);
    
    ofSoundStreamSetup(2, 0, this, 44100, 256, 4);
    
    pixelStepS = 4;
    camSize = cam.getWidth();
    changedCamSize = camSize / pixelStepS;  // 90
    cameraScreenRatio = ofGetWidth() / cam.getWidth();
    thresholdValue = 80;
    
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        pixelCircleSize = 10;
        ctrlRectS = 80;
        guideWidthStepSize = 96;
        guideHeightStepSize = 64;
    }else{
        pixelCircleSize = 5;
        ctrlRectS = 30;
        guideWidthStepSize = ctrlPnW / 16;
        guideHeightStepSize = ctrlPnH / 8;
    }
    
    index = 0;
    noteIndex = 0;
    
    oldNoteIndex1 = 0;
    oldNoteIndex2 = 0;
    oldNoteIndex3 = 0;
    oldNoteIndex4 = 0;
    oldNoteIndex5 = 0;
    
    oldScoreNote1 = 0;
    oldScoreNote2 = 0;
    oldScoreNote3 = 0;
    oldScoreNote4 = 0;
    oldScoreNote5 = 0;
    
    //    cam.setDesiredFrameRate(30);
    //    cam.initGrabber( 480, 360 );
    
    //    ofSetOrientation(OF_ORIENTATION_DEFAULT);
    
    //    if ( !cam.isInitialized() ) {
    //        return;
    //    } else {
    //    }
    
    speedCSize = ofPoint(ctrlRectS,ctrlRectS);
    speedCPos = ofPoint( 15 * guideWidthStepSize, ctrlPnY + ctrlPnH * 0.5 );
    bSpeedCtrl = false;
    
    thresholdCSize = ofPoint(ctrlRectS,ctrlRectS);
    thresholdCPos = ofPoint( 1 * guideWidthStepSize, ctrlPnY + ctrlPnH * 0.5 );
    bthresholdCtrl = false;
    
    cannyThreshold1 = 120;
    cannyThreshold2 = 120;
    grayThreshold = 120;
    
    
    informationText.load("verdana.ttf", 48);
 
    _test = 0;

}

//--------------------------------------------------------------
void ofApp::update(){
    
    cam.update();
    
    if(cam.isFrameNew()) {
        
        convertColor(cam, gray, CV_RGB2GRAY);
        
        threshold(gray, gray, grayThreshold);
        //        erode(gray);
        
        Canny(gray, edge, cannyThreshold1, cannyThreshold2, 3);
        
        thin(edge);
        invert(edge);
        
        edge.update();
        
        
        if ( bPlayNote ) {
            noteIndex = index;
        } else {
            noteIndex = 0;
            ofImage _tImage;
            
            pixelBright.clear();
            whitePixels.clear();
            blackPixels.clear();
            
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
                
                if ( pixelBright[i] == 255 ) {
                    
                    if ( _bCounter==0 ) {
                        blackWhitePixels _bWP;
                        _bWP.indexPos = i;
                        _bWP.pixelN = _wCounter;
                        blackPixels.push_back(_bWP);
                    }
                    _bCounter++;
                    _wCounter = 0;
                    
                } else {
                    
                    if ( _wCounter==0 ) {
                        blackWhitePixels _bWP;
                        _bWP.indexPos = i;
                        _bWP.pixelN = _bCounter;
                        whitePixels.push_back(_bWP);
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
    
    noteTrigger1();
    
}


//--------------------------------------------------------------
void ofApp::draw(){
    
    ofPushStyle();
    if (bPlayNote) {
        ofSetColor( 240, 50 );
    } else {
        ofSetColor( 240, 255 );
    }
    edge.draw( 0, 0, screenW, screenH);
    ofPopStyle();
    
    
    ofPushStyle();
    if (bPlayNote) {
        ofSetColor( 240, 140 );
    } else {
        ofSetColor( 240, 0 );
    }
    bufferImg.draw( 0, 0, screenW, screenH);
    ofPopStyle();
    
    
    
    ofPushMatrix();
    ofTranslate( 0, 0 );
    pixelDraw();
    playingPixel();
    ofPopMatrix();
    
    
    controlElementDraw();
    
    lineScoreDraw();

    if (bPlayNote) {
        information();
    }
    
}


//--------------------------------------------------------------
void ofApp::controlElementDraw(){
    
    ofPushStyle();
    ofSetColor( 210 );
    ofDrawRectangle( 0, ctrlPnY, ctrlPnW, ctrlPnH );
    ofPopStyle();
    
    debugControlPDraw();
    
    ofPushStyle();
    ofSetColor( 255 );
    float _sX = speedCPos.x - speedCSize.x * 0.5;
    float _sY = speedCPos.y - speedCSize.y * 0.5;
    ofDrawRectangle( _sX, _sY, speedCSize.x, speedCSize.y );
    ofPopStyle();
    
    ofPushStyle();
    ofSetColor( 255 );
    float _tX = thresholdCPos.x - thresholdCSize.x * 0.5;
    float _tY = thresholdCPos.y - thresholdCSize.y * 0.5;
    ofDrawRectangle( _tX, _tY, thresholdCSize.x, thresholdCSize.y );
    ofPopStyle();
    
}


//--------------------------------------------------------------
void ofApp::information(){
    
    ofPushStyle();
    ofSetColor( 120 );
    
    if (whitePixels.size()>0) {
        
        int _blackPixels = whitePixels[noteIndex % whitePixels.size()].pixelN;
        
        vector<int> _10bitNumber;
        _10bitNumber.resize(4);
        _10bitNumber = convertDecimalToNBase( _blackPixels, 10, _10bitNumber.size() );
        for (int i=0; i<_10bitNumber.size(); i++) {
            informationText.drawString( ofToString(_10bitNumber[i]), screenW * 0.5 - 48 * i + 48 * 1.5, ctrlPnY + 50 );
        }
        
        vector<int> _8bitNumber;
        _8bitNumber.resize(5);
        _8bitNumber = convertDecimalToNBase( _blackPixels, 8, _8bitNumber.size() );
        for (int i=0; i<_8bitNumber.size(); i++) {
            informationText.drawString( ofToString(_8bitNumber[i]), screenW * 0.5 - 48 * i + 48 * 1.5, ctrlPnY + 110 );
        }
        
    }
    
    ofPopStyle();
    
}

//--------------------------------------------------------------
void ofApp::pixelDraw(){
    
    int _pixelSize = pixelCircleSize;  // 10
    float _ellipseSizeR = 0.7;
    
    ofPushMatrix();
    ofPushStyle();
    ofEnableAntiAliasing();
    
    ofSetColor( ofColor::tomato );
    
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
        
        //
        float _x = (whitePixels[_noteIndex].indexPos % changedCamSize) * pixelStepS * cameraScreenRatio;
        float _y = (int)(whitePixels[_noteIndex].indexPos / changedCamSize) * pixelStepS * cameraScreenRatio;
        
        ofDrawCircle( _x, _y, _pixelSize * _ellipseSizeR );
        
        //
        float _xS = ((whitePixels[_noteIndex].indexPos-whitePixels[_noteIndex].pixelN) % changedCamSize) * pixelStepS * cameraScreenRatio;
        float _yS = (int)((whitePixels[_noteIndex].indexPos-whitePixels[_noteIndex].pixelN) / changedCamSize) * pixelStepS * cameraScreenRatio;
        
        ofDrawCircle(  _xS, _yS, _pixelSize * _ellipseSizeR );
        
        
        //
        int _indexPixes = whitePixels[_noteIndex].indexPos-whitePixels[_noteIndex].pixelN;
        
        int _index = whitePixels[_noteIndex].pixelN;
        for (int i=0; i<_index; i++){
            
            float _xS = ((_indexPixes+i) % changedCamSize) * pixelStepS * cameraScreenRatio;
            float _yS = (int)((_indexPixes+i) / changedCamSize) * pixelStepS * cameraScreenRatio;
            
            ofDrawCircle(  _xS, _yS, _pixelSize * _ellipseSizeR );
        }
        
        
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
        ofSetColor( 0, 255, 0, 255 );
        
        int _noteIndex = noteIndex % (whitePixels.size());
        
        float _x = (whitePixels[_noteIndex].indexPos % changedCamSize) * pixelStepS * cameraScreenRatio;
        float _y = (int)(whitePixels[_noteIndex].indexPos / changedCamSize) * pixelStepS * cameraScreenRatio;
        
        ofDrawLine( _x, 0, _x, ctrlPnY);
        ofDrawLine( 0, _y, ctrlPnW, _y);
        
        ofPopStyle();
        ofPopMatrix();
        
    }
    
}


//--------------------------------------------------------------
void ofApp::lineScoreDraw(){
    
    int _xNumber = 20;
    int _stepX = 40;
    int _stepY = 4;
    int _defaultNote = 68;
    int _size = 3;
    
    ofPushMatrix();
    ofPushStyle();
    ofTranslate( ctrlPnW * 0.5 - _stepX * (_xNumber-2) * 0.5, ctrlPnY + _defaultNote * 6 );
    ofSetColor( 0, 180 );
    
    
    if (bPlayNote) {
    
        if (whitePixels.size()>0) {
            
            for (int j=0; j<_xNumber; j++) {
                
                vector<int> _whitePixels;
                _whitePixels.resize(_xNumber);
                _whitePixels[j] = whitePixels[(noteIndex + j) % whitePixels.size()].pixelN;
                
                vector< vector<int> > _8bitNumber;
                _8bitNumber.resize(_xNumber);
                _8bitNumber[j].resize(5);
                _8bitNumber[j] = convertDecimalToNBase( _whitePixels[j], 8, _8bitNumber.size() );
                
                
                int _1Note = _8bitNumber[j][0];
                int _2Note = _8bitNumber[j][1];
                int _3Note = _8bitNumber[j][2];
                int _4Note = _8bitNumber[j][3];
                int _5Note = _8bitNumber[j][4];

                float _x1a = (j - 1) * _stepX;
                float _y2a = _defaultNote - scale2[_2Note] * _stepY;
                float _y3a = _defaultNote - scale3[_3Note] * _stepY;
                float _y4a = _defaultNote - scale4[_4Note] * _stepY;
                float _y5a = _defaultNote - scale5[_5Note] * _stepY;

                if ((_1Note - oldScoreNote1)!=0) {
                    float _y1a = _defaultNote - scale1[_1Note] * _stepY;
                    ofDrawCircle( _x1a, _y1a, _size );
                }  
                oldScoreNote1 = _1Note;
            

                
//                if ((_2Note - oldScoreNote2)!=0) {
//                    ofDrawCircle( _x1a, _y2a, _size );
//                }
//                oldScoreNote2 = _2Note;
//
//                if ((_3Note - oldScoreNote3)!=0) {
//                    ofDrawCircle( _x1a, _y3a, _size );
//                }
//                oldScoreNote3 = _3Note;
//                
//                if ((_4Note - oldScoreNote4)!=0) {
//                    ofDrawCircle( _x1a, _y4a, _size );
//                }
//                oldScoreNote4 = _4Note;
//
//                if ((_5Note - oldScoreNote5)!=0) {
//                    ofDrawCircle( _x1a, _y5a, _size );
//                }
//                oldScoreNote5 = _5Note;
                
            
            }
        
        }
    }
    
    
    
    
    ofPopStyle();

    ofPopMatrix();
    
    
    ofPushMatrix();
    ofPushStyle();
    
    ofTranslate( ctrlPnW * 0.5 - _xNumber * 0.5 * _stepX, ctrlPnY + ctrlPnH * 0.5 );
    ofSetColor( 255, 0, 0, 200 );
    ofDrawLine( 0, 200, 0, -200 );
    
    ofPopStyle();
    ofPopMatrix();
    
}


//--------------------------------------------------------------
void ofApp::debugControlPDraw(){
    
    ofPushMatrix();
    ofPushStyle();
    ofSetColor( 120 );
    
    for (int i=0; i<15; i++){
        float _x1 = i * guideWidthStepSize + guideWidthStepSize;
        ofDrawLine( _x1, ctrlPnY, _x1, screenH );
    }
    
    for (int j=0; j<7; j++){
        float _y1 = j * guideHeightStepSize + guideHeightStepSize;
        ofDrawLine( 0, _y1 + ctrlPnY, screenW, _y1 + ctrlPnY );
    }
    
    ofPopStyle();
    ofPopMatrix();
    
    ofPushStyle();
    ofSetColor(0);
    ofDrawBitmapString(ofToString(ofGetFrameRate(),2), 10, screenH-10);
    ofPopStyle();
    
}




//--------------------------------------------------------------
void ofApp::exit(){
    
    cam.close();
    
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    
    if ((touch.x>0)&&(touch.x<ctrlPnW)&&(touch.y<ctrlPnY)&&(touch.y>0)) {
        if ( touch.id==0 ) {
            bPlayNote = !bPlayNote;
            bufferImg = edge;
        }
        
        
        if ( !bPlayNote ) {
            index = 0;
            ofRemoveListener(* metroOut, this, &ofApp::triggerReceive);
        } else {
            noteIndex = index;
            ofAddListener(* metroOut, this, &ofApp::triggerReceive);
        }
    }
    
    
    if ( touch.id==0 ) {
        float _sMinX = speedCPos.x - speedCSize.x * 0.5;
        float _sMaxX = speedCPos.x + speedCSize.x * 0.5;
        float _sMinY = speedCPos.y - speedCSize.y * 0.5;
        float _sMaxY = speedCPos.y + speedCSize.y * 0.5;
        if ((touch.x>_sMinX)&&(touch.x<_sMaxX)&&(touch.y>_sMinY)&&(touch.y<_sMaxY)) {
            bSpeedCtrl = true;
        } else {
            bSpeedCtrl = false;
        }
        
        float _tMinX = thresholdCPos.x - thresholdCSize.x * 0.5;
        float _tMaxX = thresholdCPos.x + thresholdCSize.x * 0.5;
        float _tMinY = thresholdCPos.y - thresholdCSize.y * 0.5;
        float _tMaxY = thresholdCPos.y + thresholdCSize.y * 0.5;
        if ((touch.x>_tMinX)&&(touch.x<_tMaxX)&&(touch.y>_tMinY)&&(touch.y<_tMaxY)) {
            bthresholdCtrl = true;
        } else {
            bthresholdCtrl = false;
        }
    }
    
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
    
    if ( touch.id==0 ) {
        
        if (bSpeedCtrl) {
            float _minY = ctrlPnY+speedCSize.y*0.75;
            float _maxY = screenH-speedCSize.y*0.75;
            if ((touch.y>_minY)&&(touch.y<_maxY)) {
                speedCPos.y = touch.y;
                float _tempo = ofMap(speedCPos.y, _minY, _maxY, maxSpeed, minSpeed);
                synthMain.setParameter("tempo", _tempo);
            }
        }
        
        if (bthresholdCtrl) {
            float _minY = ctrlPnY+speedCSize.y*0.75;
            float _maxY = screenH-speedCSize.y*0.75;
            if ((touch.y>_minY)&&(touch.y<_maxY)) {
                thresholdCPos.y = touch.y;
                float _threshold = ofMap(thresholdCPos.y, _minY, _maxY, 255, 0);
                //                cannyThreshold1 = _threshold;
                //                cannyThreshold2 = _threshold;
                grayThreshold = _threshold;
            }
            
            //            float _minX = 1 * 96;
            //            float _maxX = 3 * 96;
            //            if ((touch.x>_minX)&&(touch.x<_maxX)) {
            //                thresholdCPos.x = touch.x;
            //                float _threshold = ofMap(thresholdCPos.x, _minX, _maxX, 255, 20);
            //                grayThreshold = _threshold;
            //            }
            
        }
        
    }
    
    
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
void ofApp::noteTrigger1(){
    
    
    vector<int> _8bitNumber;
    _8bitNumber.resize(5);
    _8bitNumber = convertDecimalToNBase( whitePixels[noteIndex % whitePixels.size()].pixelN, 8, _8bitNumber.size() );
    
    int _1Note = _8bitNumber[0];
    int _2Note = _8bitNumber[1];
    int _3Note = _8bitNumber[2];
    int _4Note = _8bitNumber[3];
    int _5Note = _8bitNumber[4];
    
    //    cout << _5Note << " " << _4Note << " " << _3Note << " " << _2Note  << " " << _1Note << endl;
    
    if ((_1Note - oldNoteIndex1)!=0) {
        synth1.setParameter("trigger1", 1);
        synth1.setParameter("carrierPitch1", scale1[_1Note]);
        
    }
    oldNoteIndex1 = _1Note;
    
//    if ((_2Note - oldNoteIndex2)!=0) {
//        synth2.setParameter("trigger2", 1);
//        synth2.setParameter("carrierPitch2", scale2[_2Note]);
//    }
//    oldNoteIndex2 = _2Note;
//    
//    if ((_3Note - oldNoteIndex3)!=0) {
//        synth3.setParameter("trigger3", 1);
//        synth3.setParameter("carrierPitch3", scale3[_3Note]);
//    }
//    oldNoteIndex3 = _3Note;
//    
//    if ((_4Note - oldNoteIndex4)!=0) {
//        synth4.setParameter("trigger4", 1);
//        synth4.setParameter("carrierPitch4", scale4[_4Note]);
//    }
//    oldNoteIndex4 = _4Note;
//    
//    if ((_5Note - oldNoteIndex5)!=0) {
//        synth5.setParameter("trigger5", 1);
//        synth5.setParameter("carrierPitch5", scale5[_5Note]);
//    }
//    oldNoteIndex5 = _5Note;
    
    
}


//--------------------------------------------------------------
vector<int> ofApp::convertDecimalToNBase(int n, int base, int size) {
    
    int i=0,div,res;
    
    vector<int> a;
    a.clear();
    a.resize(size);
    
    div=n/base;
    res=n%base;
    a[i] = res;
    
    while(1){
        if(div==0) break;
        else {
            i++;
            res=div%base;
            div=div/base;
            a[i] = res;
        }
    }
    return a;
    
}
