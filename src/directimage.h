#pragma once

#include <QImage>
#include <QQuickPaintedItem>

class DirectImage : public QQuickPaintedItem
{
  Q_OBJECT
  Q_PROPERTY(QImage image READ image WRITE setImage NOTIFY imageChanged)

 public:
  DirectImage(QQuickItem *parent = nullptr);

 signals:
  void imageChanged();

 protected:
  void paint(QPainter *painer) override;

 private:
  QImage image() const;
  void setImage(const QImage &image);
  QImage m_image;
};
