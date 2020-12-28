#pragma once

#include <QObject>
#include <QStandardPaths>
#include <QmlTypeAndRevisionsRegistration>

class DbIndexer : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QStringList rootPaths READ rootPaths WRITE setRootPaths NOTIFY rootPathsChanged)
    Q_PROPERTY(bool indexing READ isIndexing NOTIFY isIndexingChanged)
    Q_PROPERTY(QString dbName READ dbName NOTIFY dbNameChanged)

public:
    explicit DbIndexer(QObject *parent = nullptr);
    ~DbIndexer();

    Q_INVOKABLE void parse();

    Q_INVOKABLE QUrl coverArtForFile(const QUrl &fileUrl) const;
    Q_INVOKABLE QUrl coverArtForAlbum(const QString &album) const;
    Q_INVOKABLE bool saveMetadata(const QUrl &url, const QString &title, const QString &artist, const QString &album,
                                  int year, const QString &genre);

signals:
    void rootPathsChanged(const QStringList &rootPaths);
    void isIndexingChanged(bool indexing);
    void dbNameChanged(const QString &dbName);

private:
    QStringList rootPaths() const;
    void setRootPaths(const QStringList &rootPaths);
    void addRootPath(const QString & rootPath);

    bool isIndexing() const;
    void setIndexing(bool indexing);

    QString dbName() const;

    void setupDatabase();
    void closeDatabase();

    QStringList m_rootPaths{QStandardPaths::standardLocations(QStandardPaths::MusicLocation)};
    bool m_indexing{false};
    QString m_dbName;
};
