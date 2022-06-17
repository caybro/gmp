#pragma once

#include <QAbstractListModel>

class MusicIndexer;

class TracksModel : public QAbstractListModel
{
  Q_OBJECT

 public:
  enum TrackRole {
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
  Q_ENUM(TrackRole)

  explicit TracksModel(MusicIndexer *indexer = nullptr);

 protected:
  QHash<int, QByteArray> roleNames() const override;
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

 private:
  MusicIndexer *m_indexer;
};
