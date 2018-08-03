#include "resources/angelscript.h"

#define DATA    "Data"

AngelScript::AngelScript() :
        m_pModule(nullptr),
        m_Offset(0) {

}

AngelScript::~AngelScript() {

}

asIScriptModule *AngelScript::module() const {
    return m_pModule;
}

void AngelScript::loadUserData(const VariantMap &data) {
    auto it = data.find(DATA);
    if(it != data.end()) {
        m_Array = (*it).second.toByteArray();
        m_Offset    = 0;
        m_pModule->LoadByteCode(this);
    }
}

int AngelScript::Read(void *ptr, asUINT size) {
    if(size > 0) {
        memcpy(ptr, &m_Array[m_Offset], size);
        m_Offset    += size;
    }
    return size;
}

int AngelScript::Write(const void *, asUINT) {
    return 0;
}
