#pragma once

#include <QAbstractListModel>
#include <QJsonObject>

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

  Q_INVOKABLE QJsonObject getMetadata(const QUrl &url) const;

  Q_INVOKABLE QList<QUrl> allTracks() const;
  Q_INVOKABLE QList<QUrl> tracksByAlbum(const QString &album, bool ordered = false) const;
  Q_INVOKABLE QList<QUrl> tracksByGenre(const QString &genre, bool ordered = false) const;
  Q_INVOKABLE QList<QUrl> tracksByArtist(const QString &artist) const;
  Q_INVOKABLE int tracksDuration(const QList<QUrl> &urls) const;

 protected:
  QHash<int, QByteArray> roleNames() const override;
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

 private:
  MusicIndexer *m_indexer;
};
