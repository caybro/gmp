#pragma once

#include <QObject>
#include <QStandardPaths>
#include <QUrl>

#include <vector>

struct MusicRecord
{
  QString path;
  QUrl url;
  QString title;
  QString artist;
  QString album;
  uint year;
  QString genre;
  uint trackNo;
  int length;
};

using MusicDatabase = std::vector<MusicRecord>;

class MusicIndexer : public QObject
{
  Q_OBJECT

  Q_PROPERTY(QStringList rootPaths READ rootPaths WRITE setRootPaths NOTIFY rootPathsChanged)
  Q_PROPERTY(bool indexing READ isIndexing NOTIFY isIndexingChanged)

 public:
  explicit MusicIndexer(QObject *parent = nullptr);

  Q_INVOKABLE void parse(bool incremental = false);

  const MusicDatabase &database() const;

  Q_INVOKABLE QList<QUrl> allTracks() const;
  Q_INVOKABLE QList<QUrl> tracksByAlbum(const QString &album, bool ordered = false) const;
  Q_INVOKABLE QList<QUrl> tracksByGenre(const QString &genre, bool ordered = false) const;
  Q_INVOKABLE QList<QUrl> tracksByArtist(const QString &artist) const;
  Q_INVOKABLE int tracksDuration(const QList<QUrl> &urls) const;
  Q_INVOKABLE int albumTracksDuration(const QString &album) const;

  Q_INVOKABLE QUrl coverArtForFile(const QUrl &fileUrl) const;
  Q_INVOKABLE QUrl coverArtForAlbum(const QString &album) const;

 signals:
  void rootPathsChanged(const QStringList &rootPaths);
  void isIndexingChanged(bool indexing);
  void dataChanged();

 private:
  QStringList rootPaths() const;
  void setRootPaths(const QStringList &rootPaths);
  void addRootPath(const QString &rootPath);

  bool isIndexing() const;
  void setIndexing(bool indexing);

  QStringList m_rootPaths{QStandardPaths::standardLocations(QStandardPaths::MusicLocation)};
  bool m_indexing{false};

  MusicDatabase m_db;
};

inline uint qHash(const MusicRecord &rec)
{
  return qHash(rec.path);
}

inline bool operator==(const MusicRecord &rec1, const MusicRecord &rec2)
{
  return rec1.path == rec2.path;
}
