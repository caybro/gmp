#pragma once

#include <QAbstractListModel>

#include <vector>

struct Genre
{
  QString genre;
  uint numTracks{0};
};

class MusicIndexer;

class GenresModel : public QAbstractListModel
{
  Q_OBJECT
  Q_PROPERTY(int count READ count NOTIFY countChanged)

 public:
  enum GenreRole {
    RoleGenre,
    RoleNumTracks,
  };
  Q_ENUM(GenreRole)

  explicit GenresModel(MusicIndexer *indexer = nullptr);

 signals:
  void countChanged();

 protected:
  QHash<int, QByteArray> roleNames() const override;
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

 private:
  int count() const;
  void parse();
  std::vector<Genre> m_db;
  MusicIndexer *m_indexer;
};
