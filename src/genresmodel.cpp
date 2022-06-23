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

  QSet<QString> genres;
  for (const auto &rec : m_indexer->database()) {
    genres.insert(rec.genre);
  }
  for (const auto &genre : genres) {
    const int count = std::count_if(m_indexer->database().cbegin(), m_indexer->database().cend(),
                                    [genre](const auto &rec) { return rec.genre == genre; });
    m_db.push_back({genre, count});
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
  if (!checkIndex(index, QAbstractItemModel::CheckIndexOption::IndexIsValid
                             | QAbstractItemModel::CheckIndexOption::ParentIsInvalid))
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
