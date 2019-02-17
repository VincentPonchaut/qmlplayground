#include "svgelement.h"

Q_DECLARE_METATYPE(SvgElement)

SvgElement::SvgElement(QObject* pParent)
: QObject(pParent)
{
}

SvgElement::SvgElement(const SvgElement &pOther)
: QObject(pOther.parent())
{
    setSvgId(pOther.svgId());
    setSvgAttributes(pOther.svgAttributes());
}

SvgElement::~SvgElement()
{
}

QString SvgElement::svgId() const
{
    return mSvgId;
}

QVariantMap SvgElement::svgAttributes() const
{
    return mSvgAttributes;
}

void SvgElement::applyAttributes(QXmlStreamReader &pXml, QXmlStreamWriter &pStream)
{
    // Prepare output
    QMap<QString, QString> lDstAttributesStr;

    // Copy the source to it
    foreach
        (const QXmlStreamAttribute& xmlAttributeSrc, pXml.attributes())
    {
        lDstAttributesStr[xmlAttributeSrc.name().toString()] = xmlAttributeSrc.value().toString();
    }

    // And iterate over own attributes to override
    QMapIterator<QString, QVariant> lIt(mSvgAttributes);
    while
        (lIt.hasNext())
    {
        lIt.next();
        lDstAttributesStr[lIt.key()] = lIt.value().toString(); // QVariant to QString here
    }

    // Once our new attribute map is ready, we simply need to write it in the stream
    QMapIterator<QString, QString> lDstIt(lDstAttributesStr);
    while
        (lDstIt.hasNext())
    {
        lDstIt.next();
        pStream.writeAttribute(QXmlStreamAttribute(lDstIt.key(), lDstIt.value()));
    }
}

void SvgElement::setSvgId(QString pSvgId)
{
    if
        (mSvgId == pSvgId)
    {
        return;
    }

    mSvgId = pSvgId;
    emit svgIdChanged(mSvgId);
}

void SvgElement::setSvgAttributes(QVariantMap pSvgAttributes)
{
    if
        (mSvgAttributes == pSvgAttributes)
    {
        return;
    }

    mSvgAttributes = pSvgAttributes;
    emit svgAttributesChanged(mSvgAttributes);
}
