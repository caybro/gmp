#pragma once

#include <QSqlQueryModel>
#include <QSqlQuery>
#include <QQmlParserStatus>
#include <QmlTypeAndRevisionsRegistration>

class SqlQueryModel : public QSqlQueryModel, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    Q_DISABLE_COPY(SqlQueryModel)
    QML_ELEMENT

    Q_PROPERTY(QString db READ dbFileName WRITE setDbFileName NOTIFY dbFileNameChanged REQUIRED)
    Q_PROPERTY(QString query READ queryString WRITE setQueryString NOTIFY queryChanged REQUIRED)
    // TODO user, password, hostname, port

public:
    explicit SqlQueryModel(QObject *parent = nullptr);
    ~SqlQueryModel();

    void classBegin() override;
    void componentComplete() override;

    QString dbFileName() const;
    void setDbFileName(const QString &dbFileName);

    QString queryString() const;
    void setQueryString(const QString &query);

    Q_INVOKABLE bool isValid() const;
    Q_INVOKABLE QString errorMessage() const;

    Q_INVOKABLE QVariant get(int row, const QString &name) const;

signals:
    void dbFileNameChanged();
    void queryChanged();

private:
    QSqlDatabase m_db;
    QString m_query;
};