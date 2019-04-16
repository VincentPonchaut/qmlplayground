#ifndef SVGIMAGE_H
#define SVGIMAGE_H

// Qt
#include <QUrl>
#include <QObject>
#include <QQmlListProperty>
#include <QQmlPropertyMap>
#include <QVariantMap>
#include <QXmlStreamReader>
#include <QXmlStreamWriter>

#include "svgelement.h"

class SvgImageData : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(QQmlListProperty<SvgElement> svgElements READ svgElements)
    Q_PROPERTY(QVariantMap svgTextReplacements READ svgTextReplacements WRITE setSvgTextReplacements NOTIFY svgTextReplacementsChanged)
    Q_PROPERTY(bool isLoaded READ isLoaded WRITE setIsLoaded NOTIFY isLoadedChanged)
    Q_PROPERTY(QString processedContentStr READ processedContentStr NOTIFY processedContentStrChanged)
    Q_CLASSINFO("DefaultProperty", "svgElements")

public:
    explicit SvgImageData(QObject* pParent = nullptr);
    SvgImageData(const SvgImageData& pOther);
    virtual ~SvgImageData();

    bool loadFile();
    const QUrl& source() const;
    QByteArray processedContent() const;
    QString processedContentStr();
    QQmlListProperty<SvgElement> svgElements();
    QVariantMap svgTextReplacements() const;
    bool isLoaded() const;

    Q_INVOKABLE QString resolveSourceUrl(QString pBaseUrl, QString pSrcUrl);

public slots:
    void setSource(const QUrl& pSource);
    void setSvgTextReplacements(QVariantMap pSvgTextReplacements);
    void setIsLoaded(bool pIsLoaded);

signals:
    void sourceChanged(QUrl pSource);
    void svgTextReplacementsChanged(QVariantMap pSvgTextReplacements);
    void svgElementsChanged();
    void isLoadedChanged(bool isLoaded);
    void processedContentStrChanged();

protected:
    static void appendSvgElement(QQmlListProperty<SvgElement>* pList, SvgElement* pElem);
    static int svgElementCount(QQmlListProperty<SvgElement>* pList);
    static SvgElement* svgElementAt(QQmlListProperty<SvgElement>* pList, int pIndex);
    static void clearSvgElements(QQmlListProperty<SvgElement>* pList);
    void applyTextReplacements(QByteArray& pBa);
    void readElement(QXmlStreamReader& pXml, QXmlStreamWriter& pStream);

private:
    QUrl mSource;
    QByteArray mProcessedContent;
    QVector<SvgElement*> mElements;
    QVariantMap mSvgTextReplacements;
    bool mIsLoaded;
};

#endif // SVGIMAGE_H
