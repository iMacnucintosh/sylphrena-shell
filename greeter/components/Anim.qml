import QtQuick
import qs.services

NumberAnimation {
    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        StandardExtraLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge,
        EmphasizedExtraLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial,
        FastEffects,
        DefaultEffects,
        SlowEffects
    }

    property int type: Anim.DefaultSpatial

    duration: {
        const d = Theme.durations;
        switch (type) {
        case Anim.FastSpatial:
            return d.fastSpatial;
        case Anim.DefaultSpatial:
            return d.defaultSpatial;
        case Anim.SlowSpatial:
            return d.slowSpatial;
        case Anim.FastEffects:
            return d.fastEffects;
        case Anim.DefaultEffects:
            return d.defaultEffects;
        case Anim.SlowEffects:
            return d.slowEffects;
        }
        return [d.small, d.normal, d.large, d.extraLarge][type % 4] ?? d.normal;
    }
    easing.type: Easing.BezierSpline
    easing.bezierCurve: {
        const c = Theme.curves;
        switch (type) {
        case Anim.FastSpatial:
            return c.fastSpatial;
        case Anim.DefaultSpatial:
            return c.defaultSpatial;
        case Anim.SlowSpatial:
            return c.slowSpatial;
        case Anim.FastEffects:
            return c.fastEffects;
        case Anim.DefaultEffects:
            return c.defaultEffects;
        case Anim.SlowEffects:
            return c.slowEffects;
        }
        if (type >= Anim.EmphasizedSmall && type <= Anim.EmphasizedExtraLarge)
            return c.emphasized;
        return c.standard;
    }
}
