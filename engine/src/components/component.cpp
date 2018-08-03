#include "components/component.h"

#include "components/actor.h"

Component::Component() :
        Object(),
        m_Enable(true) {

}

Actor &Component::actor() const {
    return *(static_cast<Actor *>(parent()));
}

bool Component::isEnable() const {
    return m_Enable;
}

void Component::setEnable(bool enable) {
    m_Enable    = enable;
}
