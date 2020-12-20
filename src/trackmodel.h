#pragma once

#include <QAbstractListModel>
#include <QObject>
#include <QmlTypeAndRevisionsRegistration>

Q_DECLARE_METATYPE(QVariantHash)
using SongHash = QHash<QUrl, QVariantHash>;
Q_DECLARE_METATYPE(SongHash)

class TrackModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QStringList artists READ artists NOTIFY dbChanged)
    Q_PROPERTY(QStringList albums READ albums NOTIFY dbChanged)
    Q_PROPERTY(QStringList genres READ genres NOTIFY dbChanged)
public:
    enum RoleEnum {
        RoleTrackUrl = Qt::UserRole + 1,
        RoleTrackFilepath ,
        RoleTrackTitle,
        RoleTrackArtist,
        RoleTrackAlbum,
        RoleTrackYear,
        RoleTrackGenre,
        RoleTrackNumber,
        RoleTrackLength,
    };
    Q_ENUM(RoleEnum)

    TrackModel(QObject *parent = nullptr);
    ~TrackModel();

    QStringList artists() const;
    QStringList albums() const;
    QStringList genres() const;

    Q_INVOKABLE void scanAll();

signals:
    void dbChanged();

protected:
    int rowCount(const QModelIndex &parent) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

private:
    QHash<int, QByteArray> m_roleNames;

    SongHash m_tracks; // fileUrl -> {title, artist, album, year, genre, trackNo, length}
    QStringList m_artists;
    QStringList m_albums;
    QStringList m_genres;
};
