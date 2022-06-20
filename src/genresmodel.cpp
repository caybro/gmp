#include "genresmodel.h"

#include <QSet>

#include "musicindexer.h"

GenresModel::GenresModel(MusicIndexer *indexer)
    : QAbstractListModel{indexer}
    , m_indexer(indexer)
{
  connect(m_indexer, &MusicIndexer::dataChanged, this, &GenresModel::parse);
}

void GenresModel::parse()
{
  beginResetModel();
  m_db.clear();

  // get list of uniq genres
  QMap<QString, int> genres;
  for (const auto &rec : m_indexer->database()) {
    genres.insert(rec.genre, 0);
  }

  // count each genres's tracks
  QMap<QString, int>::iterator it;
  for (it = genres.begin(); it != genres.end(); ++it) {
    QSet<QString> tracks;
    for (const auto &rec : m_indexer->database()) {
      if (rec.genre == it.key()) {
        tracks.insert(rec.path);
      }
    }
    it.value() = tracks.size();

    // finally insert into our datastructure
    m_db.push_back({it.key(), it.value()});
  }

  emit countChanged();
  endResetModel();
}

QHash<int, QByteArray> GenresModel::roleNames() const
{
  static QHash<int, QByteArray> roleNames = {{GenresModel::RoleGenre, QByteArrayLiteral("genre")},
                                             {GenresModel::RoleNumTracks, QByteArrayLiteral("numTracks")}};

  return roleNames;
}

int GenresModel::rowCount(const QModelIndex &) const
{
  return m_db.size();
}

QVariant GenresModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid())
    return {};

  if (index.row() >= static_cast<int>(m_db.size()))
    return {};

  const auto item = m_db[index.row()];

  switch (static_cast<GenreRole>(role)) {
  case GenresModel::RoleGenre:
    return item.genre;
  case GenresModel::RoleNumTracks:
    return item.numTracks;
  }

  return {};
}

int GenresModel::count() const
{
  return rowCount();
}
