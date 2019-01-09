#ifndef KEYFRAME_H
#define KEYFRAME_H

#include "core/variant.h"

class NEXT_LIBRARY_EXPORT KeyFrame {
public:
    enum Type {
        Constant                = 0,
        Linear,
        Cubic
    };

public:
    KeyFrame                    ();

    KeyFrame                    (uint32_t position, Variant &value);

    KeyFrame                    (uint32_t position, Variant &value, Variant &left, Variant &right);

    uint32_t                    mPosition;

    Type                        mType;

    Variant                     mValue;

    Variant                     mLeftTangent;
    Variant                     mRightTangent;
};

#endif // KEYFRAME_H
