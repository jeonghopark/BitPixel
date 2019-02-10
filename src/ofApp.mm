// http://www.translatorscafe.com/cafe/units-converter/numbers/calculator/octal-to-decimal/


#include "ofApp.h"
#include <AVFoundation/AVFoundation.h>

using namespace ofxCv;
using namespace cv;

//--------------------------------------------------------------
void ofApp::setup() {
    
    //    [[AVAudioSession sharedInstance] setDelegate:self];
    //    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    //    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    
    colorVar[0] = ofColor(192, 25, 30);
    colorVar[1] = ofColor(79, 185, 73);
    colorVar[2] = ofColor(255, 172, 0);
    colorVar[3] = ofColor(68, 128, 173);
    colorVar[4] = ofColor(58, 193, 197);
    colorVar[5] = ofColor(249, 154, 249);
    colorVar[6] = ofColor(142, 82, 137);
    
    backgroundColor = ofColor(13, 13, 15);
    
    contourLineColor = ofColor(230, 221, 193);
    eventColor = ofColor(230, 221, 193);
    uiLineColor = ofColor(230, 221, 193);
    
    
    //    colorVar[0] = ofColor(255, 199, 43);
    //    colorVar[1] = ofColor(255, 209, 53);
    //    colorVar[2] = ofColor(255, 219, 63);
    //    colorVar[3] = ofColor(255, 229, 73);
    //    colorVar[4] = ofColor(255, 239, 83);
    //    colorVar[5] = ofColor(255, 249, 93);
    //    colorVar[6] = ofColor(142, 82, 137);
    
    //    contourLineColor = ofColor(250, 231, 193);
    //    eventColor = ofColor(129, 0, 21);
    //    backgroundColor = ofColor(13, 13, 15);
    //    uiLineColor = ofColor(131, 100, 75);
    
    
    
    baseSelection = 7;
    
    if (WHITE_VIEW) {
        ofBackground(255);
    } else {
        ofBackground(backgroundColor);
    }
    
    ofSetFrameRate(60);
    ofEnableAlphaBlending();
    
    //    backgroundControPanel.load("controlBackground.png");
    
    
    if (TARGET_IPHONE_SIMULATOR) {
        //        cam.setDeviceID(0);
        //        cam.setup(480, 360);
        //        cam.setDesiredFrameRate(15);
        camSize = 360; // 360
    } else {
        cam.setDeviceID(0);
        cam.setup(480, 360);
        cam.setDesiredFrameRate(15);
        camSize = cam.getWidth(); // 360
    }
    
    
    bufferImg.allocate(camSize, camSize, OF_IMAGE_GRAYSCALE);
    gray.allocate(camSize, camSize, OF_IMAGE_GRAYSCALE);
    edge.allocate(camSize, camSize, OF_IMAGE_GRAYSCALE);
    squareCam.setImageType(OF_IMAGE_COLOR_ALPHA);
    squareCam.allocate(camSize, camSize, OF_IMAGE_COLOR_ALPHA);
    
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        bIPhone = false;
        screenW = ofGetWidth();
        screenH = ofGetWidth() * 4.0 / 3.0;
        debugCameraImage.load("debug_layout_cat_iPad.jpg");
        setIPad();
    } else {
        bIPhone = true;
        screenW = ofGetWidth();
        screenH = ofGetHeight();
        iPhonePreviewSize = screenW;
        debugCameraImage.load("debug_layout_cat.jpg");
        setIPhone();
    }
    
    
    
    synthSetting();
    maxSpeed = 200;
    minSpeed = 30;
    bpm = synthMain.addParameter("tempo", 100).min(minSpeed).max(maxSpeed);
    metro = ControlMetro().bpm(4 * bpm);
    metroOut = synthMain.createOFEvent(metro);
    
    Reverb reverb = Reverb()
    .preDelayTime(0.001)
    .inputLPFCutoff(18000)
    .inputHPFCutoff(20)
    .decayTime(1.0)
    .decayLPFCutoff(16000)
    .decayHPFCutoff(20)
    .stereoWidth(1.0)
    .density(0.75)
    .roomShape(0.5)
    .roomSize(0.25)
    .dryLevel(ControlDbToLinear().input(0.0))
    .wetLevel(ControlDbToLinear().input(-16.0));
    
    BasicDelay delay = BasicDelay(0.5f, 1.0f)
    .delayTime(0.1f)
    .feedback(0.1)
    .dryLevel(1.0f - 0.1)
    .wetLevel(0.1);
    
    synthMain.setOutputGen((synth[0] + synth[1] + synth[2] + synth[3] + synth[4] + synth[5] + synth[6]) * 1.0 / NUM_SYNTH_LINE * 3 >> delay >> reverb);
    
    
    
    cannyThreshold1 = 120;
    cannyThreshold2 = 120;
    grayThreshold = 120;
    
    // note music play
    index = 0;
    noteIndex = 0;
    
    for (int i = 0; i < NUM_SYNTH_LINE; i++) {
        oldNoteIndex[i] = 0;
    }
    
    bPlayNote = false;
    bCameraCapturePlay = false;
    
    scaleSetting.setup();
    
    lineScoreNumber = 23;
    
    touchPos.assign(2, ofVec2f());
    
    ofSoundStreamSetup(2, 0, this, 44100, 256, 4);
    
    
    activeFactor = 0;
    activeSpeed = 0.1;
    
    
    
    menuImgSetup();
    
    
}




//--------------------------------------------------------------
void ofApp::menuImgSetup() {
    
    capture.load("capture.png");
    float _scaleCapture = 0.05;
    composingMode.setFromCenter(ofGetWidth() * 0.5, ofGetHeight() * 0.9, capture.getWidth() * _scaleCapture, capture.getHeight() * _scaleCapture);
    
    importImg.load("photoLibrary.png");
    float _scaleImport = 0.05;
    libaryImport.setFromCenter(ofGetWidth() * 0.2, ofGetHeight() * 0.9, importImg.getWidth() * _scaleImport, importImg.getHeight() * _scaleImport);
    
    changeCamera.load("cameraChange.png");
    float _scaleChange = 0.05;
    cameraChange.setFromCenter(ofGetWidth() * 0.8, ofGetHeight() * 0.9, changeCamera.getWidth() * _scaleChange, changeCamera.getHeight() * _scaleChange);
    
    returnCaptureMode.load("returnCameraMode.png");
    float _scaleReturn = 0.05;
    returnCapture.setFromCenter(ofGetWidth() * 0.5, ofGetHeight() * 0.9, returnCaptureMode.getWidth() * _scaleReturn, returnCaptureMode.getHeight() * _scaleReturn);
    
}





//--------------------------------------------------------------
void ofApp::setIPad() {
    
    float _sizeF = screenW;
    ctrlPnX = 0;
    ctrlPnY = screenW;
    ctrlPnW = screenW;
    ctrlPnH = screenH - ctrlPnY;
    
    shiftValueIphoneY = ofGetHeight() * 0.5 - (ctrlPnY + ctrlPnH) * 0.5;
    
    pixelStepS = 4;
    changedCamSize = camSize / pixelStepS;  // 90
    //    cameraScreenRatio = screenW / cam.getWidth();
    thresholdValue = 80;
    
    
    cameraScreenRatio = screenW / camSize;  // 4.2666666
    
    float _widthDefault = 1536.0;
    pixelCircleSize = 10 / _widthDefault * _sizeF;
    ctrlRectS = 80 / _widthDefault * _sizeF;
    guideWidthStep = 96 / _widthDefault * _sizeF;
    guideHeightStep = 64 / _widthDefault * _sizeF;
    lineScoreStepX = 35.5 / _widthDefault * _sizeF;
    lineScoreStepY = 5 / _widthDefault * _sizeF;
    stepBasePos = 105 / _widthDefault * _sizeF;
    pixeShapeSize = 1 / _widthDefault * _sizeF;
    
    controlObjectLineWidth = 2;
    
    speedCSize = ctrlRectS;
    speedCPos = ofPoint(15 * guideWidthStep, ctrlPnY + ctrlPnH * 0.5);
    bSpeedCtrl = false;
    
    thresholdCSize = ctrlRectS * 0.5;
    thresholdCPos = ofPoint(1 * guideWidthStep, ctrlPnY + ctrlPnH * 0.5);
    bthresholdCtrl = false;
    
    intervalSize = ctrlRectS * 0.5;
    intervalPos = ofPoint(1 * guideWidthStep, ctrlPnY + ctrlPnH * 0.5);
    bthresholdCtrl = false;
    intervalDist = 1;
    
    
    float _posIndexRight = 13.5;
    float _posIndexLeft = 2.5;
    base4Pos = ofPoint(guideWidthStep * _posIndexLeft, ctrlPnY + stepBasePos * 1);
    base5Pos = ofPoint(guideWidthStep * _posIndexLeft, ctrlPnY + stepBasePos * 2.5);
    base6Pos = ofPoint(guideWidthStep * _posIndexLeft, ctrlPnY + stepBasePos * 4);
    base7Pos = ofPoint(guideWidthStep * _posIndexRight, ctrlPnY + stepBasePos * 1);
    base8Pos = ofPoint(guideWidthStep * _posIndexRight, ctrlPnY + stepBasePos * 2.5);
    base9Pos = ofPoint(guideWidthStep * _posIndexRight, ctrlPnY + stepBasePos * 4);
    baseSize = ctrlRectS * 0.55;
    
}



//--------------------------------------------------------------
void ofApp::setIPhone() {
    
    
    float _sizeF = screenW;
    ctrlPnX = 0;
    ctrlPnY = screenW;
    ctrlPnW = screenW;
    ctrlPnH = screenH - ctrlPnY;
    ctrlPnH = screenW * 4.0 / 5.0;
    
    shiftValueIphoneY = ofGetHeight() * 0.5 - (screenH) * 0.5;
    
    screenPosLeftY = ofGetHeight() * 0.5 - iPhonePreviewSize * 0.5; // 248
    screenPosRightY = ofGetHeight() * 0.5 + iPhonePreviewSize * 0.5; // 888
    
    
    lineScoreRightX = ofGetWidth() - iPhonePreviewSize;
    
    pixelStepS = 4;
    changedCamSize = camSize / pixelStepS;  // 90
    //    cameraScreenRatio = screenW / cam.getWidth();
    thresholdValue = 80;
    
    
    cameraScreenRatio = iPhonePreviewSize / camSize; // 1.77777777
    
    float _widthDefault = screenW * 2.4;
    pixelCircleSize = 10 / _widthDefault * _sizeF;
    ctrlRectS = (screenW * 0.125) / _widthDefault * _sizeF;
    guideWidthStep = 96 / _widthDefault * _sizeF;
    guideHeightStep = 64 / _widthDefault * _sizeF;
    lineScoreStepX = screenW / 21.0;  // 30.3764
    lineScoreStepY = (screenW * 0.006) / _widthDefault * _sizeF;  // 1.6
    //    stepBasePos = 105 / _widthDefault * _sizeF;
    pixeShapeSize = 1 / _widthDefault * _sizeF;
    
    controlObjectLineWidth = 2;
    
    
    
    float _thredSlideControlPos = ofGetWidth() * 1.0 / 6.0 * 1;
    float __speedSlideControlPos = ofGetWidth() * 1.0 / 6.0 * 5;
    float _controlAreaSize = ofGetHeight() - screenW;

    speedCSize = ctrlRectS * 1.4;
    //    speedCPos = ofPoint(15 * guideWidthStep, ctrlPnY + ctrlPnH * 0.5);
    //    speedCPos = ofPoint(screenW * 0.5, screenH * 9.2 / 10.0);
    //    speedCPos = ofPoint(screenW * 0.5, screenPosRightY + __speedSlideControlPos);
    speedCPos = ofPoint(__speedSlideControlPos, screenW + _controlAreaSize * 0.5);
    speedLineLength = ofPoint(speedCPos.y - 100, speedCPos.y + 100);
    bSpeedCtrl = false;
    
    //    thresholdCSize = ctrlRectS * 0.9;
    //    thresholdCPos = ofPoint(1 * guideWidthStep, ctrlPnY + ctrlPnH * 0.5);
    //    thresholdCPos = ofPoint(screenW * 0.5, screenH * 9.0/10.0);
    bthresholdCtrl = false;
    
    intervalSize = ctrlRectS * 0.9;
    //    intervalPos = ofPoint(1 * guideWidthStep, ctrlPnY + ctrlPnH * 0.5);
    //    intervalPos = ofPoint(screenW * 0.5, screenH * 0.8/10.0);
    //    intervalPos = ofPoint(screenW * 0.5, _thredSlideControlPos);
    intervalPos = ofPoint(_thredSlideControlPos, screenW + _controlAreaSize * 0.5);
    ctrlLineLength = ofPoint(intervalPos.y - 100, intervalPos.y + 100);
    bthresholdCtrl = false;
    intervalDist = 1;
    
    
    
    
    //    float _posIndexLeft = screenH * 1.84/10.0;
    //    float _posIndexRight = screenH - _posIndexLeft;
    
    float _posIndexLeft = ofGetWidth() * 1.0 / 6.0 * 2;
    float _posIndexRight = ofGetWidth() * 1.0 / 6.0 * 4;
    
    base4Pos = ofPoint(_posIndexLeft, ofGetHeight() * 11.0 / 12.0);
    base5Pos = ofPoint(_posIndexLeft, ofGetHeight() * 10.0 / 12.0);
    base6Pos = ofPoint(_posIndexLeft, ofGetHeight() * 9.0 / 12.0);
    base7Pos = ofPoint(_posIndexRight, ofGetHeight() * 11.0 / 12.0);
    base8Pos = ofPoint(_posIndexRight, ofGetHeight() * 10.0 / 12.0);
    base9Pos = ofPoint(_posIndexRight, ofGetHeight() * 9.0 / 12.0);
    baseSize = ctrlRectS * 0.85;
    
    
}




//--------------------------------------------------------------
void ofApp::update() {
    
    if (TARGET_IPHONE_SIMULATOR) {
        
        if (bIPhone) {
            squareCam.setFromPixels(debugCameraImage.getPixels().getData(), camSize, camSize, OF_IMAGE_COLOR_ALPHA);
        } else {
            squareCam.setFromPixels(debugCameraImage.getPixels().getData(), camSize, camSize, OF_IMAGE_COLOR);
        }
        
        if (squareCam.isAllocated()) {
            calculatePixels(squareCam);
        }
        
    } else {
        
        cam.update();
        
        if (cam.isFrameNew()) {
            squareCam.setFromPixels(cam.getPixels().getData(), camSize, camSize, OF_IMAGE_COLOR);
            calculatePixels(squareCam);
        }
        
    }
    
    if (bCameraCapturePlay) {
        activeSpeed = 0.6;
        activeFactor += activeSpeed;
        if (activeFactor > 10) {
            activeFactor = 0;
        }
    } else {
        activeSpeed = 0.0;
    }
}



//--------------------------------------------------------------
void ofApp::calculatePixels(ofImage _img) {
    
    convertColor(_img, gray, CV_RGB2GRAY);
    threshold(gray, gray, grayThreshold);
    //                erode(gray);
    
    Canny(gray, edge, cannyThreshold1, cannyThreshold2, 3);
    thin(edge);
    
    if (WHITE_VIEW) {
        invert(edge);
    }
    
    edge.update();
    
    
    if (bCameraCapturePlay) {
        noteIndex = index;
    } else {
        
        noteIndex = 0;
        ofImage _tImage;
        
        pixelBright.clear();
        whitePixels.clear();
        blackPixels.clear();
        
        unsigned char * _src;
        if (!bIPhone) {
            _src = edge.getPixels().getData();
        } else {
            edge.rotate90(-1);
            _src = edge.getPixels().getData();
        }
        
        for (int j = 0; j < camSize; j += pixelStepS) {
            for (int i = 0; i < camSize; i += pixelStepS) {
                int _index = i + j * camSize;
                float _brightness = _src[_index];
                pixelBright.push_back(_brightness);
            }
        }
        
        int _wCounter = 0;
        int _bCounter = 0;
        
        for (int i = 0; i < pixelBright.size(); i++) {
            
            int _whitePixel;
            if (WHITE_VIEW) {
                _whitePixel = 255;
            } else {
                _whitePixel = 0;
            }
            
            if (pixelBright[i] == _whitePixel) {
                
                if (_bCounter == 0) {
                    blackWhitePixels _bWP;
                    _bWP.indexPos = i;
                    _bWP.pixelN = _wCounter;
                    blackPixels.push_back(_bWP);
                }
                _bCounter++;
                _wCounter = 0;
                
            } else {
                
                if (_wCounter == 0) {
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




//--------------------------------------------------------------
void ofApp::triggerReceive(float & metro) {
    
    index++;
    noteIndex = index;
    
    for (int i = 0; i < NUM_SYNTH_LINE; i++) {
        trigScoreNote(scoreNote[i], synth[i], i + 1);
    }
    
}



//--------------------------------------------------------------
void ofApp::draw() {
    
    if (!bIPhone) {
        drawIPad();
    } else {
        drawIPhone();
    }
    
}


//--------------------------------------------------------------
void ofApp::drawIPad() {
    
    ofPushMatrix();
    
    ofPushStyle();
    if (!bCameraCapturePlay) {
        
        if (WHITE_VIEW) {
            ofSetColor(255, 255);
        } else {
            ofSetColor(255, 150);
        }
        
        edge.draw(0, 0, screenW, screenW);
    }
    ofPopStyle();
    
    ofPushStyle();
    if (bCameraCapturePlay) {
        //        ofSetColor(255, 255);
        //        ofDrawRectangle(0, 0, screenW, screenW);
        
        if (WHITE_VIEW) {
            ofSetColor(255, 80);
        } else {
            ofSetColor(255, 120);
        }
        bufferImg.draw(0, 0, screenW, screenW);
    }
    ofPopStyle();
    
    ofPopMatrix();
    
    //    ofPushStyle();
    //    ofSetColor(255, 230);
    //    ofDrawRectangle(0, 0, screenW, screenH);
    //    ofPopStyle();
    
    
    ofPushStyle();
    if (bCameraCapturePlay) {
        if (WHITE_VIEW) {
            ofSetColor(0, 60);
        } else {
            ofSetColor(255, 60);
        }
    } else {
        if (WHITE_VIEW) {
            ofSetColor(0, 220);
        } else {
            ofSetColor(255, 160);
        }
    }
    drawTrianglePixel();
    ofPopStyle();
    
    
    if (bCameraCapturePlay) {
        
        drawPixelNumbersCircleNotes();
        //        drawPlayingShapeNotes();
        //        drawPixelAllNoteShape();
        
        for (int i = 0; i < NUM_SYNTH_LINE; i++) {
            drawPixelAllNoteShapesIPad(scoreNote[i], i + 1);
            drawPlayingShapeNote(scoreNote[i], i + 1);
        }
        
        //        drawPixelShapeColorSize();
        
    }
    
    drawControlElementIPad();
    
    if (bCameraCapturePlay) {
        drawLineScoreIPad();
    }
    
    drawBaseInterface(bCameraCapturePlay);
    
}




//--------------------------------------------------------------
void ofApp::mainCameraCaptureViewiPhone() {
    
    ofPushMatrix();
    
    ofPushStyle();
    if (!bCameraCapturePlay) {
        if (WHITE_VIEW) {
            ofSetColor(255, 255);
        } else {
            ofSetColor(contourLineColor, 120);
        }
        
        ofPushMatrix();
        edge.draw(0, 0, iPhonePreviewSize + 1, iPhonePreviewSize + 1);
        ofPopMatrix();
    }
    ofPopStyle();
    
    ofPushStyle();
    if (bCameraCapturePlay) {
        //        ofSetColor(255, 255);
        //        ofDrawRectangle(0, 0, iPhonePreviewSize, iPhonePreviewSize);
        
        if (WHITE_VIEW) {
            ofSetColor(255, 120);
        } else {
            ofSetColor(contourLineColor, 180);
        }
        bufferImg.draw(0, 0, iPhonePreviewSize + 1, iPhonePreviewSize + 1);
    }
    ofPopStyle();
    
    ofPopMatrix();
    
    
    //    ofPushStyle();
    //    ofSetColor(255,230);
    //    ofDrawRectangle(0, 0, screenW, screenH);
    //    ofPopStyle();
    
    
    ofPushMatrix();
    
    ofPushStyle();
    
    if (bCameraCapturePlay) {
        if (WHITE_VIEW) {
            ofSetColor(0, 120);
        } else {
            ofSetColor(contourLineColor, 120);
        }
    } else {
        if (WHITE_VIEW) {
            ofSetColor(0, 220);
        } else {
            ofSetColor(contourLineColor, 255);
        }
    }
    
    drawIPhoneTrianglePixel();
    
    ofPopStyle();
    
    if (bCameraCapturePlay) {
        
        drawPixelNumbersCircleNotes();
        
        //        drawPlayingShapeNotes();
        //        drawPixelAllNoteShape();
        
        for (int i = 0; i < NUM_SYNTH_LINE; i++) {
            drawPixelAllNoteShapesIPhone(scoreNote[i], i + 1);
            drawPlayingShapeNote(scoreNote[i], i + 1);
        }
        
        //        drawPixelShapeColorSize();
        
    }
    
    ofPopMatrix();
    
}



//--------------------------------------------------------------
void ofApp::drawIPhone() {
    
    //    ofPushMatrix();
    //    ofTranslate(ofGetWidth() * 0.5 * 2, screenPosLeftY);
    //    ofTranslate(screenW, screenPosLeftY);
    //    ofRotateZDeg(90);
    
    
    //
    //
    //    ofPushMatrix();
    //    ofPushStyle();
    //    if (WHITE_VIEW) {
    //        ofSetColor(255, 255);
    //    } else {
    //        ofSetColor(backgroundColor);
    //    }
    //    ofDrawRectangle(0, screenPosLeftY, screenW - iPhonePreviewSize, iPhonePreviewSize);
    //    ofPopStyle();
    //    ofPopMatrix();

    
    //FIXME: Translate (???)
    ofPushMatrix();
    ofTranslate(0, -40);

    ofPushMatrix();
    ofPushStyle();
    ofSetColor(uiLineColor);
    ofTranslate(0, screenW + 30 * 7);
    ofDrawLine(0, 0, ofGetWidth(), 0);
    ofPopStyle();
    ofPopMatrix();
    
    drawLineScoreIPhone(bCameraCapturePlay);
    ofPopMatrix();
    
    mainCameraCaptureViewiPhone();

    
//    drawControlElementIPhone(bCameraCapturePlay);
//    drawBaseInterface(bCameraCapturePlay);

    drawControlElementIPhone(true);
    drawBaseInterface(true);

    menuImgDraw(bCameraCapturePlay);
    
    
    
}



//--------------------------------------------------------------
void ofApp::menuImgDraw(bool playOn) {
    
    ofPushStyle();
    
    if (playOn) {
        returnCaptureMode.draw(returnCapture);
    } else {
        capture.draw(composingMode);
        importImg.draw(libaryImport);
        changeCamera.draw(cameraChange);
    }
    
    ofPopStyle();
    
}


//--------------------------------------------------------------
void ofApp::drawControlElementIPad() {
    
    ofPushStyle();
    if (WHITE_VIEW) {
        ofSetColor(255);
    } else {
        ofSetColor(0);
    }
    ofDrawRectangle(0, ctrlPnY, ctrlPnW, ctrlPnH);
    if (WHITE_VIEW) {
        ofSetColor(0, 10);
    } else {
        ofSetColor(255, 20);
    }
    //    backgroundControPanel.draw(0, ctrlPnY, ctrlPnW, 140);
    ofPopStyle();
    
    
    ofPushMatrix();
    ofPushStyle();
    
    if (WHITE_VIEW) {
        ofSetColor(0, 80);
    } else {
        ofSetColor(255, 80);
    }
    
    float _speedX = guideWidthStep;
    float _yD = 20;
    ofDrawLine(_speedX, ctrlPnY + _yD, _speedX, screenH - _yD);
    
    float _thresholdX = guideWidthStep * 15;
    ofDrawLine(_thresholdX, ctrlPnY + _yD, _thresholdX, screenH - _yD);
    
    //    float _intervalX = guideWidthStep * 2.5;
    //    ofDrawLine(_intervalX, ctrlPnY + _yD, _intervalX, screenH - _yD);
    
    ofPopStyle();
    ofPopMatrix();
    
    
    drawElemSpeedShape();
    drawElemIntervalShape();
    
    
    ofPushMatrix();
    ofPushStyle();
    
    if (WHITE_VIEW) {
        ofSetColor(0, 80);
    } else {
        ofSetColor(255, 80);
    }
    
    int _offsetXPos = lineScoreStepX * (lineScoreNumber - 1);
    
    float _xL1 = ctrlPnW * 0.5 - _offsetXPos * 0.5;
    ofDrawLine(_xL1, ctrlPnY + _yD, _xL1, screenH - _yD);
    
    float _xL2 = ctrlPnW * 0.5 + _offsetXPos * 0.5;
    ofDrawLine(_xL2, ctrlPnY + _yD, _xL2, screenH - _yD);
    
    
    
    float _xM = ctrlPnW * 0.5;
    if (WHITE_VIEW) {
        ofSetColor(0, 40);
    } else {
        ofSetColor(255, 40);
    }
    ofDrawLine(_xM, ctrlPnY + _yD, _xM, screenH - _yD);
    
    ofPopStyle();
    ofPopMatrix();
    
}




//--------------------------------------------------------------
void ofApp::drawControlElementIPhone(bool playOn) {
    
    if (playOn) {
        
        //    ofPushStyle();
        
        //    if (WHITE_VIEW) {
        //        ofSetColor(255);
        //    } else {
        //        ofSetColor(backgroundColor);
        //    }
        //
        //    ofDrawRectangle(0, 0, screenW, screenPosLeftY);
        //    ofDrawRectangle(0, screenPosRightY, screenW, (screenH - screenPosRightY));
        
        //    if (WHITE_VIEW) {
        //        ofSetColor(0, 10);
        //    } else {
        //        ofSetColor(backgroundColor);
        //    }
        //
        //    backgroundControPanel.draw(0, screenPosLeftY, screenW, -screenPosLeftY);
        //    backgroundControPanel.draw(0, screenPosRightY, screenW, (screenH - screenPosRightY));
        //
        //    ofPopStyle();
        
        
        
        ofPushMatrix();
        ofPushStyle();
        
        if (WHITE_VIEW) {
            ofSetColor(0, 180);
        } else {
            ofSetColor(uiLineColor);
        }
        
        //    ofDrawLine(intervalPos.x, _intervalY, intervalPos.x, _intervalY);
        //    ofDrawLine(intervalPos.x, 0, intervalPos.x, ofGetHeight());
        
        //    float _intervalY = intervalPos.y;
        ofDrawLine(intervalPos.x, ctrlLineLength.x, intervalPos.x, ctrlLineLength.y);
        
        //    float _speedY = speedCPos.y;
        ofDrawLine(speedCPos.x, speedLineLength.x, speedCPos.x, speedLineLength.y);
        
        ofPopStyle();
        ofPopMatrix();
        
        
        
        drawElemSpeedShape();
        drawElemIntervalShape();
        
        
        
        //    ofPushMatrix();
        //    ofPushStyle();
        //
        //    if (WHITE_VIEW) {
        //        ofSetColor(0, 40);
        //    } else {
        //        ofSetColor(uiLineColor);
        //    }
        //
        //    ofPoint _line1S = ofPoint(0, screenPosLeftY);
        //    ofPoint _line1E = ofPoint(screenW, screenPosLeftY);
        //    ofDrawLine(_line1S, _line1E);
        //
        //    ofPoint _line2S = ofPoint(0, screenPosRightY);
        //    ofPoint _line2E = ofPoint(screenW, screenPosRightY);
        //    ofDrawLine(_line2S, _line2E);
        //
        //    ofPoint _lineUpS = ofPoint(screenW - iPhonePreviewSize, screenPosLeftY);
        //    ofPoint _lineUpE = ofPoint(screenW - iPhonePreviewSize, screenPosRightY);
        //    ofDrawLine(_lineUpS, _lineUpE);
        //
        //    ofPopStyle();
        
        
        //    ofPushStyle();
        //    if (WHITE_VIEW) {
        //        ofSetColor(0, 40);
        //    } else {
        //        ofSetColor(uiLineColor);
        //    }
        //
        //    ofPoint _lineMS = ofPoint(10, (screenPosRightY + screenPosLeftY) * 0.5);
        //    ofPoint _lineME = ofPoint(screenW - iPhonePreviewSize - 10, (screenPosRightY + screenPosLeftY) * 0.5);
        //    ofDrawLine(_lineMS, _lineME);
        //
        //    ofPopStyle();
        
        //    ofPopMatrix();
        
    }
    
}



//--------------------------------------------------------------
void ofApp::drawElemSpeedShape() {
    
    ofPushStyle();
    
    if (WHITE_VIEW) {
        ofSetColor(0, 180);
    } else {
        ofSetColor(uiLineColor, 40);
    }
    ofSetCircleResolution(24);
    float _sX = speedCPos.x;
    float _sY = speedCPos.y;
    //    ofNoFill();
    ofSetLineWidth(controlObjectLineWidth);
    ofDrawCircle(_sX, _sY, speedCSize * 0.5);
    
    ofNoFill();
    ofSetColor(uiLineColor);
    ofDrawCircle(_sX, _sY, speedCSize * 0.5);
    ofPopStyle();
    
}



//--------------------------------------------------------------
void ofApp::drawElemIntervalShape() {
    
    ofPushStyle();
    
    if (WHITE_VIEW) {
        ofSetColor(0, 180);
    } else {
        ofSetColor(uiLineColor, 40);
    }
    
    ofSetLineWidth(controlObjectLineWidth);
    
    float _iX = intervalPos.x;
    float _iY = intervalPos.y;
    //    ofDrawLine(_iX - intervalSize, _iY, _iX, _iY + intervalSize);
    //    ofDrawLine(_iX, _iY - intervalSize, _iX + intervalSize, _iY);
    //    ofDrawLine(_iX + intervalSize, _iY, _iX, _iY + intervalSize);
    //    ofDrawLine(_iX, _iY - intervalSize, _iX - intervalSize, _iY);
    
    ofMesh _mesh;
    _mesh.setMode(OF_PRIMITIVE_TRIANGLE_FAN);
    _mesh.addVertex(ofPoint(_iX, _iY));
    _mesh.addVertex(ofPoint(_iX - intervalSize, _iY));
    _mesh.addVertex(ofPoint(_iX, _iY - intervalSize));
    _mesh.addVertex(ofPoint(_iX + intervalSize, _iY));
    _mesh.addVertex(ofPoint(_iX, _iY + intervalSize));
    _mesh.addVertex(ofPoint(_iX - intervalSize, _iY));
    _mesh.draw();
    
    
    ofSetColor(uiLineColor);
    ofMesh _meshLine;
    _meshLine.setMode(OF_PRIMITIVE_LINE_STRIP);
    _meshLine.addVertex(ofPoint(_iX - intervalSize, _iY));
    _meshLine.addVertex(ofPoint(_iX, _iY - intervalSize));
    _meshLine.addVertex(ofPoint(_iX + intervalSize, _iY));
    _meshLine.addVertex(ofPoint(_iX, _iY + intervalSize));
    _meshLine.addVertex(ofPoint(_iX - intervalSize, _iY));
    _meshLine.draw();
    
    ofPopStyle();
    
}




//--------------------------------------------------------------
void ofApp::drawTrianglePixel() {
    
    int _pixelSize = pixelCircleSize;  // 10
    float _ellipseSizeR = 1.7;
    
    ofPushMatrix();
    ofPushStyle();
    ofEnableAntiAliasing();
    
    if (whitePixels.size() > 1) {
        
        for (int i = 0; i < whitePixels.size(); i++) {
            
            int _noteLoopIndex = ((i) % (whitePixels.size() - 1)) + 1;
            int _pixelNumbers = whitePixels[_noteLoopIndex].pixelN;
            int _idPixels = whitePixels[_noteLoopIndex].indexPos - _pixelNumbers;
            
            float _x = ((_idPixels) % (int)changedCamSize) * pixelStepS * cameraScreenRatio - _pixelSize;
            float _y = (int)((_idPixels) / (int)changedCamSize) * pixelStepS * cameraScreenRatio;
            
            ofPoint _1P = ofPoint(_x, _y - _pixelSize * _ellipseSizeR * 0.75);
            ofPoint _2P = ofPoint(_x - _pixelSize * _ellipseSizeR * 0.55, _y + _pixelSize * _ellipseSizeR * 0.25);
            ofPoint _3P = ofPoint(_x + _pixelSize * _ellipseSizeR * 0.55, _y + _pixelSize * _ellipseSizeR * 0.25);
            
            ofDrawTriangle(_1P, _2P, _3P);
            
        }
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
    
}



//--------------------------------------------------------------
void ofApp::drawIPhoneTrianglePixel() {
    
    int _pixelSize = pixelCircleSize;  // 10
    float _ellipseSizeR = 1.7;
    
    ofPushMatrix();
    ofPushStyle();
    ofEnableAntiAliasing();
    
    if (whitePixels.size() > 1) {
        
        for (int i = 0; i < whitePixels.size(); i++) {
            
            int _noteLoopIndex = ((i) % (whitePixels.size() - 1)) + 1;
            int _pixelNumbers = whitePixels[_noteLoopIndex].pixelN;
            int _idPixels = whitePixels[_noteLoopIndex].indexPos - _pixelNumbers;
            
            float _x = ((_idPixels) % (int)changedCamSize) * pixelStepS * cameraScreenRatio - _pixelSize;
            float _y = (int)((_idPixels) / (int)changedCamSize) * pixelStepS * cameraScreenRatio;
            
            ofPoint _1P = ofPoint(_x, _y - _pixelSize * _ellipseSizeR * 0.75);
            ofPoint _2P = ofPoint(_x - _pixelSize * _ellipseSizeR * 0.55, _y + _pixelSize * _ellipseSizeR * 0.25);
            ofPoint _3P = ofPoint(_x + _pixelSize * _ellipseSizeR * 0.55, _y + _pixelSize * _ellipseSizeR * 0.25);
            
            ofDrawTriangle(_1P, _2P, _3P);
            
        }
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
}




//--------------------------------------------------------------
void ofApp::drawPixelAllNoteShapesIPad(vector<int> _vNote, int _scoreCh) {
    
    ofPushMatrix();
    ofPushStyle();
    ofEnableAntiAliasing();
    
    if (WHITE_VIEW) {
        ofSetColor(0, 80);
    } else {
        ofSetColor(255, 80);
    }
    
    for (int i = 0; i < whitePixels.size(); i++) {
        
        int _noteLoopIndex = ((i) % (whitePixels.size() - 1)) + 1;
        int _pixelNumbers = whitePixels[_noteLoopIndex].pixelN;
        int _idPixels = whitePixels[_noteLoopIndex].indexPos - _pixelNumbers;
        
        float _x = ((_idPixels) % (int)changedCamSize) * pixelStepS * cameraScreenRatio;
        float _y = (int)((_idPixels) / (int)changedCamSize) * pixelStepS * cameraScreenRatio;
        ofPoint _p = ofPoint(_x, _y);
        
        
        int _idLoopLine = ((i) % (whitePixels.size() - 1)) + 1;
        int _idLoopLineOld = ((i + 1) % (whitePixels.size() - 1)) + 1;
        
        int _note = _vNote[_idLoopLine];
        int _noteOld = _vNote[_idLoopLineOld];
        
        int _scaledNote = scaleSetting.noteSelector(baseSelection, _scoreCh, _note);
        int _scaledNoteOld = scaleSetting.noteSelector(baseSelection, _scoreCh, _noteOld);
        
        
        if (abs(_scaledNoteOld - _scaledNote) >= intervalDist) {
            if (_note > 0) {
                float _size = _scaledNote * pixeShapeSize;
                drawShape(_p, baseSelection, _size);
            }
        }
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
    
}


//--------------------------------------------------------------
void ofApp::drawPixelAllNoteShapesIPhone(vector<int> _vNote, int _scoreCh) {
    
    ofPushMatrix();
    ofPushStyle();
    ofEnableAntiAliasing();
    
    if (WHITE_VIEW) {
        ofSetColor(0, 50);
    } else {
        ofSetColor(255, 60);
    }
    
    for (int i = 0; i < whitePixels.size(); i++) {
        
        int _noteLoopIndex = ((i) % (whitePixels.size() - 1)) + 1;
        int _pixelNumbers = whitePixels[_noteLoopIndex].pixelN;
        int _idPixels = whitePixels[_noteLoopIndex].indexPos - _pixelNumbers;
        
        float _x = ((_idPixels) % (int)changedCamSize) * pixelStepS * cameraScreenRatio;
        float _y = (int)((_idPixels) / (int)changedCamSize) * pixelStepS * cameraScreenRatio;
        ofPoint _p = ofPoint(_x, _y);
        
        
        int _idLoopLine = ((i) % (whitePixels.size() - 1)) + 1;
        int _idLoopLineOld = ((i + 1) % (whitePixels.size() - 1)) + 1;
        
        int _note = _vNote[_idLoopLine];
        int _noteOld = _vNote[_idLoopLineOld];
        
        int _scaledNote = scaleSetting.noteSelector(baseSelection, _scoreCh, _note);
        int _scaledNoteOld = scaleSetting.noteSelector(baseSelection, _scoreCh, _noteOld);
        
        
        if (abs(_scaledNoteOld - _scaledNote) >= intervalDist) {
            if (_note > 0) {
                float _size = _scaledNote * pixeShapeSize;
                drawShape(_p, baseSelection, _size);
            }
        }
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
}





//--------------------------------------------------------------
void ofApp::drawPixelNumbersCircleNotes() {
    
    int _pixelSize = pixelCircleSize;
    float _ellipseSizeR = 0.7;
    
    ofPushMatrix();
    ofPushStyle();
    ofEnableAntiAliasing();
    
    if (WHITE_VIEW) {
        ofSetColor(0, 120);
    } else {
        ofSetColor(255, 120);
    }
    
    if (whitePixels.size() > 0) {
        
        int _noteLoopIndex = ((noteIndex) % (whitePixels.size() - 1)) + 1;
        int _pixelNumbers = whitePixels[_noteLoopIndex].pixelN;
        int _idPixels = whitePixels[_noteLoopIndex].indexPos - _pixelNumbers;
        
        for (int i = 0; i < _pixelNumbers; i++) {
            
            float _xS = ((_idPixels + i) % (int)changedCamSize) * pixelStepS * cameraScreenRatio;
            float _yS = (int)((_idPixels + i) / (int)changedCamSize) * pixelStepS * cameraScreenRatio;
            
            //            ofFill();
            //            ofSetColor(255, 20);
            //            ofDrawCircle(_xS, _yS, _pixelSize * _ellipseSizeR);
            
            ofNoFill();
            if (WHITE_VIEW) {
                ofSetColor(0, 120);
            } else {
                ofSetColor(eventColor, 80);
            }
            ofDrawCircle(_xS, _yS, _pixelSize * _ellipseSizeR);
            
        }
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
}



//--------------------------------------------------------------
void ofApp::drawPlayingShapeNotes() {
    
    ofPushMatrix();
    ofPushStyle();
    ofEnableAntiAliasing();
    if (WHITE_VIEW) {
        ofSetColor(0, 120);
    } else {
        ofSetColor(255, 120);
    }
    
    if (whitePixels.size() > 0) {
        
        int _noteLoopIndex = ((noteIndex) % (whitePixels.size() - 1)) + 1;
        int _pixelNumbers = whitePixels[_noteLoopIndex].pixelN;
        int _idPixels = whitePixels[_noteLoopIndex].indexPos - _pixelNumbers;
        
        float _x = ((_idPixels) % (int)changedCamSize) * pixelStepS * cameraScreenRatio;
        float _y = (int)((_idPixels) / (int)changedCamSize) * pixelStepS * cameraScreenRatio;
        ofPoint _p = ofPoint(_x, _y);
        
        drawShape(_p, baseSelection, _pixelNumbers);
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
}



//--------------------------------------------------------------
void ofApp::drawPlayingShapeNote(vector<int> _vNote, int _scoreCh) {
    
    ofPushMatrix();
    ofPushStyle();
    
    //    float _h = ofMap(_scoreCh, 1, 7, 0, 255);
    //    ofColor _c = ofColor::fromHsb(_h, 180, 255, 180);
    
    ofColor _c = colorVar[_scoreCh - 1];
    
    if (whitePixels.size() > 0) {
        
        int _noteLoopIndex = ((noteIndex) % (whitePixels.size() - 1)) + 1;
        int _pixelNumbers = whitePixels[_noteLoopIndex].pixelN;
        int _idPixels = whitePixels[_noteLoopIndex].indexPos - _pixelNumbers;
        
        float _x = ((_idPixels) % (int)changedCamSize) * pixelStepS * cameraScreenRatio;
        float _y = (int)((_idPixels) / (int)changedCamSize) * pixelStepS * cameraScreenRatio;
        ofPoint _p = ofPoint(_x, _y);
        
        int _idLoopLineOld = ((1 + noteIndex) % (whitePixels.size() - 1)) + 1;
        
        int _note = _vNote[_noteLoopIndex];
        int _noteOld = _vNote[_idLoopLineOld];
        
        int _scaledNote = scaleSetting.noteSelector(baseSelection, _scoreCh, _note);
        int _scaledNoteOld = scaleSetting.noteSelector(baseSelection, _scoreCh, _noteOld);
        
        if (abs(_scaledNoteOld - _scaledNote) >= intervalDist) {
            if (_note > 0) {
                //                drawShapeWithCenterlines(_p, baseSelection, _pixelNumbers);
                
                float _size = _scaledNote * pixeShapeSize;
                drawShapeWithCenterlinesColorRotation(_p, baseSelection, _size, _c);
            }
        }
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
}


//--------------------------------------------------------------
void ofApp::drawLineScoreIPad() {
    
    int _xNumber = lineScoreNumber;
    int _stepX = lineScoreStepX;
    int _stepY = lineScoreStepY;
    int _offsetNote = 56;
    int _offsetXPos = _stepX * (_xNumber - 1);
    
    
    ofPushMatrix();
    ofTranslate(ctrlPnW * 0.5 - _offsetXPos * 0.5, ctrlPnY + 127 * _stepY - _offsetNote);
    
    ofPushStyle();
    if (WHITE_VIEW) {
        ofSetColor(0, 120);
    } else {
        ofSetColor(255, 120);
    }
    
    for (int i = 0; i < NUM_SYNTH_LINE; i++) {
        drawScoreCircleLineIPad(scoreNote[i], i + 1);
    }
    
    ofPopStyle();
    ofPopMatrix();
    
}


//--------------------------------------------------------------
void ofApp::drawScoreCircleLineIPad(vector<int> _vNote, int _scoreCh) {
    
    int _xNumber = lineScoreNumber;
    //    int _middle = _xNumber * 0.5;
    int _stepX = lineScoreStepX;
    int _stepY = lineScoreStepY;
    //    int _offsetNote = 56;
    int _offsetXPos = _stepX * (_xNumber - 1);
    
    vector<int> _scoreNote = _vNote;
    
    //    float _h = ofMap(_scoreCh, 1, 7, 0, 255);
    //    ofColor _c = ofColor::fromHsb(_h, 255, 180, 180);
    
    ofColor _c = colorVar[_scoreCh - 1];
    
    if (_scoreNote.size() > 0) {
        
        drawCircle(_c, _xNumber, _scoreNote, _stepX, _stepY, _scoreCh, _offsetXPos);
        
        drawLine(_c, _xNumber, _scoreNote, _stepX, _stepY, _scoreCh, _offsetXPos);
        
    }
    
}



//--------------------------------------------------------------
void ofApp::drawLineScoreIPhone(bool playOn) {
    
    if (playOn) {
        ofPushMatrix();
        
        ofTranslate(0, iPhonePreviewSize);
        
        ofPushStyle();
        if (WHITE_VIEW) {
            ofSetColor(0, 120);
        } else {
            ofSetColor(255, 120);
        }
        
        for (int i = 0; i < NUM_SYNTH_LINE; i++) {
            drawScoreCircleLineIPhone(scoreNote[i], i + 1);
        }
        
        ofPopStyle();
        
        ofPopMatrix();
    }
    
}


//--------------------------------------------------------------
void ofApp::drawScoreCircleLineIPhone(vector<int> vNote, int scoreCh) {
    
    int _offsetXPos = lineScoreStepX * (lineScoreNumber - 1);
    
    ofColor _c = colorVar[scoreCh - 1];
    
    if (vNote.size() > 0) {
        drawCircle(_c, lineScoreNumber, vNote, lineScoreStepX, lineScoreStepY, scoreCh, _offsetXPos);
        drawLine(_c, lineScoreNumber, vNote, lineScoreStepX, lineScoreStepY, scoreCh, _offsetXPos);
    }
    
}


//--------------------------------------------------------------
void ofApp::drawCircle(ofColor cIn, int xNumber, vector<int> scoreNote, float stepX, float stepY, int scoreCh, int offsetXPos) {
    
    int _middle = xNumber * 0.5;
    
    ofPushStyle();
    
    for (int i = 0; i < xNumber; i++) {
        
        int _idLoopLine = ((i + noteIndex - _middle) % (whitePixels.size() - 1)) + 1;
        int _idLoopLinePrev = ((i + 1 + noteIndex - _middle) % (whitePixels.size() - 1)) + 1;
        
        int _note = scoreNote[_idLoopLine];
        int _notePrev = scoreNote[_idLoopLinePrev];
        
        int _scaledNote = scaleSetting.noteSelector(baseSelection, scoreCh, _note);
        int _scaledNotePrev = scaleSetting.noteSelector(baseSelection, scoreCh, _notePrev);
        
        float _x1 = offsetXPos - i * stepX;
        float _y1 = _scaledNote * stepY;
        
        ofColor _c = cIn;
        int _size = 3;
        if (abs(_scaledNotePrev - _scaledNote) >= intervalDist) {
            if (i == 11) {
                _c = ofColor(cIn);
                _size = 5;
            } else {
                _c = ofColor(cIn, 120);
                _size = 3;
            }
            if (_note > 0) {
                ofSetColor(_c);
                ofDrawCircle(_x1, _y1, _size);
            }
        }
        
    }
    
    ofPopStyle();
    
}



//--------------------------------------------------------------
void ofApp::drawLine(ofColor c, int xNumber,  vector<int> scoreNote, float stepX, float stepY, int scoreCh, int offsetXPos) {
    
    int _middle = xNumber * 0.5;
    
    ofPushStyle();
    ofSetColor(c, 160);
    
    for (int i = 0; i < xNumber - 1; i++) {
        
        int _idLoopLineS = ((i + noteIndex - _middle) % (whitePixels.size() - 1)) + 1;
        int _idLoopLineE = ((i + 1 + noteIndex - _middle) % (whitePixels.size() - 1)) + 1;
        int _idLoopLineEOld = ((i + 2 + noteIndex - _middle) % (whitePixels.size() - 1)) + 1;
        
        int _noteS = scoreNote[_idLoopLineS];
        int _noteE = scoreNote[_idLoopLineE];
        int _noteEOld = scoreNote[_idLoopLineEOld];
        
        int _noteSScaled = scaleSetting.noteSelector(baseSelection, scoreCh, _noteS);
        int _noteEScaled = scaleSetting.noteSelector(baseSelection, scoreCh, _noteE);
        int _noteEOldScaled = scaleSetting.noteSelector(baseSelection, scoreCh, _noteEOld);
        
        float _x1 = offsetXPos - i * stepX;
        float _y1 = _noteSScaled * stepY;
        float _x2 = offsetXPos - (i + 1) * stepX;
        float _y2 = _noteEScaled * stepY;
        
        if ((abs(_noteEScaled - _noteSScaled) >= intervalDist) && abs(_noteEOldScaled - _noteEScaled) >= intervalDist) {
            if (_noteS > 0 && _noteE > 0) {
                if (_y1 > 0 && _y2 > 0) {
                    ofDrawLine(_x1, _y1, _x2, _y2);
                }
            }
        }
    }
    
    ofPopStyle();
    
}



//--------------------------------------------------------------
void ofApp::drawBaseInterface(bool playOn) {
    
    if (playOn) {
        
        ofPushMatrix();
        ofPushStyle();
        
        ofColor _c[6];
        
        for (int i = 0; i < 6; i++) {
            if (baseSelection == (4 + i)) {
                _c[i] = uiLineColor;
            } else {
                _c[i] = ofColor(30);
            }
        }
        
        drawShapeFillColor(base4Pos, 4, baseSize, _c[0]);
        drawShapeFillColor(base5Pos, 5, baseSize, _c[1]);
        drawShapeFillColor(base6Pos, 6, baseSize, _c[2]);
        drawShapeFillColor(base7Pos, 7, baseSize, _c[3]);
        drawShapeFillColor(base8Pos, 8, baseSize, _c[4]);
        drawShapeFillColor(base9Pos, 9, baseSize, _c[5]);
        
        if (bCameraCapturePlay) {
            switch (baseSelection) {
                case 4:
                    activeShapeFillColor(base4Pos, 4, baseSize, _c[0]);
                    break;
                case 5:
                    activeShapeFillColor(base5Pos, 5, baseSize, _c[1]);
                    break;
                case 6:
                    activeShapeFillColor(base6Pos, 6, baseSize, _c[2]);
                    break;
                case 7:
                    activeShapeFillColor(base7Pos, 7, baseSize, _c[3]);
                    break;
                case 8:
                    activeShapeFillColor(base8Pos, 8, baseSize, _c[4]);
                    break;
                case 9:
                    activeShapeFillColor(base9Pos, 9, baseSize, _c[5]);
                    break;
                default:
                    break;
            }
            
        }
        
        ofPopMatrix();
        ofPopStyle();
        
    }
    
}



//--------------------------------------------------------------
void ofApp::drawShapeFillColor(ofPoint pos, int base, int size, ofColor _c) {
    
    ofPoint _pos = pos;
    
    vector<ofPoint> posLine;
    
    int _base = base;
    int _size = size;
    
    for (int i = 0; i < _base; i++) {
        float _sizeDegree = i * 360 / _base + 180.0;
        float _x = sin(ofDegToRad(_sizeDegree)) * _size;
        float _y = cos(ofDegToRad(_sizeDegree)) * _size;
        
        ofPoint _p = ofPoint(_x, _y);
        posLine.push_back(_p);
    }
    
    
    ofPushMatrix();
    ofPushStyle();
    
    ofTranslate(_pos);
    
    //    if (!bIPhone) {
    //        ofRotateZDeg(0);
    //    } else {
    //        if (_base == 5) {
    //            ofRotateZDeg(18);
    //        } else if (_base == 7) {
    //            ofRotateZDeg(38.571429);
    //        } else if (_base == 8) {
    //            ofRotateZDeg(45);
    //        } else if (_base == 9) {
    //            ofRotateZDeg(50);
    //        } else {
    //            ofRotateZDeg(0);
    //        }
    //    }
    
    
    //    if (WHITE_VIEW) {
    //        ofSetColor(_c, 120);
    //    } else {
    //        ofSetColor(_c, 120);
    //    }
    //    for (int i = 0; i < posLine.size(); i++) {
    //        ofDrawLine(0, 0, posLine[i].x, posLine[i].y);
    //    }
    
    
    
    if (WHITE_VIEW) {
        ofSetColor(_c, 180);
    } else {
        ofSetColor(_c, 40);
    }
    
    ofSetLineWidth(controlObjectLineWidth);
    
    ofMesh _shapeM;
    _shapeM.setMode(OF_PRIMITIVE_TRIANGLE_FAN);
    _shapeM.addVertex(ofPoint(0, 0));
    for (int i = 0; i < posLine.size(); i++) {
        _shapeM.addVertex(ofPoint(posLine[i].x, posLine[i].y));
    }
    _shapeM.addVertex(ofPoint(posLine[0].x, posLine[0].y));
    _shapeM.draw();
    
    
    if (WHITE_VIEW) {
        ofSetColor(255, 180);
    } else {
        ofSetColor(uiLineColor);
    }
    
    ofMesh _shapeOutLine;
    _shapeOutLine.setMode(OF_PRIMITIVE_LINE_STRIP);
    for (int i = 0; i < posLine.size(); i++) {
        _shapeOutLine.addVertex(ofPoint(posLine[i].x, posLine[i].y));
    }
    _shapeOutLine.addVertex(ofPoint(posLine[0].x, posLine[0].y));
    _shapeOutLine.draw();
    
    ofPopStyle();
    ofPopMatrix();
    
}



//--------------------------------------------------------------
void ofApp::activeShapeFillColor(ofPoint pos, int base, int size, ofColor _c) {
    
    ofPoint _pos = pos;
    
    vector<ofPoint> posLine;
    
    int _base = base;
    int _size = size;
    
    for (int i = 0; i < _base; i++) {
        float _sizeDegree = i * 360 / _base + 180.0;
        float _x = sin(ofDegToRad(_sizeDegree)) * _size;
        float _y = cos(ofDegToRad(_sizeDegree)) * _size;
        
        ofPoint _p = ofPoint(_x, _y);
        posLine.push_back(_p);
    }
    
    
    ofPushMatrix();
    ofPushStyle();
    
    ofTranslate(_pos);
    
    if (!bIPhone) {
        ofRotateZDeg(0);
    } else {
        if (_base == 5) {
            ofRotateZDeg(18);
        } else if (_base == 7) {
            ofRotateZDeg(38.571429);
        } else if (_base == 8) {
            ofRotateZDeg(45);
        } else if (_base == 9) {
            ofRotateZDeg(50);
        } else {
            ofRotateZDeg(0);
        }
    }
    
    
    if (WHITE_VIEW) {
        ofSetColor(_c, 120);
    } else {
        ofSetColor(_c, 120);
    }
    for (int i = 0; i < posLine.size(); i++) {
        //        ofDrawLine(0, 0, posLine[i].x, posLine[i].y);
    }
    
    
    
    if (WHITE_VIEW) {
        ofSetColor(_c, 180);
    } else {
        ofSetColor(_c, 180);
    }
    
    ofSetLineWidth(controlObjectLineWidth);
    
    //    ofMesh _shapeM;
    //    _shapeM.setMode(OF_PRIMITIVE_TRIANGLE_FAN);
    //    _shapeM.addVertex(ofPoint(0, 0));
    //    for (int i = 0; i < posLine.size(); i++) {
    //        _shapeM.addVertex(ofPoint(posLine[i].x, posLine[i].y));
    //    }
    //    _shapeM.addVertex(ofPoint(posLine[0].x, posLine[0].y));
    //    _shapeM.draw();
    
    
    float _scaleMoving = floor(activeFactor) * 0.05 + 1.2;
    
    if (WHITE_VIEW) {
        ofSetColor(255, 180);
    } else {
        ofSetColor(uiLineColor);
    }
    
    //    float _scale = 0;
    //    for (int j=0; j<int(activeFactor); j+=10) {
    //        _scale = j * 0.1 + 1.2;
    //
    //        ofMesh _shapeOutLine;
    //        _shapeOutLine.setMode(OF_PRIMITIVE_LINE_STRIP);
    //        for (int i = 0; i < posLine.size(); i++) {
    //            _shapeOutLine.addVertex(ofPoint(posLine[i].x * _scale, posLine[i].y * _scale));
    //        }
    //        _shapeOutLine.addVertex(ofPoint(posLine[0].x * _scale, posLine[0].y * _scale));
    //        ofPushStyle();
    //        ofSetColor(255, j * 20);
    //        _shapeOutLine.draw();
    //        ofPopStyle();
    //    }
    
    
    ofPushStyle();
    ofSetColor(_c, 220);
    
    ofMesh _shapeOutMovingLine;
    _shapeOutMovingLine.setMode(OF_PRIMITIVE_LINE_STRIP);
    for (int i = 0; i < posLine.size(); i++) {
        _shapeOutMovingLine.addVertex(ofPoint(posLine[i].x * _scaleMoving, posLine[i].y * _scaleMoving));
    }
    _shapeOutMovingLine.addVertex(ofPoint(posLine[0].x * _scaleMoving, posLine[0].y * _scaleMoving));
    _shapeOutMovingLine.draw();
    ofPopStyle();
    
    
    ofPopStyle();
    ofPopMatrix();
    
}



//--------------------------------------------------------------
void ofApp::drawShapeWithCenterlines(ofPoint pos, int base, int size, ofColor _c) {
    
    ofPoint _pos = pos;
    
    vector<ofPoint> posLine;
    
    int _base = base;
    int _size = size;
    
    for (int i = 0; i < _base; i++) {
        float _sizeDegree = i * 360 / _base + 180.0;
        float _x = sin(ofDegToRad(_sizeDegree)) * _size;
        float _y = cos(ofDegToRad(_sizeDegree)) * _size;
        
        ofPoint _p = ofPoint(_x, _y);
        posLine.push_back(_p);
    }
    
    
    ofPushMatrix();
    ofPushStyle();
    
    ofTranslate(_pos);
    
    if (!bIPhone) {
        ofRotateZDeg(0);
    } else {
        if (_base == 5) {
            ofRotateZDeg(18);
        } else if (_base == 7) {
            ofRotateZDeg(38.571429);
        } else if (_base == 8) {
            ofRotateZDeg(45);
        } else if (_base == 9) {
            ofRotateZDeg(50);
        } else {
            ofRotateZDeg(0);
        }
    }
    
    if (WHITE_VIEW) {
        ofSetColor(_c, 120);
    } else {
        ofSetColor(_c, 60);
    }
    for (int i = 0; i < posLine.size(); i++) {
        ofDrawLine(0, 0, posLine[i].x, posLine[i].y);
    }
    
    if (WHITE_VIEW) {
        ofSetColor(_c, 180);
    } else {
        ofSetColor(_c, 180);
    }
    
    ofSetLineWidth(controlObjectLineWidth);
    
    for (int i = 0; i < posLine.size() - 1; i++) {
        ofDrawLine(posLine[i].x, posLine[i].y, posLine[i + 1].x, posLine[i + 1].y);
    }
    ofDrawLine(posLine[0].x, posLine[0].y, posLine[posLine.size() - 1].x, posLine[posLine.size() - 1].y);
    
    ofPopStyle();
    ofPopMatrix();
    
}


//---------------------------------------------du bist dumm-----------------
void ofApp::drawShapeWithCenterlinesColorRotation(ofPoint pos, int base, int size, ofColor _color) {
    
    ofPoint _pos = pos;
    
    vector<ofPoint> posLine;
    
    int _base = base;
    int _size = size;
    
    for (int i = 0; i < _base; i++) {
        float _sizeDegree = i * 360 / _base + 180.0;
        float _x = sin(ofDegToRad(_sizeDegree)) * _size;
        float _y = cos(ofDegToRad(_sizeDegree)) * _size;
        
        ofPoint _p = ofPoint(_x, _y);
        posLine.push_back(_p);
    }
    
    
    ofPushMatrix();
    ofPushStyle();
    
    
    ofTranslate(_pos);
    //    ofRotateZDeg(45);
    
    ofSetLineWidth(20);
    
    ofSetColor(_color.r, _color.g, _color.b, _color.a * 0.8);
    for (int i = 0; i < posLine.size(); i++) {
        //        ofDrawLine(0, 0, posLine[i].x, posLine[i].y);
    }
    
    ofSetColor(_color);
    for (int i = 0; i < posLine.size() - 1; i++) {
        ofDrawLine(posLine[i].x, posLine[i].y, posLine[i + 1].x, posLine[i + 1].y);
    }
    ofDrawLine(posLine[0].x, posLine[0].y, posLine[posLine.size() - 1].x, posLine[posLine.size() - 1].y);
    
    ofPopMatrix();
    ofPopStyle();
    
}




//--------------------------------------------------------------
void ofApp::drawShape(ofPoint pos, int base, int size) {
    
    ofPoint _pos = pos;
    
    vector<ofPoint> posLine;
    
    int _base = base;
    int _size = size;
    
    for (int i = 0; i < _base; i++) {
        float _sizeDegree = i * 360 / _base + 180.0;
        float _x = sin(ofDegToRad(_sizeDegree)) * _size;
        float _y = cos(ofDegToRad(_sizeDegree)) * _size;
        
        ofPoint _p = ofPoint(_x, _y);
        posLine.push_back(_p);
    }
    
    ofPushMatrix();
    
    ofTranslate(_pos);
    
    for (int i = 0; i < posLine.size() - 1; i++) {
        ofDrawLine(posLine[i].x, posLine[i].y, posLine[i + 1].x, posLine[i + 1].y);
    }
    ofDrawLine(posLine[0].x, posLine[0].y, posLine[posLine.size() - 1].x, posLine[posLine.size() - 1].y);
    
    ofPopMatrix();
    
}



//--------------------------------------------------------------
void ofApp::debugControlPDraw() {
    
    ofPushMatrix();
    ofPushStyle();
    
    if (WHITE_VIEW) {
        ofSetColor(0);
    } else {
        ofSetColor(255);
    }
    
    for (int i = 0; i < 15; i++) {
        float _x1 = i * guideWidthStep + guideWidthStep;
        ofDrawLine(_x1, ctrlPnY, _x1, screenH);
    }
    
    for (int j = 0; j < 7; j++) {
        float _y1 = j * guideHeightStep + guideHeightStep;
        ofDrawLine(0, _y1 + ctrlPnY, screenW, _y1 + ctrlPnY);
    }
    
    ofPopStyle();
    ofPopMatrix();
    
    
    ofPushStyle();
    ofSetColor(0);
    ofDrawBitmapString(ofToString(ofGetFrameRate(), 2), 10, screenH - 10);
    ofPopStyle();
    
}




//--------------------------------------------------------------
void ofApp::exit() {
    
    cam.close();
    std::exit(0);
    
}



//--------------------------------------------------------------
void ofApp::iPhoneTouchDown(ofTouchEventArgs & touch) {
    
    float _tolerance = 2;
    
    ofPoint _chgdTouch = ofPoint(touch.x, touch.y);
    
    touchPos[touch.id] = _chgdTouch;
    
    distS[touch.id] = ofDist(speedCPos.x, speedCPos.y , touchPos[touch.id].x, touchPos[touch.id].y);
    
    for (int i = 0; i < 2; i++) {
        float _distS = ofDist(speedCPos.x, speedCPos.y , touchPos[i].x, touchPos[i].y);
        if ((_distS < speedCSize * 0.642857 * _tolerance) && bSpeedCtrl == false) {
            bSpeedCtrl = true;
        }
    }
    
    
    distI[touch.id] = ofDist(intervalPos.x, intervalPos.y , touchPos[touch.id].x, touchPos[touch.id].y);
    
    for (int i = 0; i < 2; i++) {
        float _distI = ofDist(intervalPos.x, intervalPos.y , touchPos[i].x, touchPos[i].y);
        if ((_distI < intervalSize * _tolerance) && bInterval == false) {
            bInterval = true;
        }
    }
    
    
    if (touch.id == 0) {
        
        //        float _distS = ofDist(speedCPos.x, speedCPos.y , _chgdTouch.x, _chgdTouch.y);
        //
        //        if (_distS < thresholdCSize * _tolerance) {
        //            bSpeedCtrl = true;
        //        } else {
        //            bSpeedCtrl = false;
        //        }
        
        //        float _distT = ofDist(thresholdCPos.x, thresholdCPos.y , _chgdTouch.x, _chgdTouch.y);
        
        //        if (_distT < thresholdCSize * _tolerance) {
        //            bthresholdCtrl = true;
        //        } else {
        //            bthresholdCtrl = false;
        //        }
        
        //        float _distI = ofDist(intervalPos.x, intervalPos.y , _chgdTouch.x, _chgdTouch.y);
        //
        //        if (_distI < intervalSize * _tolerance) {
        //            bInterval = true;
        //        } else {
        //            bInterval = false;
        //        }
        
        float _xL = screenPosLeftY;
        float _xR = screenPosLeftY + iPhonePreviewSize;
        if ((_chgdTouch.x > (screenW - iPhonePreviewSize)) && (_chgdTouch.x < screenW) && (_chgdTouch.y < _xR) && (_chgdTouch.y > _xL)) {
            
            grayThreshold = 120;
            touchDownDefault = _chgdTouch.x;
            
        }
        
        
        
    }
    
    float _torelanceTouchDownIPhone = 2;
    float _4BaseDist = ofDist(_chgdTouch.x, _chgdTouch.y, base4Pos.x, base4Pos.y);
    if (_4BaseDist < baseSize * _torelanceTouchDownIPhone) {
        baseSelection = 4;
    }
    
    float _5BaseDist = ofDist(_chgdTouch.x, _chgdTouch.y, base5Pos.x, base5Pos.y);
    if (_5BaseDist < baseSize * _torelanceTouchDownIPhone) {
        baseSelection = 5;
    }
    
    float _6BaseDist = ofDist(_chgdTouch.x, _chgdTouch.y, base6Pos.x, base6Pos.y);
    if (_6BaseDist < baseSize * _torelanceTouchDownIPhone) {
        baseSelection = 6;
    }
    
    float _7BaseDist = ofDist(_chgdTouch.x, _chgdTouch.y, base7Pos.x, base7Pos.y);
    if (_7BaseDist < baseSize * _torelanceTouchDownIPhone) {
        baseSelection = 7;
    }
    
    float _8BaseDist = ofDist(_chgdTouch.x, _chgdTouch.y, base8Pos.x, base8Pos.y);
    if (_8BaseDist < baseSize * _torelanceTouchDownIPhone) {
        baseSelection = 8;
    }
    
    float _9BaseDist = ofDist(_chgdTouch.x, _chgdTouch.y, base9Pos.x, base9Pos.y);
    if (_9BaseDist < baseSize * _torelanceTouchDownIPhone) {
        baseSelection = 9;
    }
    
}




//--------------------------------------------------------------
void ofApp::iPadTouchDown(ofTouchEventArgs & touch) {
    
    float _tolerance = 2;
    
    ofPoint _chgdTouch = ofPoint(touch.x, touch.y - shiftValueIphoneY);
    
    touchPos[touch.id] = _chgdTouch;
    
    distS[touch.id] = ofDist(speedCPos.x, speedCPos.y, touchPos[touch.id].x, touchPos[touch.id].y);
    
    for (int i = 0; i < 2; i++) {
        float _distS = ofDist(speedCPos.x, speedCPos.y, touchPos[i].x, touchPos[i].y);
        if ((_distS < thresholdCSize * _tolerance) && bSpeedCtrl == false) {
            bSpeedCtrl = true;
        }
    }
    
    distI[touch.id] = ofDist(intervalPos.x, intervalPos.y , touchPos[touch.id].x, touchPos[touch.id].y);
    
    for (int i = 0; i < 2; i++) {
        float _distI = ofDist(intervalPos.x, intervalPos.y , touchPos[i].x, touchPos[i].y);
        if ((_distI < intervalSize * _tolerance) && bInterval == false) {
            bInterval = true;
        }
        
    }
    
    if (touch.id == 0) {
        
        //        float _distS = ofDist(speedCPos.x, speedCPos.y , _chgdTouch.x, _chgdTouch.y);
        //
        //        if (_distS < thresholdCSize * _tolerance) {
        //            bSpeedCtrl = true;
        //        } else {
        //            bSpeedCtrl = false;
        //        }
        
        //        float _distT = ofDist(thresholdCPos.x, thresholdCPos.y , _chgdTouch.x, _chgdTouch.y);
        
        //        if (_distT < thresholdCSize * _tolerance) {
        //            bthresholdCtrl = true;
        //        } else {
        //            bthresholdCtrl = false;
        //        }
        
        //        float _distI = ofDist(intervalPos.x, intervalPos.y , _chgdTouch.x, _chgdTouch.y);
        //
        //        if (_distI < intervalSize * _tolerance) {
        //            bInterval = true;
        //        } else {
        //            bInterval = false;
        //        }
        
        if ((_chgdTouch.x > 0) && (_chgdTouch.x < ctrlPnW) && (_chgdTouch.y < ctrlPnY) && (_chgdTouch.y > 0)) {
            
            grayThreshold = 120;
            touchDownDefault = _chgdTouch.y;
            
        }
        
        
    }
    
    float _4BaseDist = ofDist(_chgdTouch.x, _chgdTouch.y, base4Pos.x, base4Pos.y);
    if (_4BaseDist < baseSize) {
        baseSelection = 4;
    }
    
    float _5BaseDist = ofDist(_chgdTouch.x, _chgdTouch.y, base5Pos.x, base5Pos.y);
    if (_5BaseDist < baseSize) {
        baseSelection = 5;
    }
    
    float _6BaseDist = ofDist(_chgdTouch.x, _chgdTouch.y, base6Pos.x, base6Pos.y);
    if (_6BaseDist < baseSize) {
        baseSelection = 6;
    }
    
    float _7BaseDist = ofDist(_chgdTouch.x, _chgdTouch.y, base7Pos.x, base7Pos.y);
    if (_7BaseDist < baseSize) {
        baseSelection = 7;
    }
    
    float _8BaseDist = ofDist(_chgdTouch.x, _chgdTouch.y, base8Pos.x, base8Pos.y);
    if (_8BaseDist < baseSize) {
        baseSelection = 8;
    }
    
    float _9BaseDist = ofDist(_chgdTouch.x, _chgdTouch.y, base9Pos.x, base9Pos.y);
    if (_9BaseDist < baseSize) {
        baseSelection = 9;
    }
}



//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch) {
    
    if (!bIPhone) {
        iPadTouchDown(touch);
    } else {
        iPhoneTouchDown(touch);
    }
    
}




//--------------------------------------------------------------
void ofApp::iPadTouchMoved(ofTouchEventArgs & touch) {
    
    ofPoint _chgdTouch = ofPoint(touch.x, touch.y - shiftValueIphoneY);
    
    touchPos[touch.id] = _chgdTouch;
    
    if (bSpeedCtrl) {
        float _minY = ctrlPnY + speedCSize * 0.75;
        float _maxY = screenH - speedCSize * 0.75;
        
        if ((touchPos[touch.id].y > _minY) && (touchPos[touch.id].y < _maxY) && touchPos[touch.id].x > speedCPos.x - (ctrlPnW - speedCPos.x)) {
            speedCPos.y = touchPos[touch.id].y;
            float _tempo = ofMap(speedCPos.y, _minY, _maxY, maxSpeed, minSpeed);
            synthMain.setParameter("tempo", _tempo);
        }
    }
    
    //        if (bthresholdCtrl) {
    //            float _minY = ctrlPnY + speedCSize * 0.75;
    //            float _maxY = screenH - speedCSize * 0.75;
    //
    //            if ((_chgdTouch.y>_minY)&&(_chgdTouch.y<_maxY)) {
    //                thresholdCPos.y = _chgdTouch.y;
    //                float _threshold = ofMap(thresholdCPos.y, _minY, _maxY, 255, 0);
    //                grayThreshold = _threshold;
    //            }
    //        }
    
    
    if (bInterval) {
        float _minY = ctrlPnY + speedCSize * 0.75;
        float _maxY = screenH - speedCSize * 0.75;
        if ((touchPos[touch.id].y > _minY) && (touchPos[touch.id].y < _maxY) && touchPos[touch.id].x < intervalPos.x * 2) {
            intervalPos.y = touchPos[touch.id].y;
            float _interval = ofMap(intervalPos.y, _minY, _maxY, 0, 20);
            intervalDist = _interval;
        }
    }
    
    
    if (touch.id == 0) {
        
        //        if (bSpeedCtrl) {
        //            float _minY = ctrlPnY + speedCSize * 0.75;
        //            float _maxY = screenH - speedCSize * 0.75;
        //
        //            if ((_chgdTouch.y>_minY)&&(_chgdTouch.y<_maxY)) {
        //                speedCPos.y = _chgdTouch.y;
        //                float _tempo = ofMap(speedCPos.y, _minY, _maxY, maxSpeed, minSpeed);
        //                synthMain.setParameter("tempo", _tempo);
        //            }
        //
        //        }
        //
        ////        if (bthresholdCtrl) {
        ////            float _minY = ctrlPnY + speedCSize * 0.75;
        ////            float _maxY = screenH - speedCSize * 0.75;
        ////
        ////            if ((_chgdTouch.y>_minY)&&(_chgdTouch.y<_maxY)) {
        ////                thresholdCPos.y = _chgdTouch.y;
        ////                float _threshold = ofMap(thresholdCPos.y, _minY, _maxY, 255, 0);
        ////                grayThreshold = _threshold;
        ////            }
        ////        }
        //
        //
        //        if (bInterval) {
        //            float _minY = ctrlPnY + speedCSize * 0.75;
        //            float _maxY = screenH - speedCSize * 0.75;
        //            if ((_chgdTouch.y>_minY)&&(_chgdTouch.y<_maxY)) {
        //                intervalPos.y = _chgdTouch.y;
        //                float _interval = ofMap(intervalPos.y, _minY, _maxY, 0, 20);
        //                intervalDist = _interval;
        //            }
        //        }
        
        if ((_chgdTouch.x > 0) && (_chgdTouch.x < ctrlPnW) && (_chgdTouch.y < ctrlPnY) && (_chgdTouch.y > 0)) {
            
            grayThreshold = 120 + (_chgdTouch.y - touchDownDefault);
            
        }
        
    }
    
}



//--------------------------------------------------------------
void ofApp::iPhoneTouchMoved(ofTouchEventArgs & touch) {
    
    ofPoint _chgdTouch = ofPoint(touch.x, touch.y);
    
    touchPos[touch.id] = _chgdTouch;
    
    //    if (bSpeedCtrl) {
    //        float _minX = ofGetWidth() * 0.15;
    //        float _maxX = screenW * 0.9;
    //        if ((touchPos[touch.id].x > _minX) && (touchPos[touch.id].x < _maxX) && touchPos[touch.id].y > screenPosRightY) {
    //            speedCPos.x = touchPos[touch.id].x;
    //            float _tempo = ofMap(speedCPos.x, _minX, _maxX, minSpeed, maxSpeed);
    //            synthMain.setParameter("tempo", _tempo);
    //        }
    //    }
    
    if (bSpeedCtrl) {
        float _minY = speedLineLength.x;
        float _maxY = speedLineLength.y;
        if ((touchPos[touch.id].y > _minY) && (touchPos[touch.id].y < _maxY) && touchPos[touch.id].x > ofGetWidth() * 0.8) {
            speedCPos.y = touchPos[touch.id].y;
            float _tempo = ofMap(speedCPos.y, _minY, _maxY, minSpeed, maxSpeed);
            synthMain.setParameter("tempo", _tempo);
        }
    }
    
    //    if (bInterval) {
    //        float _minX = ofGetWidth() * 0.15;
    //        float _maxX = screenW * 0.9;
    //        if ((touchPos[touch.id].x > _minX) && (touchPos[touch.id].x < _maxX) && touchPos[touch.id].y < intervalPos.y * 2) {
    //            intervalPos.x = touchPos[touch.id].x;
    //            float _interval = ofMap(intervalPos.x, _minX, _maxX, 20, 0);
    //            intervalDist = _interval;
    //        }
    //    }
    
    if (bInterval) {
        float _minY = ctrlLineLength.x;
        float _maxY = ctrlLineLength.y;
        if ((touchPos[touch.id].y > _minY) && (touchPos[touch.id].y < _maxY) && touchPos[touch.id].x < ofGetWidth() * 0.2) {
            intervalPos.y = touchPos[touch.id].y;
            float _interval = ofMap(intervalPos.y, _minY, _maxY, 20, 0);
            intervalDist = _interval;
        }
    }
    
    
    
    //    if (touch.id == 0) {
    //        float _xL = screenPosLeftY;
    //        float _xR = screenPosLeftY + iPhonePreviewSize;
    //        if ((_chgdTouch.x > (screenW - iPhonePreviewSize)) && (_chgdTouch.x < screenW) && (_chgdTouch.y < _xR) && (_chgdTouch.y > _xL)) {
    //            grayThreshold = 120 + (_chgdTouch.x - touchDownDefault);
    //        }
    //    }
    
    
}




//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch) {
    
    if (!bIPhone) {
        iPadTouchMoved(touch);
    } else {
        iPhoneTouchMoved(touch);
    }
    
}




//--------------------------------------------------------------
void ofApp::iPadTouchUp(ofTouchEventArgs & touch) {
    
    ofPoint _chgdTouch = ofPoint(touch.x, touch.y - shiftValueIphoneY);
    
    if ((_chgdTouch.x > 0) && (_chgdTouch.x < ctrlPnW) && (_chgdTouch.y < ctrlPnY) && (_chgdTouch.y > 0)) {
        if ((whitePixels.size() > 2) && (touch.id == 0)) {
            bCameraCapturePlay = !bCameraCapturePlay;
            //            blur(edge, 3);
            bufferImg = edge;
            
            if (!bCameraCapturePlay) {
                index = 0;
                ofRemoveListener(*metroOut, this, &ofApp::triggerReceive);
            } else {
                scoreMake();
                //                noteIndex = index;
                ofAddListener(*metroOut, this, &ofApp::triggerReceive);
                bPlayNote = true;
            }
            
            grayThreshold = 120;
            touchDownDefault = 0;
        }
        
    }
    
    
    if ((_chgdTouch.x < guideWidthStep * 11) && (_chgdTouch.x > guideWidthStep * 4) && (_chgdTouch.y > ctrlPnY) && (_chgdTouch.y < screenH) && bCameraCapturePlay) {
        
        bPlayNote = !bPlayNote;
        
        if (!bPlayNote) {
            ofRemoveListener(*metroOut, this, &ofApp::triggerReceive);
        } else {
            ofAddListener(*metroOut, this, &ofApp::triggerReceive);
        }
        
    }
    
    
    
    float _tolerance = 2;
    
    distS[touch.id] = ofDist(speedCPos.x, speedCPos.y , touchPos[touch.id].x, touchPos[touch.id].y);
    if ((distS[touch.id] < thresholdCSize * _tolerance) && bSpeedCtrl == true) {
        bSpeedCtrl = false;
    }
    
    distI[touch.id] = ofDist(intervalPos.x, intervalPos.y , touchPos[touch.id].x, touchPos[touch.id].y);
    if ((distI[touch.id] < intervalSize * _tolerance) && bInterval == true) {
        bInterval = false;
    }
    
}


//--------------------------------------------------------------
void ofApp::iPhoneTouchUp(ofTouchEventArgs & touch) {
    
    ofPoint _chgdTouch = ofPoint(touch.x, touch.y);
    
    //    if ((_chgdTouch.x > 0) && (_chgdTouch.x < screenW) && (_chgdTouch.y < iPhonePreviewSize) && (_chgdTouch.y > 0)) {
    //
    //        if ((whitePixels.size() > 2) && (touch.id == 0)) {
    //            bCameraCapturePlay = !bCameraCapturePlay;
    //            //            blur(edge, 3);
    //            bufferImg = edge;
    //
    //            if (!bCameraCapturePlay) {
    //                index = 0;
    //                ofRemoveListener(*metroOut, this, &ofApp::triggerReceive);
    //            } else {
    //                scoreMake();
    //                //                noteIndex = index;
    //                ofAddListener(*metroOut, this, &ofApp::triggerReceive);
    //                bPlayNote = true;
    //            }
    //
    //            grayThreshold = 120;
    //            touchDownDefault = 0;
    //        }
    //
    //    }
    
    if (composingMode.inside(_chgdTouch)) {
        if ((whitePixels.size() > 2) && (touch.id == 0)) {
            bCameraCapturePlay = !bCameraCapturePlay;
            bufferImg = edge;
            
            if (!bCameraCapturePlay) {
                index = 0;
                ofRemoveListener(*metroOut, this, &ofApp::triggerReceive);
            } else {
                scoreMake();
                //                noteIndex = index;
                ofAddListener(*metroOut, this, &ofApp::triggerReceive);
                bPlayNote = true;
            }
            
            grayThreshold = 120;
            touchDownDefault = 0;
        }
    }
    
    
    if ((_chgdTouch.x < lineScoreRightX) && (_chgdTouch.x > 0) && (_chgdTouch.y > screenPosLeftY) && (_chgdTouch.y < screenPosRightY) && bCameraCapturePlay) {
        
        bPlayNote = !bPlayNote;
        
        if (!bPlayNote) {
            ofRemoveListener(*metroOut, this, &ofApp::triggerReceive);
        } else {
            ofAddListener(*metroOut, this, &ofApp::triggerReceive);
        }
        
    }
    
    
    float _tolerance = 2;
    
    distS[touch.id] = ofDist(speedCPos.x, speedCPos.y , touchPos[touch.id].x, touchPos[touch.id].y);
    if ((distS[touch.id] < speedCSize * 0.642857 * _tolerance) && bSpeedCtrl == true) {
        bSpeedCtrl = false;
    }
    
    distI[touch.id] = ofDist(intervalPos.x, intervalPos.y , touchPos[touch.id].x, touchPos[touch.id].y);
    if ((distI[touch.id] < intervalSize * _tolerance) && bInterval == true) {
        bInterval = false;
    }
}



//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch) {
    
    if (!bIPhone) {
        
        iPadTouchUp(touch);
        
    } else {
        
        iPhoneTouchUp(touch);
        
    }
    
}



//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch) {
    
}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch) {
    
}

//--------------------------------------------------------------
void ofApp::lostFocus() {
    
}

//--------------------------------------------------------------
void ofApp::gotFocus() {
    
}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning() {
    
}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation) {
    
}


//--------------------------------------------------------------
void ofApp::audioRequested (float * output, int bufferSize, int nChannels) {
    
    synthMain.fillBufferOfFloats(output, bufferSize, nChannels);
    
}




//--------------------------------------------------------------
void ofApp::audioReceived(float * output, int bufferSize, int nChannels) {
    
}




//--------------------------------------------------------------
void ofApp::synthSetting() {
    
    float _volume = 0.9;
    
    ControlParameter _carrierPitch1 = synth[0].addParameter("carrierPitch1");
    float _amountMod1 = 1;
    ControlGenerator _rCarrierFreq1 = ControlMidiToFreq().input(_carrierPitch1);
    ControlGenerator _rModFreq1 = _rCarrierFreq1 * 2.5;
    Generator _modulationTone1 = SineWave().freq(_rModFreq1) * _rModFreq1 * _amountMod1;
    Generator _tone1 = SineWave().freq(_rCarrierFreq1 + _modulationTone1);
    ControlGenerator _envelopTrigger1 = synth[0].addParameter("trigger1");
    Generator _env1 = ADSR().attack(0.01).decay(0.3).sustain(0).release(0).trigger(_envelopTrigger1).legato(false);
    synth[0].setOutputGen(_tone1 * _env1 * _volume);
    
    ControlParameter _carrierPitch2 = synth[1].addParameter("carrierPitch2");
    float _amountMod2 = 1;
    ControlGenerator _rCarrierFreq2 = ControlMidiToFreq().input(_carrierPitch2);
    ControlGenerator _rModFreq2 = _rCarrierFreq2 * 3.489;
    Generator _modulationTone2 = SineWave().freq(_rModFreq2) * _rModFreq2 * _amountMod2;
    Generator _tone2 = SineWave().freq(_rCarrierFreq2 + _modulationTone2);
    ControlGenerator _envelopTrigger2 = synth[1].addParameter("trigger2");
    Generator _env2 = ADSR().attack(0.01).decay(0.1).sustain(0).release(0).trigger(_envelopTrigger2).legato(false);
    synth[1].setOutputGen(_tone2 * _env2 * _volume);
    
    ControlParameter _carrierPitch3 = synth[2].addParameter("carrierPitch3");
    float _amountMod3 = 12;
    ControlGenerator _rCarrierFreq3 = ControlMidiToFreq().input(_carrierPitch3);
    ControlGenerator _rModFreq3 = _rCarrierFreq3 * 14.489;
    Generator _modulationTone3 = SineWave().freq(_rModFreq3) * _rModFreq3 * _amountMod3;
    Generator _tone3 = SineWave().freq(_rCarrierFreq3 + _modulationTone3);
    ControlGenerator _envelopTrigger3 = synth[2].addParameter("trigger3");
    Generator _env3 = ADSR().attack(0.01).decay(0.1).sustain(0).release(0).trigger(_envelopTrigger3).legato(true);
    synth[2].setOutputGen(_tone3 * _env3 * _volume);
    
    ControlParameter _carrierPitch4 = synth[3].addParameter("carrierPitch4");
    float _amountMod4 = 18;
    ControlGenerator _rCarrierFreq4 = ControlMidiToFreq().input(_carrierPitch4);
    ControlGenerator _rModFreq4 = _rCarrierFreq4 * 1.1;
    Generator _modulationTone4 = SineWave().freq(_rModFreq4) * _rModFreq4 * _amountMod4;
    Generator _tone4 = SineWave().freq(_rCarrierFreq4 + _modulationTone4);
    ControlGenerator _envelopTrigger4 = synth[3].addParameter("trigger4");
    Generator _env4 = ADSR().attack(0.001).decay(0.1).sustain(0).release(0).trigger(_envelopTrigger4).legato(false);
    synth[3].setOutputGen(_tone4 * _env4 * _volume);
    
    ControlParameter _carrierPitch5 = synth[4].addParameter("carrierPitch5");
    float _amountMod5 = 6;
    ControlGenerator _rCarrierFreq5 = ControlMidiToFreq().input(_carrierPitch5);
    ControlGenerator _rModFreq5 = _rCarrierFreq5 * 1.489;
    Generator _modulationTone5 = SineWave().freq(_rModFreq5) * _rModFreq5 * _amountMod5;
    Generator _tone5 = SineWave().freq(_rCarrierFreq5 + _modulationTone5);
    ControlGenerator _envelopTrigger5 = synth[4].addParameter("trigger5");
    Generator _env5 = ADSR().attack(0.001).decay(0.1).sustain(0).release(0).trigger(_envelopTrigger5).legato(false);
    synth[4].setOutputGen(_tone5 * _env5 * _volume);
    
    ControlParameter _carrierPitch6 = synth[5].addParameter("carrierPitch6");
    float _amountMod6 = 2;
    ControlGenerator _rCarrierFreq6 = ControlMidiToFreq().input(_carrierPitch6);
    ControlGenerator _rModFreq6 = _rCarrierFreq6 * 1.109;
    Generator _modulationTone6 = SineWave().freq(_rModFreq6) * _rModFreq6 * _amountMod6;
    Generator _tone6 = SineWave().freq(_rCarrierFreq6 + _modulationTone6);
    ControlGenerator _envelopTrigger6 = synth[5].addParameter("trigger6");
    Generator _env6 = ADSR().attack(0.001).decay(0.1).sustain(0).release(0).trigger(_envelopTrigger6).legato(false);
    synth[5].setOutputGen(_tone6 * _env6 * _volume);
    
    ControlParameter _carrierPitch7 = synth[6].addParameter("carrierPitch7");
    float _amountMod7 = 4;
    ControlGenerator _rCarrierFreq7 = ControlMidiToFreq().input(_carrierPitch7);
    ControlGenerator _rModFreq7 = _rCarrierFreq7 * 3.109;
    Generator _modulationTone7 = SineWave().freq(_rModFreq7) * _rModFreq7 * _amountMod7;
    Generator _tone7 = SineWave().freq(_rCarrierFreq7 + _modulationTone7);
    ControlGenerator _envelopTrigger7 = synth[6].addParameter("trigger7");
    Generator _env7 = ADSR().attack(0.001).decay(0.2).sustain(0).release(0).trigger(_envelopTrigger7).legato(false);
    synth[6].setOutputGen(_tone7 * _env7 * _volume);
    
}






//--------------------------------------------------------------
void ofApp::scoreMake() {
    
    for (int i = 0; i < NUM_SYNTH_LINE; i++) {
        scoreNote[i].clear();
    }
    
    int _intervalDist = 1;
    int _Note[NUM_SYNTH_LINE];
    
    for (int i = 0; i < whitePixels.size(); i++) {
        
        vector<int> _bitNumber;
        _bitNumber.resize(NUM_SYNTH_LINE);
        
        int _indexLoop = ((i) % (whitePixels.size() - 1)) + 1;
        int _pixelNumbers = whitePixels[_indexLoop].pixelN;
        _bitNumber = convertDecimalToNBase(_pixelNumbers, baseSelection, (int)_bitNumber.size());
        
        for (int i = 0; i < NUM_SYNTH_LINE; i++) {
            _Note[i] = _bitNumber[i];;
        }
        
        for (int i = 0; i < NUM_SYNTH_LINE; i++) {
            if (abs(_Note[i] - oldNoteIndex[i]) >= _intervalDist) {
                scoreNote[i].push_back(_Note[i]);
            } else {
                scoreNote[i].push_back(-1);
            }
            oldNoteIndex[i] = _Note[i];
        }
        
    }
    
}




//--------------------------------------------------------------
void ofApp::trigScoreNote(vector<int> _vNote, ofxTonicSynth _synthIn, int _scoreCh) {
    
    int _indexLoop = ((noteIndex) % (whitePixels.size() - 1)) + 1;
    int _indexLoopOld = ((noteIndex + 1) % (whitePixels.size() - 1)) + 1;
    
    vector<int> _scoreNote = _vNote;
    ofxTonicSynth _synth = _synthIn;
    
    int _note = _scoreNote[_indexLoop];
    int _noteOld = _scoreNote[_indexLoopOld];
    
    int _scaledNote = scaleSetting.noteSelector(baseSelection, _scoreCh, _note);
    int _scaledNoteOld = scaleSetting.noteSelector(baseSelection, _scoreCh, _noteOld);
    
    
    string tName = "trigger" + ofToString(_scoreCh);
    string tPitch = "carrierPitch" + ofToString(_scoreCh);
    
    if (abs(_scaledNoteOld - _scaledNote) >= intervalDist) {
        if (_note > 0) {
            int _scaledNote = scaleSetting.noteSelector(baseSelection, _scoreCh, _note);
            _synth.setParameter(tName, 1);
            _synth.setParameter(tPitch, _scaledNote);
        }
    }
    
    
}



//--------------------------------------------------------------
vector<int> ofApp::convertDecimalToNBase(int n, int base, int size) {
    
    int i = 0, div, res;
    
    vector<int> a;
    a.clear();
    a.resize(size);
    
    div = n / base;
    res = n % base;
    a[i] = res;
    
    while (1) {
        if (div == 0) {
            break;
        } else {
            i++;
            res = div % base;
            div = div / base;
            a[i] = res;
        }
    }
    return a;
    
}
