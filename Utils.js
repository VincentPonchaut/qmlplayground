function isNull(pObject) {
    // @disable-check M126
    return pObject == undefined || typeof (pObject) == "undefined"
            || pObject == null
}

function isNotNull(pObject) {
    return !isNull(pObject)
}
