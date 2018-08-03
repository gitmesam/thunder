#ifndef ANGELSYSTEM_H
#define ANGELSYSTEM_H

#include <system.h>

class asIScriptEngine;
class asIScriptContext;

class asSMessageInfo;

class AngelSystem : public ISystem {
public:
    AngelSystem                 (Engine *engine);
    ~AngelSystem                ();

    bool                        init                        ();

    const char                 *name                        () const;

    void                        update                      (Scene &, uint32_t = 0);

    void                        overrideController          (IController *);

    void                        resize                      (uint32_t, uint32_t);

    static void                 registerClasses             (asIScriptEngine *engine);
protected:
    static void                 messageCallback             (const asSMessageInfo *msg, void *param);

    asIScriptEngine            *m_pScriptEngine;

    asIScriptContext           *m_pContext;
};

#endif // ANGELSYSTEM_H
