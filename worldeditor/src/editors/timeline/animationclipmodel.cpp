#include "animationclipmodel.h"

#include <resources/animationclip.h>
#include <components/animationcontroller.h>
#include <components/actor.h>

#include <iterator>

#include <QColor>

AnimationClipModel::AnimationClipModel(QObject *parent) :
        QAbstractItemModel(parent),
        m_pController(nullptr),
        m_isHighlighted(false),
        m_Position(0.0f){

}

void AnimationClipModel::setController(AnimationController *controller) {
    m_pController = controller;

    emit layoutAboutToBeChanged();
    emit layoutChanged();
}

QVariant AnimationClipModel::data(const QModelIndex &index, int role) const {
    if(!index.isValid() || m_pController == nullptr || m_pController->clip() == nullptr) {
        return QVariant();
    }

    AnimationClip *clip = m_pController->clip();

    auto it = clip->m_Tracks.begin();
    advance(it, index.row());
    switch(role) {
        case Qt::EditRole:
        case Qt::ToolTipRole:
        case Qt::DisplayRole: {
            QStringList lst = QString::fromStdString(it->path).split('/');
            QString name = lst.last();
            int32_t size = lst.size();
            if(name.isEmpty()) {
                name    = QString::fromStdString(m_pController->actor().name());
                size    = 0;
            }

            QString spaces;
            for(int32_t i = 0; i < size; i++) {
                spaces  += "    ";
            }
            return QString("%1%2 : %3").arg(spaces).arg(name).arg(it->property.c_str());
        }
        case Qt::BackgroundColorRole: {
            if(m_isHighlighted && (index == m_HoverIndex)) {
                return QColor(229, 0, 0);
            }
        } break;
        default: break;
    }

    return QVariant();
}

QVariant AnimationClipModel::headerData(int section, Qt::Orientation orientation, int role) const {
    if(orientation == Qt::Horizontal && role == Qt::DisplayRole) {
        switch (section) {
            case 0: return tr("");
        }
    }
    return QVariant();
}

int AnimationClipModel::columnCount(const QModelIndex &) const {
    return 1;
}

QModelIndex AnimationClipModel::index(int row, int column, const QModelIndex &parent) const {
    Q_UNUSED(parent);
    AnimationClip::TrackList *list  = nullptr;
    if(m_pController && m_pController->clip()) {
        list    = &m_pController->clip()->m_Tracks;
    }
    return createIndex(row, column, list);
}

QModelIndex AnimationClipModel::parent(const QModelIndex &) const {
    return QModelIndex();
}

int AnimationClipModel::rowCount(const QModelIndex &parent) const {
    if(m_pController && m_pController->clip() && !parent.isValid()) {
        return m_pController->clip()->m_Tracks.size();
    }
    return 0;
}

int AnimationClipModel::keysCount(int index) const {
    if(m_pController && m_pController->clip() && index >= 0) {
        return (*std::next(m_pController->clip()->m_Tracks.begin(), index)).curve.size();
    }
    return 0;
}

unsigned int AnimationClipModel::keyPosition(int track, int index) const {
    if(m_pController && m_pController->clip() && track >= 0 && index >= 0) {
        auto &curve = (*std::next(m_pController->clip()->m_Tracks.begin(), track)).curve;
        return (*std::next(curve.begin(), index)).mPosition;
    }
    return 0;
}

QVariant AnimationClipModel::keyValue(int track, int index) const {
    if(m_pController && m_pController->clip() && track >= 0 && index >= 0) {
        auto &curve = (*std::next(m_pController->clip()->m_Tracks.begin(), track)).curve;
        Variant v = (*std::next(curve.begin(), index)).mValue;

        QVariantList list;

        switch(v.userType()) {
            case MetaType::VECTOR2: {
                Vector2 vec = v.toVector2();
                list = {2, vec.x, vec.y};
            } break;
            case MetaType::VECTOR3: {
                Vector3 vec = v.toVector3();
                list = {3, vec.x, vec.y, vec.z};
            } break;
            case MetaType::VECTOR4: {
                Vector4 vec = v.toVector4();
                list = {4, vec.x, vec.y, vec.z, vec.w};
            } break;
            default: {
                float val = v.toFloat();
                list = {1, val};
            } break;
        }

        return list;
    }
    return QVariant();
}

QVariant AnimationClipModel::trackData(int track) const {
    if(m_pController && m_pController->clip() && track >= 0) {
        auto &curve = (*std::next(m_pController->clip()->m_Tracks.begin(), track)).curve;

        QVariantList list;
        uint32_t components = 0;
        for(auto &it : curve) {
            Variant v = it.mValue;
            Variant t0 = it.mLeftTangent;
            Variant t1 = it.mRightTangent;
            QVariantList key;
            switch(v.userType()) {
                case MetaType::VECTOR2: {
                    Vector2 val = v.toVector2();
                    Vector2 tan0 = t0.toVector2();
                    Vector2 tan1 = t1.toVector2();
                    key = {it.mPosition, val.x, val.y,
                                         tan0.x, tan0.y,
                                         tan1.x, tan1.y};
                    components = 2;
                } break;
                case MetaType::VECTOR3: {
                    Vector3 val = v.toVector3();
                    Vector3 tan0 = t0.toVector3();
                    Vector3 tan1 = t1.toVector3();
                    key = {it.mPosition, val.x, val.y, val.z,
                                         tan0.x, tan0.y, tan0.z,
                                         tan1.x, tan1.y, tan1.z};
                    components = 3;
                } break;
                case MetaType::VECTOR4: {
                    Vector4 val = v.toVector4();
                    Vector4 tan0 = t0.toVector4();
                    Vector4 tan1 = t1.toVector4();
                    key = {it.mPosition, val.x, val.y, val.z, val.w,
                                         tan0.x, tan0.y, tan0.z, tan0.w,
                                         tan1.x, tan1.y, tan1.z, tan1.w};
                    components = 4;
                } break;
                default: {
                    float val = v.toFloat();
                    float tan0 = t0.toFloat();
                    float tan1 = t1.toFloat();
                    key = {it.mPosition, val, tan0, tan1};
                    components = 1;
                } break;
            }
            list.push_back(key);
        }
        list.push_front(components);
        return list;

    }
    return QVariant();
}

void AnimationClipModel::setTrackData(int track, const QVariant &data) {
    if(m_pController && m_pController->clip() && track >= 0 && data.isValid()) {
        auto &curve = (*std::next(m_pController->clip()->m_Tracks.begin(), track)).curve;
        curve.clear();

        QVariantList list = data.toList();
        uint32_t components = list[0].toUInt();
        list.pop_front();

        foreach(QVariant it, list) {
            QVariantList k = it.toList();

            KeyFrame key;
            key.mPosition = k[0].toUInt();
            key.mType = KeyFrame::Cubic;
            switch(components) {
                case 2: {
                    key.mValue        = Vector2(k[1].toFloat(), k[2].toFloat());
                    key.mLeftTangent  = Vector2(k[3].toFloat(), k[4].toFloat());
                    key.mRightTangent = Vector2(k[5].toFloat(), k[6].toFloat());
                } break;
                case 3: {
                    key.mValue        = Vector3(k[1].toFloat(), k[2].toFloat(), k[3].toFloat());
                    key.mLeftTangent  = Vector3(k[4].toFloat(), k[5].toFloat(), k[6].toFloat());
                    key.mRightTangent = Vector3(k[7].toFloat(), k[8].toFloat(), k[9].toFloat());
                } break;
                case 4: {
                    key.mValue        = Vector4(k[1].toFloat(), k[2].toFloat(), k[3].toFloat(), k[4].toFloat());
                    key.mLeftTangent  = Vector4(k[5].toFloat(), k[6].toFloat(), k[7].toFloat(), k[8].toFloat());
                    key.mRightTangent = Vector4(k[9].toFloat(), k[10].toFloat(), k[11].toFloat(), k[12].toFloat());
                } break;
                default: {
                    key.mValue        = k[1].toFloat();
                    key.mLeftTangent  = k[2].toFloat();
                    key.mRightTangent = k[3].toFloat();
                } break;
            }

            curve.push_back(key);
        }

        emit changed();

        emit layoutAboutToBeChanged();
        emit layoutChanged();
    }
}

float AnimationClipModel::position() const {
    return m_Position;
}

void AnimationClipModel::setPosition(float value) {
    m_Position = value;

    if(m_pController) {
        m_pController->setPosition(1000 * m_Position);
    }

    emit positionChanged();
}

void AnimationClipModel::onAddKey(int row, qreal value) {
    if(row >= 0) {
        AnimationClip *clip = m_pController->clip();

        VariantAnimation::Curve &curve = (*std::next(clip->m_Tracks.begin(), row)).curve;

        KeyFrame key;
        key.mPosition = round(value * 1000.0);

        VariantAnimation anim;
        anim.setKeyFrames(curve);
        anim.setCurrentTime(key.mPosition);

        key.mValue  = anim.currentValue();

        /// \todo build support points

        curve.push_back(key);
        curve.sort(AnimationClip::compare);

        emit changed();

        emit layoutAboutToBeChanged();
        emit layoutChanged();
    }
}

void AnimationClipModel::onRemoveKey(int row, int index) {
    if(row >= 0 && index >= 0) {
        AnimationClip *clip = m_pController->clip();

        VariantAnimation::Curve &curve = (*std::next(clip->m_Tracks.begin(), row)).curve;
        curve.erase(std::next(curve.begin(), index));

        emit changed();

        emit layoutAboutToBeChanged();
        emit layoutChanged();
    }
}

void AnimationClipModel::onMoveKey(int row, int index, qreal value) {
    if(row >= 0 && index >= 0) {
        AnimationClip *clip = m_pController->clip();

        VariantAnimation::Curve &curve = (*std::next(clip->m_Tracks.begin(), row)).curve;
        (*std::next(curve.begin(), index)).mPosition = round(value * 1000.0);

        emit changed();

        emit layoutAboutToBeChanged();
        emit layoutChanged();
    }
}
