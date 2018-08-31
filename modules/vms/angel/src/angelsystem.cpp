#include "angelsystem.h"

#include <assert.h>

#include <log.h>
#include <controller.h>

#include <analytics/profiler.h>

#include <angelscript.h>
#include <scriptstdstring/scriptstdstring.h>

#include <components/scene.h>
#include <components/angelbehaviour.h>

#include <resources/angelscript.h>

class AngelStream : public asIBinaryStream {
public:
    AngelStream(ByteArray &ptr) :
            m_Array(ptr),
            m_Offset(0) {

    }
    int         Write   (const void *, asUINT) {
        return 0;
    }
    int         Read    (void *ptr, asUINT size) {
        if(size > 0) {
            memcpy(ptr, &m_Array[m_Offset], size);
            m_Offset    += size;
        }
        return size;
    }
protected:
    ByteArray          &m_Array;

    uint32_t            m_Offset;
};

AngelSystem::AngelSystem(Engine *engine) :
        ISystem(engine),
        m_pScriptEngine(nullptr),
        m_pContext(nullptr) {
    PROFILER_MARKER;

    AngelScript::registerClassFactory();

    AngelBehaviour::registerClassFactory();
}

AngelSystem::~AngelSystem() {
    PROFILER_MARKER;

    if(m_pContext) {
        m_pContext->Release();
    }

    if(m_pScriptEngine) {
        m_pScriptEngine->ShutDownAndRelease();
    }
}

bool AngelSystem::init() {
    PROFILER_MARKER;

    m_pScriptEngine = asCreateScriptEngine();

    int32_t r   = m_pScriptEngine->SetMessageCallback(asFUNCTION(messageCallback), 0, asCALL_CDECL);
    if(r >= 0) {
        m_pContext  = m_pScriptEngine->CreateContext();

        registerClasses(m_pScriptEngine);

        AngelScript *script = Engine::loadResource<AngelScript>("test.as");
        if(script) {
            AngelStream stream(script->m_Array);
            m_pScriptModule = m_pScriptEngine->GetModule("AngelData", asGM_CREATE_IF_NOT_EXISTS);
            m_pScriptModule->LoadByteCode(&stream);
        } else {
            Log(Log::ERR) << "Filed to load a script";
        }
    }

    return (r >= 0);
}

const char *AngelSystem::name() const {
    return "AngelScript";
}

void AngelSystem::update(Scene &scene, uint32_t) {
    PROFILER_MARKER;

    for(auto &it : scene.findChildren<AngelBehaviour *>()) {
        if(it->isEnable()) {
            asIScriptObject *object = it->scriptObject();
            string value    = it->script();
            if(object == nullptr && !value.empty()) {
                asITypeInfo *type   = m_pScriptModule->GetTypeInfoByDecl(value.c_str());
                if(type) {
                    string stream   = value + " @+" + value + "()";
                    asIScriptFunction *factory  = type->GetFactoryByDecl(stream.c_str());

                    m_pContext->Prepare(factory);
                    m_pContext->Execute();

                    object  = *(asIScriptObject**)m_pContext->GetAddressOfReturnValue();
                    if(object) {
                        object->AddRef();

                        it->setScriptStart(type->GetMethodByDecl("void start()"));
                        it->setScriptStart(type->GetMethodByDecl("void update()"));

                        it->setScriptObject(object);
                        if(object->GetPropertyCount() > 0) {
                            AngelBehaviour *o   = it;
                            memcpy(reinterpret_cast<AngelBehaviour**>(object->GetAddressOfProperty(0)), &o, sizeof(void *));
                        }
                    } else {
                        Log(Log::ERR) << "Can't create an object" << value.c_str();
                    }
                }
            }

            if(object) {
                asIScriptFunction *func = it->scriptUpdate();
                if(func) {
                    m_pContext->Prepare(func);
                    m_pContext->SetObject(object);
                    m_pContext->Execute();
                }
            }

        }
    }
}

void AngelSystem::overrideController(IController *) {
    PROFILER_MARKER;

}

void AngelSystem::resize(uint32_t, uint32_t) {
    PROFILER_MARKER;

}

void AngelSystem::registerClasses(asIScriptEngine *engine) {
    PROFILER_MARKER;

    RegisterStdString(engine);

    ObjectSystem *system  = Engine::instance();
    for(auto &it: system->factories()) {
        const char *name    = it.first.c_str();

        const MetaObject *meta  = system->metaFactory(name);

        uint32_t type   = MetaType::type(name);
        uint32_t size   = MetaType::size(type);
        MetaType::Table *table  = MetaType::table(type);
        if(size && table) {
            //int r   = engine->RegisterObjectType(name, size, asOBJ_VALUE);
            //r = engine->RegisterObjectBehaviour(name, asBEHAVE_CONSTRUCT, "void f()", asFUNCTION(table->construct), asCALL_CDECL_OBJLAST);
            //r = engine->RegisterObjectBehaviour(name, asBEHAVE_DESTRUCT,  "void f()", asFUNCTION(table->destruct),  asCALL_CDECL_OBJLAST);

            int r   = engine->RegisterObjectType(name, 0, asOBJ_REF | asOBJ_NOCOUNT);
            string stream   = string(name) + "@ f()";
            r = engine->RegisterObjectBehaviour(name, asBEHAVE_FACTORY, stream.c_str(), asFUNCTION(table->static_new), asCALL_CDECL);
            //r = engine->RegisterObjectBehaviour(name, asBEHAVE_ADDREF, "void f()", asMETHOD(CRef,AddRef), asCALL_THISCALL);
            //r = engine->RegisterObjectBehaviour(name, asBEHAVE_RELEASE, "void f()", asMETHOD(CRef,Release), asCALL_THISCALL);
/*
            for(uint32_t m = 0; m < meta->methodCount(); m++) {
                MetaMethod method   = meta->method(m);
                if(method.isValid()) {
                    asSFuncPtr ptr(3);
                    ptr.CopyMethodPtr(method., SINGLE_PTR_SIZE+4*sizeof(int));

                    r = engine->RegisterObjectMethod(it.first.c_str(),
                                                     method.signature().c_str(),
                                                     ptr,
                                                     asCALL_THISCALL); assert( r >= 0 );
                }
            }
*/
        } else {
            Log(Log::ERR) << "Can't register" << it.first.c_str() << "masked to" << meta->name();
        }
    }
}

void AngelSystem::messageCallback(const asSMessageInfo *msg, void *param) {
    PROFILER_MARKER;

    A_UNUSED(param)
    Log((Log::LogTypes)msg->type) << msg->section << "(" << msg->row << msg->col << "):" << msg->message;
}
