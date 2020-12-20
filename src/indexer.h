#pragma once

#include <QImage>
#include <QObject>
#include <QSet>
#include <QStandardPaths>
#include <QVariantHash>
#include <QUrl>

Q_DECLARE_METATYPE(QVariantHash)
using SongHash = QHash<QUrl, QVariantHash>;
Q_DECLARE_METATYPE(SongHash)

class Indexer : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QStringList rootPaths READ rootPaths WRITE setRootPaths NOTIFY rootPathsChanged)
    Q_PROPERTY(SongHash songs READ songs NOTIFY dbChanged)
    Q_PROPERTY(QStringList artists READ artists NOTIFY dbChanged)
    Q_PROPERTY(QStringList albums READ albums NOTIFY dbChanged)
    Q_PROPERTY(QList<QUrl> tracks READ tracks NOTIFY dbChanged)
    Q_PROPERTY(QStringList genres READ genres NOTIFY dbChanged)

public:
    explicit Indexer(QObject *parent = nullptr);
    ~Indexer() = default;

    QStringList rootPaths() const;
    void setRootPaths(const QStringList &rootPaths);
    void addRootPath(const QString & rootPath);

    SongHash songs() const;

    QStringList artists() const;
    QStringList albums() const;
    QList<QUrl> tracks() const;
    QStringList genres() const;

public slots:
    int scanAll();

    QStringList filterArtists(const QString &filter = QString()) const;
    QStringList filterAlbums(const QString &filter = QString()) const;
    QList<QUrl> filterTracks(const QString &filter = QString()) const;
    QStringList filterGenres(const QString &filter = QString()) const;

    QVariant metadata(const QUrl &fileUrl, const QString &key) const;
    QString artistForAlbum(const QString &album) const;
    int yearForAlbum(const QString &album) const;
    QList<QUrl> tracksForAlbum(const QString &album) const;
    QStringList albumsForArtist(const QString &artist) const;
    QList<QUrl> tracksForGenre(const QString &genre) const;
    QString genreForAlbum(const QString &album) const;
    int albumLength(const QString &album) const;

    QUrl coverArtForFile(const QUrl &fileUrl) const;
    QUrl coverArtForAlbum(const QString &album) const;

signals:
    void rootPathsChanged(const QStringList &rootPaths);
    void dbChanged();

private:
    QStringList m_rootPaths{QStandardPaths::standardLocations(QStandardPaths::MusicLocation)};
    SongHash m_songs; // fileUrl -> {title, artist, album, year, genre, trackNo}
    QSet<QString> m_artists;
    QSet<QString> m_albums;
    QHash<QString, QUrl> m_tracks; // title -> fileUrl
    QSet<QString> m_genres;
};
