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
void ofApp::setup() {
    
    ofSetOrientation(OF_ORIENTATION_DEFAULT);
    
    activeAudioSilenceMode();
    
    setupColors();
    
    frontCameraOnOff = true;
    
    baseSelection = 7;
    intervalDist = 1;
    
    ofBackground(backgroundColor);
    
    ofSetFrameRate(60);
    ofEnableAlphaBlending();
    
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
    
    setInterfacePosition();
    
    setImageParameter();
    
    createSynthVoice();
    
    setSynthMain();
    
    ofSoundStreamSetup(2, 0, this, 44100, 256, 4);
    
    activeFactor = 0;
    activeSpeed = 0.1;
    
    menuImgSetup();
    
    importLibraryImg = false;
    libraryImportDone = false;
    
    bthresholdCtrl = false;
    
}


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
    
    colorVar[0] = ofColor(192, 25, 30) * 1.5;
    colorVar[1] = ofColor(79, 185, 73) * 1.5;
    colorVar[2] = ofColor(255, 172, 0) * 1.5;
    colorVar[3] = ofColor(68, 128, 173) * 1.5;
    colorVar[4] = ofColor(58, 193, 197) * 1.5;
    colorVar[5] = ofColor(249, 154, 249) * 1.5;
    colorVar[6] = ofColor(142, 82, 137) * 1.5;
    
    backgroundColor = ofColor(13, 13, 15);
    
    contourLineColor = ofColor(230, 221, 193);
    eventColor = ofColor(230, 221, 193);
    uiLineColor = ofColor(230, 221, 193);
    
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
void ofApp::setCamera() {
    
#if TARGET_OS_SIMULATOR
    float _ratio = 360.0 / ofGetWidth();
    camSize.set(int(cameraViewSize.x * _ratio), int(cameraViewSize.y * _ratio));
#else
    settingCamera(0);
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
    
}


//--------------------------------------------------------------
void ofApp::setInterfacePosition() {
    
    float _ctrlAreaPosTopY = ofGetHeight() - controlAreaSize.y;
    float _screenWStepsize = ofGetWidth() * 1.0 / 6.0;
    
    setSpeedCtrl(_ctrlAreaPosTopY, _screenWStepsize, controlAreaSize);
    setIntervalCtrl(_ctrlAreaPosTopY, _screenWStepsize, controlAreaSize);
    setBase(_ctrlAreaPosTopY, _screenWStepsize);
    
}


//--------------------------------------------------------------
void ofApp::setSpeedCtrl(float _topY, float _screenWStepsize, ofVec2f _ctrlAreaSize) {
    
    speedCSize = ctrlRectS * 1.4;
    bSpeedCtrl = false;
    float _x = _screenWStepsize * 5.25;
    float _lineLengthRatio = _ctrlAreaSize.y * 0.35;
    
    speedPos = ofPoint(_x, _topY + _ctrlAreaSize.y * 0.5 - 44 * safeZoneHeightFactor);
    speedLineLength = ofPoint(speedPos.y - _lineLengthRatio, speedPos.y + _lineLengthRatio);
    
}


//--------------------------------------------------------------
void ofApp::setIntervalCtrl(float _topY, float _screenWStepsize, ofVec2f _ctrlAreaSize) {
    
    intervalSize = ctrlRectS * 0.9;
    float _x = _screenWStepsize * 0.75;
    float _lineLengthRatio = _ctrlAreaSize.y * 0.35;
    
    intervalPos = ofPoint(_x, _topY + _ctrlAreaSize.y * 0.5 - 44 * safeZoneHeightFactor);
    intervalLineLength = ofPoint(intervalPos.y - _lineLengthRatio, intervalPos.y + _lineLengthRatio);
    
}


//--------------------------------------------------------------
void ofApp::setBase(float _topY, float _screenWStepsize) {
    
    baseSize = ctrlRectS * 0.85;
    float _basePosLeft = _screenWStepsize * 1.75;
    float _basePosRight = _screenWStepsize * 4.25;
    float _offSetY = _topY - 44 * safeZoneHeightFactor;
    
    base4Pos = ofPoint(_basePosLeft, controlAreaSize.y * 1.0 / 4.0 + _offSetY);
    base5Pos = ofPoint(_basePosLeft, controlAreaSize.y * 2.0 / 4.0 + _offSetY);
    base6Pos = ofPoint(_basePosLeft, controlAreaSize.y * 3.0 / 4.0 + _offSetY);
    base7Pos = ofPoint(_basePosRight, controlAreaSize.y * 1.0 / 4.0 + _offSetY);
    base8Pos = ofPoint(_basePosRight, controlAreaSize.y * 2.0 / 4.0 + _offSetY);
    base9Pos = ofPoint(_basePosRight, controlAreaSize.y * 3.0 / 4.0 + _offSetY);
    
}


//--------------------------------------------------------------
void ofApp::setImageParameter() {
    
    cannyThreshold1 = 120;
    cannyThreshold2 = 120;
    grayThreshold = 120;
    
}


//--------------------------------------------------------------
void ofApp::createSynthVoice() {
    
    float _volume = 0.9;
    ControlParameter _s0 = synth[0].addParameter("carrierPitch1");
    Generator _tone0 = addGenerator(_s0, 2.5, 1);
    ControlParameter _t0 = synth[0].addParameter("trigger1");
    Generator _env0 = ADSR().attack(0.01).decay(0.3).sustain(0).release(0).trigger(_t0).legato(false);
    synth[0].setOutputGen(_tone0 * _env0 * _volume);
    
    ControlParameter _s1 = synth[1].addParameter("carrierPitch2");
    Generator _tone1 = addGenerator(_s1, 3.489, 1);
    ControlParameter _t1 = synth[1].addParameter("trigger2");
    Generator _env1 = ADSR().attack(0.01).decay(0.1).sustain(0).release(0).trigger(_t1).legato(false);
    synth[1].setOutputGen(_tone1 * _env1 * _volume);
    
    ControlParameter _s2 = synth[2].addParameter("carrierPitch3");
    Generator _tone2 = addGenerator(_s2, 14.489, 12);
    ControlParameter _t2 = synth[2].addParameter("trigger3");
    Generator _env2 = ADSR().attack(0.01).decay(0.1).sustain(0).release(0).trigger(_t2).legato(true);
    synth[2].setOutputGen(_tone2 * _env2 * _volume);
    
    ControlParameter _s3 = synth[3].addParameter("carrierPitch4");
    Generator _tone3 = addGenerator(_s3, 1.1, 18);
    ControlParameter _t3 = synth[3].addParameter("trigger4");
    Generator _env3 = ADSR().attack(0.001).decay(0.1).sustain(0).release(0).trigger(_t3).legato(false);
    synth[3].setOutputGen(_tone3 * _env3 * _volume);
    
    ControlParameter _s4 = synth[4].addParameter("carrierPitch5");
    Generator _tone4 = addGenerator(_s4, 1.489, 6);
    ControlParameter _t4 = synth[4].addParameter("trigger5");
    Generator _env4 = ADSR().attack(0.001).decay(0.1).sustain(0).release(0).trigger(_t4).legato(false);
    synth[4].setOutputGen(_tone4 * _env4 * _volume);
    
    ControlParameter _s5 = synth[5].addParameter("carrierPitch6");
    Generator _tone5 = addGenerator(_s5, 1.109, 2);
    ControlParameter _t5 = synth[5].addParameter("trigger6");
    Generator _env5 = ADSR().attack(0.001).decay(0.1).sustain(0).release(0).trigger(_t5).legato(false);
    synth[5].setOutputGen(_tone5 * _env5 * _volume);
    
    ControlParameter _s6 = synth[6].addParameter("carrierPitch7");
    Generator _tone6 = addGenerator(_s6, 3.109, 4);
    ControlParameter _t6 = synth[6].addParameter("trigger7");
    Generator _env6 = ADSR().attack(0.001).decay(0.2).sustain(0).release(0).trigger(_t6).legato(false);
    synth[6].setOutputGen(_tone6 * _env6 * _volume);
    
}


//--------------------------------------------------------------
Generator ofApp::addGenerator(ControlParameter _carrierPitch, float _addFq, float _amountMod) {
    
    ControlGenerator _rCarrierFreq = ControlMidiToFreq().input(_carrierPitch);
    ControlGenerator _rModFreq = _rCarrierFreq * _addFq;
    Generator _modulationTone = SineWave().freq(_rModFreq) * _rModFreq * _amountMod;
    
    return SineWave().freq(_rCarrierFreq + _modulationTone);
    
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
    
    thresholdImg.load("threshold.png");
    float _scaleThreshold = 0.05;
    thresholdRect.setFromCenter(_w * 0.1, lineScoreAreaPosTopY * 0.5, thresholdImg.getWidth() * _scaleThreshold, thresholdImg.getHeight() * _scaleThreshold);

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
            libraryImportDone = true;
        }
    } else {
        cam.update();
        
        if (cam.isFrameNew()) {
            captureCamImg.setFromPixels(cam.getPixels().getData(), camSize.x, camSize.y, OF_IMAGE_COLOR);
        }
    }
    
    calculatePixels(captureCamImg);
    
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
            int _whitePixel = 0;
            
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
void ofApp::draw() {
    
    drawIPhone();
    
#if TARGET_OS_SIMULATOR
    debugRatioLayout();
#endif
    
}


//--------------------------------------------------------------
void ofApp::drawIPhone() {
    
    mainCameraCaptureViewiPhone();
    
    if (bCameraCapturePlay) {
        drawLineScoreIPhone();
    }
    
    drawIPhoneBaseLineLayout();
    
    drawControlElementIPhone(bCameraCapturePlay);
    
    drawBaseInterface(bCameraCapturePlay);
    
    menuImgDraw(bCameraCapturePlay);

    drawThresholdInterface(bCameraCapturePlay);
    
//    ofPushMatrix();
////    ofTranslate(thresholdCPos);
//    thresholdImg.draw(thresholdRect);
//    ofPopMatrix();
    
}


//--------------------------------------------------------------
void ofApp::drawLineScoreIPhone() {
    
    ofPushMatrix();
    ofPushStyle();
    
    ofTranslate(0, lineScoreAreaPosTopY);
    ofSetColor(0, 255);
    
    ofDrawRectangle(0, 0, lineScoreAreaSize.x, lineScoreAreaSize.y);
    
    ofPopMatrix();
    
    ofPushMatrix();
    //     FIXME: ??? 40 pixel Translate
    ofTranslate(0, lineScoreAreaPosTopY - 40);
    for (int i = 0; i < NUM_SYNTH_LINE; i++) {
        drawScoreCircleLineIPhone(scoreNote[i], i + 1);
    }
    ofPopMatrix();
    ofPopStyle();
    
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
void ofApp::mainCameraCaptureViewiPhone() {
    
    realtimeCameraConvertedImageView();
    realtimeBufferImageView();
    
    ofPushMatrix();
    
    drawIPhoneTrianglePixel();
    
    if (bCameraCapturePlay) {
        
        drawPixelNumbersCircleNotes();
        
        for (int i = 0; i < NUM_SYNTH_LINE; i++) {
            drawPixelAllNoteShapesIPhone(scoreNote[i], i + 1);
            drawPlayingShapeNote(scoreNote[i], i + 1);
        }
        
    }
    
    ofPopMatrix();
    
}


//--------------------------------------------------------------
void ofApp::realtimeCameraConvertedImageView() {
    
    ofPushMatrix();
    
    ofTranslate(0, 44 * 1 * safeZoneHeightFactor);
    
    ofPushStyle();
    if (!bCameraCapturePlay) {
        ofSetColor(contourLineColor, 180);
        
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
        ofSetColor(contourLineColor, 200);
        
        bufferImg.draw(0, 0, cameraViewSize.x + 1, cameraViewSize.y + 1);
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
        ofSetColor(contourLineColor, 180);
    } else {
        ofSetColor(contourLineColor, 255);
    }
    
    //    ofEnableAntiAliasing();
    
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
void ofApp::drawPixelNumbersCircleNotes() {
    
    int _pixelSize = pixelCircleSize;
    float _ellipseSizeR = 0.7;
    
    ofPushMatrix();
    ofPushStyle();
    //    ofEnableAntiAliasing();
    
    ofSetColor(255, 180);
    ofNoFill();
    ofSetColor(eventColor, 80);
    
    if (whitePixels.size() > 1) {
        
        int _noteLoopIndex = ((noteIndex) % (whitePixels.size() - 1)) + 1;
        int _pixelNumbers = whitePixels[_noteLoopIndex].pixelN;
        int _idPixels = whitePixels[_noteLoopIndex].indexPos - _pixelNumbers;
        
        for (int i = 0; i < _pixelNumbers; i++) {
            
            float _xS = ((_idPixels + i) % (int)changedCamSize) * pixelStepS * cameraScreenRatio;
            float _yS = (int)((_idPixels + i) / (int)changedCamSize) * pixelStepS * cameraScreenRatio;
            
            ofDrawCircle(_xS, _yS, _pixelSize * _ellipseSizeR);
            
        }
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
}


//--------------------------------------------------------------
void ofApp::drawPixelAllNoteShapesIPhone(vector<int> _vNote, int _scoreCh) {
    
    ofPushMatrix();
    ofPushStyle();
    //    ofEnableAntiAliasing();
    
    ofSetColor(255, 120);
    
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
void ofApp::drawPlayingShapeNote(vector<int> _vNote, int _scoreCh) {
    
    ofPushMatrix();
    ofPushStyle();
    
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
                float _size = _scaledNote * pixeShapeSize;
                drawShapeWithCenterlinesColorRotation(_p, baseSelection, _size, _c);
            }
        }
        
    }
    
    ofPopStyle();
    ofPopMatrix();
    
}


//--------------------------------------------------------------
void ofApp::drawIPhoneBaseLineLayout() {
    
    ofPushMatrix();
    ofTranslate(0, lineScoreAreaPosTopY);
    
    ofPushStyle();
    
    ofSetColor(uiLineColor, 255);
    ofDrawLine(0, 0, ofGetWidth(), 0);
    
    ofSetColor(uiLineColor, 255);
    ofDrawLine(ofGetWidth() * 0.5, 0, ofGetWidth() * 0.5, lineScoreAreaSize.y);
    
    ofSetColor(uiLineColor, 255);
    ofDrawLine(0, lineScoreAreaSize.y, ofGetWidth(), lineScoreAreaSize.y);
    
    ofPopStyle();
    
    ofPopMatrix();
    
}


//--------------------------------------------------------------
void ofApp::drawControlElementIPhone(bool playOn) {
    
    if (playOn) {
        
        ofPushMatrix();
        
        ofTranslate(0, 0);
        
        ofPushStyle();
        
        ofSetColor(uiLineColor);
        
        ofDrawLine(intervalPos.x, intervalLineLength.x, intervalPos.x, intervalLineLength.y);
        ofDrawLine(speedPos.x, speedLineLength.x, speedPos.x, speedLineLength.y);
        
        ofPopStyle();
        ofPopMatrix();
        
        drawElemSpeedShape();
        drawElemIntervalShape();
        
    }
    
}


//--------------------------------------------------------------
void ofApp::drawElemSpeedShape() {
    
    ofPushStyle();
    
    ofSetColor(uiLineColor, 40);
    
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
    
    ofSetColor(uiLineColor, 40);
    
    ofSetLineWidth(controlObjectLineWidth);
    
    float _iX = intervalPos.x;
    float _iY = intervalPos.y;
    
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
void ofApp::drawBaseInterface(bool playOn) {
    
    if (playOn) {
        
        ofPushMatrix();
        ofTranslate(0, 0);
        
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
            //            activeShapeFillColor(base4Pos, baseSelection, baseSize, _c[baseSelection - 4]);
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
    
    ofSetColor(_c, 40);
    
    ofSetLineWidth(controlObjectLineWidth);
    
    ofMesh _shapeM;
    _shapeM.setMode(OF_PRIMITIVE_TRIANGLE_FAN);
    _shapeM.addVertex(ofPoint(0, 0));
    
    for (int i = 0; i < posLine.size(); i++) {
        _shapeM.addVertex(ofPoint(posLine[i].x, posLine[i].y));
    }
    
    _shapeM.addVertex(ofPoint(posLine[0].x, posLine[0].y));
    _shapeM.draw();
    
    ofSetColor(uiLineColor);
    
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
    
    ofSetColor(_c, 120);
    
    ofSetColor(_c, 180);
    
    ofSetLineWidth(controlObjectLineWidth);
    
    float _scaleMoving = floor(activeFactor) * 0.05 + 1.2;
    
    ofSetColor(uiLineColor);
    
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
void ofApp::drawThresholdInterface(bool bCameraCapturePlay) {

    if (!bCameraCapturePlay) {
        thresholdImg.draw(thresholdRect);
    }

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
    
    ofPopStyle();
    
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
                _c = ofColor(cIn, 220);
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
    ofSetColor(c, 220);
    
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
    ofSetLineWidth(3);
    
    ofSetColor(_color);
    
    for (int i = 0; i < posLine.size() - 1; i++) {
        ofDrawLine(posLine[i].x, posLine[i].y, posLine[i + 1].x, posLine[i + 1].y);
    }
    ofDrawLine(posLine[0].x, posLine[0].y, posLine[posLine.size() - 1].x, posLine[posLine.size() - 1].y);
    
    ofPopStyle();
    ofPopMatrix();
    
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
    
}


//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch) {
    
    iPhoneTouchDown(touch);
    
}


//--------------------------------------------------------------
void ofApp::iPhoneTouchDown(ofTouchEventArgs & touch) {
    
    float _tolerance = 2;
    
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
        float _distT = ofDist(thresholdRect.x, thresholdRect.y , _chgdTouch.x, _chgdTouch.y);
        
        if (_distT < thresholdRect.getWidth() * 3) {
            bthresholdCtrl = true;
        } else {
            bthresholdCtrl = false;
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
void ofApp::touchMoved(ofTouchEventArgs & touch) {
    
    iPhoneTouchMoved(touch);
    
}


//--------------------------------------------------------------
void ofApp::iPhoneTouchMoved(ofTouchEventArgs & touch) {
    
    ofPoint _chgdTouch = ofPoint(touch.x, touch.y);
    
    touchPos[touch.id] = _chgdTouch;
    
    if (bSpeedCtrl) {
        float _minY = speedLineLength.x;
        float _maxY = speedLineLength.y;
        
        if ((touchPos[touch.id].y > _minY) && (touchPos[touch.id].y < _maxY) && touchPos[touch.id].x > ofGetWidth() * 0.8) {
            speedPos.y = touchPos[touch.id].y;
            float _tempo = ofMap(speedPos.y, _minY, _maxY, maxSpeed, minSpeed);
            synthMain.setParameter("tempo", _tempo);
        }
    }
    
    if (bInterval) {
        float _minY = intervalLineLength.x;
        float _maxY = intervalLineLength.y;
        
        if ((touchPos[touch.id].y > _minY) && (touchPos[touch.id].y < _maxY) && touchPos[touch.id].x < ofGetWidth() * 0.2) {
            intervalPos.y = touchPos[touch.id].y;
            float _interval = ofMap(intervalPos.y, _minY, _maxY, 0, 20);
            intervalDist = _interval;
        }
    }
    
    if (bthresholdCtrl) {
        float _minY = lineScoreAreaPosTopY * 0.3;
        float _maxY = lineScoreAreaPosTopY * 0.7;
        
        if (touchPos[touch.id].y > _minY && touchPos[touch.id].y < _maxY) {
            thresholdRect.y = touchPos[touch.id].y - thresholdRect.getHeight() * 0.5;
            float _threshold = ofMap(thresholdRect.y, _minY, _maxY, 0, 255);
            grayThreshold = _threshold;
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
void ofApp::touchUp(ofTouchEventArgs & touch) {
    
    iPhoneTouchUp(touch);
    
}


//--------------------------------------------------------------
void ofApp::iPhoneTouchUp(ofTouchEventArgs & touch) {
    
    ofPoint _chgdTouch = ofPoint(touch.x, touch.y);
    ofVec3f _composeModCenter = composeMode.getCenter();
    if (_composeModCenter.distance(_chgdTouch) < composeMode.getWidth() * 0.75 && _composeModCenter.distance(_chgdTouch) < composeMode.getHeight() * 0.75) {
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
        importLibraryImg = false;
        frontCameraOnOff = !frontCameraOnOff;
        
#if TARGET_OS_SIMULATOR
#else
        if (frontCameraOnOff) {
            settingCamera(0);
        } else {
            settingCamera(1);
        }
        
#endif
        
    }
    
    if (!bPlayNote && libaryImport.inside(_chgdTouch)) {
        libraryImg.openLibrary();
        importLibraryImg = true;
    }
        
    if (libaryImportCancle.inside(_chgdTouch)) {
        if (!bCameraCapturePlay) {
            importLibraryImg = false;
        }
    }
    
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
void ofApp::settingCamera(int cameraDevice) {
    
#if TARGET_OS_SIMULATOR
#else
    cam.setDeviceID(cameraDevice);
    cam.setup(360, 480); // 4 : 3
    cam.setDesiredFrameRate(15);
    float _ratio = 360.0 / ofGetWidth();
    camSize.set(int(cameraViewSize.x * _ratio), int(cameraViewSize.y * _ratio));
#endif
    
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
