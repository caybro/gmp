#include "dbindexer.h"

#include <QDebug>
#include <QDir>
#include <QDirIterator>
#include <QElapsedTimer>
#include <QFile>
#include <QHashIterator>
#include <QImage>
#include <QMimeDatabase>
#include <QSqlDatabase>
#include <QSqlDriver>
#include <QSqlError>
#include <QSqlQuery>
#include <QUrl>

#include <taglib/attachedpictureframe.h>
#include <taglib/fileref.h>
#include <taglib/id3v2tag.h>
#include <taglib/mpegfile.h>

TagLib::String toTString(const QString &str) {
    return TagLib::String(str.toUtf8().constData(), TagLib::String::UTF8);
}

DbIndexer::DbIndexer(QObject *parent)
    : QObject(parent)
{
    setupDatabase();
}

DbIndexer::~DbIndexer()
{
    closeDatabase();
}

void DbIndexer::parse()
{
    setIndexing(true);
#ifdef QT_DEBUG
    qDebug() << "!!! Start indexing...";
    QElapsedTimer timer;
    timer.start();
#endif

    TagLib::FileRef f;
    QSqlQuery query;
    query.setForwardOnly(true);
    query.prepare(QStringLiteral("INSERT INTO Tracks (path, url, title, artist, album, year, genre, trackNo, length) "
                                 "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"));

    QVariantList paths, urls, titles, artists, albums, years, genres, trackNos, lengths;

    for (const auto &rootPath: qAsConst(m_rootPaths)) { // TODO watch paths for changes
        QDirIterator it(rootPath, {QStringLiteral("*.mp3"), QStringLiteral("*.ogg"), QStringLiteral("*.oga"),
                                   QStringLiteral("*.wma"), QStringLiteral("*.wav"), QStringLiteral("*.flac"),
                                   QStringLiteral("*.m4a"), QStringLiteral("*.aac")}, // FIXME find out dynamically
                        QDir::Files|QDir::NoDotAndDotDot|QDir::Readable,
                        QDirIterator::Subdirectories);
        while (it.hasNext()) {
            it.next();
            const QString filePath = it.filePath();

            //qDebug() << "Found audio file:" << filePath;
            f = TagLib::FileRef(QFile::encodeName(filePath));

            uint pos = 0;
            TagLib::MPEG::File f2(QFile::encodeName(filePath)); // TODO extend also beyond MP3
            if (f2.hasID3v2Tag()) {
                TagLib::ID3v2::Tag * tag = f2.ID3v2Tag();
                TagLib::ID3v2::FrameList l = tag->frameList("TPOS");
                if (!l.isEmpty()) {
                    TagLib::ID3v2::Frame * frame = l.front();
                    const int tmpPos = QString::fromLatin1(frame->toString().toCString()).section('/', 0, 0).toUInt(); // 1/0
                    if (tmpPos > 0)
                        pos = 1000 * tmpPos;
                }
            }

            QString album = f.tag()->album().toCString(true);
            if (album.isEmpty()) album = tr("Unknown album");
            QString genre = f.tag()->genre().toCString(true);
            if (genre.isEmpty()) genre = tr("Unknown genre");

            paths.append(filePath);
            urls.append(QUrl::fromLocalFile(filePath));
            titles.append(f.tag()->title().toCString(true));
            artists.append(f.tag()->artist().toCString(true));
            albums.append(album);
            years.append(f.tag()->year());
            genres.append(genre);
            trackNos.append(f.tag()->track() + pos);
            lengths.append(f.audioProperties()->lengthInSeconds());
        }
    }

    query.addBindValue(paths);
    query.addBindValue(urls);
    query.addBindValue(titles);
    query.addBindValue(artists);
    query.addBindValue(albums);
    query.addBindValue(years);
    query.addBindValue(genres);
    query.addBindValue(trackNos);
    query.addBindValue(lengths);

    if (!query.execBatch()) {
        qWarning() << "Failed to batch insert; error:" << query.lastError();
    }

    query.finish();
    query.clear();
    setIndexing(false);
#ifdef QT_DEBUG
    qDebug() << "!!! Indexing took" << timer.elapsed() << "ms";
#endif
}

QUrl DbIndexer::coverArtForFile(const QUrl &fileUrl) const
{
    const QString localFile = fileUrl.toLocalFile();
    const QString result = localFile + QStringLiteral(".png");
    if (QFile::exists(result))
        return QUrl::fromLocalFile(result);

    TagLib::MPEG::File f(QFile::encodeName(localFile)); // TODO extend also beyond MP3
    if (f.hasID3v2Tag()) {
        TagLib::ID3v2::Tag *tag = f.ID3v2Tag();
        TagLib::ID3v2::FrameList l = tag->frameList("APIC");
        if (l.isEmpty())
            return {};

        auto *frame = static_cast<TagLib::ID3v2::AttachedPictureFrame *>(l.front());
        if (!frame)
            return {};

        QImage image;
        image.loadFromData((const uchar *) frame->picture().data(), frame->picture().size());
        image.save(result);
        return QUrl::fromLocalFile(result);
    }

    return {};
}

QUrl DbIndexer::coverArtForAlbum(const QString &album) const
{
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT url FROM Tracks WHERE album=?"));
    q.addBindValue(album);
    if (!q.exec()) {
        qWarning() << "Failed to get list of tracks for album:" << album << "; error:" << q.lastError();
        return {};
    }
    QList<QUrl> tracks;
    while (q.next()) {
        tracks.push_back(q.value(0).toUrl());
    }
    q.finish();
    QUrl result;
    for (const QUrl &track: qAsConst(tracks)) {
        result = coverArtForFile(track);
        if (!result.isEmpty())
            break;
    }

    if (result.isEmpty())
        result = QStringLiteral("qrc:/icons/ic_album_48px.svg");

    return result;
}

bool DbIndexer::saveMetadata(const QUrl &url, const QString &title, const QString &artist, const QString &album,
                             int year, const QString &genre)
{
    auto f = TagLib::FileRef(QFile::encodeName(url.toLocalFile()));
    f.tag()->setTitle(toTString(title));
    f.tag()->setArtist(toTString(artist));
    f.tag()->setAlbum(toTString(album));
    f.tag()->setYear(year);
    f.tag()->setGenre(toTString(genre));
    bool result = f.save();

    QSqlQuery query;
    query.prepare(QStringLiteral("UPDATE Tracks SET title=?, artist=?, album=?, year=?, genre=? WHERE url=?"));
    query.addBindValue(title);
    query.addBindValue(artist);
    query.addBindValue(album);
    query.addBindValue(year);
    query.addBindValue(genre);
    query.addBindValue(url);
    result = result && query.exec();

    qDebug() << "Saved metadata for url:" << url << "; status:" << result;
    return result;
}

bool DbIndexer::saveAlbumMetadata(const QString &album, const QString &artist, const QString &genre, int year, const QUrl &albumCover)
{
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT id, path FROM Tracks WHERE album=? AND artist=?"));
    q.addBindValue(album);
    q.addBindValue(artist);
    if (!q.exec()) {
        qWarning() << "Failed to get list of tracks for album:" << album << "and artist:" << artist << "; error:" << q.lastError();
        return false;
    }

    QStringList paths;
    while (q.next()) {
        paths.push_back(q.value(1).toString());
    }
    q.finish();

    bool result = true;
    TagLib::FileRef f;
    QMimeDatabase mime;
    for (const auto &path: qAsConst(paths)) {
        f = TagLib::FileRef(QFile::encodeName(path));
        f.tag()->setGenre(toTString(genre));
        f.tag()->setYear(year);
        if (!f.save()) {
            result = false;
            if (albumCover.isEmpty())
                continue;
        }

//        TagLib::MPEG::File ff(QFile::encodeName(path)); // TODO extend also beyond MP3
//        if (ff.hasID3v2Tag()) {
//            TagLib::ID3v2::Tag *tag = ff.ID3v2Tag();
//            QImage image(albumCover.toLocalFile());
//            auto *frame = new TagLib::ID3v2::AttachedPictureFrame();
//            frame->setType(TagLib::ID3v2::AttachedPictureFrame::FrontCover);
//            frame->setMimeType(toTString(mime.mimeTypeForFile(path).name()));
//            frame->setPicture(TagLib::ByteVector(*image.constBits(), image.sizeInBytes()));
//            tag->addFrame(frame);
//            ff.save();
//        }
    }

    QSqlQuery query;
    query.prepare(QStringLiteral("UPDATE Tracks SET genre=?, year=? WHERE path IN (?)"));
    query.addBindValue(genre);
    query.addBindValue(year);
    query.addBindValue(paths.join(QStringLiteral(", ")));
    result = result && query.exec();

    qDebug() << "Saved metadata for album:" << album << "and artist:" << artist << "; status:" << result;
    return result;
}

QString DbIndexer::dbName() const
{
    return m_dbName;
}

QStringList DbIndexer::rootPaths() const
{
    return m_rootPaths;
}

void DbIndexer::setRootPaths(const QStringList &rootPaths)
{
    if (m_rootPaths == rootPaths)
        return;

    m_rootPaths = rootPaths;
    emit rootPathsChanged(m_rootPaths);
}

void DbIndexer::addRootPath(const QString &rootPath)
{
    if (m_rootPaths.contains(rootPath))
        return;

    m_rootPaths.append(rootPath);
    emit rootPathsChanged(m_rootPaths);
}

bool DbIndexer::isIndexing() const
{
    return m_indexing;
}

void DbIndexer::setIndexing(bool indexing)
{
    if (m_indexing == indexing)
        return;

    m_indexing = indexing;
    emit isIndexingChanged(m_indexing);
}

void DbIndexer::setupDatabase()
{
#if 0
    const auto storageLocation = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    //qDebug() << "Storage location:" << storageLocation;
    QDir storageDir(storageLocation);
    if (!storageDir.exists()) {
        storageDir.mkpath(storageLocation);
    }
#endif

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
#if 0
    db.setDatabaseName(storageLocation + QStringLiteral("/gmp.db"));
#endif
    db.setDatabaseName(QStringLiteral(":memory:"));

    if (!db.driver()->hasFeature(QSqlDriver::QuerySize)) {
        qInfo() << "DB driver" << db.driverName() << "doesn't support query size!";
    }

    if (!db.open()) {
        qWarning() << "Error opening the DB:" << db.lastError();
        return;
    }

    QSqlQuery query;
    if (!query.exec(QStringLiteral("CREATE TABLE IF NOT EXISTS Tracks ("
                                   "id INTEGER PRIMARY KEY AUTOINCREMENT,"
                                   "path TEXT UNIQUE,"
                                   "url TEXT NOT NULL,"
                                   "title TEXT,"
                                   "artist TEXT,"
                                   "album TEXT,"
                                   "year INTEGER,"
                                   "genre TEXT,"
                                   "trackNo INTEGER,"
                                   "length INTEGER)"))) {
        qWarning() << "Failed to create table 'Tracks':" << query.lastError();
        return;
    }

    m_dbName = db.databaseName();
    emit dbNameChanged(m_dbName);
    qDebug() << "!!! DB opened at:" << m_dbName;
}

void DbIndexer::closeDatabase()
{
    QSqlDatabase db = QSqlDatabase::database();
    if (db.isOpen()) {
        db.close();
    }
    QSqlDatabase::removeDatabase(db.connectionName());
}
