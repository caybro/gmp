#pragma once

#include <QAbstractListModel>

#include <vector>

struct Album
{
  QString album;
  QString artist;
  uint year;
  int numTracks{0};
  QString genre;
};

class MusicIndexer;

class AlbumsModel : public QAbstractListModel
{
  Q_OBJECT

 public:
  enum AlbumRole {
    RoleAlbum,
    RoleArtist,
    RoleYear,
    RoleNumTracks,
    RoleGenre,
  };
  Q_ENUM(AlbumRole)

  explicit AlbumsModel(MusicIndexer *indexer = nullptr);

 protected:
  QHash<int, QByteArray> roleNames() const override;
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

 private:
  void parse();
  std::vector<Album> m_db;
  MusicIndexer *m_indexer;
};