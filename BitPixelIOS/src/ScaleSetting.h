//
//  scaleSetting.h
//  BitPixel
//
//  Created by JeongHo Park on 5/23/15.
//
//

#ifndef __BitPixel__ScaleSetting__
#define __BitPixel__ScaleSetting__

#include "ofMain.h"

class ScaleSetting {
    
    public :
    
    void setup();
    
    // note scale selector
    int noteSelector(int _n, int _index, int _subIndex);
    
    
    private :
    
    void changeScale();
    
    
    
    
};

#endif /* defined(__BitPixel__ScaleSetting__) */
