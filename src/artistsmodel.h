#pragma once

#include <QAbstractListModel>

#include <vector>

struct Artist
{
  Artist(const QString &a, uint n)
      : artist(std::move(a))
      , numAlbums(std::move(n))
  {}
  QString artist;
  uint numAlbums{0};
};

class MusicIndexer;

class ArtistsModel : public QAbstractListModel
{
  Q_OBJECT
  Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

 public:
  enum ArtistRole {
    RoleArtist,
    RoleNumAlbums,
  };
  Q_ENUM(ArtistRole)

  explicit ArtistsModel(MusicIndexer *indexer = nullptr);

 signals:
  void countChanged();

 protected:
  QHash<int, QByteArray> roleNames() const override;
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

 private:
  void parse();
  std::vector<Artist> m_db;
  MusicIndexer *m_indexer;
};
