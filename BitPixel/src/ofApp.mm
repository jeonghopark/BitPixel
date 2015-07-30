// http://www.translatorscafe.com/cafe/units-converter/numbers/calculator/octal-to-decimal/


#include "ofApp.h"

using namespace ofxCv;
using namespace cv;


//--------------------------------------------------------------
void ofApp::setup(){
    
    baseSelection = 7;
    
    if (WHITE_VIEW) {
        ofBackground( 40 );
    } else {
        ofBackground( 15 );
    }

    ofSetFrameRate( 60 );
    ofEnableAlphaBlending();
    
    backgroundControPanel.load("controlBackground.png");
    
    cam.setDeviceID( 0 );
    cam.setup( 480, 360 );
    cam.setDesiredFrameRate(15);
    
    screenW = ofGetWidth();
    screenH = ofGetWidth() * 4.0 / 3.0;
    
    
    float _sizeF = screenW;
    ctrlPnX = 0;
    ctrlPnY = screenW;
    ctrlPnW = screenW;
    ctrlPnH = screenH - ctrlPnY;
    
    shiftValueIphoneY = ofGetHeight() * 0.5 - (ctrlPnY + ctrlPnH) * 0.5;
    
    bufferImg.allocate(screenW, screenW, OF_IMAGE_GRAYSCALE);
    
    cameraScreenRatio = screenW / cam.getWidth();
    
    float _widthDefault = 1536.0;
    pixelCircleSize = 10 / _widthDefault * _sizeF;
    ctrlRectS = 80 / _widthDefault * _sizeF;
    guideWidthStepSize = 96 / _widthDefault * _sizeF;
    guideHeightStepSize = 64 / _widthDefault * _sizeF;
    lineScoreStepX = 35.5 / _widthDefault * _sizeF;
    lineScoreStepY = 5 / _widthDefault * _sizeF;
    stepBasePos = 105 / _widthDefault * _sizeF;
    pixeShapeSize = 1 / _widthDefault * _sizeF;
    
    synthSetting();
    maxSpeed = 200;
    minSpeed = 30;
    bpm = synthMain.addParameter("tempo",100).min(minSpeed).max(maxSpeed);
    metro = ControlMetro().bpm(4 * bpm);
    metroOut = synthMain.createOFEvent(metro);
    synthMain.setOutputGen(synth1 + synth2 + synth3 + synth4 + synth5 + synth6 + synth7);
    
    pixelStepS = 4;
    camSize = cam.getWidth();
    changedCamSize = camSize / pixelStepS;  // 90
//    cameraScreenRatio = screenW / cam.getWidth();
    thresholdValue = 80;
    
    
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        ofSoundStreamSetup(2, 0, this, 44100, 256, 4);
        bIPhone = false;
    } else {
        ofSoundStreamSetup(2, 0, this, 44100, 256, 4);
        bIPhone = true;
    }
    
    index = 0;
    noteIndex = 0;
    
    oldNoteIndex1 = 0;
    oldNoteIndex2 = 0;
    oldNoteIndex3 = 0;
    oldNoteIndex4 = 0;
    oldNoteIndex5 = 0;
    oldNoteIndex6 = 0;
    oldNoteIndex7 = 0;
    
    oldScoreNote1 = 0;
    oldScoreNote2 = 0;
    oldScoreNote3 = 0;
    oldScoreNote4 = 0;
    oldScoreNote5 = 0;
    oldScoreNote6 = 0;
    oldScoreNote7 = 0;
    
    speedCSize = ctrlRectS;
    speedCPos = ofPoint( 15 * guideWidthStepSize, ctrlPnY + ctrlPnH * 0.5 );
    bSpeedCtrl = false;
    
    thresholdCSize = ctrlRectS * 0.5;
    thresholdCPos = ofPoint( 1 * guideWidthStepSize, ctrlPnY + ctrlPnH * 0.5 );
    bthresholdCtrl = false;
    
    intervalSize = ctrlRectS * 0.5;
    intervalPos = ofPoint( 1 * guideWidthStepSize, ctrlPnY + ctrlPnH * 0.5 );
    bthresholdCtrl = false;
    intervalDist = 1;
    
    cannyThreshold1 = 120;
    cannyThreshold2 = 120;
    grayThreshold = 120;
    
    
    float _posIndexRight = 13.5;
    float _posIndexLeft = 2.5;
    base4Pos = ofPoint( guideWidthStepSize * _posIndexLeft, ctrlPnY + stepBasePos * 1 );
    base5Pos = ofPoint( guideWidthStepSize * _posIndexLeft, ctrlPnY + stepBasePos * 2.5 );
    base6Pos = ofPoint( guideWidthStepSize * _posIndexLeft, ctrlPnY + stepBasePos * 4 );
    base7Pos = ofPoint( guideWidthStepSize * _posIndexRight, ctrlPnY + stepBasePos * 1 );
    base8Pos = ofPoint( guideWidthStepSize * _posIndexRight, ctrlPnY + stepBasePos * 2.5 );
    base9Pos = ofPoint( guideWidthStepSize * _posIndexRight, ctrlPnY + stepBasePos * 4 );
    baseSize = ctrlRectS * 0.55;
    
    bPlayNote = false;
    bCameraCapturePlay = false;
    
    scaleSetting.setup();
    
    lineScoreNumber = 23;
    
    touchPos.assign(2, ofVec2f());
    
}

//--------------------------------------------------------------
void ofApp::update(){
    
    cam.update();
    
    if(cam.isFrameNew()) {
        
        convertColor(cam, gray, CV_RGB2GRAY);
        threshold(gray, gray, grayThreshold);
//                erode(gray);
        Canny(gray, edge, cannyThreshold1, cannyThreshold2, 3);
        thin(edge);
        
        if (WHITE_VIEW) {
            invert(edge);
        }
        
        edge.update();
        
        
        if ( bCameraCapturePlay ) {
            noteIndex = index;
        } else {
            
            unsigned char * _src = edge.getPixels().getData();
            
            noteIndex = 0;
            ofImage _tImage;
            
            pixelBright.clear();
            whitePixels.clear();
            blackPixels.clear();
            
            for (int j=0; j<camSize; j+=pixelStepS) {
                for (int i=0; i<camSize; i+=pixelStepS) {
                    int _index = i + j * camSize;
                    float _brightness = _src[_index];
                    pixelBright.push_back(_brightness);
                }
            }
            
            
            int _wCounter = 0;
            int _bCounter = 0;
            
            for (int i=0; i<pixelBright.size(); i++) {
                
                int _whitePixel;
                if (WHITE_VIEW) {
                    _whitePixel = 255;
                } else {
                    _whitePixel = 0;
                }

                if ( pixelBright[i] == _whitePixel ) {
                    
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
    
    trigScoreNote( scoreNote1, synth1, 1 );
    trigScoreNote( scoreNote2, synth2, 2 );
    trigScoreNote( scoreNote3, synth3, 3 );
    trigScoreNote( scoreNote4, synth4, 4 );
    trigScoreNote( scoreNote5, synth5, 5 );
    trigScoreNote( scoreNote6, synth6, 6 );
    trigScoreNote( scoreNote7, synth7, 7 );
    
    
}


//--------------------------------------------------------------
void ofApp::draw(){
    
    ofTranslate( 0, shiftValueIphoneY );

    ofPushMatrix();
    
    ofPushStyle();

    if (!bCameraCapturePlay) {

        if (WHITE_VIEW) {
            ofSetColor( 255, 255 );
        } else {
            ofSetColor( 255, 150 );
        }

        edge.draw( 0, 0, screenW, screenH);
    }
    ofPopStyle();
    
    
    ofPushStyle();
    if (bCameraCapturePlay) {
        ofSetColor( 255, 255 );
        ofDrawRectangle(0, 0, screenW, screenH);

        if (WHITE_VIEW) {
            ofSetColor( 255, 80 );
        } else {
            ofSetColor( 255, 120 );
        }
        bufferImg.draw( 0, 0, screenW, screenH);
    }
    ofPopStyle();
    ofPopMatrix();
    
    //    ofPushStyle();
    //    ofSetColor(255,230);
    //    ofDrawRectangle(0, 0, screenW, screenH);
    //    ofPopStyle();
    
    
    ofPushStyle();
    if (bCameraCapturePlay) {
        if (WHITE_VIEW) {
            ofSetColor( 0, 60 );
        } else {
            ofSetColor( 255, 60 );
        }
    } else {
        if (WHITE_VIEW) {
            ofSetColor( 0, 220 );
        } else {
            ofSetColor( 255, 160 );
        }
    }
    drawTrianglePixel();
    ofPopStyle();
    
    
    if (bCameraCapturePlay) {
        
        drawPixelNumbersCircleNotes();
        //        drawPlayingShapeNotes();
        //        drawPixelAllNoteShape();
        
        drawPixelAllNoteShapes( scoreNote1, 1 );
        drawPixelAllNoteShapes( scoreNote2, 2 );
        drawPixelAllNoteShapes( scoreNote3, 3 );
        drawPixelAllNoteShapes( scoreNote4, 4 );
        drawPixelAllNoteShapes( scoreNote5, 5 );
        drawPixelAllNoteShapes( scoreNote6, 6 );
        drawPixelAllNoteShapes( scoreNote7, 7 );
        
        //        drawPixelShapeColorSize();
        
        drawPlayingShapeNote( scoreNote1, 1 );
        drawPlayingShapeNote( scoreNote2, 2 );
        drawPlayingShapeNote( scoreNote3, 3 );
        drawPlayingShapeNote( scoreNote4, 4 );
        drawPlayingShapeNote( scoreNote5, 5 );
        drawPlayingShapeNote( scoreNote6, 6 );
        drawPlayingShapeNote( scoreNote7, 7 );
        
    }
    
    drawControlElement();
    
    if (bCameraCapturePlay) {
        drawLineScore();
    }
    
    drawBaseInterface();
    
}


//--------------------------------------------------------------
void ofApp::drawControlElement(){
    
    
    ofPushStyle();
    if (WHITE_VIEW) {
        ofSetColor( 255 );
    } else {
        ofSetColor( 0 );
    }
    ofDrawRectangle( 0, ctrlPnY, ctrlPnW, ctrlPnH );
    if (WHITE_VIEW) {
        ofSetColor( 0, 10 );
    } else {
        ofSetColor( 255, 20 );
    }
    backgroundControPanel.draw( 0, ctrlPnY, ctrlPnW, 140 );
    ofPopStyle();
    
    ofPushMatrix();
    ofPushStyle();

    if (WHITE_VIEW) {
        ofSetColor( 0, 80 );
    } else {
        ofSetColor( 255, 80 );
    }
    
    float _speedX = guideWidthStepSize;
    float _yD = 20;
    ofDrawLine( _speedX, ctrlPnY + _yD, _speedX, screenH - _yD);
    
    float _thresholdX = guideWidthStepSize * 15;
    ofDrawLine( _thresholdX, ctrlPnY + _yD, _thresholdX, screenH - _yD);
    
//    float _intervalX = guideWidthStepSize * 2.5;
//    ofDrawLine( _intervalX, ctrlPnY + _yD, _intervalX, screenH - _yD);
    
    ofPopStyle();
    ofPopMatrix();
    
    int _alpha = 180;
    ofPushStyle();
    if (WHITE_VIEW) {
        ofSetColor( 0, _alpha );
    } else {
        ofSetColor( 255, _alpha );
    }
    ofSetCircleResolution(48);
    float _sX = speedCPos.x;
    float _sY = speedCPos.y;
    ofNoFill();
    ofDrawCircle( _sX, _sY, speedCSize * 0.5 );
    ofPopStyle();
    
//    ofPushStyle();
//    ofSetColor( 255, _alpha );
//    ofNoFill();
//    float _sizeF = 1.1;
//    float _x1 = thresholdCPos.x;
//    float _y1 = thresholdCPos.y - thresholdCSize * _sizeF;
//    float _x2 = thresholdCPos.x - cos(ofDegToRad(30)) * thresholdCSize * _sizeF;
//    float _y2 = thresholdCPos.y + sin(ofDegToRad(30)) * thresholdCSize * _sizeF;
//    float _x3 = thresholdCPos.x + cos(ofDegToRad(30)) * thresholdCSize * _sizeF;
//    float _y3 = thresholdCPos.y + sin(ofDegToRad(30)) * thresholdCSize * _sizeF;
//    ofDrawTriangle( _x1, _y1, _x2, _y2, _x3, _y3 );
//    ofPopStyle();
    
    
    ofPushStyle();
    if (WHITE_VIEW) {
        ofSetColor( 0, _alpha );
    } else {
        ofSetColor( 255, _alpha );
    }
    float _iX = intervalPos.x;
    float _iY = intervalPos.y;
    ofDrawLine( _iX - intervalSize, _iY, _iX, _iY + intervalSize );
    ofDrawLine( _iX, _iY - intervalSize, _iX + intervalSize, _iY );
    ofDrawLine( _iX + intervalSize, _iY, _iX, _iY + intervalSize );
    ofDrawLine( _iX, _iY - intervalSize, _iX - intervalSize, _iY );
    ofPopStyle();
    
    
    ofPushMatrix();
    ofPushStyle();
    if (WHITE_VIEW) {
        ofSetColor( 0, 80 );
    } else {
        ofSetColor( 255, 80 );
    }
    
    int _xDefaultPos = lineScoreStepX * (lineScoreNumber-1);

    float _xL1 = ctrlPnW * 0.5 - _xDefaultPos * 0.5;
    ofDrawLine( _xL1, ctrlPnY + _yD, _xL1, screenH - _yD);
    
    float _xL2 = ctrlPnW * 0.5 + _xDefaultPos * 0.5;
    ofDrawLine( _xL2, ctrlPnY + _yD, _xL2, screenH - _yD);

    float _xM = ctrlPnW * 0.5;
    if (WHITE_VIEW) {
        ofSetColor( 0, 40 );
    } else {
        ofSetColor( 255, 40 );
    }
    ofDrawLine( _xM, ctrlPnY + _yD, _xM, screenH - _yD);
    
    ofPopStyle();
    ofPopMatrix();

    
}




//--------------------------------------------------------------
void ofApp::drawTrianglePixel(){
    
    int _pixelSize = pixelCircleSize;  // 10
    float _ellipseSizeR = 1.7;
    
    ofPushMatrix();
    ofPushStyle();
    ofEnableAntiAliasing();
    
    for (int i=0; i<whitePixels.size(); i++) {
        
        int _noteLoopIndex = ((i) % (whitePixels.size()-1))+1;
        int _pixelNumbers = whitePixels[ _noteLoopIndex ].pixelN;
        int _indexPixes = whitePixels[ _noteLoopIndex ].indexPos - _pixelNumbers;
        
        float _x = ((_indexPixes) % changedCamSize) * pixelStepS * cameraScreenRatio - _pixelSize;
        float _y = (int)((_indexPixes) / changedCamSize) * pixelStepS * cameraScreenRatio;
        
        ofPoint _1P = ofPoint( _x, _y - _pixelSize * _ellipseSizeR * 0.75 );
        ofPoint _2P = ofPoint( _x - _pixelSize * _ellipseSizeR * 0.55, _y + _pixelSize * _ellipseSizeR * 0.25 );
        ofPoint _3P = ofPoint( _x + _pixelSize * _ellipseSizeR * 0.55, _y + _pixelSize * _ellipseSizeR * 0.25 );
        
        ofDrawTriangle( _1P, _2P, _3P );
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
    
}


//--------------------------------------------------------------
void ofApp::drawPixelAllNoteShape(){
    
    ofPushMatrix();
    ofPushStyle();
    ofEnableAntiAliasing();
    
    if (WHITE_VIEW) {
        ofSetColor( 0, 180 );
    } else {
        ofSetColor( 255, 180 );
    }
    
    for (int i=0; i<whitePixels.size(); i++) {
        
        int _noteLoopIndex = ((i) % (whitePixels.size()-1))+1;
        int _pixelNumbers = whitePixels[ _noteLoopIndex ].pixelN;
        int _indexPixes = whitePixels[ _noteLoopIndex ].indexPos - _pixelNumbers;
        
        float _x = ((_indexPixes) % changedCamSize) * pixelStepS * cameraScreenRatio;
        float _y = (int)((_indexPixes) / changedCamSize) * pixelStepS * cameraScreenRatio;
        ofPoint _p = ofPoint( _x, _y );
        
        float _size = ofMap( _pixelNumbers, 0, 400, 5, 100 );
        drawShape( _p, baseSelection, _size );
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
    
}



//--------------------------------------------------------------
void ofApp::drawPixelAllNoteShapes( vector<int> _vNote, int _scoreCh ){
    
    ofPushMatrix();
    ofPushStyle();
    ofEnableAntiAliasing();
    
    if (WHITE_VIEW) {
        ofSetColor( 0, 80 );
    } else {
        ofSetColor( 255, 80 );
    }
    
    for (int i=0; i<whitePixels.size(); i++) {
        
        int _noteLoopIndex = ((i) % (whitePixels.size()-1))+1;
        int _pixelNumbers = whitePixels[ _noteLoopIndex ].pixelN;
        int _indexPixes = whitePixels[ _noteLoopIndex ].indexPos - _pixelNumbers;
        
        float _x = ((_indexPixes) % changedCamSize) * pixelStepS * cameraScreenRatio;
        float _y = (int)((_indexPixes) / changedCamSize) * pixelStepS * cameraScreenRatio;
        ofPoint _p = ofPoint( _x, _y );
        
        
        int _indexLoopLine = ((i) % (whitePixels.size()-1)) + 1;
        int _indexLoopLineOld = ((i + 1) % (whitePixels.size()-1)) + 1;
        
        int _note = _vNote[_indexLoopLine];
        int _noteOld = _vNote[_indexLoopLineOld];
        
        int _noteScaled = scaleSetting.noteSelector(baseSelection, _scoreCh, _note);
        int _noteOldScaled = scaleSetting.noteSelector(baseSelection, _scoreCh, _noteOld);
        
        
        if ( abs(_noteOldScaled-_noteScaled) >= intervalDist ) {
            if (_note>0) {
                float _size = _noteScaled * pixeShapeSize;
                drawShape( _p, baseSelection, _size );
            }
        }
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
    
}




//--------------------------------------------------------------
void ofApp::drawPixelShapeColorSize(){
    
    ofPushMatrix();
    ofPushStyle();
    ofEnableAntiAliasing();
    
    if (WHITE_VIEW) {
        ofSetColor( 0, 45 );
    } else {
        ofSetColor( 255, 45 );
    }
    
    for (int i=0; i<whitePixels.size(); i++) {
        
        vector<int> _bitNumber;
        _bitNumber.resize(7);
        int _indexLoop = ((i) % (whitePixels.size()-1))+1;
        int _pixelNumbers = whitePixels[ _indexLoop ].pixelN;
        _bitNumber = convertDecimalToNBase( _pixelNumbers, baseSelection, (int)_bitNumber.size() );
        
        int _1Note = _bitNumber[0];
        int _2Note = _bitNumber[1];
        int _3Note = _bitNumber[2];
        int _4Note = _bitNumber[3];
        int _5Note = _bitNumber[4];
        int _6Note = _bitNumber[5];
        int _7Note = _bitNumber[6];
        
        int _indexPixes = whitePixels[ _indexLoop ].indexPos - _pixelNumbers;
        
        float _x = ((_indexPixes) % changedCamSize) * pixelStepS * cameraScreenRatio;
        float _y = (int)((_indexPixes) / changedCamSize) * pixelStepS * cameraScreenRatio;
        ofPoint _p = ofPoint( _x, _y );
        
        int _min = 10;
        int _max = 100;
        
        float _size1 = ofMap( _1Note, 0, baseSelection-1, _min, _max );
        drawShape( _p, baseSelection, _size1 );
        float _size2 = ofMap( _2Note, 0, baseSelection-1, _min, _max );
        drawShape( _p, baseSelection, _size2 );
        float _size3 = ofMap( _3Note, 0, baseSelection-1, _min, _max );
        drawShape( _p, baseSelection, _size3 );
        float _size4 = ofMap( _4Note, 0, baseSelection-1, _min, _max );
        drawShape( _p, baseSelection, _size4 );
        float _size5 = ofMap( _5Note, 0, baseSelection-1, _min, _max );
        drawShape( _p, baseSelection, _size5 );
        float _size6 = ofMap( _6Note, 0, baseSelection-1, _min, _max );
        drawShape( _p, baseSelection, _size6 );
        float _size7 = ofMap( _7Note, 0, baseSelection-1, _min, _max );
        drawShape( _p, baseSelection, _size7 );
        
        
        if (scoreNote1[i]>0) {
            ofDrawCircle( _x, _y, scoreNote1[i] * 10 );
        }
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
}




//--------------------------------------------------------------
void ofApp::drawPixelNumbersCircleNotes(){
    
    int _pixelSize = pixelCircleSize;
    float _ellipseSizeR = 0.7;
    
    ofPushMatrix();
    ofPushStyle();
    ofEnableAntiAliasing();

    if (WHITE_VIEW) {
        ofSetColor( 0, 120 );
    } else {
        ofSetColor( 255, 120 );
    }
    
    if (whitePixels.size()>0) {
        
        int _noteLoopIndex = ((noteIndex) % (whitePixels.size()-1))+1;
        int _pixelNumbers = whitePixels[_noteLoopIndex].pixelN;
        int _indexPixes = whitePixels[_noteLoopIndex].indexPos - _pixelNumbers;
        
        for (int i=0; i<_pixelNumbers; i++){
            
            float _xS = ((_indexPixes+i) % changedCamSize) * pixelStepS * cameraScreenRatio;
            float _yS = (int)((_indexPixes+i) / changedCamSize) * pixelStepS * cameraScreenRatio;
            
//            ofFill();
//            ofSetColor( 255, 20 );
//            ofDrawCircle( _xS, _yS, _pixelSize * _ellipseSizeR );
           
            ofNoFill();
            if (WHITE_VIEW) {
                ofSetColor( 0, 120 );
            } else {
                ofSetColor( 255, 120 );
            }
            ofDrawCircle( _xS, _yS, _pixelSize * _ellipseSizeR );
            
        }
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
}



//--------------------------------------------------------------
void ofApp::drawPlayingShapeNotes(){
    
    ofPushMatrix();
    ofPushStyle();
    ofEnableAntiAliasing();
    if (WHITE_VIEW) {
        ofSetColor( 0, 120 );
    } else {
        ofSetColor( 255, 120 );
    }
    
    if (whitePixels.size()>0) {
        
        int _noteLoopIndex = ((noteIndex) % (whitePixels.size()-1))+1;
        int _pixelNumbers = whitePixels[ _noteLoopIndex ].pixelN;
        int _indexPixes = whitePixels[ _noteLoopIndex ].indexPos - _pixelNumbers;
        
        float _x = ((_indexPixes) % changedCamSize) * pixelStepS * cameraScreenRatio;
        float _y = (int)((_indexPixes) / changedCamSize) * pixelStepS * cameraScreenRatio;
        ofPoint _p = ofPoint( _x, _y );
        
        drawShape( _p, baseSelection, _pixelNumbers);
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
}



//--------------------------------------------------------------
void ofApp::drawPlayingShapeNote( vector<int> _vNote, int _scoreCh ){
    
    ofPushMatrix();
    ofPushStyle();
    
    float _h = ofMap( _scoreCh, 1, 7, 0, 255 );
    ofColor _c = ofColor::fromHsb( _h, 180, 255, 180 );
    
    if (whitePixels.size()>0) {
        
        int _noteLoopIndex = ((noteIndex) % (whitePixels.size()-1))+1;
        int _pixelNumbers = whitePixels[ _noteLoopIndex ].pixelN;
        int _indexPixes = whitePixels[ _noteLoopIndex ].indexPos - _pixelNumbers;
        
        float _x = ((_indexPixes) % changedCamSize) * pixelStepS * cameraScreenRatio;
        float _y = (int)((_indexPixes) / changedCamSize) * pixelStepS * cameraScreenRatio;
        ofPoint _p = ofPoint( _x, _y );
        
        int _indexLoopLineOld = ((1 + noteIndex) % (whitePixels.size()-1)) + 1;
        
        int _note = _vNote[_noteLoopIndex];
        int _noteOld = _vNote[_indexLoopLineOld];
        
        int _noteScaled = scaleSetting.noteSelector(baseSelection, _scoreCh, _note);
        int _noteOldScaled = scaleSetting.noteSelector(baseSelection, _scoreCh, _noteOld);
        
        if ( abs(_noteOldScaled-_noteScaled) >= intervalDist ) {
            if (_note>0) {
                //                drawShapeCeterLine( _p, baseSelection, _pixelNumbers);
                
                float _size = _noteScaled * pixeShapeSize;
                drawShapeCeterLineColorRotation( _p, baseSelection, _size, _c );
            }
        }
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
}


//--------------------------------------------------------------
void ofApp::drawLineScore(){
    
    int _xNumber = lineScoreNumber;
    int _stepX = lineScoreStepX;
    int _stepY = lineScoreStepY;
    int _defaultNote = 56;
    int _xDefaultPos = _stepX * (_xNumber-1);
    
    
    ofPushMatrix();
    ofTranslate( ctrlPnW * 0.5 - _xDefaultPos * 0.5, ctrlPnY + 127 * _stepY - _defaultNote );
    
    ofPushStyle();
    if (WHITE_VIEW) {
        ofSetColor( 0, 120 );
    } else {
        ofSetColor( 255, 120 );
    }
    
    drawScoreCircleLine(scoreNote1, 1);
    drawScoreCircleLine(scoreNote2, 2);
    drawScoreCircleLine(scoreNote3, 3);
    drawScoreCircleLine(scoreNote4, 4);
    drawScoreCircleLine(scoreNote5, 5);
    drawScoreCircleLine(scoreNote6, 6);
    drawScoreCircleLine(scoreNote7, 7);
    
    ofPopStyle();
    ofPopMatrix();
    
}


//--------------------------------------------------------------
void ofApp::drawScoreCircleLine( vector<int> _vNote, int _scoreCh ){
    
    
    int _xNumber = lineScoreNumber;
    int _middle = _xNumber * 0.5;
    int _stepX = lineScoreStepX;
    int _stepY = lineScoreStepY;
    int _defaultNote = 56;
    int _size = 3;
    int _xDefaultPos = _stepX * (_xNumber-1);
    
    vector<int> _scoreNote = _vNote;
    
    float _h = ofMap( _scoreCh, 1, 7, 0, 255 );
    ofColor _c = ofColor::fromHsb( _h, 180, 255, 180 );

    
    if (_scoreNote.size()>0) {
        
        ofPushStyle();

        for (int i=0; i<_xNumber; i++){
            
            int _indexLoopLine = ((i + noteIndex - _middle) % (whitePixels.size()-1)) + 1;
            int _indexLoopLineOld = ((i + 1 + noteIndex - _middle) % (whitePixels.size()-1)) + 1;
            
            int _note = _scoreNote[_indexLoopLine];
            int _noteOld = _scoreNote[_indexLoopLineOld];
            
            int _noteScaled = scaleSetting.noteSelector(baseSelection, _scoreCh, _note);
            int _noteOldScaled = scaleSetting.noteSelector(baseSelection, _scoreCh, _noteOld);
            
            float _x1 = _xDefaultPos - i * _stepX;
            float _y1 = _defaultNote - _noteScaled * _stepY;
                        
            if ( abs(_noteOldScaled-_noteScaled) >= intervalDist ) {
                ofColor _c;
                if (i==11) {
                    _c = ofColor::fromHsb( _h, 255, 255, 255 );
                } else {
                    _c = ofColor::fromHsb( _h, 180, 255, 120 );
                }
                if (_note>0) {
                    ofSetColor( _c );
                    ofDrawCircle( _x1, _y1, _size );
                }
            }
            
        }
        
        ofPopStyle();

        ofPushStyle();
        ofSetColor( _c, 60 );

        
        for (int i=0; i<_xNumber-1; i++){
            
            int _indexLoopLineS = ((i + noteIndex - _middle) % (whitePixels.size()-1)) + 1;
            int _indexLoopLineE = ((i + 1 + noteIndex - _middle) % (whitePixels.size()-1)) + 1;
            
            int _indexLoopLineEOld = ((i + 2 + noteIndex - _middle) % (whitePixels.size()-1)) + 1;
            
            int _noteS = _scoreNote[_indexLoopLineS];
            int _noteE = _scoreNote[_indexLoopLineE];
            int _noteEOld = _scoreNote[_indexLoopLineEOld];
            
            int _noteSScaled = scaleSetting.noteSelector(baseSelection, _scoreCh, _noteS);
            int _noteEScaled = scaleSetting.noteSelector(baseSelection, _scoreCh, _noteE);
            int _noteEOldScaled = scaleSetting.noteSelector(baseSelection, _scoreCh, _noteEOld);
            
            float _x1 = _xDefaultPos - i * _stepX;
            float _y1 = _defaultNote - _noteSScaled * _stepY;
            float _x2 = _xDefaultPos - (i + 1) * _stepX;
            float _y2 = _defaultNote - _noteEScaled * _stepY;
            
            
            if ( (abs(_noteEScaled-_noteSScaled) >= intervalDist) && abs(_noteEOldScaled-_noteEScaled) >= intervalDist ) {
                if ( _noteS > 0 && _noteE > 0 ) {
                    ofDrawLine( _x1, _y1, _x2, _y2 );
                }
            }
        }
        
        ofPopStyle();
        
    }
    
    
    
    
}



//--------------------------------------------------------------
void ofApp::controlGuide(){
    
    
    
}



//--------------------------------------------------------------
void ofApp::drawBaseInterface(){
    
    ofPushMatrix();
    ofPushStyle();

    ofColor _c[6];
    
    for (int i=0; i<6; i++) {
        if ( baseSelection == (4 + i) ) {
            _c[i] = ofColor::fromHsb( i*40, 180, 180 );
        } else {
            _c[i] = ofColor(0, 0, 0);
        }
    }

    drawShapeCeterLine( base4Pos, 4, baseSize, _c[0] );
    drawShapeCeterLine( base5Pos, 5, baseSize, _c[1] );
    drawShapeCeterLine( base6Pos, 6, baseSize, _c[2] );
    drawShapeCeterLine( base7Pos, 7, baseSize, _c[3] );
    drawShapeCeterLine( base8Pos, 8, baseSize, _c[4] );
    drawShapeCeterLine( base9Pos, 9, baseSize, _c[5] );
    
    ofPopMatrix();
    ofPopStyle();
    
}


//--------------------------------------------------------------
void ofApp::drawShapeCeterLine(ofPoint pos, int base, int size, ofColor _c){
    
    ofPoint _pos = pos;
    
    vector<ofPoint> posLine;
    
    int _base = base;
    int _size = size;
    
    for (int i=0; i<_base; i++) {
        float _sizeDegree = i * 360 / _base + 180.0;
        float _x = sin(ofDegToRad( _sizeDegree )) * _size;
        float _y = cos(ofDegToRad( _sizeDegree )) * _size;
        
        ofPoint _p = ofPoint( _x, _y );
        posLine.push_back( _p );
    }
    
    
    ofPushMatrix();
    ofPushStyle();
    
    ofTranslate( _pos );
    
    if (WHITE_VIEW) {
        ofSetColor( _c, 60 );
    } else {
        ofSetColor( _c, 60 );
    }
    for (int i=0; i<posLine.size(); i++){
        ofDrawLine( 0, 0, posLine[i].x, posLine[i].y );
    }
    
    if (WHITE_VIEW) {
        ofSetColor( _c, 180 );
    } else {
        ofSetColor( _c, 180 );
    }
    for (int i=0; i<posLine.size()-1; i++){
        ofDrawLine( posLine[i].x, posLine[i].y, posLine[i+1].x, posLine[i+1].y );
    }
    ofDrawLine( posLine[0].x, posLine[0].y, posLine[posLine.size()-1].x, posLine[posLine.size()-1].y );
    
    ofPopMatrix();
    ofPopStyle();
    
}


//--------------------------------------------------------------
void ofApp::drawShapeCeterLineColorRotation(ofPoint pos, int base, int size, ofColor color){
    
    ofPoint _pos = pos;
    
    vector<ofPoint> posLine;
    
    int _base = base;
    int _size = size;
    
    for (int i=0; i<_base; i++) {
        float _sizeDegree = i * 360 / _base + 180.0;
        float _x = sin(ofDegToRad( _sizeDegree )) * _size;
        float _y = cos(ofDegToRad( _sizeDegree )) * _size;
        
        ofPoint _p = ofPoint( _x, _y );
        posLine.push_back( _p );
    }
    
    
    ofPushMatrix();
    ofPushStyle();
    
    
    ofTranslate( _pos );
    ofRotateZ( 45 );
    
    ofSetLineWidth( 3 );
    
    ofSetColor( color.r, color.g, color.b, color.a * 0.2 );
    for (int i=0; i<posLine.size(); i++){
        ofDrawLine( 0, 0, posLine[i].x, posLine[i].y );
    }
    
    ofSetColor( color );
    for (int i=0; i<posLine.size()-1; i++){
        ofDrawLine( posLine[i].x, posLine[i].y, posLine[i+1].x, posLine[i+1].y );
    }
    ofDrawLine( posLine[0].x, posLine[0].y, posLine[posLine.size()-1].x, posLine[posLine.size()-1].y );
    
    ofPopMatrix();
    ofPopStyle();
    
}




//--------------------------------------------------------------
void ofApp::drawShape(ofPoint pos, int base, int size){
    
    ofPoint _pos = pos;
    
    vector<ofPoint> posLine;
    
    int _base = base;
    int _size = size;
    
    for (int i=0; i<_base; i++) {
        float _sizeDegree = i * 360 / _base + 180.0;
        float _x = sin(ofDegToRad( _sizeDegree )) * _size;
        float _y = cos(ofDegToRad( _sizeDegree )) * _size;
        
        ofPoint _p = ofPoint( _x, _y );
        posLine.push_back( _p );
    }
    
    
    ofPushMatrix();
    
    ofTranslate( _pos );
    
    for (int i=0; i<posLine.size()-1; i++){
        ofDrawLine( posLine[i].x, posLine[i].y, posLine[i+1].x, posLine[i+1].y );
    }
    ofDrawLine( posLine[0].x, posLine[0].y, posLine[posLine.size()-1].x, posLine[posLine.size()-1].y );
    
    ofPopMatrix();
    
}



//--------------------------------------------------------------
void ofApp::debugControlPDraw(){
    
    ofPushMatrix();
    ofPushStyle();
    if (WHITE_VIEW) {
        ofSetColor( 0 );
    } else {
        ofSetColor( 255 );
    }
    
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
    ofDrawBitmapString( ofToString(ofGetFrameRate(),2), 10, screenH-10 );
    ofPopStyle();
    
}




//--------------------------------------------------------------
void ofApp::exit(){
    
    cam.close();
    
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    
    float _tolerance = 3;
    
    ofPoint _changedTouch = ofPoint(touch.x, touch.y - shiftValueIphoneY);
    
    touchPos[touch.id] = _changedTouch;
    
    distS[touch.id] = ofDist( speedCPos.x, speedCPos.y , touchPos[touch.id].x, touchPos[touch.id].y );
    
    for (int i=0; i<2; i++) {
        
        float _distS = ofDist( speedCPos.x, speedCPos.y , touchPos[i].x, touchPos[i].y );
        if ( (_distS < thresholdCSize * _tolerance) && bSpeedCtrl == false) {
            bSpeedCtrl = true;
        }

    }
    
    
    distI[touch.id] = ofDist( intervalPos.x, intervalPos.y , touchPos[touch.id].x, touchPos[touch.id].y );
    
    for (int i=0; i<2; i++) {
        float _distI = ofDist( intervalPos.x, intervalPos.y , touchPos[i].x, touchPos[i].y );
        if ( (_distI < intervalSize * _tolerance) && bInterval == false) {
            bInterval = true;
        }

    }
    

    
    
    if ( touch.id==0 ) {
    
//        float _distS = ofDist( speedCPos.x, speedCPos.y , _changedTouch.x, _changedTouch.y );
//        
//        if (_distS < thresholdCSize * _tolerance) {
//            bSpeedCtrl = true;
//        } else {
//            bSpeedCtrl = false;
//        }
        
//        float _distT = ofDist( thresholdCPos.x, thresholdCPos.y , _changedTouch.x, _changedTouch.y );
        
//        if (_distT < thresholdCSize * _tolerance) {
//            bthresholdCtrl = true;
//        } else {
//            bthresholdCtrl = false;
//        }
        
//        float _distI = ofDist( intervalPos.x, intervalPos.y , _changedTouch.x, _changedTouch.y );
//        
//        if (_distI < intervalSize * _tolerance) {
//            bInterval = true;
//        } else {
//            bInterval = false;
//        }
        
        
        if ( (_changedTouch.x>0)&&(_changedTouch.x<ctrlPnW) && (_changedTouch.y<ctrlPnY)&&(_changedTouch.y>0) ) {
            
            grayThreshold = 120;
            touchDownDefault = _changedTouch.y;
            
        }
   
    }
    
    float _4BaseDist = ofDist( _changedTouch.x, _changedTouch.y, base4Pos.x, base4Pos.y );
    if ( _4BaseDist < baseSize ) {
        //        index = 0;
        baseSelection = 4;
    }
    
    float _5BaseDist = ofDist( _changedTouch.x, _changedTouch.y, base5Pos.x, base5Pos.y );
    if ( _5BaseDist < baseSize ) {
        //        index = 0;
        baseSelection = 5;
    }
    
    float _6BaseDist = ofDist( _changedTouch.x, _changedTouch.y, base6Pos.x, base6Pos.y );
    if ( _6BaseDist < baseSize ) {
        //        index = 0;
        baseSelection = 6;
    }
    
    float _7BaseDist = ofDist( _changedTouch.x, _changedTouch.y, base7Pos.x, base7Pos.y );
    if ( _7BaseDist < baseSize ) {
        //        index = 0;
        baseSelection = 7;
    }
    
    float _8BaseDist = ofDist( _changedTouch.x, _changedTouch.y, base8Pos.x, base8Pos.y );
    if ( _8BaseDist < baseSize ) {
        //        index = 0;
        baseSelection = 8;
    }
    
    float _9BaseDist = ofDist( _changedTouch.x, _changedTouch.y, base9Pos.x, base9Pos.y );
    if ( _9BaseDist < baseSize ) {
        //        index = 0;
        baseSelection = 9;
    }
    
    
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
    
    ofPoint _changedTouch = ofPoint(touch.x, touch.y - shiftValueIphoneY);

    touchPos[touch.id] = _changedTouch;
    if (bSpeedCtrl) {
        float _minY = ctrlPnY + speedCSize * 0.75;
        float _maxY = screenH - speedCSize * 0.75;
        
        if ( (touchPos[touch.id].y>_minY) && (touchPos[touch.id].y<_maxY) && touchPos[touch.id].x>speedCPos.x - (ctrlPnW-speedCPos.x) ) {
            speedCPos.y = touchPos[touch.id].y;
            float _tempo = ofMap( speedCPos.y, _minY, _maxY, maxSpeed, minSpeed );
            synthMain.setParameter("tempo", _tempo);
        }
        
    }
    
    //        if (bthresholdCtrl) {
    //            float _minY = ctrlPnY + speedCSize * 0.75;
    //            float _maxY = screenH - speedCSize * 0.75;
    //
    //            if ((_changedTouch.y>_minY)&&(_changedTouch.y<_maxY)) {
    //                thresholdCPos.y = _changedTouch.y;
    //                float _threshold = ofMap(thresholdCPos.y, _minY, _maxY, 255, 0);
    //                grayThreshold = _threshold;
    //            }
    //        }
    
    
    if (bInterval) {
        float _minY = ctrlPnY + speedCSize * 0.75;
        float _maxY = screenH - speedCSize * 0.75;
        if ((touchPos[touch.id].y>_minY)&&(touchPos[touch.id].y<_maxY) && touchPos[touch.id].x<intervalPos.x * 2 ) {
            intervalPos.y = touchPos[touch.id].y;
            float _interval = ofMap(intervalPos.y, _minY, _maxY, 0, 20);
            intervalDist = _interval;
        }
    }

    
    
    if ( touch.id==0 ) {
        
//        if (bSpeedCtrl) {
//            float _minY = ctrlPnY + speedCSize * 0.75;
//            float _maxY = screenH - speedCSize * 0.75;
//            
//            if ((_changedTouch.y>_minY)&&(_changedTouch.y<_maxY)) {
//                speedCPos.y = _changedTouch.y;
//                float _tempo = ofMap( speedCPos.y, _minY, _maxY, maxSpeed, minSpeed );
//                synthMain.setParameter("tempo", _tempo);
//            }
//            
//        }
//        
////        if (bthresholdCtrl) {
////            float _minY = ctrlPnY + speedCSize * 0.75;
////            float _maxY = screenH - speedCSize * 0.75;
////            
////            if ((_changedTouch.y>_minY)&&(_changedTouch.y<_maxY)) {
////                thresholdCPos.y = _changedTouch.y;
////                float _threshold = ofMap(thresholdCPos.y, _minY, _maxY, 255, 0);
////                grayThreshold = _threshold;
////            }
////        }
//        
//        
//        if (bInterval) {
//            float _minY = ctrlPnY + speedCSize * 0.75;
//            float _maxY = screenH - speedCSize * 0.75;
//            if ((_changedTouch.y>_minY)&&(_changedTouch.y<_maxY)) {
//                intervalPos.y = _changedTouch.y;
//                float _interval = ofMap(intervalPos.y, _minY, _maxY, 0, 20);
//                intervalDist = _interval;
//            }
//        }
        
        
        if ( (_changedTouch.x>0)&&(_changedTouch.x<ctrlPnW) && (_changedTouch.y<ctrlPnY)&&(_changedTouch.y>0) ) {
            
            grayThreshold = 120 + (_changedTouch.y - touchDownDefault);
            
        }
        
    }
    
    
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){
    
    ofPoint _changedTouch = ofPoint(touch.x, touch.y - shiftValueIphoneY);

    if ( (_changedTouch.x>0)&&(_changedTouch.x<ctrlPnW) && (_changedTouch.y<ctrlPnY)&&(_changedTouch.y>0) ) {
        if ((whitePixels.size()>2)&&( touch.id==0 )) {
            bCameraCapturePlay = !bCameraCapturePlay;
            //            blur(edge, 3);
            bufferImg = edge;
            
            if ( !bCameraCapturePlay ) {
                index = 0;
                ofRemoveListener(* metroOut, this, &ofApp::triggerReceive);
            } else {
                scoreMake();
                //                noteIndex = index;
                ofAddListener(* metroOut, this, &ofApp::triggerReceive);
                bPlayNote = true;
            }
            
            grayThreshold = 120;
            touchDownDefault = 0;
        }
        
    }

    
    if ( (_changedTouch.x<guideWidthStepSize * 11)&&(_changedTouch.x>guideWidthStepSize * 4) && (_changedTouch.y>ctrlPnY)&&(_changedTouch.y<screenH) && bCameraCapturePlay ) {

        bPlayNote = !bPlayNote;
        
        if ( !bPlayNote ) {
            ofRemoveListener(* metroOut, this, &ofApp::triggerReceive);
        } else {
            ofAddListener(* metroOut, this, &ofApp::triggerReceive);
        }

    }

    float _tolerance = 2;
    
    distS[touch.id] = ofDist( speedCPos.x, speedCPos.y , touchPos[touch.id].x, touchPos[touch.id].y );
    if ((distS[touch.id] < thresholdCSize * _tolerance) && bSpeedCtrl==true) {
        bSpeedCtrl = false;
    }
    
    distI[touch.id] = ofDist( intervalPos.x, intervalPos.y , touchPos[touch.id].x, touchPos[touch.id].y );
    if ((distI[touch.id] < intervalSize * _tolerance) && bInterval == true) {
        bInterval = false;
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
void ofApp::audioReceived(float * output, int bufferSize, int nChannels){
    
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

    ControlParameter carrierPitch7 = synth7.addParameter("carrierPitch7");
    float amountMod7 = 4;
    ControlGenerator rCarrierFreq7 = ControlMidiToFreq().input(carrierPitch7);
    ControlGenerator rModFreq7 = rCarrierFreq7 * 3.109;
    Generator modulationTone7 = SineWave().freq( rModFreq7 ) * rModFreq7 * amountMod7;
    Generator tone7 = SineWave().freq(rCarrierFreq7 + modulationTone7);
    ControlGenerator envelopTrigger7 = synth7.addParameter("trigger7");
    Generator env7 = ADSR().attack(0.001).decay(0.2).sustain(0).release(0).trigger(envelopTrigger7).legato(false);
    synth7.setOutputGen( tone7 * env7 * 0.75 );

}


//--------------------------------------------------------------
void ofApp::noteTrigger(){
    
    //    vector<int> _bitNumber;
    //    _bitNumber.resize(6);
    //
    //    int _indexLoop = ((noteIndex) % (whitePixels.size()-1))+1;
    //    int _pixelNumbers = whitePixels[ _indexLoop ].pixelN;
    //    _bitNumber = convertDecimalToNBase( _pixelNumbers, baseSelection, (int)_bitNumber.size() );
    //
    //    int _1Note = _bitNumber[0];
    //    int _2Note = _bitNumber[1];
    //    int _3Note = _bitNumber[2];
    //    int _4Note = _bitNumber[3];
    //    int _5Note = _bitNumber[4];
    //    int _6Note = _bitNumber[5];
    //
    //
    //    if (abs(_1Note - oldNoteIndex1)>=intervalDist) {
    //        synth1.setParameter("trigger1", 1);
    //        int _note1 = scaleSetting.noteSelector(baseSelection, 1, _1Note);
    //        synth1.setParameter("carrierPitch1", _note1);
    //        scoreNote1.push_back(_note1);
    //    } else {
    //        scoreNote1.push_back(-1);
    //    }
    //    oldNoteIndex1 = _1Note;
    //
    //    if (abs(_2Note - oldNoteIndex2)>=intervalDist) {
    //        synth2.setParameter("trigger2", 1);
    //        int _note2 = scaleSetting.noteSelector(baseSelection, 2, _2Note);
    //        synth2.setParameter("carrierPitch2", _note2);
    //        scoreNote2.push_back(_note2);
    //    } else {
    //        scoreNote2.push_back(-1);
    //    }
    //    oldNoteIndex2 = _2Note;
    //
    //    if (abs(_3Note - oldNoteIndex3)>=intervalDist) {
    //        synth3.setParameter("trigger3", 1);
    //        int _note3 = scaleSetting.noteSelector(baseSelection, 3, _3Note);
    //        synth3.setParameter("carrierPitch3", _note3);
    //        scoreNote3.push_back(_note3);
    //    } else {
    //        scoreNote3.push_back(-1);
    //    }
    //    oldNoteIndex3 = _3Note;
    //
    //    if (abs(_4Note - oldNoteIndex4)>=intervalDist) {
    //        synth4.setParameter("trigger4", 1);
    //        int _note4 = scaleSetting.noteSelector(baseSelection, 4, _4Note);
    //        synth4.setParameter("carrierPitch4", _note4);
    //        scoreNote4.push_back(_note4);
    //    } else {
    //        scoreNote4.push_back(-1);
    //    }
    //    oldNoteIndex4 = _4Note;
    //
    //    if (abs(_5Note - oldNoteIndex5)>=intervalDist) {
    //        synth5.setParameter("trigger5", 1);
    //        int _note5 = scaleSetting.noteSelector(baseSelection, 5, _5Note);
    //        synth5.setParameter("carrierPitch5", _note5);
    //        scoreNote5.push_back(_note5);
    //    } else {
    //        scoreNote5.push_back(-1);
    //    }
    //    oldNoteIndex5 = _5Note;
    //
    //    if (abs(_6Note - oldNoteIndex6)>=intervalDist) {
    //        synth6.setParameter("trigger6", 1);
    //        int _note6 = scaleSetting.noteSelector(baseSelection, 6, _6Note);
    //        synth6.setParameter("carrierPitch6", _note6);
    //        scoreNote6.push_back(_note6);
    //    } else {
    //        scoreNote6.push_back(-1);
    //    }
    //    oldNoteIndex6 = _6Note;
    
    
}


//--------------------------------------------------------------
void ofApp::scoreMake(){
    
    scoreNote1.clear();
    scoreNote2.clear();
    scoreNote3.clear();
    scoreNote4.clear();
    scoreNote5.clear();
    scoreNote6.clear();
    scoreNote7.clear();
    
    int _intervalDist = 1;
    
    for (int i=0; i<whitePixels.size(); i++) {
        
        vector<int> _bitNumber;
        _bitNumber.resize(7);
        
        int _indexLoop = ((i) % (whitePixels.size()-1))+1;
        int _pixelNumbers = whitePixels[ _indexLoop ].pixelN;
        _bitNumber = convertDecimalToNBase( _pixelNumbers, baseSelection, (int)_bitNumber.size() );
                
        int _1Note = _bitNumber[0];
        int _2Note = _bitNumber[1];
        int _3Note = _bitNumber[2];
        int _4Note = _bitNumber[3];
        int _5Note = _bitNumber[4];
        int _6Note = _bitNumber[5];
        int _7Note = _bitNumber[6];
        
        if (abs(_1Note - oldNoteIndex1) >= _intervalDist) {
            scoreNote1.push_back(_1Note);
        } else {
            scoreNote1.push_back(-1);
        }
        oldNoteIndex1 = _1Note;
        
        if (abs(_2Note - oldNoteIndex2) >= _intervalDist) {
            scoreNote2.push_back(_2Note);
        } else {
            scoreNote2.push_back(-1);
        }
        oldNoteIndex2 = _2Note;
        
        if (abs(_3Note - oldNoteIndex3) >= _intervalDist) {
            scoreNote3.push_back(_3Note);
        } else {
            scoreNote3.push_back(-1);
        }
        oldNoteIndex3 = _3Note;
        
        if (abs(_4Note - oldNoteIndex4) >= _intervalDist) {
            scoreNote4.push_back(_4Note);
        } else {
            scoreNote4.push_back(-1);
        }
        oldNoteIndex4 = _4Note;
        
        if (abs(_5Note - oldNoteIndex5) >= _intervalDist) {
            scoreNote5.push_back(_5Note);
        } else {
            scoreNote5.push_back(-1);
        }
        oldNoteIndex5 = _5Note;
        
        if (abs(_6Note - oldNoteIndex6) >= _intervalDist) {
            scoreNote6.push_back(_6Note);
        } else {
            scoreNote6.push_back(-1);
        }
        oldNoteIndex6 = _6Note;

        if (abs(_7Note - oldNoteIndex7) >= _intervalDist) {
            scoreNote7.push_back(_7Note);
        } else {
            scoreNote7.push_back(-1);
        }
        oldNoteIndex7 = _7Note;

    }
    
}


//--------------------------------------------------------------
void ofApp::noteTrig(){
    
    
    //    int _indexLoop = ((noteIndex) % (whitePixels.size()-1))+1;
    //    int _indexLoopOld = ((noteIndex + 1) % (whitePixels.size()-1))+1;
    //
    //    int _note1 = scoreNote1[_indexLoop];
    //    int _note1Old = scoreNote1[_indexLoopOld];
    //
    //    if ( abs(_note1Old - _note1) >= intervalDist ) {
    //        if (_note1>0) {
    //            synth1.setParameter("trigger1", 1);
    //            synth1.setParameter("carrierPitch1", _note1);
    //        }
    //    }
    //
    //
    //
    //    if ( abs(_note1Old - _note1) >= intervalDist ) {
    //        if (_note1>0) {
    //            synth1.setParameter("trigger1", 1);
    //            synth1.setParameter("carrierPitch1", _note1);
    //        }
    //    }
    
    
    //    synth2.setParameter("trigger2", 1);
    //    int _note2 = scoreNote2[_indexLoop];
    //    synth2.setParameter("carrierPitch2", _note2);
    //
    //    synth3.setParameter("trigger3", 1);
    //    int _note3 = scoreNote3[_indexLoop];
    //    synth3.setParameter("carrierPitch3", _note3);
    //
    //    synth4.setParameter("trigger4", 1);
    //    int _note4 = scoreNote4[_indexLoop];
    //    synth4.setParameter("carrierPitch4", _note4);
    //
    //    synth5.setParameter("trigger5", 1);
    //    int _note5 = scoreNote5[_indexLoop];
    //    synth5.setParameter("carrierPitch5", _note5);
    //
    //    synth6.setParameter("trigger6", 1);
    //    int _note6 = scoreNote6[_indexLoop];
    //    synth6.setParameter("carrierPitch6", _note6);
    
    
}


//--------------------------------------------------------------
void ofApp::trigScoreNote( vector<int> _vNote, ofxTonicSynth _synthIn, int _scoreCh ){
    
    int _indexLoop = ((noteIndex) % (whitePixels.size()-1))+1;
    int _indexLoopOld = ((noteIndex + 1) % (whitePixels.size()-1))+1;
    
    
    vector<int> _scoreNote = _vNote;
    ofxTonicSynth _synth = _synthIn;
    
    int _note = _scoreNote[_indexLoop];
    int _noteOld = _scoreNote[_indexLoopOld];
    
    int _noteScaled = scaleSetting.noteSelector(baseSelection, _scoreCh, _note);
    int _noteOldScaled = scaleSetting.noteSelector(baseSelection, _scoreCh, _noteOld);
    
    
    string tName = "trigger" + ofToString(_scoreCh);
    string tPitch = "carrierPitch" + ofToString(_scoreCh);
    
    
    
    if ( abs(_noteOldScaled - _noteScaled) >= intervalDist ) {
        if (_note>0) {
            
            int _noteScaled = scaleSetting.noteSelector(baseSelection, _scoreCh, _note);
            
            _synth.setParameter( tName, 1);
            _synth.setParameter( tPitch, _noteScaled);
            
        }
    }
    
    
}



//--------------------------------------------------------------
vector<int> ofApp::convertDecimalToNBase(int n, int base, int size) {
    
    int i=0, div, res;
    
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

