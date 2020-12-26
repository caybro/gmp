#include "dbindexer.h"

#include <QDir>
#include <QSqlDatabase>
#include <QSqlDriver>
#include <QSqlError>
#include <QDebug>
#include <QSqlQuery>
#include <QDirIterator>
#include <QFile>
#include <QDebug>
#include <QHashIterator>
#include <QUrl>
#include <QElapsedTimer>
#include <QImage>

#include <taglib/fileref.h>
#include <taglib/id3v2tag.h>
#include <taglib/attachedpictureframe.h>
#include <taglib/mpegfile.h>

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
                                 "VALUES (:path, :url, :title, :artist, :album, :year, :genre, :trackNo, :length)"));

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

            query.bindValue(QStringLiteral(":path"), filePath);
            query.bindValue(QStringLiteral(":url"), QUrl::fromLocalFile(filePath));
            query.bindValue(QStringLiteral(":title"), f.tag()->title().toCString(true));
            query.bindValue(QStringLiteral(":artist"), f.tag()->artist().toCString(true));
            query.bindValue(QStringLiteral(":album"), album);
            query.bindValue(QStringLiteral(":year"), f.tag()->year());
            query.bindValue(QStringLiteral(":genre"), genre);
            query.bindValue(QStringLiteral(":trackNo"), f.tag()->track() + pos);
            query.bindValue(QStringLiteral(":length"), f.audioProperties()->lengthInSeconds());
            if (!query.exec()) {
                //qWarning() << "Failed to insert track:" << filePath << "; error:" << query.lastError().text();
            }
            query.finish();
        }
    }

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

        TagLib::ID3v2::AttachedPictureFrame *f = static_cast<TagLib::ID3v2::AttachedPictureFrame *>(l.front());
        if (!f)
            return {};

        QImage image;
        image.loadFromData((const uchar *) f->picture().data(), f->picture().size());
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
    for (const QUrl &track: tracks) {
        result = coverArtForFile(track);
        if (!result.isEmpty())
            break;
    }

    if (result.isEmpty())
        result = QStringLiteral("qrc:/icons/ic_album_48px.svg");

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
    const auto storageLocation = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    //qDebug() << "Storage location:" << storageLocation;
    QDir storageDir(storageLocation);
    if (!storageDir.exists()) {
        storageDir.mkpath(storageLocation);
    }

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
    db.setDatabaseName(storageLocation + QStringLiteral("/gmp.db"));
    if (!db.open()) {
        qWarning() << "DB open failed:" << db.lastError();
        return;
    }

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
