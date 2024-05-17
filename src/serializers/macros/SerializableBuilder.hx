package serializers.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

class SerializableBuilder {
    public static function findOrAddConstructor(fields:Array<Field>, hasSuper:Bool):Field {
        var ctor:Field = null;
        for (field in fields) {
            if (field.name == "new") {
                ctor = field;
            }
        }

        var expr = macro {
        }
        if (hasSuper) {
            expr = macro {
                super();
            }
        }

        if (ctor == null) {
            ctor = {
                name: "new",
                access: [APublic],
                kind: FFun({
                    args:[],
                    expr: expr
                }),
                pos: Context.currentPos()
            }
            fields.push(ctor);
        }

        return ctor;
    }

    public static function findOrAddSerialize(fields:Array<Field>, hasSuper:Bool):Field {
        var fn:Field = null;
        for (field in fields) {
            if (field.name == "serialize") {
                fn = field;
            }
        }
        
        var access = [APublic];
        if (hasSuper) {
            access.push(AOverride);
        }

        if (fn == null) {
            fn = {
                name: "serialize",
                access: access,
                kind: FFun({
                    args:[],
                    expr: macro {
                    },
                    ret: macro: String,
                }),
                pos: Context.currentPos()
            }
            fields.push(fn);
        }

        return fn;
    }

    public static function findOrAddUnserialize(fields:Array<Field>, hasSuper:Bool):Field {
        var fn:Field = null;
        for (field in fields) {
            if (field.name == "unserialize") {
                fn = field;
            }
        }

        var access = [APublic];
        if (hasSuper) {
            access.push(AOverride);
        }

        if (fn == null) {
            fn = {
                name: "unserialize",
                access: access,
                kind: FFun({
                    args:[{
                        name: "data",
                        type: macro: Any
                    }],
                    expr: macro {
                    }
                }),
                pos: Context.currentPos()
            }
            fields.push(fn);
        }

        return fn;
    }
}