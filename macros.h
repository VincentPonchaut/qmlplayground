#ifndef MACROS_H
#define MACROS_H

// Read + Write in C++
// Read + Write in QML
#define PROPERTY(T, R, W)\
    public:\
      T R() const { return m_##R ; } \
    public Q_SLOTS: \
      void W(T R) {\
        if (m_##R == R) { return; } \
        m_##R = R;\
        emit R##Changed(R);}    \
    Q_SIGNALS:\
      void R##Changed(T R); \
    private:\
      Q_PROPERTY(T R READ R WRITE W NOTIFY R##Changed)\
      T m_##R;

// Read + Write in C++ (Same as above)
// Read-only in QML (Because `WRITE setterFunction` is not specified in Q_PROPERTY)
#define READONLY_PROPERTY(T, R, W)\
    public:\
      T R() const { return m_##R ; } \
    public Q_SLOTS: \
      void W(T R) {\
        if (m_##R == R) { return; } \
        m_##R = R;\
        emit R##Changed(R);}    \
    Q_SIGNALS:\
      void R##Changed(T R); \
    private:\
      Q_PROPERTY(T R READ R NOTIFY R##Changed);\
      T m_##R;

#endif // MACROS_H
