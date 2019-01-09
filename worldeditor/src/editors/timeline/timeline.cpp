#include "timeline.h"
#include "ui_timeline.h"

#include <timer.h>
#include <json.h>

#include <resources/animationclip.h>
#include <components/animationcontroller.h>
#include <components/actor.h>

#include "animationclipmodel.h"

#include "assetmanager.h"
#include "projectmanager.h"

#include <QSettings>
#include <QQmlContext>
#include <QQuickItem>

bool compare(const AnimationClip::Track &first, const AnimationClip::Track &second) {
    if(first.path == second.path) {
        return first.property < second.property;
    }
    return first.path < second.path;
}

Timeline::Timeline(QWidget *parent) :
        QWidget(parent),
        ui(new Ui::Timeline),
        m_pController(nullptr),
        m_TimerId(0),
        m_ContentMenu(this),
        m_Modified(false) {
    ui->setupUi(this);
    ui->pause->setVisible(false);

    readSettings();

    m_pModel = new AnimationClipModel(this);

    ui->treeView->setModel(m_pModel);
    ui->treeView->setContextMenuPolicy(Qt::CustomContextMenu);
    ui->treeView->setMouseTracking(true);

    ui->quickTimeline->rootContext()->setContextProperty("clipModel", m_pModel);
    ui->quickTimeline->setSource(QUrl("qrc:/QML/qml/Timeline.qml"));

    ui->record->setProperty("checkred", true);
    ui->play->setProperty("checkgreen", true);

    QQuickItem *item = ui->quickTimeline->rootObject();
    connect(item, SIGNAL(addKey(int,qreal)), m_pModel, SLOT(onAddKey(int,qreal)));
    connect(item, SIGNAL(removeKey(int,int)), m_pModel, SLOT(onRemoveKey(int,int)));
    connect(item, SIGNAL(moveKey(int,int,qreal)), m_pModel, SLOT(onMoveKey(int,int,qreal)));

    connect(m_pModel, SIGNAL(changed()), this, SLOT(onModified()));

    connect(m_pModel, SIGNAL(positionChanged()), this, SIGNAL(moved()), Qt::QueuedConnection);

    m_ContentMenu.addAction(tr("Remove Properties"), this, SLOT(onRemoveProperty()));
}

Timeline::~Timeline() {
    saveClip();

    writeSettings();

    delete ui;
}

void Timeline::readSettings() {
    QSettings settings(COMPANY_NAME, EDITOR_NAME);
    QVariant value  = settings.value("timeline.splitter");
    if(value.isValid()) {
        ui->splitter->restoreState(value.toByteArray());
    }
}

void Timeline::writeSettings() {
    QSettings settings(COMPANY_NAME, EDITOR_NAME);
    settings.setValue("timeline.splitter", ui->splitter->saveState());
}

void Timeline::saveClip() {
    if(m_Modified && m_pController) {
        AnimationClip *clip = m_pController->clip();

        string ref  = Engine::reference(clip);
        QFile file(ProjectManager::instance()->contentPath() + "/" + AssetManager::instance()->guidToPath(ref).c_str());
        if(file.open(QIODevice::WriteOnly)) {
            VariantList tracks;
            for(auto t : clip->m_Tracks) {
                VariantList track;
                track.push_back(t.path);
                track.push_back(t.property);

                VariantList keys;
                for(auto c : t.curve) {
                    VariantList key;
                    key.push_back(int32_t(c.mPosition));
                    key.push_back(c.mType);
                    key.push_back(c.mValue);
                    key.push_back(c.mLeftTangent);
                    key.push_back(c.mRightTangent);

                    keys.push_back(key);
                }
                track.push_back(keys);
                tracks.push_back(track);
            }

            file.write(Json::save(tracks, 0).c_str());
            file.close();

            m_Modified  = false;
        }

    }
}

AnimationController *Timeline::findController(Object *object) {
    AnimationController *result = object->findChild<AnimationController *>(false);
    if(!result) {
        Object *parent  = object->parent();
        if(parent) {
            result  = findController(parent);
        }
    }
    return result;
}

void Timeline::onObjectSelected(Object::ObjectList objects) {
    if(m_TimerId) {
        killTimer(m_TimerId);
        m_TimerId   = 0;
    }

    saveClip();

    m_pController   = nullptr;
    for(auto object : objects) {
        m_pController  = findController(object);
        if(m_pController) {
            break;
        }
    }
    m_pModel->setController(m_pController);

    bool enable = (m_pController != nullptr);

    ui->begin->setEnabled(enable);
    ui->end->setEnabled(enable);
    ui->record->setEnabled(enable);
    ui->play->setEnabled(enable);

    ui->next->setEnabled(enable);
    ui->previous->setEnabled(enable);

    ui->treeView->setCurrentIndex(m_pModel->index(0, 0));

    emit animated(enable);

    on_begin_clicked();
}

void Timeline::onChanged(Object::ObjectList objects, const QString &property) {
    for(auto it : objects) {
        onUpdated(it, property);
    }
}

void Timeline::onUpdated(Object *object, const QString &property) {
    if(object && !property.isEmpty() && ui->record->isChecked()) {
        AnimationController *controller = findController(object);
        if(controller) {
            QString path    = pathTo(static_cast<Object *>(&controller->actor()), object);

            const MetaObject *meta  = object->metaObject();
            int32_t index   = meta->indexOfProperty(qPrintable(property));
            if(index >= 0) {
                MetaProperty p  = meta->property(index);
                Variant value   = p.read(object);
                KeyFrame key(controller->position(), value);
                /// \todo build support points

                bool create = true;
                AnimationClip *clip = controller->clip();
                if(clip == nullptr) {
                    return;
                }
                for(auto &it : clip->m_Tracks) {
                    if(it.path == path.toStdString() && it.property == property.toStdString()) {
                        bool update = false;
                        for(auto &k : it.curve) {
                            if(k.mPosition == key.mPosition) {
                                k.mValue = key.mValue;
                                k.mLeftTangent = key.mLeftTangent;
                                k.mRightTangent = key.mRightTangent;
                                update  = true;
                            }
                        }
                        if(!update) {
                            it.curve.push_back(key);
                            it.curve.sort(AnimationClip::compare);
                        }
                        create  = false;
                        break;
                    }
                }

                if(create) {
                    AnimationClip::Track track;
                    track.curve.push_back(key);
                    track.path      = path.toStdString();
                    track.property  = property.toStdString();

                    clip->m_Tracks.push_back(track);
                    clip->m_Tracks.sort(compare);

                    controller->setClip(clip);
                }
                m_pModel->setController(m_pController);
                onModified();
            }
        }
    }
}

void Timeline::onModified() {
    m_Modified  = true;
}

void Timeline::onRemoveProperty() {
    QModelIndexList list    = ui->treeView->selectionModel()->selectedIndexes();
    AnimationClip *clip     = m_pController->clip();
    foreach(const QModelIndex &index, list) {
        auto it = clip->m_Tracks.begin();
        advance(it, index.row());

        clip->m_Tracks.erase(it);
    }
    m_pModel->setController(m_pController);
    m_pController->setClip(clip);

    onModified();
}

void Timeline::timerEvent(QTimerEvent *) {
    if(m_pController) {
        uint32_t ms = m_pController->position() + static_cast<uint32_t>(Timer::deltaTime() * 1000.0f);
        if(ms >= m_pController->duration()) {
            on_begin_clicked();
        } else {
            m_pModel->setPosition(ms / 1000.0f);
        }
    }
}

void Timeline::on_play_clicked() {
    if(m_TimerId) {
        killTimer(m_TimerId);
        m_TimerId   = 0;
    } else {
        m_TimerId   = startTimer(2);
    }
}

void Timeline::on_begin_clicked() {
    m_pModel->setPosition(0.0f);
}

void Timeline::on_end_clicked() {
    m_pModel->setPosition(m_pController->duration() / 1000.0f);
}

void Timeline::on_previous_clicked() {
    m_pModel->setPosition(findNear(true) / 1000.0f);
}

void Timeline::on_next_clicked() {
    m_pModel->setPosition(findNear() / 1000.0f);
}

uint32_t Timeline::findNear(bool backward) {
    uint32_t current    = 0;
    if(m_pController) {
        current    = m_pController->position();
        AnimationClip *clip = m_pController->clip();
        if(clip) {
            for(auto it : clip->m_Tracks) {
                if(backward) {
                    auto key    = it.curve.rbegin();
                    while(key != it.curve.rend()) {
                        if(key->mPosition < current) {
                            return key->mPosition;
                        }
                        key++;
                    }
                } else {
                    for(auto key : it.curve) {
                        if(key.mPosition > current) {
                            return key.mPosition;
                        }
                    }
                }

            }
        }
    }
    return current;
}

QString Timeline::pathTo(Object *src, Object *dst) {
    QString result;
    if(src != dst) {
        QString parent  = pathTo(src, dst->parent());
        if(!parent.isEmpty()) {
            result  += parent + "/";
        }
        result  += dst->name().c_str();
    }

    return result;
}

void Timeline::on_treeView_customContextMenuRequested(const QPoint &pos) {
    if(!ui->treeView->selectionModel()->selectedIndexes().empty()) {
        m_ContentMenu.exec(ui->treeView->mapToGlobal(pos));
    }
}
