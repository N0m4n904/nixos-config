pragma Singleton
import QtQuick

QtObject {
    readonly property string widgets: "quickshell:widgets"
    readonly property string clock: "quickshell:clock"
    readonly property string popover: "quickshell:popover"

    function panelContent(name, id) { return `quickshell:panel-${name}-${id}` }
    function panelBlur(name, id) { return `quickshell:panel-${name}-${id}-blur` }
    function panelRuleName(name, id, isBlur) {
        return isBlur ? `panel-${name}-${id}-blur` : `panel-${name}-${id}`
    }
}
