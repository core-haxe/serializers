package serializers.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

class SerializableBuilder {
    public static function findOrAddConstructor(fields:Array<Field>):Field {
        var ctor:Field = null;
        for (field in fields) {
            if (field.name == "new") {
                ctor = field;
            }
        }

        if (ctor == null) {
            ctor = {
                name: "new",
                access: [APublic],
                kind: FFun({
                    args:[],
                    expr: macro {
                    }
                }),
                pos: Context.currentPos()
            }
            fields.push(ctor);
        }

        return ctor;
    }

    public static function findOrAddSerialize(fields:Array<Field>):Field {
        var fn:Field = null;
        for (field in fields) {
            if (field.name == "serialize") {
                fn = field;
            }
        }
        
        if (fn == null) {
            fn = {
                name: "serialize",
                access: [APublic],
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

    public static function findOrAddUnserialize(fields:Array<Field>):Field {
        var fn:Field = null;
        for (field in fields) {
            if (field.name == "unserialize") {
                fn = field;
            }
        }

        if (fn == null) {
            fn = {
                name: "unserialize",
                access: [APublic],
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