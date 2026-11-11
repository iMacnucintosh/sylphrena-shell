pragma Singleton

import Sylphrena
import Sylphrena.I18n

TranslatorInternal {
    // Catalogs shipped by extensions installed outside the shell (i18n/<lang>.json in the extension):
    // { <extension id>: { <lang>: { <msgid> | "<context>\u0004<msgid>": <translation> } } }. Set by
    // services/Extensions.qml. Only consulted when the shell's own catalog has no translation.
    property var extraCatalogs: ({})

    function _extra(text: string, context: string): string {
        const key = context ? `${context}\u0004${text}` : text;
        const name = locale.name;
        const langs = [language, name, name.split("_")[0]].filter(l => !!l);
        for (const id in extraCatalogs) {
            const byLang = extraCatalogs[id] ?? {};
            for (const l of langs) {
                const t = byLang[l]?.[key];
                if (typeof t === "string" && t.length > 0)
                    return t;
            }
        }
        return "";
    }

    function _withExtra(translated: string, text: string, context: string): string {
        return translated !== text ? translated : (_extra(text, context) || translated);
    }

    function formatDateTime(date: date, fmt: var): string {
        return date.toLocaleString(locale, fmt);
    }

    function tr(text: string): string {
        CUtils.dependency(__trsChanged);
        return _withExtra(_tr(text, "", false), text, "");
    }

    function trCtx(text: string, context: string): string {
        CUtils.dependency(__trsChanged);
        return _withExtra(_tr(text, context, false), text, context);
    }

    function trN(text: string, plural: string, n: int): string {
        CUtils.dependency(__trsChanged);
        return _trN(text, plural, n, "");
    }

    function trCtxN(text: string, plural: string, n: int, context: string): string {
        CUtils.dependency(__trsChanged);
        return _trN(text, plural, n, context);
    }

    function trMarked(text: string): string {
        CUtils.dependency(__trsChanged);
        return _withExtra(_tr(text, "", true), text, "");
    }
}
