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
            QString name    = lst.last();
            uint32_t size   = lst.size();
            if(name.isEmpty()) {
                name    = QString::fromStdString(m_pController->actor().name());
                size    = 0;
            }

            QString spaces;
            for(auto i = 0; i < size; i++) {
                spaces  += "    ";
            }
            return QString("%1%2 : %3").arg(spaces).arg(name).arg(it->property.c_str());
        }
        case Qt::BackgroundColorRole: {
            if(m_isHighlighted && (index == m_HoverIndex)) {
                return QColor(229, 0, 0);
            }
        }
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

        emit layoutAboutToBeChanged();
        emit layoutChanged();

        emit changed();
    }
}

void AnimationClipModel::onRemoveKey(int row, int index) {
    if(row >= 0 && index >= 0) {
        AnimationClip *clip = m_pController->clip();

        VariantAnimation::Curve &curve = (*std::next(clip->m_Tracks.begin(), row)).curve;
        curve.erase(std::next(curve.begin(), index));

        emit layoutAboutToBeChanged();
        emit layoutChanged();

        emit changed();
    }
}

void AnimationClipModel::onMoveKey(int row, int index, qreal value) {
    if(row >= 0 && index >= 0) {
        AnimationClip *clip = m_pController->clip();

        VariantAnimation::Curve &curve = (*std::next(clip->m_Tracks.begin(), row)).curve;
        (*std::next(curve.begin(), index)).mPosition = round(value * 1000.0);

        emit layoutAboutToBeChanged();
        emit layoutChanged();

        emit changed();
    }
}
