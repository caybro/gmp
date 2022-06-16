#pragma once

#include <QAbstractListModel>
#include <QStandardPaths>
#include <QUrl>
#include <QmlTypeAndRevisionsRegistration>

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

class MusicIndexer : public QAbstractListModel
{
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

  Q_PROPERTY(QStringList rootPaths READ rootPaths WRITE setRootPaths NOTIFY rootPathsChanged)
  Q_PROPERTY(bool indexing READ isIndexing NOTIFY isIndexingChanged)

 public:
  enum MusicRecordRole {
    RolePath = Qt::UserRole + 1,
    RoleUrl,
    RoleTitle,
    RoleArtist,
    RoleAlbum,
    RoleYear,
    RoleGenre,
    RoleTrackNo,
    RoleLength,
  };
  Q_ENUM(MusicRecordRole)

  explicit MusicIndexer(QObject *parent = nullptr);

  Q_INVOKABLE void parse(bool incremental = false);

 protected:
  QHash<int, QByteArray> roleNames() const override;
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

 signals:
  void rootPathsChanged(const QStringList &rootPaths);
  void isIndexingChanged(bool indexing);

 private:
  QStringList rootPaths() const;
  void setRootPaths(const QStringList &rootPaths);
  void addRootPath(const QString &rootPath);

  bool isIndexing() const;
  void setIndexing(bool indexing);

  QStringList m_rootPaths{QStandardPaths::standardLocations(QStandardPaths::MusicLocation)};
  bool m_indexing{false};

  std::vector<MusicRecord> m_db;
};
