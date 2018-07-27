#include "angel.h"

#include "angelsystem.h"

IModule *moduleCreate(Engine *engine) {
    return new Angel(engine);
}

Angel::Angel(Engine *engine) :
        m_pEngine(engine) {
}

Angel::~Angel() {

}

const char *Angel::description() const {
    return "AngelScript Module";
}

const char *Angel::version() const {
    return "1.0";
}

uint8_t Angel::types() const {
    return SYSTEM;
}

ISystem *Angel::system() {
    return new AngelSystem(m_pEngine);
}
