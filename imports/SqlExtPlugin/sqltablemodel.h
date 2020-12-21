#pragma once

#include <QSqlTableModel>
#include <QQmlParserStatus>
#include <QmlTypeAndRevisionsRegistration>

class SqlTableModel : public QSqlTableModel, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    Q_DISABLE_COPY(SqlTableModel)
    QML_ELEMENT

    Q_PROPERTY(QString db READ dbFileName WRITE setDbFileName NOTIFY dbFileNameChanged REQUIRED)
    Q_PROPERTY(QString table READ tableName WRITE setTable NOTIFY tableNameChanged REQUIRED)
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    // TODO user, password, hostname, port

public:
    SqlTableModel(QObject *parent = nullptr);
    ~SqlTableModel();

    void classBegin() override;
    void componentComplete() override;

    QString dbFileName() const;
    void setDbFileName(const QString &dbFileName);

    void setTable(const QString &name) override;
    void setFilter(const QString &filt) override;

    Q_INVOKABLE bool isValid() const;
    Q_INVOKABLE QString errorMessage() const;

signals:
    void dbFileNameChanged();
    void tableNameChanged();
    void filterChanged();

private:
    QSqlDatabase m_db;
};
