#include "borderconfig.hpp"

#include <algorithm>

namespace sylphrena::shell::config {

int BorderConfig::minThickness() {
    return 2;
}

int BorderConfig::clampedThickness() const {
    return std::max(minThickness(), m_thickness);
}

} // namespace sylphrena::shell::config
