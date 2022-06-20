#include "musicindexer.h"

#include <taglib/attachedpictureframe.h>
#include <taglib/fileref.h>
#include <taglib/id3v2tag.h>
#include <taglib/mpegfile.h>

#include <QDebug>
#include <QDirIterator>
#include <QElapsedTimer>

#include <algorithm>

MusicIndexer::MusicIndexer(QObject *parent)
    : QObject{parent}
{
}

QStringList MusicIndexer::rootPaths() const
{
  return m_rootPaths;
}

void MusicIndexer::setRootPaths(const QStringList &rootPaths)
{
  if (m_rootPaths == rootPaths)
    return;

  m_rootPaths = rootPaths;
  emit rootPathsChanged(m_rootPaths);
}

void MusicIndexer::addRootPath(const QString &rootPath)
{
  if (m_rootPaths.contains(rootPath))
    return;

  m_rootPaths.append(rootPath);
  emit rootPathsChanged(m_rootPaths);
}

bool MusicIndexer::isIndexing() const
{
  return m_indexing;
}

void MusicIndexer::setIndexing(bool indexing)
{
  if (m_indexing == indexing)
    return;

  m_indexing = indexing;
  emit isIndexingChanged(m_indexing);
}

void MusicIndexer::parse(bool incremental)
{
  setIndexing(true);
#ifdef QT_DEBUG
  qDebug() << "!!! INDEXER start parsing...";
  QElapsedTimer timer;
  timer.start();
#endif

  if (!incremental)
    m_db.clear();

  TagLib::FileRef f;
  for (const auto &rootPath : qAsConst(m_rootPaths)) { // TODO watch paths for changes
    QDirIterator it(rootPath,
                    {QStringLiteral("*.mp3"), QStringLiteral("*.ogg"), QStringLiteral("*.oga"), QStringLiteral("*.wma"),
                     QStringLiteral("*.wav"), QStringLiteral("*.flac"), QStringLiteral("*.m4a"),
                     QStringLiteral("*.aac")}, // FIXME find out dynamically
                    QDir::Files | QDir::NoDotAndDotDot | QDir::Readable, QDirIterator::Subdirectories);
    while (it.hasNext()) {
      const QString filePath = it.next();
      //qDebug() << "Found audio file:" << filePath;

      f = TagLib::FileRef(QFile::encodeName(filePath));

      uint pos = 0;
      TagLib::MPEG::File f2(QFile::encodeName(filePath)); // TODO extend also beyond MP3
      if (f2.hasID3v2Tag()) {
        auto tag = f2.ID3v2Tag();
        const auto l = tag->frameList("TPOS");
        if (!l.isEmpty()) {
          const auto frame = l.front();
          const int tmpPos
              = QString::fromLatin1(frame->toString().toCString()).section(QLatin1Char('/'), 0, 0).toUInt(); // 1/0
          if (tmpPos > 0)
            pos = 1000 * tmpPos;
        }
      }

      const auto tag = f.tag();

      QString album = tag->album().toCString(true);
      if (album.isEmpty())
        album = tr("Unknown album");
      QString genre = tag->genre().toCString(true);
      if (genre.isEmpty())
        genre = tr("Unknown genre");

      MusicRecord rec;
      rec.path = filePath;
      rec.url = QUrl::fromLocalFile(filePath);
      rec.title = tag->title().toCString(true);
      rec.artist = tag->artist().toCString(true);
      rec.album = album;
      rec.year = tag->year();
      rec.genre = genre;
      rec.trackNo = tag->track() + pos;
      rec.length = f.audioProperties()->lengthInSeconds();

      if (incremental) {
        // erase old record
        const auto old = std::find_if(m_db.cbegin(), m_db.cend(),
                                      [&](const MusicRecord &rec) { return rec.path == filePath; });
        if (old != std::cend(m_db)) {
          m_db.erase(old);
        }
      }
      m_db.push_back(rec);
    }
  }

  setIndexing(false);
  emit dataChanged();
#ifdef QT_DEBUG
  qDebug() << "!!! INDEXER took" << timer.elapsed() << "ms";
  qDebug() << "!!! INDEXER found" << m_db.size() << "files";
#endif
}

const MusicDatabase &MusicIndexer::database() const
{
  return m_db;
}