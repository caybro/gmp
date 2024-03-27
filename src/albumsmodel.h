#pragma once

#include <QAbstractListModel>
#include <QImage>

#include <vector>

struct Album
{
  QString album;
  QString artist;
  uint year;
  uint numTracks{0};
  QString genre;
  QImage coverImage;
};

class MusicIndexer;

class AlbumsModel : public QAbstractListModel
{
  Q_OBJECT
  Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

 public:
  enum AlbumRole {
    RoleAlbum,
    RoleArtist,
    RoleYear,
    RoleNumTracks,
    RoleGenre,
    RoleCoverImage,
  };
  Q_ENUM(AlbumRole)

  explicit AlbumsModel(MusicIndexer *indexer = nullptr);

 signals:
  void countChanged();

 protected:
  QHash<int, QByteArray> roleNames() const override;
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

 private:
  void parse();
  std::vector<Album> m_db;
  MusicIndexer *m_indexer;
};
