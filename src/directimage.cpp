#include "directimage.h"

#include <QPainter>

DirectImage::DirectImage(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
  setFlag(ItemHasContents);
  setRenderTarget(FramebufferObject);
}

void DirectImage::paint(QPainter *painter)
{
  painter->drawImage(QRectF(0, 0, width(), height()), m_image);
}

QImage DirectImage::image() const
{
  return m_image;
}

void DirectImage::setImage(const QImage &image)
{
  if (m_image == image)
    return;

  m_image = image;
  emit imageChanged();

  setImplicitWidth(image.width());
  setImplicitHeight(image.height());
  update();
}
