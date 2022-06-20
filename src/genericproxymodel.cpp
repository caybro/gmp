#include "genericproxymodel.h"

GenericProxyModel::GenericProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
  setSortCaseSensitivity(Qt::CaseInsensitive);
  setFilterCaseSensitivity(Qt::CaseInsensitive);
  setSortLocaleAware(true);

  sort(0);
}

QString GenericProxyModel::filterString() const
{
  return m_filterString;
}

void GenericProxyModel::setFilterString(const QString &filterString)
{
  if (m_filterString == filterString)
    return;

  m_filterString = filterString;
  setFilterWildcard(m_filterString);
  emit filterStringChanged(m_filterString);
}
