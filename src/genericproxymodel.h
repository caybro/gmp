#pragma once

#include <QSortFilterProxyModel>
#include <QmlTypeAndRevisionsRegistration>

class GenericProxyModel : public QSortFilterProxyModel
{
  Q_OBJECT
  QML_ELEMENT

  Q_PROPERTY(QString filterString READ filterString WRITE setFilterString NOTIFY filterStringChanged)

 public:
  GenericProxyModel(QObject *parent = nullptr);

 signals:
  void filterStringChanged(const QString &filterString);

 private:
  QString filterString() const;
  void setFilterString(const QString &filterString);
  QString m_filterString;
};
