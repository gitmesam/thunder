#ifndef ANGELMODULE_H
#define ANGELMODULE_H

#include "engine.h"

#include <angelscript.h>

class NEXT_LIBRARY_EXPORT AngelScript : public Object, asIBinaryStream {
    A_REGISTER(AngelScript, Object, Resources);

public:
    AngelScript                 ();

    virtual ~AngelScript        ();

    asIScriptModule            *module                      () const;

protected:
    void                        loadUserData                (const VariantMap &data);

    int                         Read                        (void *ptr, asUINT size);
    int                         Write                       (const void *, asUINT);

protected:
    asIScriptModule            *m_pModule;

    ByteArray                   m_Array;

    uint32_t                    m_Offset;

};

#endif // ANGELMODULE_H
