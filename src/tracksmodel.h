#pragma once

#include <QAbstractListModel>
#include <QJsonObject>

class MusicIndexer;

class TracksModel : public QAbstractListModel
{
  Q_OBJECT
  Q_PROPERTY(int count READ count NOTIFY countChanged)

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

  Q_INVOKABLE QJsonObject getMetadata(const QUrl &url) const;

 signals:
  void countChanged();

 protected:
  QHash<int, QByteArray> roleNames() const override;
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

 private:
  int count() const;
  MusicIndexer *m_indexer;
};
