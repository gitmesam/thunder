#include "converters/angelconverter.h"

#include <log.h>
#include <bson.h>

#include <angelscript.h>

#include <QFile>

#include "angelsystem.h"

#define DATA    "Data"

class CBytecodeStream : public asIBinaryStream {
public:
    CBytecodeStream(ByteArray *ptr) :
        array(ptr) {

    }
    int Write(const void *ptr, asUINT size) {
        if( size == 0 ) {
            return size;
        }
        uint32_t offset = array->size();
        array->resize(offset + size);
        memcpy(&array[offset - 1], ptr, size);

        return size;
    }
    int Read(void *ptr, asUINT size) {
        return 0;
    }
protected:
    ByteArray        *array;
};

VariantMap AngelSerial::saveUserData() const {
    VariantMap result;

    result[DATA]  = m_Array;

    return result;
}

AngelConverter::AngelConverter() {
    m_pScriptEngine = asCreateScriptEngine();

    m_pScriptEngine->SetMessageCallback(asFUNCTION(messageCallback), 0, asCALL_CDECL);

    AngelSystem::registerClasses(m_pScriptEngine);
}

uint8_t AngelConverter::convertFile(IConverterSettings *settings) {
    asIScriptModule *mod = m_pScriptEngine->GetModule("module", asGM_ALWAYS_CREATE);

    QFile file(settings->source());
    if(file.open( QIODevice::ReadOnly)) {
        mod->AddScriptSection("AngelBehaviour", file.readAll().data());
        if(mod->Build() >= 0) {
            AngelSerial serial;
            serial.m_Array.clear();
            CBytecodeStream stream(&serial.m_Array);
            mod->SaveByteCode(&stream);

            ByteArray data  = Bson::save( Engine::toVariant(&serial) );
            file.write((const char *)&data[0], data.size());
        }
        file.close();
    }

    return 0;
}

void AngelConverter::messageCallback(const asSMessageInfo *msg, void *param) {
    A_UNUSED(param)
    Log((Log::LogTypes)msg->type) << msg->section << "(" << msg->row << msg->col << "):" << msg->message;
}
