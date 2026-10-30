#pragma once

#include <qobject.h>

namespace sylphrena::shell::settings {

class ChangeBatcher : public QObject {
    Q_OBJECT

public:
    explicit ChangeBatcher(QObject* parent = nullptr);

    void dirty();

signals:
    void dirtied();

private:
    bool m_dirty;

    void flush();
};

} // namespace sylphrena::shell::settings
