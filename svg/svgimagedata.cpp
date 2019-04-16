#include "svgimagedata.h"
#include <QDir>
#include <QFile>

Q_DECLARE_METATYPE(SvgImageData)

SvgImageData::SvgImageData(QObject* pParent)
    : QObject(pParent)
    , mIsLoaded(false)
{
    connect(this, &SvgImageData::svgElementsChanged, this, &SvgImageData::processedContentStrChanged);
    connect(this, &SvgImageData::svgTextReplacementsChanged, this, &SvgImageData::processedContentStrChanged);
    connect(this, &SvgImageData::isLoadedChanged, this, &SvgImageData::processedContentStrChanged);
}

SvgImageData::SvgImageData(const SvgImageData& pOther)
    : QObject(pOther.parent())
{
    setSource(pOther.source());
}

SvgImageData::~SvgImageData()
{
}

const QUrl& SvgImageData::source() const
{
    return mSource;
}

void SvgImageData::setSource(const QUrl& pSource)
{
    if
        (mSource == pSource)
    {
        return;
    }

    // Assign the value ...
    mSource = pSource;

    // ...  attempt to load the file
    loadFile();

    // ... and notify
    emit sourceChanged(mSource);
}

void SvgImageData::setSvgTextReplacements(QVariantMap pSvgTextReplacements)
{
    if
        (mSvgTextReplacements == pSvgTextReplacements)
    {
        return;
    }

    mSvgTextReplacements = pSvgTextReplacements;
    loadFile();

    emit svgTextReplacementsChanged(mSvgTextReplacements);
}

void SvgImageData::readElement(QXmlStreamReader& pXml, QXmlStreamWriter& pStream)
{
    // If there is no ID, simply copy the element as it is
    if
        (! pXml.attributes().hasAttribute("id"))
    {
        pStream.writeCurrentToken(pXml);
        return;
    }

    // Then, try to find an element matching this ID
    QString lId = pXml.attributes().value("id").toString();
    SvgElement* lElement = nullptr;

    foreach
        (SvgElement* lSvgElement, mElements)
    {
        if
            (lSvgElement->svgId() == lId)
        {
            lElement = lSvgElement;
            break;
        }
    }

    // If there is none, we leave the element unmodified ...
    if
        (! lElement)
    {
        pStream.writeCurrentToken(pXml);
        return;
    }

    // If there is one, we apply it to our stream
    pStream.writeStartElement(pXml.name().toString());
    lElement->applyAttributes(pXml, pStream);
}

bool SvgImageData::loadFile()
{
    QString lSourcePath = mSource.toString();

    // Remove the "file:///" scheme (apparently not working with QFile)
    lSourcePath = lSourcePath.replace("file:///", "");

    // Remove initial "/" if any
    if
        (lSourcePath.startsWith("/"))
    {
        lSourcePath.remove(0, 1);
    }

    // Attempt to open the file ...
    QFile lFile(lSourcePath);
    if
        (! lFile.open(QIODevice::ReadOnly))
    {
        setIsLoaded(false);
        return false;
    }

    // ... then parse its elements
    QXmlStreamReader lXml;
    lXml.setDevice(&lFile);
    lXml.setNamespaceProcessing(false);

    mProcessedContent.clear();
    QXmlStreamWriter lStream(&mProcessedContent);
    lStream.setAutoFormatting(true);

    while
        (! lXml.atEnd())
    {
        lXml.readNext();

        switch
            (lXml.tokenType())
        {
            case QXmlStreamReader::StartElement:
            {
                readElement(lXml, lStream);
                break;
            }
            default:
            {
                lStream.writeCurrentToken(lXml);
                break;
            }
        };
    }
    lStream.writeEndDocument();

    applyTextReplacements(mProcessedContent);

    lFile.close();

    setIsLoaded(true);
    return true;
}

QByteArray SvgImageData::processedContent() const
{
    return mProcessedContent;
}

void SvgImageData::appendSvgElement(QQmlListProperty<SvgElement>* pList,SvgElement* pElem)
{
#if __cplusplus >= 201103L || _MSC_VER >= 1800
    SvgImageData* lImage = reinterpret_cast<SvgImageData*>(pList->data);

    if
        (pElem && lImage)
    {
        connect(pElem, &SvgElement::svgAttributesChanged, [=] ()
        {
            lImage->loadFile();
            emit lImage->svgElementsChanged();
        });

        lImage->mElements.append(pElem);
    }
#endif
}

int SvgImageData::svgElementCount(QQmlListProperty<SvgElement>* pList)
{
    return reinterpret_cast<SvgImageData*>(pList->data)->mElements.size();
}

SvgElement *SvgImageData::svgElementAt(QQmlListProperty<SvgElement>* pList, int pIndex)
{
    return reinterpret_cast<SvgImageData*>(pList->data)->mElements.at(pIndex);
}

void SvgImageData::clearSvgElements(QQmlListProperty<SvgElement>* pList)
{
    reinterpret_cast<SvgImageData*>(pList->data)->mElements.clear();
}

QQmlListProperty<SvgElement> SvgImageData::svgElements()
{
    return QQmlListProperty<SvgElement>(
        this,
        this,
        &SvgImageData::appendSvgElement,
        &SvgImageData::svgElementCount,
        &SvgImageData::svgElementAt,
        &SvgImageData::clearSvgElements
    );
}

QVariantMap SvgImageData::svgTextReplacements() const
{
    return mSvgTextReplacements;
}

void SvgImageData::applyTextReplacements(QByteArray& pBa)
{
    QMapIterator<QString, QVariant> lIt(mSvgTextReplacements);
    while
        (lIt.hasNext())
    {
        lIt.next();
        pBa.replace(lIt.key(), lIt.value().toString().toLocal8Bit().constData());
    }
}

bool SvgImageData::isLoaded() const
{
    return mIsLoaded;
}

void SvgImageData::setIsLoaded(bool isLoaded)
{
    if
        (mIsLoaded == isLoaded)
    {
        return;
    }

    mIsLoaded = isLoaded;

    emit isLoadedChanged(mIsLoaded);
}

QString SvgImageData::resolveSourceUrl(QString pBaseUrl, QString pSrcUrl)
{
    QDir lSrcPath(pSrcUrl);
    if
        (lSrcPath.isAbsolute())
    {
        return pSrcUrl;
    }

    QDir lBasePath(pBaseUrl);
    return lBasePath.relativeFilePath(pSrcUrl);
}

QString SvgImageData::processedContentStr()
{
    QString str(mProcessedContent);
    return str;
}

