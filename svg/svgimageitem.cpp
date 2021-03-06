#include "svgimageitem.h"
#include "svgelement.h"

#include <QQmlEngine>

SvgImageItem::SvgImageItem(QQuickItem* pParent)
    : QQuickPaintedItem(pParent)
{
    connect(&mSvgImage, &SvgImageData::sourceChanged, this, &SvgImageItem::sourceChanged);
    connect(&mSvgImage, &SvgImageData::svgElementsChanged, this, &SvgImageItem::svgElementsChanged);
    connect(&mSvgImage, &SvgImageData::svgTextReplacementsChanged, this, &SvgImageItem::svgTextReplacementsChanged);
    connect(&mSvgImage, &SvgImageData::isLoadedChanged, this, &SvgImageItem::isLoadedChanged);

    // Repaint when something is modified
    connect(&mSvgImage, &SvgImageData::sourceChanged, this, &SvgImageItem::handleDataChange);
    connect(&mSvgImage, &SvgImageData::svgElementsChanged, this, &SvgImageItem::handleDataChange);
    connect(&mSvgImage, &SvgImageData::svgTextReplacementsChanged, this, &SvgImageItem::handleDataChange);
    connect(&mSvgImage, &SvgImageData::isLoadedChanged, this, &SvgImageItem::handleDataChange);
}

SvgImageItem::~SvgImageItem()
{

}

void SvgImageItem::paint(QPainter *pPainter)
{
    mRenderer.load(mSvgImage.processedContent());
    mRenderer.render(pPainter);
}

const QUrl&SvgImageItem::source() const
{
    return mSvgImage.source();
}

void SvgImageItem::setSource(const QUrl& pSource)
{
    mSvgImage.setSource(pSource);
}

void SvgImageItem::setSvgTextReplacements(QVariantMap pSvgTextReplacements)
{
    mSvgImage.setSvgTextReplacements(pSvgTextReplacements);
}

QQmlListProperty<SvgElement> SvgImageItem::svgElements()
{
    return mSvgImage.svgElements();
}

QVariantMap SvgImageItem::svgTextReplacements() const
{
    return mSvgImage.svgTextReplacements();
}


bool SvgImageItem::isLoaded() const
{
    return mSvgImage.isLoaded();
}

void SvgImageItem::setIsLoaded(bool isLoaded)
{
    mSvgImage.setIsLoaded(isLoaded);
}

void SvgImageItem::repaint()
{
    // Call QQuickPaintedItem::update(QRect r = QRect()) to redraw
    update();
}

void SvgImageItem::handleDataChange()
{
    repaint();
    emit this->processedContentChanged(processedContent());
}

void SvgImageItem::registerQmlTypes(const char *uri)
{
    qmlRegisterType<SvgElement>(uri, 1, 0, "SvgElement");
    qmlRegisterType<SvgImageItem>(uri, 1, 0, "SvgImage");
}

QString SvgImageItem::processedContent() const
{
    return QString(mSvgImage.processedContent());
}
