#ifndef  SVGIMAGEITEM_H
#define  SVGIMAGEITEM_H

#include <QSvgRenderer>
#include <QQuickPaintedItem>
#include <QQmlListProperty>
#include <QVariantMap>
#include <QUrl>

#include "svgimagedata.h"
#include "svgelement.h"

class QPainter;
class QQmlEngine;

class SvgImageItem: public QQuickPaintedItem
{
    Q_OBJECT

    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(QQmlListProperty<SvgElement> svgElements READ svgElements)
    Q_PROPERTY(QVariantMap svgTextReplacements READ svgTextReplacements WRITE setSvgTextReplacements NOTIFY svgTextReplacementsChanged)
    Q_PROPERTY(bool isLoaded READ isLoaded WRITE setIsLoaded NOTIFY isLoadedChanged)
    Q_PROPERTY(QString processedContent READ processedContent NOTIFY processedContentChanged)
    Q_CLASSINFO("DefaultProperty", "svgElements")

public:
    explicit SvgImageItem(QQuickItem *pParent = nullptr);
    virtual ~SvgImageItem();

    // QQuickPaintedItem interface
    virtual void paint(QPainter *pPainter) override;

    // QProperties
    const QUrl& source() const;
    QQmlListProperty<SvgElement> svgElements();
    QVariantMap svgTextReplacements() const;
    bool isLoaded() const;
    QString processedContent() const;

    // QML engine
    static void registerQmlTypes(const char* uri);

public slots:
    void setSource(const QUrl& pSource);
    void setSvgTextReplacements(QVariantMap pSvgTextReplacements);
    void setIsLoaded(bool pIsLoaded);
    void repaint();

    void handleDataChange();

signals:
    void sourceChanged(QUrl pSource);
    void svgTextReplacementsChanged(QVariantMap pSvgTextReplacements);
    void svgElementsChanged();
    void isLoadedChanged(bool isLoaded);
    void processedContentChanged(QString processedContent);

private:
    SvgImageData mSvgImage;
    QSvgRenderer mRenderer;
    QString m_processedContent;
};

#endif // SVGIMAGEITEM_H
