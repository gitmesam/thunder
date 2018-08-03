#include "angelsystem.h"

#include <log.h>
#include <controller.h>

#include <analytics/profiler.h>

#include <angelscript.h>
#include <scriptstdstring/scriptstdstring.h>

#include <resources/angelscript.h>

AngelSystem::AngelSystem(Engine *engine) :
        ISystem(engine),
        m_pScriptEngine(nullptr),
        m_pContext(nullptr) {
    PROFILER_MARKER;

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
            asIScriptModule *module = script->module();
        }

        //asIScriptFunction *func = mod->GetFunctionByDecl("void main()");
        //m_pContext->Prepare(func);
        //r = m_pContext->Execute();
    }

    return (r >= 0);
}

const char *AngelSystem::name() const {
    return "AngelScript";
}

void AngelSystem::update(Scene &, uint32_t) {
    PROFILER_MARKER;

}

void AngelSystem::overrideController(IController *) {
    PROFILER_MARKER;

}

void AngelSystem::resize(uint32_t, uint32_t) {
    PROFILER_MARKER;

}

void AngelSystem::registerClasses(asIScriptEngine *engine) {
    RegisterStdString(engine);

}

void AngelSystem::messageCallback(const asSMessageInfo *msg, void *param) {
    A_UNUSED(param)
    Log((Log::LogTypes)msg->type) << msg->section << "(" << msg->row << msg->col << "):" << msg->message;
}
