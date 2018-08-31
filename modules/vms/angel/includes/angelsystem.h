#ifndef ANGELSYSTEM_H
#define ANGELSYSTEM_H

#include <system.h>

class asIScriptEngine;
class asIScriptModule;
class asIScriptContext;

class asSMessageInfo;

class MetaObject;

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

    asIScriptModule            *m_pScriptModule;

    asIScriptContext           *m_pContext;
};

#endif // ANGELSYSTEM_H
