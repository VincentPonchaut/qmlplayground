#ifndef SVGELEMENT_H
#define SVGELEMENT_H

#include <QObject>
#include <QVariantMap>
#include <QXmlStreamReader>
#include <QXmlStreamWriter>

class SvgElement: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString svgId READ svgId WRITE setSvgId NOTIFY svgIdChanged)
    Q_PROPERTY(QVariantMap svgAttributes READ svgAttributes WRITE setSvgAttributes NOTIFY svgAttributesChanged)

public:
    explicit SvgElement(QObject* pParent = NULL);
    SvgElement(const SvgElement& pOther);
    virtual ~SvgElement();

    QString svgId() const;
    QVariantMap svgAttributes() const;

    void applyAttributes(QXmlStreamReader &pXml, QXmlStreamWriter &pStream);

public slots:
    void setSvgId(QString pSvgId);
    void setSvgAttributes(QVariantMap pSvgAttributes);

signals:

    void svgIdChanged(QString pSvgId);
    void svgAttributesChanged(QVariantMap pSvgAttributes);

protected:
    QString mSvgId;
    QVariantMap mSvgAttributes;
};

#endif // SVGELEMENT_H
