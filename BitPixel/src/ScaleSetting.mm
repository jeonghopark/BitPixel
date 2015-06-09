//
//  scaleSetting.cpp
//  BitPixel
//
//  Created by JeongHo Park on 5/23/15.
//
//

#include "ScaleSetting.h"


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



//--------------------------------------------------------------
void ScaleSetting::setup(){
    
    changeScale();
    
}



//--------------------------------------------------------------
int ScaleSetting::noteSelector(int _n, int _index, int _subIndex){
    
    int _result = 0;
    
    switch (_n) {
        case 5:
            
            switch (_index) {
                case 1:
                    _result = scale51[_subIndex];
                    break;
                case 2:
                    _result = scale52[_subIndex];
                    break;
                case 3:
                    _result = scale53[_subIndex];
                    break;
                case 4:
                    _result = scale54[_subIndex];
                    break;
                case 5:
                    _result = scale55[_subIndex];
                    break;
                case 6:
                    _result = scale56[_subIndex];
                    break;
                    
                default:
                    break;
            }
            
            break;
            
        case 6:
            switch (_index) {
                    
                case 1:
                    _result = scale61[_subIndex];
                    break;
                case 2:
                    _result = scale62[_subIndex];
                    break;
                case 3:
                    _result = scale63[_subIndex];
                    break;
                case 4:
                    _result = scale64[_subIndex];
                    break;
                case 5:
                    _result = scale65[_subIndex];
                    break;
                case 6:
                    _result = scale66[_subIndex];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case 7:
            switch (_index) {
                    
                case 1:
                    _result = scale71[_subIndex];
                    break;
                case 2:
                    _result = scale72[_subIndex];
                    break;
                case 3:
                    _result = scale73[_subIndex];
                    break;
                case 4:
                    _result = scale74[_subIndex];
                    break;
                case 5:
                    _result = scale75[_subIndex];
                    break;
                    
                default:
                    break;
            }
            
            break;
            
        case 8:
            switch (_index) {
                    
                case 1:
                    _result = scale81[_subIndex];
                    break;
                case 2:
                    _result = scale82[_subIndex];
                    break;
                case 3:
                    _result = scale83[_subIndex];
                    break;
                case 4:
                    _result = scale84[_subIndex];
                    break;
                case 5:
                    _result = scale85[_subIndex];
                    break;
                    
                default:
                    break;
            }
            
            break;
            
        default:
            break;
            
    }
    
    return _result;
    
}


//--------------------------------------------------------------
void ScaleSetting::changeScale(){
    
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