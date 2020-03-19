// http://www.translatorscafe.com/cafe/units-converter/numbers/calculator/octal-to-decimal/

#include "ofApp.h"
#include <AVFoundation/AVFoundation.h>

#if TARGET_OS_SIMULATOR
#else
using namespace ofxCv;
using namespace cv;
#endif

#import <sys/utsname.h>


//--------------------------------------------------------------
void ofApp::activeAudioSilenceMode() {
    
    //    [[AVAudioSession sharedInstance] setDelegate:self];
    //    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: nil];
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    //    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
}


//--------------------------------------------------------------
void ofApp::setupColors() {
    
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
    
}


//--------------------------------------------------------------
void ofApp::setup() {
    
    ofSetOrientation(OF_ORIENTATION_DEFAULT);
    
    activeAudioSilenceMode();
    
    setupColors();
    
    frontCameraOnOff = true;

    baseSelection = 7;
    intervalDist = 1;

    if (WHITE_VIEW) {
        ofBackground(255);
    } else {
        ofBackground(backgroundColor);
    }
    
    ofSetFrameRate(60);
    ofEnableAlphaBlending();
    
    //    backgroundControPanel.load("controlBackground.png");
    
    safeZoneHeightFactor = iPhoneXDeviceScreenFactor();

    lineScoreStepSize = 23;
    lineScoreAreaSize.set(ofGetWidth(), 170);
    
    controlObjectLineWidth = 2;
    controlAreaSize.set(ofGetWidth(), 326);
    
    cameraViewSize.set(ofGetWidth(), ofGetHeight() - controlAreaSize.y - lineScoreAreaSize.y - 44 * 2 * safeZoneHeightFactor);

    setCamera();
    setImageBuffer();
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        bIPhone = true;
        setIPhone();
    } else {
        //        bIPhone = false;
        //        screenW = ofGetWidth();
        //        screenH = ofGetWidth() * 4.0 / 3.0;
    }
    setImageParameter();

    createSynthVoice();
    setSynthMain();
    
    ofSoundStreamSetup(2, 0, this, 44100, 256, 4);
    
    activeFactor = 0;
    activeSpeed = 0.1;
    
    menuImgSetup();
    
    importLibraryImg = false;
    libraryImportDone = false;
    
}


//--------------------------------------------------------------
void ofApp::setCamera() {
        
    #if TARGET_OS_SIMULATOR
        float _ratio = 360.0 / ofGetWidth();
        camSize.set(int(cameraViewSize.x * _ratio), int(cameraViewSize.y * _ratio));
    #else
        cam.setDeviceID(0);
        cam.setup(360, 480); // 4 : 3
        cam.setDesiredFrameRate(15);
        float _ratio = 360.0 / ofGetWidth();
        camSize.set(int(cameraViewSize.x * _ratio), int(cameraViewSize.y * _ratio));
    #endif

}


//--------------------------------------------------------------
void ofApp::setImageBuffer() {
        
    bufferImg.allocate(camSize.x, camSize.y, OF_IMAGE_GRAYSCALE);
    gray.allocate(camSize.x, camSize.y, OF_IMAGE_GRAYSCALE);
    edge.allocate(camSize.x, camSize.y, OF_IMAGE_GRAYSCALE);
    captureCamImg.setImageType(OF_IMAGE_COLOR_ALPHA);
    captureCamImg.allocate(camSize.x, camSize.y, OF_IMAGE_COLOR_ALPHA);
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        debugCameraImage.load("debug_layout_cat_e.jpg");
        debugCameraImage.setImageType(OF_IMAGE_GRAYSCALE);
    } else {
        //        debugCameraImage.load("debug_layout_cat_iPad.jpg");
    }
        
}


//--------------------------------------------------------------
void ofApp::setImageParameter() {
    
    cannyThreshold1 = 120;
    cannyThreshold2 = 120;
    grayThreshold = 120;

}


//--------------------------------------------------------------
void ofApp::setSynthMain() {
    
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
    
    // note music play
    index = 0;
    noteIndex = 0;
    
    for (int i = 0; i < NUM_SYNTH_LINE; i++) {
        oldNoteIndex[i] = 0;
    }
    
    bPlayNote = false;
    bCameraCapturePlay = false;
    
    scaleSetting.setup();
    
    touchPos.assign(2, ofVec2f());
    
}


//--------------------------------------------------------------
int ofApp::iPhoneXDeviceScreenFactor() {
    
    int _value = 0;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        float _height = [UIScreen mainScreen].nativeBounds.size.height;
        switch (int(_height)) {
            case 1136:
                //                cout << "IPHONE 5,5S,5C" << endl;
                _value = 0;
                break;
            case 1334:
                //                cout << "IPHONE 6,7,8 IPHONE 6S,7S,8S " << endl;
                _value = 0;
                break;
            case 1920:
            case 2208:
                _value = 0;
                //                cout << "IPHONE 6PLUS, 6SPLUS, 7PLUS, 8PLUS" << endl;
                break;
            case 2436:
                //                cout << "IPHONE 11 Pro, IPHONE X, IPHONE XS" << endl;
                _value = 3;
                break;
            case 2688:
                //                cout << "IPHONE 11 Pro Max, IPHONE XS_MAX" << endl;
                _value = 3;
                break;
            case 1792:
                //                cout << "IPHONE 11, IPHONE XR" << endl;
                _value = 2;
                break;
                //            default:
                //                cout << "UNDETERMINED" << endl;
        }
    }
    
    return _value;
    
}


//--------------------------------------------------------------
void ofApp::menuImgSetup() {
    
    capture.load("capture.png");
    
    float _w = ofGetWidth();
    float _h = ofGetHeight();
    float _scaleCapture = 0.05;
    
    composeMode.setFromCenter(_w * 0.5, _h * 0.85, capture.getWidth() * _scaleCapture, capture.getHeight() * _scaleCapture);
    
    importImg.load("photoLibrary.png");
    float _scaleImport = 0.05;
    libaryImport.setFromCenter(_w * 0.2, _h * 0.85, importImg.getWidth() * _scaleImport, importImg.getHeight() * _scaleImport);
    
    importCancleImg.load("cancleLibrary.png");
    float _scaleImportCacle = 0.05;
    libaryImportCancle.setFromCenter(_w * 0.9, _h * 0.05, importCancleImg.getWidth() * _scaleImportCacle, importCancleImg.getHeight() * _scaleImportCacle);
    
    cameraModeImg.load("cameraMode.png");
    float _scaleMode = 0.05;
    cameraMode.setFromCenter(_w * 0.2, _h * 0.85, cameraModeImg.getWidth() * _scaleMode, cameraModeImg.getHeight() * _scaleMode);
    
    changeCamera.load("cameraChange_1.png");
    float _scaleChange = 0.05;
    cameraChange.setFromCenter(_w * 0.8, _h * 0.85, changeCamera.getWidth() * _scaleChange, changeCamera.getHeight() * _scaleChange);
    
    returnCaptureMode.load("returnCameraMode.png");
    float _scaleReturn = 0.05;
    returnCapture.setFromCenter(_w * 0.5, _h * 0.85, returnCaptureMode.getWidth() * _scaleReturn, returnCaptureMode.getHeight() * _scaleReturn);
    
}


//--------------------------------------------------------------
void ofApp::setIPhone() {
        
    lineScoreAreaPosTopY = ofGetHeight() - controlAreaSize.y - lineScoreAreaSize.y - 44 * 1 * safeZoneHeightFactor;
        
    pixelStepS = 4;
    changedCamSize = camSize.x / pixelStepS;  // 90
    thresholdValue = 80;
    
    cameraScreenRatio = cameraViewSize.x / camSize.x; // 1.77777777
    
    pixelCircleSize = 4; // 4
    ctrlRectS = 34;
    lineScoreStepX = ofGetWidth() / float(lineScoreStepSize - 1);
    lineScoreStepY = 1.6;  // 1.6
    pixeShapeSize = 0.4167; // 0.4167
    
    setInterfacePosition();
    
}


//--------------------------------------------------------------
void ofApp::setInterfacePosition() {
    
    controlAreaPosTopY = ofGetHeight() - controlAreaSize.y;
    
    float _screenWStepsize = ofGetWidth() * 1.0 / 6.0;
    
    setSpeedCtrl(_screenWStepsize, controlAreaSize);
    setIntervalCtrl(_screenWStepsize, controlAreaSize);
    setBase(_screenWStepsize);

}


//--------------------------------------------------------------
void ofApp::setSpeedCtrl(float _screenWStepsize, ofVec2f _controlAreaSize) {
    
    speedCSize = ctrlRectS * 1.4;
    bSpeedCtrl = false;
    float _posX = _screenWStepsize * 5.25;
    float _lineLengthRatio = _controlAreaSize.y * 0.35;

    speedPos = ofPoint(_posX, controlAreaPosTopY + _controlAreaSize.y * 0.5);
    speedLineLength = ofPoint(speedPos.y - _lineLengthRatio, speedPos.y + _lineLengthRatio);

}


//--------------------------------------------------------------
void ofApp::setIntervalCtrl(float _screenWStepsize, ofVec2f _controlAreaSize) {
 
    intervalSize = ctrlRectS * 0.9;
    bthresholdCtrl = false;
    float _posX = _screenWStepsize * 0.75;
    float _lineLengthRatio = _controlAreaSize.y * 0.35;

    intervalPos = ofPoint(_posX, controlAreaPosTopY + _controlAreaSize.y * 0.5);
    intervalLineLength = ofPoint(intervalPos.y - _lineLengthRatio, intervalPos.y + _lineLengthRatio);

}


//--------------------------------------------------------------
void ofApp::setBase(float _screenWStepsize) {
    
    baseSize = ctrlRectS * 0.85;
    float _basePosLeft = _screenWStepsize * 1.75;
    float _basePosRight = _screenWStepsize * 4.25;
    
    base4Pos = ofPoint(_basePosLeft, controlAreaPosTopY + controlAreaSize.y * 1.0 / 4.0);
    base5Pos = ofPoint(_basePosLeft, controlAreaPosTopY + controlAreaSize.y * 2.0 / 4.0);
    base6Pos = ofPoint(_basePosLeft, controlAreaPosTopY + controlAreaSize.y * 3.0 / 4.0);
    base7Pos = ofPoint(_basePosRight, controlAreaPosTopY + controlAreaSize.y * 1.0 / 4.0);
    base8Pos = ofPoint(_basePosRight, controlAreaPosTopY + controlAreaSize.y * 2.0 / 4.0);
    base9Pos = ofPoint(_basePosRight, controlAreaPosTopY + controlAreaSize.y * 3.0 / 4.0);

}


//--------------------------------------------------------------
void ofApp::update() {
    
#if TARGET_OS_SIMULATOR
        
    captureCamImg.setFromPixels(debugCameraImage.getPixels().getData(), camSize.x, camSize.y, OF_IMAGE_COLOR_ALPHA);

    if (captureCamImg.isAllocated()) {
        calculatePixels(captureCamImg);
    }
    
#else
    
    if (importLibraryImg) {
        if (libraryImg.getImageUpdated()) {
            ofImage _buffImg;
            _buffImg.allocate(libraryImg.getWidth(), libraryImg.getHeight(), OF_IMAGE_COLOR_ALPHA);
            _buffImg.setFromPixels(libraryImg.getPixels(), libraryImg.getWidth(), libraryImg.getHeight(), OF_IMAGE_COLOR_ALPHA);
            _buffImg.resize(cam.getWidth(), cam.getHeight());
            captureCamImg.setFromPixels(_buffImg.getPixels().getData(), camSize.x, camSize.y, OF_IMAGE_COLOR_ALPHA);
            
            libraryImg.close();
            calculatePixels(captureCamImg);
            libraryImportDone = true;
        }
    } else {
        cam.update();
        
        if (cam.isFrameNew()) {
            captureCamImg.setFromPixels(cam.getPixels().getData(), camSize.x, camSize.y, OF_IMAGE_COLOR);
            calculatePixels(captureCamImg);
        }
    }
    
#endif
    
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
    
#if TARGET_OS_SIMULATOR
    
    edge.setFromPixels(_img.getPixels().getData(), camSize.x, camSize.y, OF_IMAGE_GRAYSCALE);
    
#else
    
    convertColor(_img, gray, CV_RGB2GRAY);
    threshold(gray, gray, grayThreshold);
    //                erode(gray);
    
    Canny(gray, edge, cannyThreshold1, cannyThreshold2, 3);
    thin(edge);
    
    if (WHITE_VIEW) {
        invert(edge);
    }
    
#endif
    
    edge.update();
    
    if (bCameraCapturePlay) {
        noteIndex = index;
    } else {
        noteIndex = 0;
        ofImage _tImage;
        
        pixelBright.clear();
        whitePixels.clear();
        blackPixels.clear();
        
        unsigned char * _src = edge.getPixels().getData();
        
//        if (!bIPhone) {
//            _src = edge.getPixels().getData();
//        } else {
//            //            edge.rotate90(-1);
//            _src = edge.getPixels().getData();
//        }
        
        for (int j = 0; j < camSize.y; j += pixelStepS) {
            for (int i = 0; i < camSize.x; i += pixelStepS) {
                int _index = i + j * camSize.x;
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
    
    drawIPhone();
    
#if TARGET_OS_SIMULATOR
    debugRatioLayout();
#endif
    
}


//--------------------------------------------------------------
void ofApp::debugRatioLayout() {
    
    ofPushStyle();
    
    // safeZone
    // iPhone X Pro Max  = x 3
    ofSetColor(255, 0, 0);
    ofDrawBitmapString(ofToString(ofGetHeight()), 10, 100);
    
    int xProMaxSafeZonePixelHeight = 44 * safeZoneHeightFactor;
    float upSafeZoneY = xProMaxSafeZonePixelHeight;
    ofDrawLine(0, upSafeZoneY, ofGetWidth(), upSafeZoneY);
    
    float dnSafeZoneY = ofGetHeight() - xProMaxSafeZonePixelHeight;
    ofDrawLine(0, dnSafeZoneY, ofGetWidth(), dnSafeZoneY);
    
    float interfaceZoneHeight = ofGetHeight() - xProMaxSafeZonePixelHeight - 500;
    ofDrawLine(0, interfaceZoneHeight, ofGetWidth(), interfaceZoneHeight);
    
    //    ofSetColor(255, 30);
    //    ofDrawRectangle(0, 0, ofGetWidth(), ofGetHeight());
    //
    //    ofSetColor(120, 255, 120);
    //    ofDrawLine(0, ofGetHeight() * 0.125 * 5, ofGetWidth(), ofGetHeight() * 0.125 * 5);
    //    ofDrawLine(0, ofGetHeight() * 0.125 * 6.5, ofGetWidth(), ofGetHeight() * 0.125 * 6.5);
    //
    //    ofSetColor(120, 255, 120);
    //    for (int i = 0; i < 5; i++) {
    //        ofDrawLine(ofGetWidth() * 0.2 * i, 0, ofGetWidth() * 0.2 * i, ofGetHeight());
    //    }
    //
    //    ofSetColor(255, 180, 120);
    //    for (int i = 0; i < 3; i++) {
    //        ofDrawLine(ofGetWidth() * 0.33333 * i, 0, ofGetWidth() * 0.33333 * i, ofGetHeight());
    //    }
    
    ofPopStyle();
    
}


//--------------------------------------------------------------
void ofApp::debugLayout() {
    
    ofPushStyle();
    
    ofSetColor(255, 30);
    ofDrawRectangle(0, 0, ofGetWidth(), ofGetHeight());
    
    ofSetColor(120, 255, 120);
    ofDrawLine(0, ofGetHeight() * 0.125 * 5, ofGetWidth(), ofGetHeight() * 0.125 * 5);
    ofDrawLine(0, ofGetHeight() * 0.125 * 6.5, ofGetWidth(), ofGetHeight() * 0.125 * 6.5);
    
    ofSetColor(120, 255, 120);
    for (int i = 0; i < 5; i++) {
        ofDrawLine(ofGetWidth() * 0.2 * i, 0, ofGetWidth() * 0.2 * i, ofGetHeight());
    }
    
    ofSetColor(255, 180, 120);
    for (int i = 0; i < 3; i++) {
        ofDrawLine(ofGetWidth() * 0.33333 * i, 0, ofGetWidth() * 0.33333 * i, ofGetHeight());
    }
    
    ofPopStyle();
    
}   


//--------------------------------------------------------------
void ofApp::mainCameraCaptureViewiPhone() {
    
    realtimeCameraConvertedImageView();
    realtimeBufferImageView();
    
    ofPushMatrix();

    drawIPhoneTrianglePixel();
        
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
void ofApp::realtimeCameraConvertedImageView() {
      
    ofPushMatrix();
    
    ofTranslate(0, 44 * 1 * safeZoneHeightFactor);
    
    ofPushStyle();
    if (!bCameraCapturePlay) {
        if (WHITE_VIEW) {
            ofSetColor(255, 255);
        } else {
            ofSetColor(contourLineColor, 120);
        }
        
        ofPushMatrix();
        edge.draw(0, 0, cameraViewSize.x + 1, cameraViewSize.y + 1);
        ofPopMatrix();
    }
    ofPopStyle();
    
    ofPopMatrix();
    
}


//--------------------------------------------------------------
void ofApp::realtimeBufferImageView() {
    
    ofPushMatrix();

    ofTranslate(0, 44 * 1 * safeZoneHeightFactor);

    ofPushStyle();
    if (bCameraCapturePlay) {
        if (WHITE_VIEW) {
            ofSetColor(255, 120);
        } else {
            ofSetColor(contourLineColor, 180);
        }
        
        bufferImg.draw(0, 0, cameraViewSize.x + 1, cameraViewSize.y + 1);
    }
    ofPopStyle();

    ofPopMatrix();

}


//--------------------------------------------------------------
void ofApp::drawIPhone() {
    
    drawLineScoreIPhone(bCameraCapturePlay);
    
    mainCameraCaptureViewiPhone();
    
    drawIPhoneBaseLineLayout();
    
    drawControlElementIPhone(bCameraCapturePlay);
    
    drawBaseInterface(bCameraCapturePlay);
    
    menuImgDraw(bCameraCapturePlay);
    
}


//--------------------------------------------------------------
void ofApp::drawIPhoneBaseLineLayout() {
    
    ofPushMatrix();
    ofTranslate(0, lineScoreAreaPosTopY);
    
    ofPushStyle();
    
    ofSetColor(uiLineColor, 180);
    ofDrawLine(0, 0, ofGetWidth(), 0);
    
    ofSetColor(uiLineColor, 120);
    ofDrawLine(ofGetWidth() * 0.5, 0, ofGetWidth() * 0.5, lineScoreAreaSize.y);
    
    ofSetColor(uiLineColor, 180);
    ofDrawLine(0, lineScoreAreaSize.y, ofGetWidth(), lineScoreAreaSize.y);
    
    ofPopStyle();
    
    ofPopMatrix();

}


//--------------------------------------------------------------
void ofApp::menuImgDraw(bool playOn) {
    
    ofPushStyle();
    
    if (playOn) {
        returnCaptureMode.draw(returnCapture);
    } else {
        if (importLibraryImg) {
            cameraModeImg.draw(cameraMode);
            importCancleImg.draw(libaryImportCancle);
        } else {
            importImg.draw(libaryImport);
        }
        capture.draw(composeMode);
        changeCamera.draw(cameraChange);
    }
    
    
    ofPopStyle();
    
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
        ofDrawLine(intervalPos.x, intervalLineLength.x, intervalPos.x, intervalLineLength.y);
        
        //    float _speedY = speedPos.y;
        ofDrawLine(speedPos.x, speedLineLength.x, speedPos.x, speedLineLength.y);
        
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
        //    ofPoint _lineUpS = ofPoint(screenW - cameraViewSize, screenPosLeftY);
        //    ofPoint _lineUpE = ofPoint(screenW - cameraViewSize, screenPosRightY);
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
        //    ofPoint _lineME = ofPoint(screenW - cameraViewSize - 10, (screenPosRightY + screenPosLeftY) * 0.5);
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
    float _sX = speedPos.x;
    float _sY = speedPos.y;
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
void ofApp::drawLineScoreIPhone(bool playOn) {
    
    if (playOn) {
        ofPushMatrix();
        
        //     FIXME: 40 pixel Translate
        ofTranslate(0, lineScoreAreaPosTopY - 40);
        
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
    
    int _offsetXPos = lineScoreStepX * (lineScoreStepSize - 1);
    
    ofColor _c = colorVar[scoreCh - 1];
    
    if (vNote.size() > 0) {
        drawCircle(_c, lineScoreStepSize, vNote, lineScoreStepX, lineScoreStepY, scoreCh, _offsetXPos);
        drawLine(_c, lineScoreStepSize, vNote, lineScoreStepX, lineScoreStepY, scoreCh, _offsetXPos);
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
void ofApp::exit() {
    
    //    cam.close();
    //    std::exit(0);
    
}


//--------------------------------------------------------------
void ofApp::iPhoneTouchDown(ofTouchEventArgs & touch) {
    
    float _tolerance = 2 * 0.642857;
    
    ofPoint _chgdTouch = ofPoint(touch.x, touch.y);
    
    touchPos[touch.id] = _chgdTouch;
    
    distS[touch.id] = ofDist(speedPos.x, speedPos.y , touchPos[touch.id].x, touchPos[touch.id].y);
    
    if (bCameraCapturePlay) {
        for (int i = 0; i < 2; i++) {
            float _distS = ofDist(speedPos.x, speedPos.y , touchPos[i].x, touchPos[i].y);
            
            if ((_distS < speedCSize * _tolerance) && bSpeedCtrl == false) {
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
    }
    
    if (touch.id == 0) {
        
        //        float _distS = ofDist(speedPos.x, speedPos.y , _chgdTouch.x, _chgdTouch.y);
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
        
//        float _xL = screenPosLeftY;
//        float _xR = screenPosLeftY + cameraViewSize;
//        if ((_chgdTouch.x > (screenW - cameraViewSize)) && (_chgdTouch.x < screenW) && (_chgdTouch.y < _xR) && (_chgdTouch.y > _xL)) {
//            grayThreshold = 120;
//            touchDownDefault = _chgdTouch.x;
//        }

        if ((_chgdTouch.y < cameraViewSize.y) && (_chgdTouch.y > 0)) {
            grayThreshold = 120;
            touchDownDefault = _chgdTouch.x;
        }

    }
    
    if (bCameraCapturePlay) {
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
    
}


//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch) {
    
    iPhoneTouchDown(touch);
    
}


//--------------------------------------------------------------
void ofApp::iPhoneTouchMoved(ofTouchEventArgs & touch) {
    
    ofPoint _chgdTouch = ofPoint(touch.x, touch.y);
    
    touchPos[touch.id] = _chgdTouch;
    
    //    if (bSpeedCtrl) {
    //        float _minX = ofGetWidth() * 0.15;
    //        float _maxX = screenW * 0.9;
    //        if ((touchPos[touch.id].x > _minX) && (touchPos[touch.id].x < _maxX) && touchPos[touch.id].y > screenPosRightY) {
    //            speedPos.x = touchPos[touch.id].x;
    //            float _tempo = ofMap(speedPos.x, _minX, _maxX, minSpeed, maxSpeed);
    //            synthMain.setParameter("tempo", _tempo);
    //        }
    //    }
    
    if (bSpeedCtrl) {
        float _minY = speedLineLength.x;
        float _maxY = speedLineLength.y;
        
        if ((touchPos[touch.id].y > _minY) && (touchPos[touch.id].y < _maxY) && touchPos[touch.id].x > ofGetWidth() * 0.8) {
            speedPos.y = touchPos[touch.id].y;
            float _tempo = ofMap(speedPos.y, _minY, _maxY, maxSpeed, minSpeed);
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
        float _minY = intervalLineLength.x;
        float _maxY = intervalLineLength.y;
        
        if ((touchPos[touch.id].y > _minY) && (touchPos[touch.id].y < _maxY) && touchPos[touch.id].x < ofGetWidth() * 0.2) {
            intervalPos.y = touchPos[touch.id].y;
            float _interval = ofMap(intervalPos.y, _minY, _maxY, 0, 20);
            intervalDist = _interval;
        }
    }
    
    //    if (touch.id == 0) {
    //        float _xL = screenPosLeftY;
    //        float _xR = screenPosLeftY + cameraViewSize;
    //        if ((_chgdTouch.x > (screenW - cameraViewSize)) && (_chgdTouch.x < screenW) && (_chgdTouch.y < _xR) && (_chgdTouch.y > _xL)) {
    //            grayThreshold = 120 + (_chgdTouch.x - touchDownDefault);
    //        }
    //    }
    
    if (_chgdTouch.y < cameraViewSize.y) {
        grayThreshold = 120 + (_chgdTouch.y - touchDownDefault);
    }
    
}


//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch) {
    
    iPhoneTouchMoved(touch);
    
}


//--------------------------------------------------------------
void ofApp::iPhoneTouchUp(ofTouchEventArgs & touch) {
    
    ofPoint _chgdTouch = ofPoint(touch.x, touch.y);
    if (composeMode.inside(_chgdTouch)) {
        if ((whitePixels.size() > 2) && (touch.id == 0)) {
            bCameraCapturePlay = !bCameraCapturePlay;
            bufferImg = edge;
            
            if (!bCameraCapturePlay) {
                index = 0;
                ofRemoveListener(*metroOut, this, &ofApp::triggerReceive);
                bPlayNote = false;
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
    
    if (!bPlayNote && cameraChange.inside(_chgdTouch)) {
        frontCameraOnOff = !frontCameraOnOff;
        
#if TARGET_OS_SIMULATOR
#else
        if (frontCameraOnOff) {
            cam.setDeviceID(0);
            cam.setup(480, 360);
            cam.setDesiredFrameRate(15);
            camSize.set(cam.getWidth(), cam.getHeight()); // 360
        } else {
            cam.setDeviceID(1);
            cam.setup(480, 360);
            cam.setDesiredFrameRate(15);
            camSize.set(cam.getWidth(), cam.getHeight()); // 360
        }
        
#endif
        
    }
    
    if (!bPlayNote && libaryImport.inside(_chgdTouch)) {
        //        if (!bPlayNote) {
        libraryImg.openLibrary();
        importLibraryImg = true;
        //            importLibraryImg = false;
        //        }
    }
    
    //    if (importLibraryImg && libaryImport.inside(_chgdTouch)) {
    //        if (!bCameraCapturePlay) {
    //            cout << "open" << endl;
    //            libraryImg.openLibrary();
    //            importLibraryImg = false;
    //        }
    ////        importLibraryImg = false;
    ////        libraryImportDone = false;
    //    }
    
    if (libaryImportCancle.inside(_chgdTouch)) {
        //        libraryImg.openLibrary();
        if (!bCameraCapturePlay) {
            //            cout << "open" << endl;
            importLibraryImg = false;
        }
    }
    
    //    if ((_chgdTouch.x < lineScoreRightX) && (_chgdTouch.x > 0) && (_chgdTouch.y > screenPosLeftY) && (_chgdTouch.y < screenPosRightY) && bCameraCapturePlay) {
    //
    //        bPlayNote = !bPlayNote;
    //
    //        if (!bPlayNote) {
    //            ofRemoveListener(*metroOut, this, &ofApp::triggerReceive);
    //        } else {
    //            ofAddListener(*metroOut, this, &ofApp::triggerReceive);
    //        }
    //
    //    }
    //
    
    float _tolerance = 2;
    
    distS[touch.id] = ofDist(speedPos.x, speedPos.y , touchPos[touch.id].x, touchPos[touch.id].y);
    
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
    
    iPhoneTouchUp(touch);
    
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
void ofApp::audioRequested(float * output, int bufferSize, int nChannels) {
    synthMain.fillBufferOfFloats(output, bufferSize, nChannels);
}

//--------------------------------------------------------------
void ofApp::audioReceived(float * output, int bufferSize, int nChannels) {
    
}

//--------------------------------------------------------------
void ofApp::createSynthVoice() {
    
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
