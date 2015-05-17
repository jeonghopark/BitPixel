// http://www.translatorscafe.com/cafe/units-converter/numbers/calculator/octal-to-decimal/


int scale51[5] = {0, 2, 4, 7, 9};
int scale52[5] = {0, 2, 5, 7, 9};
int scale53[5] = {0, 2, 4, 7, 9};
int scale54[5] = {0, 2, 5, 7, 9};
int scale55[5] = {0, 2, 4, 7, 9};
int scale56[3] = {-7, 0, 7};

int scale61[6] = {0, 4, 5, 7, 9, 12};
int scale62[6] = {0, 7, 12, 14, 16, 19};
int scale63[6] = {0, 4, 5, 7, 9, 12};
int scale64[6] = {0, 4, 5, 7, 9, 12};
int scale65[6] = {0, 4, 5, 7, 9, 12};
int scale66[2] = {0, 7};

int scale71[7] = {0, 2, 4, 7, 9, 12, 14};
int scale72[7] = {0, 7, 12, 14, 16, 19, 21};
int scale73[7] = {0, 2, 5, 7, 9, 11, 14};
int scale74[7] = {0, 2, 4, 5, 7, 9, 11};
int scale75[3] = {-7, 0, 7};

int scale81[8] = {0, 2, 5, 7, 9, 11, 12, 17};
int scale82[8] = {0, 7, 12, 14, 16, 19, 21, 24};
int scale83[8] = {0, 5, 6, 7, 9, 11, 12, 17};
int scale84[8] = {0, 5, 6, 7, 9, 11, 12, 17};
int scale85[2] = {0, 7};



#include "ofApp.h"

using namespace ofxCv;
using namespace cv;


//--------------------------------------------------------------
void ofApp::setup(){
    
    
    baseSelection = 7;
    scaleChange();
    
    ofBackground( 255 );
    ofSetFrameRate( 60 );
    ofEnableAlphaBlending();
    
    screenW = ofGetWidth();
    screenH = ofGetHeight();
    
    cout << screenW << endl;
    
    ctrlPnX = 0;
    ctrlPnY = screenW;
    ctrlPnW = screenW;
    ctrlPnH = screenH - screenW;
    
    cam.setDeviceID(0);
    cam.setup( 480, 360 );
    cam.setDesiredFrameRate(15);
    
    bufferImg.allocate(screenW, screenW, OF_IMAGE_GRAYSCALE);
    
    synthSetting();
    maxSpeed = 200;
    minSpeed = 30;
    bpm = synthMain.addParameter("tempo",100).min(minSpeed).max(maxSpeed);
    metro = ControlMetro().bpm(4 * bpm);
    metroOut = synthMain.createOFEvent(metro);
    synthMain.setOutputGen(synth1 + synth2 + synth3 + synth4 + synth5);
    
//    ofSoundStreamSetup(2, 0, this, 44100, 256, 4);
    
    pixelStepS = 4;
    camSize = cam.getWidth();
    changedCamSize = camSize / pixelStepS;  // 90
    cameraScreenRatio = screenW / cam.getWidth();
    thresholdValue = 80;
    
    float _sizeF = screenW;

    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        ofSoundStreamSetup(2, 0, this, 44100, 256, 4);
        pixelCircleSize = 10 / 1536.0 * _sizeF;
        ctrlRectS = 80 / 1536.0 * _sizeF;
        guideWidthStepSize = 96 / 1536.0 * _sizeF;
        guideHeightStepSize = 64 / 1536.0 * _sizeF;
        fontSize = 28 / 1536.0 * _sizeF;
        lineScoreStepX = 40 / 1536.0 * _sizeF;
        lineScoreStepY = 5 / 1536.0 * _sizeF;
    }else{
        ofSoundStreamSetup(2, 1, this, 44100, 256, 4);
        pixelCircleSize = 5 / 640.0 * _sizeF;
        ctrlRectS = 50 / 640.0 * _sizeF;
        guideWidthStepSize = ctrlPnW / 16;
        guideHeightStepSize = ctrlPnH / 8;
        fontSize = 36 / 640.0 * _sizeF;
        lineScoreStepX = 20 / 640.0 * _sizeF;
        lineScoreStepY = 3 / 640.0 * _sizeF;
    }
    
    index = 0;
    noteIndex = 0;
    
    oldNoteIndex1 = 0;
    oldNoteIndex2 = 0;
    oldNoteIndex3 = 0;
    oldNoteIndex4 = 0;
    oldNoteIndex5 = 0;
    oldNoteIndex6 = 0;
    
    oldScoreNote1 = 0;
    oldScoreNote2 = 0;
    oldScoreNote3 = 0;
    oldScoreNote4 = 0;
    oldScoreNote5 = 0;
    oldScoreNote6 = 0;
    
    //    cam.setDesiredFrameRate(30);
    //    cam.initGrabber( 480, 360 );
    
    //    ofSetOrientation(OF_ORIENTATION_DEFAULT);
    
    //    if ( !cam.isInitialized() ) {
    //        return;
    //    } else {
    //    }
    
    speedCSize = ctrlRectS;
    speedCPos = ofPoint( 15 * guideWidthStepSize, ctrlPnY + ctrlPnH * 0.5 );
    bSpeedCtrl = false;
    
    thresholdCSize = ctrlRectS * 0.5;
    thresholdCPos = ofPoint( 1 * guideWidthStepSize, ctrlPnY + ctrlPnH * 0.5 );
    bthresholdCtrl = false;

    intervalSize = ctrlRectS * 0.5;
    intervalPos = ofPoint( 2.5 * guideWidthStepSize, ctrlPnY + ctrlPnH * 0.5 );
    bthresholdCtrl = false;
    intervalDist = 1;
    
    cannyThreshold1 = 120;
    cannyThreshold2 = 120;
    grayThreshold = 120;
    
    
    informationText.load("verdana.ttf", fontSize);
    
    float _stepBasePos = 105 / 1536.0 * _sizeF;
    base5Pos = ofPoint( guideWidthStepSize * 13.5, ctrlPnY + _stepBasePos );
    base6Pos = ofPoint( guideWidthStepSize * 13.5, ctrlPnY + _stepBasePos * 2 );
    base7Pos = ofPoint( guideWidthStepSize * 13.5, ctrlPnY + _stepBasePos * 3 );
    base8Pos = ofPoint( guideWidthStepSize * 13.5, ctrlPnY + _stepBasePos * 4 );
    baseSize = ctrlRectS * 0.55;
    
    bPlayNote = false;
    
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
        
        unsigned char * src = edge.getPixels().getData();

        if ( bPlayNote ) {
            noteIndex = index;
        } else {
            noteIndex = 0;
            ofImage _tImage;
            
            pixelBright.clear();
            whitePixels.clear();
            blackPixels.clear();
            
            
            
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
        bufferImg.draw( 0, 0, screenW, screenH);
    } else {
        ofSetColor( 255, 0 );
    }
    ofPopStyle();
    
    
    ofPushStyle();
    ofSetColor(255,30);
    ofDrawRectangle(0, 0, screenW, screenH);
    ofPopStyle();
    
    
    
    ofPushMatrix();
    ofTranslate( 0, 0 );
    pixelDraw();
    playingPixel();
    ofPopMatrix();
    
    
    controlElementDraw();
    
    lineScoreDraw();
    
    baseInterface();
    
    if (bPlayNote) {
        information();
    }
    
}


//--------------------------------------------------------------
void ofApp::controlElementDraw(){
    

    ofPushStyle();
    ofSetColor( 255 );
    ofDrawRectangle( 0, ctrlPnY, ctrlPnW, ctrlPnH );
    ofPopStyle();


    ofPushMatrix();
    ofPushStyle();
    ofSetColor( 0, 80 );
    
    float _speedX = guideWidthStepSize;
    float _yD = 20;
    ofDrawLine( _speedX, ctrlPnY + _yD, _speedX, screenH - _yD);
    
    float _thresholdX = guideWidthStepSize * 15;
    ofDrawLine( _thresholdX, ctrlPnY + _yD, _thresholdX, screenH - _yD);
    
    float _intervalX = guideWidthStepSize * 2.5;
    ofDrawLine( _intervalX, ctrlPnY + _yD, _intervalX, screenH - _yD);
    
    
    //    for (int j=0; j<7; j++){
    //        float _y1 = j * guideHeightStepSize + guideHeightStepSize;
    //        ofDrawLine( 0, _y1 + ctrlPnY, screenW, _y1 + ctrlPnY );
    //    }
    
    ofPopStyle();
    ofPopMatrix();

    
    ofPushStyle();
    ofSetColor( 0 );
    ofSetCircleResolution(48);
    float _sX = speedCPos.x;
    float _sY = speedCPos.y;
    ofNoFill();
    ofDrawCircle( _sX, _sY, speedCSize * 0.5 );
    ofPopStyle();
    
    ofPushStyle();
    ofSetColor( 0 );
    ofNoFill();
    float _sizeF = 1.1;
    float _x1 = thresholdCPos.x;
    float _y1 = thresholdCPos.y - thresholdCSize * _sizeF;
    float _x2 = thresholdCPos.x - cos(ofDegToRad(30)) * thresholdCSize * _sizeF;
    float _y2 = thresholdCPos.y + sin(ofDegToRad(30)) * thresholdCSize * _sizeF;
    float _x3 = thresholdCPos.x + cos(ofDegToRad(30)) * thresholdCSize * _sizeF;
    float _y3 = thresholdCPos.y + sin(ofDegToRad(30)) * thresholdCSize * _sizeF;
    ofDrawTriangle( _x1, _y1, _x2, _y2, _x3, _y3 );
    ofPopStyle();
    
    
    ofPushStyle();
    ofSetColor( 0 );
    float _iX = intervalPos.x;
    float _iY = intervalPos.y;
    
    ofDrawLine( _iX - intervalSize, _iY, _iX, _iY + intervalSize );
    ofDrawLine( _iX, _iY - intervalSize, _iX + intervalSize, _iY );
    ofDrawLine( _iX + intervalSize, _iY, _iX, _iY + intervalSize );
    ofDrawLine( _iX, _iY - intervalSize, _iX - intervalSize, _iY );
    ofPopStyle();
    
}


//--------------------------------------------------------------
void ofApp::information(){
    
    ofPushStyle();
    ofSetColor( 120 );
    
    if (whitePixels.size()>0) {
        
        int _whitePixels = whitePixels[((noteIndex) % (whitePixels.size()-1))+1].pixelN;
        
        informationText.drawString( ofToString(_whitePixels), screenW * 0.5 - 200, ctrlPnY + fontSize * 1 + fontSize * 1.1 );

//        vector<int> _10bitNumber;
//        _10bitNumber.resize(4);
//        _10bitNumber = convertDecimalToNBase( _whitePixels, 10, _10bitNumber.size() );
//        for (int i=0; i<_10bitNumber.size(); i++) {
//            informationText.drawString( ofToString(_10bitNumber[i]), screenW * 0.5 - fontSize * i + fontSize * 1.5, ctrlPnY + fontSize * 1 + fontSize * 1.1 );
//        }
        
        vector<int> _8bitNumber;
        if ((baseSelection==5)||(baseSelection==6)) {
            _8bitNumber.resize(6);
            _8bitNumber = convertDecimalToNBase( _whitePixels, baseSelection, (int)_8bitNumber.size() );
            for (int i=0; i<_8bitNumber.size(); i++) {
                informationText.drawString( ofToString(_8bitNumber[i]), screenW * 0.5 - fontSize * i + fontSize * 1.5, ctrlPnY + fontSize * 1 + fontSize * 1.1 );
            }
        }
        if ((baseSelection==7)||(baseSelection==8)) {
            _8bitNumber.resize(5);
            _8bitNumber = convertDecimalToNBase( _whitePixels, baseSelection, (int)_8bitNumber.size() );
            for (int i=0; i<_8bitNumber.size(); i++) {
                informationText.drawString( ofToString(_8bitNumber[i]), screenW * 0.5 - fontSize * i + fontSize * 1.5, ctrlPnY + fontSize * 1 + fontSize * 1.1 );
            }
        }
        
    }
    
    ofPopStyle();
    
}

//--------------------------------------------------------------
void ofApp::pixelDraw(){
    
    int _pixelSize = pixelCircleSize;  // 10
    float _ellipseSizeR = 1.7;
    
    ofPushMatrix();
    ofPushStyle();
    ofEnableAntiAliasing();
    
    ofSetColor( 0, 180 );
    
    // Canny
    for (int i=0; i<whitePixels.size(); i++) {
        
        float _x = (whitePixels[i].indexPos % changedCamSize) * pixelStepS * cameraScreenRatio;
        float _y = (int)(whitePixels[i].indexPos / changedCamSize) * pixelStepS * cameraScreenRatio;
        
        //        ofDrawCircle( _x, _y, _pixelSize * _ellipseSizeR );
        
        ofPoint _1P = ofPoint( _x, _y - _pixelSize * _ellipseSizeR * 0.75 );
        ofPoint _2P = ofPoint( _x - _pixelSize * _ellipseSizeR * 0.55, _y + _pixelSize * _ellipseSizeR * 0.25 );
        ofPoint _3P = ofPoint( _x + _pixelSize * _ellipseSizeR * 0.55, _y + _pixelSize * _ellipseSizeR * 0.25 );
        ofDrawTriangle( _1P, _2P, _3P );
        
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
        ofSetColor( 0, 120 );
        
        if (whitePixels.size()>0) {
            
            int _noteIndex = ((noteIndex) % (whitePixels.size()-1))+1;
            
            
            //
            //            float _x = (whitePixels[_noteIndex].indexPos % changedCamSize) * pixelStepS * cameraScreenRatio;
            //            float _y = (int)(whitePixels[_noteIndex].indexPos / changedCamSize) * pixelStepS * cameraScreenRatio;
            //            ofDrawCircle( _x, _y, _pixelSize * _ellipseSizeR );
            
            //
            //            float _xS = ((whitePixels[_noteIndex].indexPos-whitePixels[_noteIndex].pixelN) % changedCamSize) * pixelStepS * cameraScreenRatio;
            //            float _yS = (int)((whitePixels[_noteIndex].indexPos-whitePixels[_noteIndex].pixelN) / changedCamSize) * pixelStepS * cameraScreenRatio;
            //            ofDrawCircle(  _xS, _yS, _pixelSize * _ellipseSizeR );
            
            
            //
            int _pixelNumbers = whitePixels[((noteIndex) % (whitePixels.size()-1))+1].pixelN;
            int _indexPixes = whitePixels[((noteIndex) % (whitePixels.size()-1))+1].indexPos - _pixelNumbers;
            
            for (int i=0; i<_pixelNumbers; i++){
                
                float _xS = ((_indexPixes+i) % changedCamSize) * pixelStepS * cameraScreenRatio;
                float _yS = (int)((_indexPixes+i) / changedCamSize) * pixelStepS * cameraScreenRatio;
                
                ofFill();
                ofSetColor( 0, 20 );
                ofDrawCircle( _xS, _yS, _pixelSize * _ellipseSizeR );
                ofNoFill();
                ofSetColor( 0, 120 );
                ofDrawCircle( _xS, _yS, _pixelSize * _ellipseSizeR );
            }
            
        }
        
        ofPopStyle();
        ofPopMatrix();
        
    }
    
}



//--------------------------------------------------------------
void ofApp::lineScoreDraw(){
    
    int _xNumber = 19;
    int _stepX = lineScoreStepX;
    int _stepY = lineScoreStepY;
    int _defaultNote = 56;
    int _size = 3;
    int _xDefaultPos = _stepX * (_xNumber-1);
    
    ofPushMatrix();
    ofPushStyle();
    ofTranslate( ctrlPnW * 0.5 - _xDefaultPos * 0.5, ctrlPnY + 127 * _stepY - _defaultNote );
    ofSetColor( 0, 120 );
    
    if (bPlayNote) {
        
        if (scoreNote1.size()>_xNumber) {
            scoreNote1.erase(scoreNote1.begin());
        }
        for (int i=0; i<scoreNote1.size(); i++){
            float _x1a = _xDefaultPos - i * _stepX;
            float _y1a = _defaultNote - scoreNote1[i] * _stepY;
            if (scoreNote1[i]>0) {
                ofDrawCircle( _x1a, _y1a, _size );
            }
        }
        
        if (scoreNote1.size()>0) {
            for (int i=0; i<scoreNote1.size()-1; i++){
                float _x1 = _xDefaultPos - i * _stepX;
                float _y1 = _defaultNote - scoreNote1[i] * _stepY;
                float _x2 = _xDefaultPos - (i + 1) * _stepX;
                float _y2 = _defaultNote - scoreNote1[i+1] * _stepY;
                if ((scoreNote1[i]>0)&&(scoreNote1[i+1]>0)) {
                    ofDrawLine( _x1, _y1, _x2, _y2 );
                }
            }
        }
        
        
        if (scoreNote2.size()>_xNumber) {
            scoreNote2.erase(scoreNote2.begin());
        }
        for (int i=0; i<scoreNote2.size(); i++){
            float _x2a = _xDefaultPos - i * _stepX;
            float _y2a = _defaultNote - scoreNote2[i] * _stepY;
            if (scoreNote2[i]>0) {
                ofDrawCircle( _x2a, _y2a, _size );
            }
        }
        
        if (scoreNote2.size()>0) {
            for (int i=0; i<scoreNote2.size()-1; i++){
                float _x1 = _xDefaultPos - i * _stepX;
                float _y1 = _defaultNote - scoreNote2[i] * _stepY;
                float _x2 = _xDefaultPos - (i + 1) * _stepX;
                float _y2 = _defaultNote - scoreNote2[i+1] * _stepY;
                if ((scoreNote2[i]>0)&&(scoreNote2[i+1]>0)) {
                    ofDrawLine( _x1, _y1, _x2, _y2 );
                }
            }
        }
        
        
        
        if (scoreNote3.size()>_xNumber) {
            scoreNote3.erase(scoreNote3.begin());
        }
        for (int i=0; i<scoreNote3.size(); i++){
            float _x3a = _xDefaultPos - i * _stepX;
            float _y3a = _defaultNote - scoreNote3[i] * _stepY;
            if (scoreNote3[i]>0) {
                ofDrawCircle( _x3a, _y3a, _size );
            }
        }
        
        if (scoreNote3.size()>0) {
            for (int i=0; i<scoreNote3.size()-1; i++){
                float _x1 = _xDefaultPos - i * _stepX;
                float _y1 = _defaultNote - scoreNote3[i] * _stepY;
                float _x2 = _xDefaultPos - (i + 1) * _stepX;
                float _y2 = _defaultNote - scoreNote3[i+1] * _stepY;
                if ((scoreNote3[i]>0)&&(scoreNote3[i+1]>0)) {
                    ofDrawLine( _x1, _y1, _x2, _y2 );
                }
            }
        }
        
        
        
        
        if (scoreNote4.size()>_xNumber) {
            scoreNote4.erase(scoreNote4.begin());
        }
        for (int i=0; i<scoreNote4.size(); i++){
            float _x4a = _xDefaultPos - i * _stepX;
            float _y4a = _defaultNote - scoreNote4[i] * _stepY;
            if (scoreNote4[i]>0) {
                ofDrawCircle( _x4a, _y4a, _size );
            }
        }
        
        if (scoreNote4.size()>0) {
            for (int i=0; i<scoreNote4.size()-1; i++){
                float _x1 = _xDefaultPos - i * _stepX;
                float _y1 = _defaultNote - scoreNote4[i] * _stepY;
                float _x2 = _xDefaultPos - (i + 1) * _stepX;
                float _y2 = _defaultNote - scoreNote4[i+1] * _stepY;
                if ((scoreNote4[i]>0)&&(scoreNote4[i+1]>0)) {
                    ofDrawLine( _x1, _y1, _x2, _y2 );
                }
            }
        }
        
        
        
        if (scoreNote5.size()>_xNumber) {
            scoreNote5.erase(scoreNote5.begin());
        }
        for (int i=0; i<scoreNote5.size(); i++){
            float _x5a = _xDefaultPos - i * _stepX;
            float _y5a = _defaultNote - scoreNote5[i] * _stepY;
            if (scoreNote5[i]>0) {
                ofDrawCircle( _x5a, _y5a, _size );
            }
        }
        
        if (scoreNote5.size()>0) {
            for (int i=0; i<scoreNote5.size()-1; i++){
                float _x1 = _xDefaultPos - i * _stepX;
                float _y1 = _defaultNote - scoreNote5[i] * _stepY;
                float _x2 = _xDefaultPos - (i + 1) * _stepX;
                float _y2 = _defaultNote - scoreNote5[i+1] * _stepY;
                if ((scoreNote5[i]>0)&&(scoreNote5[i+1]>0)) {
                    ofDrawLine( _x1, _y1, _x2, _y2 );
                }
            }
        }
        
        
        if (scoreNote6.size()>_xNumber) {
            scoreNote6.erase(scoreNote6.begin());
        }
        for (int i=0; i<scoreNote6.size(); i++){
            float _x6a = _xDefaultPos - i * _stepX;
            float _y6a = _defaultNote - scoreNote6[i] * _stepY;
            if (scoreNote6[i]>0) {
                ofDrawCircle( _x6a, _y6a, _size );
            }
        }
        
        if (scoreNote6.size()>0) {
            for (int i=0; i<scoreNote6.size()-1; i++){
                float _x1 = _xDefaultPos - i * _stepX;
                float _y1 = _defaultNote - scoreNote6[i] * _stepY;
                float _x2 = _xDefaultPos - (i + 1) * _stepX;
                float _y2 = _defaultNote - scoreNote6[i+1] * _stepY;
                if ((scoreNote6[i]>0)&&(scoreNote6[i+1]>0)) {
                    ofDrawLine( _x1, _y1, _x2, _y2 );
                }
            }
        }
        
        
        
    }
    
    
    
    
    ofPopStyle();
    
    ofPopMatrix();
    
    
    
    ofPushMatrix();
    ofPushStyle();
    ofSetColor( 0, 80 );
    
    float _yD = 20;
    float _x1 = ctrlPnW * 0.5 - _xDefaultPos * 0.5;
    ofDrawLine( _x1, ctrlPnY + _yD, _x1, screenH - _yD);
    
    float _x2 = ctrlPnW * 0.5 + _xDefaultPos * 0.5;
    ofDrawLine( _x2, ctrlPnY + _yD, _x2, screenH - _yD);
    
    ofPopStyle();
    ofPopMatrix();
    
}


//--------------------------------------------------------------
void ofApp::controlGuide(){
    
    
    
}



//--------------------------------------------------------------
void ofApp::baseInterface(){
    
    ofPushMatrix();
    ofPushStyle();
    
    drawShape( base5Pos, 5, baseSize );
    drawShape( base6Pos, 6, baseSize );
    drawShape( base7Pos, 7, baseSize );
    drawShape( base8Pos, 8, baseSize );
    
    ofPopMatrix();
    ofPopStyle();
    
}


//--------------------------------------------------------------
void ofApp::drawShape(ofPoint _p, int _b, int _s){
    
    ofPoint _pos = _p;
    
    vector<ofPoint> posLine;
    
    int _base = _b;
    int _size = _s;
    for (int i=0; i<_base; i++) {
        float _sizeDegree = 360 / _base;
        float _x = sin(ofDegToRad(i*_sizeDegree+180)) * _size;
        float _y = cos(ofDegToRad(i*_sizeDegree+180)) * _size;
        
        ofPoint _p = ofPoint( _x, _y );
        posLine.push_back( _p );
    }
    
    
    ofPushMatrix();
    ofPushStyle();
    
    ofTranslate( _pos );
    
    ofSetColor(10, 60);
    for (int i=0; i<posLine.size(); i++){
        ofDrawLine( 0, 0, posLine[i].x, posLine[i].y );
    }
    
    ofSetColor(0);
    for (int i=0; i<posLine.size()-1; i++){
        ofDrawLine( posLine[i].x, posLine[i].y, posLine[i+1].x, posLine[i+1].y );
    }
    ofDrawLine( posLine[0].x, posLine[0].y, posLine[posLine.size()-1].x, posLine[posLine.size()-1].y );
    
    ofPopMatrix();
    ofPopStyle();
    
}



//--------------------------------------------------------------
void ofApp::debugControlPDraw(){
    
    ofPushMatrix();
    ofPushStyle();
    ofSetColor( 10 );
    
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
    
    if ( touch.id==0 ) {
        float _distS = ofDist( speedCPos.x, speedCPos.y , touch.x, touch.y );
        
        if (_distS<thresholdCSize) {
            bSpeedCtrl = true;
        } else {
            bSpeedCtrl = false;
        }
        
        //        float _sizeF = 0.7;
        float _distT = ofDist( thresholdCPos.x, thresholdCPos.y , touch.x, touch.y );
        
        if (_distT<thresholdCSize) {
            bthresholdCtrl = true;
        } else {
            bthresholdCtrl = false;
        }
        
        float _distI = ofDist( intervalPos.x, intervalPos.y , touch.x, touch.y );
        
        if (_distI<intervalSize) {
            bInterval = true;
        } else {
            bInterval = false;
        }

    }
    
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
    
    if ( touch.id==0 ) {
        
        if (bSpeedCtrl) {
            float _minY = ctrlPnY + speedCSize * 0.75;
            float _maxY = screenH - speedCSize * 0.75;
            if ((touch.y>_minY)&&(touch.y<_maxY)) {
                speedCPos.y = touch.y;
                float _tempo = ofMap(speedCPos.y, _minY, _maxY, maxSpeed, minSpeed);
                synthMain.setParameter("tempo", _tempo);
            }
        }
        
        if (bthresholdCtrl) {
            float _minY = ctrlPnY + speedCSize * 0.75;
            float _maxY = screenH - speedCSize * 0.75;
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
        
        
        if (bInterval) {
            float _minY = ctrlPnY + speedCSize * 0.75;
            float _maxY = screenH - speedCSize * 0.75;
            if ((touch.y>_minY)&&(touch.y<_maxY)) {
                intervalPos.y = touch.y;
                float _interval = ofMap(intervalPos.y, _minY, _maxY, 0, 4);
                intervalDist = _interval;
            }
        }
        
    }
    
    
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){
    
    if ((touch.x>0)&&(touch.x<ctrlPnW)&&(touch.y<ctrlPnY)&&(touch.y>0)) {
        if ((whitePixels.size()!=0)&&( touch.id==0 )) {
            bPlayNote = !bPlayNote;
            //            blur(edge, 3);
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
    
    
    float _5BaseDist = ofDist( touch.x, touch.y, base5Pos.x, base5Pos.y );
    float _6BaseDist = ofDist( touch.x, touch.y, base6Pos.x, base6Pos.y );
    float _7BaseDist = ofDist( touch.x, touch.y, base6Pos.x, base7Pos.y );
    float _8BaseDist = ofDist( touch.x, touch.y, base6Pos.x, base8Pos.y );
    
    if (_5BaseDist<baseSize) {
        index = 0;
        baseSelection = 5;
    }
    
    if (_6BaseDist<baseSize) {
        index = 0;
        baseSelection = 6;
    }
    
    if (_7BaseDist<baseSize) {
        index = 0;
        baseSelection = 7;
    }
    
    if (_8BaseDist<baseSize) {
        index = 0;
        baseSelection = 8;
    }
    
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
    
    
    // modu synth
//    ControlParameter modIndex = synth1.addParameter("modIndex", 0.25f);
//    ControlParameter carrierPitch1 = synth1.addParameter("carrierPitch1");
//    Generator rCarrierFreq = ControlMidiToFreq().input(carrierPitch1).smoothed();
//    Generator rModFreq     = rCarrierFreq * 18.0f;
//    Generator outputGen = SineWave()
//    .freq( rCarrierFreq
//          + (
//             SineWave().freq( rModFreq ) *
//             rModFreq *
//             (modIndex.smoothed() * (1.0f + SineWave().freq((LFNoise().setFreq(0.5f) + 1.f) * 2.f + 0.2f)))
//             )
//          ) * ControlDbToLinear().input(0).smoothed();
//    
//    ControlGenerator envelopTrigger1 = synth1.addParameter("trigger1");
//    Generator env1 = ADSR().attack(0.001).decay(0.2).sustain(0).release(0).trigger(envelopTrigger1).legato(false);
//    synth1.setOutputGen(outputGen * env1 * 0.75 );
    
    
    // bell ? synth
    ControlParameter carrierPitch1 = synth1.addParameter("carrierPitch1");
    float amountMod1 = 1;
    ControlGenerator rCarrierFreq1 = ControlMidiToFreq().input(carrierPitch1);
    ControlGenerator rModFreq1 = rCarrierFreq1 * 2.5;
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
    float amountMod3 = 12;
    ControlGenerator rCarrierFreq3 = ControlMidiToFreq().input(carrierPitch3);
    ControlGenerator rModFreq3 = rCarrierFreq3 * 14.489;
    Generator modulationTone3 = SineWave().freq( rModFreq3 ) * rModFreq3 * amountMod3;
    Generator tone3 = SineWave().freq(rCarrierFreq3 + modulationTone3);
    ControlGenerator envelopTrigger3 = synth3.addParameter("trigger3");
    Generator env3 = ADSR().attack(0.001).decay(0.1).sustain(0).release(0).trigger(envelopTrigger3).legato(true);
    synth3.setOutputGen( tone3 * env3 * 0.75 );
    
    ControlParameter carrierPitch4 = synth4.addParameter("carrierPitch4");
    float amountMod4 = 18;
    ControlGenerator rCarrierFreq4 = ControlMidiToFreq().input(carrierPitch4);
    ControlGenerator rModFreq4 = rCarrierFreq4 * 1.1;
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
    
    
    ControlParameter carrierPitch6 = synth6.addParameter("carrierPitch6");
    float amountMod6 = 2;
    ControlGenerator rCarrierFreq6 = ControlMidiToFreq().input(carrierPitch6);
    ControlGenerator rModFreq6 = rCarrierFreq6 * 1.109;
    Generator modulationTone6 = SineWave().freq( rModFreq6 ) * rModFreq6 * amountMod6;
    Generator tone6 = SineWave().freq(rCarrierFreq6 + modulationTone6);
    ControlGenerator envelopTrigger6 = synth6.addParameter("trigger6");
    Generator env6 = ADSR().attack(0.001).decay(0.1).sustain(0).release(0).trigger(envelopTrigger6).legato(false);
    synth6.setOutputGen( tone6 * env6 * 0.75 );
    
}


//--------------------------------------------------------------
void ofApp::noteTrigger1(){
    
    vector<int> _8bitNumber;
    _8bitNumber.resize(6);
    int _input = whitePixels[((noteIndex) % (whitePixels.size()-1))+1].pixelN;
    _8bitNumber = convertDecimalToNBase( _input, baseSelection, (int)_8bitNumber.size() );
    
    int _1Note = _8bitNumber[0];
    int _2Note = _8bitNumber[1];
    int _3Note = _8bitNumber[2];
    int _4Note = _8bitNumber[3];
    int _5Note = _8bitNumber[4];
    int _6Note = _8bitNumber[5];
    
    //    cout << _5Note << " " << _4Note << " " << _3Note << " " << _2Note  << " " << _1Note << endl;
    
    
    if (abs(_1Note - oldNoteIndex1)>=intervalDist) {
        synth1.setParameter("trigger1", 1);
        int _note1 = noteSelector(baseSelection, 1, _1Note);
        synth1.setParameter("carrierPitch1", _note1);
        scoreNote1.push_back(_note1);
    } else {
        scoreNote1.push_back(-1);
    }
    oldNoteIndex1 = _1Note;
    
    if (abs(_2Note - oldNoteIndex2)>=intervalDist) {
        synth2.setParameter("trigger2", 1);
        int _note2 = noteSelector(baseSelection, 2, _2Note);
        synth2.setParameter("carrierPitch2", _note2);
        scoreNote2.push_back(_note2);
    } else {
        scoreNote2.push_back(-1);
    }
    oldNoteIndex2 = _2Note;
    
    if (abs(_3Note - oldNoteIndex3)>=intervalDist) {
        synth3.setParameter("trigger3", 1);
        int _note3 = noteSelector(baseSelection, 3, _3Note);
        synth3.setParameter("carrierPitch3", _note3);
        scoreNote3.push_back(_note3);
    } else {
        scoreNote3.push_back(-1);
    }
    oldNoteIndex3 = _3Note;
    
    if (abs(_4Note - oldNoteIndex4)>=intervalDist) {
        synth4.setParameter("trigger4", 1);
        int _note4 = noteSelector(baseSelection, 4, _4Note);
        synth4.setParameter("carrierPitch4", _note4);
        scoreNote4.push_back(_note4);
    } else {
        scoreNote4.push_back(-1);
    }
    oldNoteIndex4 = _4Note;
    
    if (abs(_5Note - oldNoteIndex5)>=intervalDist) {
        synth5.setParameter("trigger5", 1);
        int _note5 = noteSelector(baseSelection, 5, _5Note);
        synth5.setParameter("carrierPitch5", _note5);
        scoreNote5.push_back(_note5);
    } else {
        scoreNote5.push_back(-1);
    }
    oldNoteIndex5 = _5Note;
    
    if (abs(_6Note - oldNoteIndex6)>=intervalDist) {
        synth6.setParameter("trigger6", 1);
        int _note6 = noteSelector(baseSelection, 6, _6Note);
        synth6.setParameter("carrierPitch6", _note6);
        scoreNote6.push_back(_note6);
    } else {
        scoreNote6.push_back(-1);
    }
    oldNoteIndex6 = _6Note;
    
    
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


//--------------------------------------------------------------
int ofApp::noteSelector(int _n, int _index, int _subIndex){
    
    switch (_n) {
        case 5:
            
            switch (_index) {
                case 1:
                    return scale51[_subIndex];
                    break;
                case 2:
                    return scale52[_subIndex];
                    break;
                case 3:
                    return scale53[_subIndex];
                    break;
                case 4:
                    return scale54[_subIndex];
                    break;
                case 5:
                    return scale55[_subIndex];
                    break;
                case 6:
                    return scale56[_subIndex];
                    break;
                    
                default:
                    break;
            }
            
            break;
            
        case 6:
            switch (_index) {
                    
                case 1:
                    return scale61[_subIndex];
                    break;
                case 2:
                    return scale62[_subIndex];
                    break;
                case 3:
                    return scale63[_subIndex];
                    break;
                case 4:
                    return scale64[_subIndex];
                    break;
                case 5:
                    return scale65[_subIndex];
                    break;
                case 6:
                    return scale66[_subIndex];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case 7:
            switch (_index) {
                    
                case 1:
                    return scale71[_subIndex];
                    break;
                case 2:
                    return scale72[_subIndex];
                    break;
                case 3:
                    return scale73[_subIndex];
                    break;
                case 4:
                    return scale74[_subIndex];
                    break;
                case 5:
                    return scale75[_subIndex];
                    break;
                    
                default:
                    break;
            }
            
            break;
            
        case 8:
            switch (_index) {
                    
                case 1:
                    return scale81[_subIndex];
                    break;
                case 2:
                    return scale82[_subIndex];
                    break;
                case 3:
                    return scale83[_subIndex];
                    break;
                case 4:
                    return scale84[_subIndex];
                    break;
                case 5:
                    return scale85[_subIndex];
                    break;
                    
                default:
                    break;
            }
            
            break;
            
        default:
            break;
            
    }
    
}


//--------------------------------------------------------------
void ofApp::scaleChange(){
    
    for (int i=0; i<5; i++){
        scale51[i] = scale51[i] + 64;
        scale52[i] = scale52[i] + 84;
        scale53[i] = scale53[i] + 72;
        scale54[i] = scale54[i] + 48;
        scale55[i] = scale55[i] + 36;
    }
    for (int i=0; i<3; i++){
        scale56[i] = scale56[i] + 36;
    }
    
    for (int i=0; i<6; i++){
        scale61[i] = scale61[i] + 64;
        scale62[i] = scale62[i] + 84;
        scale63[i] = scale63[i] + 72;
        scale64[i] = scale64[i] + 48;
        scale65[i] = scale65[i] + 36;
    }
    for (int i=0; i<2; i++){
        scale66[i] = scale66[i] + 36;
    }
    
    for (int i=0; i<7; i++){
        scale71[i] = scale71[i] + 64;
        scale72[i] = scale72[i] + 84;
        scale73[i] = scale73[i] + 72;
        scale74[i] = scale74[i] + 48;
    }
    for (int i=0; i<3; i++){
        scale75[i] = scale75[i] + 36;
    }
    
    for (int i=0; i<8; i++){
        scale81[i] = scale81[i] + 64;
        scale82[i] = scale82[i] + 84;
        scale83[i] = scale83[i] + 72;
        scale84[i] = scale84[i] + 48;
    }
    for (int i=0; i<2; i++){
        scale85[i] = scale85[i] + 36;
    }
    
}

