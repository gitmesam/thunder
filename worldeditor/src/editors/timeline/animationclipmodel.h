#ifndef ANIMATIONCLIPMODEL_H
#define ANIMATIONCLIPMODEL_H

#include <QAbstractItemModel>

class AnimationController;

class AnimationClipModel : public QAbstractItemModel {
    Q_OBJECT

    Q_PROPERTY(float position READ position WRITE setPosition NOTIFY positionChanged)

public:
    AnimationClipModel          (QObject *parent);

    void                        setController               (AnimationController *controller);

    QVariant                    data                        (const QModelIndex &index, int) const;

    QVariant                    headerData                  (int, Qt::Orientation, int) const;

    int                         columnCount                 (const QModelIndex &) const;

    QModelIndex                 index                       (int row, int column, const QModelIndex &parent = QModelIndex()) const;

    QModelIndex                 parent                      (const QModelIndex &) const;

    int                         rowCount                    (const QModelIndex &) const;

    Q_INVOKABLE int             keysCount                   (int index) const;

    Q_INVOKABLE unsigned int    keyPosition                 (int track, int index) const;

    float                       position                    () const;
    void                        setPosition                 (float value);

public slots:
    void                        onAddKey                    (int row, qreal value);
    void                        onRemoveKey                 (int row, int index);
    void                        onMoveKey                   (int row, int index, qreal value);

signals:
    void                        changed                     ();

    void                        positionChanged             ();

protected:
    AnimationController        *m_pController;

    bool                        m_isHighlighted;

    QModelIndex                 m_HoverIndex;

    float                       m_Position;

};

#endif // ANIMATIONCLIPMODEL_H
