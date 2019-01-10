#include "anim/keyframe.h"

KeyFrame::KeyFrame() :
        mPosition(0.0f),
        mType(Linear) {

}

KeyFrame::KeyFrame(uint32_t position, const Variant &value) :
        mPosition(position),
        mType(Linear),
        mValue(value) {

}

KeyFrame::KeyFrame(uint32_t position, uint32_t type, const Variant &value, const Variant &left, const Variant &right) :
        mPosition(position),
        mType((Type)type),
        mValue(value),
        mLeftTangent(left),
        mRightTangent(right) {

}
