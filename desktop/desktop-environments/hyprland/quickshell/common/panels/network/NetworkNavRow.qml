import QtQuick
import ".."
import qs.common.lib

NavRow {
    id: root

    property bool isPrimary: false

    trailingIcon: root.isPrimary ? MaterialSymbols.primaryRoute : ""
    trailingIconColor: Theme.colors.accent
}
