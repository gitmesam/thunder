#ifndef ANGELSYSTEM_H
#define ANGELSYSTEM_H

#include <system.h>

class AngelSystem : public ISystem {
public:
    AngelSystem                 (Engine *engine);
    ~AngelSystem                ();

    bool                        init                        ();

    const char                 *name                        () const;

    void                        update                      (Scene &, uint32_t = 0);

    void                        overrideController          (IController *);

    void                        resize                      (uint32_t, uint32_t);

protected:

};

#endif // ANGELSYSTEM_H
