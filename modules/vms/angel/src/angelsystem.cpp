#include "angelsystem.h"

#include <log.h>
#include <controller.h>

#include <analytics/profiler.h>

AngelSystem::AngelSystem(Engine *engine) :
        ISystem(engine) {
    PROFILER_MARKER;

}

AngelSystem::~AngelSystem() {
    PROFILER_MARKER;

}

bool AngelSystem::init() {
    PROFILER_MARKER;

    return false;
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
