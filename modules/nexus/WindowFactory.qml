pragma Singleton

import QtQuick
import Quickshell
import Sylphrena.Config
import Sylphrena.I18n
import qs.components
import qs.services
import qs.modules.nexus

Singleton {
    id: root

    function create(parent: Item, props: var): void {
        nexusComp.createObject(parent ?? dummy, props);
    }

    // Normal Nexus window opened straight on a page (PageRegistry id), e.g. "bluetooth"
    function openPage(pageId: string): void {
        Updates.pendingNexusPageId = pageId;
        root.create();
    }

    // Same, but also opens one of the page's sub pages (index as in its NavRow.openSubPage)
    function openSubPage(pageId: string, subPageIdx: int): void {
        Updates.pendingNexusSubPageIdx = subPageIdx;
        openPage(pageId);
    }

    QtObject {
        id: dummy
    }

    Component {
        id: nexusComp

        FloatingWindow {
            id: win

            color: Colours.tPalette.m3surface
            surfaceFormat.opaque: false

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            implicitWidth: nexus.implicitWidth
            implicitHeight: nexus.implicitHeight

            minimumSize.width: contentItem.Tokens.sizes.nexus.minWidth
            minimumSize.height: contentItem.Tokens.sizes.nexus.minHeight

            contentItem.Config.screen: screen.name
            contentItem.Tokens.screen: screen.name

            title: Tr.tr("Nexus — %1").arg(PageRegistry.pages[nexus.nState.currentPageIdx].label)

            Nexus {
                id: nexus

                anchors.fill: parent
                nState.screen: win.screen
                nState.isWindow: true
                onClose: win.destroy()
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
