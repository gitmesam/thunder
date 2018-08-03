#ifndef NATIVEBEHAVIOUR_H
#define NATIVEBEHAVIOUR_H

#include "components/component.h"

class NEXT_LIBRARY_EXPORT NativeBehaviour : public Component {
public:
    virtual void                start                   ();

    virtual void                update                  ();

    virtual void                draw                    (ICommandBuffer &buffer, int8_t layer);
};

#endif // NATIVEBEHAVIOUR_H
