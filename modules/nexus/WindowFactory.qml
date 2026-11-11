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

    // Nexus → Network on the add / edit VPN provider page: edit the provider at `index` of
    // utilities.vpn.provider, or (index -1) add one of provider type `type` ("" = commands)
    // (in the Nexus window that is already open, else in a new one)
    function openVpnEditor(index: int, type: string): void {
        const n = root.activeNexus;
        if (n) {
            n.editingVpnIndex = index;
            n.newVpnType = type;
            const net = PageRegistry.idxOf("network");
            if (n.currentPageIdx === net) {
                n.subPageIdxStack.length = 0;
                n.openSubPage(4);
                return;
            }
            // The page switch replaces the page: open the sub page once the new one is there (the old
            // one still gets the signal until then and would reject it)
            n.currentPageIdx = net;
            root._pendingVpnNexus = n;
            vpnEditorTimer.restart();
            return;
        }
        Updates.pendingNexusVpn = { index: index, type: type };
        openSubPage("network", 4);
    }

    property var _pendingVpnNexus: null

    Timer {
        id: vpnEditorTimer

        interval: 450
        onTriggered: {
            const n = root._pendingVpnNexus;
            root._pendingVpnNexus = null;
            if (n && root.activeNexus === n)
                n.openSubPage(4);
        }
    }

    // State of the Nexus window that is open (the last one opened), or null
    property var activeNexus: null

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
