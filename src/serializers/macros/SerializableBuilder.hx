package serializers.macros;

import haxe.macro.ExprTools;
import haxe.macro.Type.MetaAccess;
import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

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

    public static function getConfig(meta:MetaAccess):SerializerConfig {
        var config:SerializerConfig = {
            ignore: []
        };

        for (serializer in meta.extract(":serializer")) {
            var expr = ExprTools.map(serializer.params[0], addQuotes);
            var tempConfig:SerializerConfig = ExprTools.getValue(expr);
            if (tempConfig != null && tempConfig.ignore != null) {
                config.ignore = config.ignore.concat(tempConfig.ignore);
            }
        }

        var ignoreFields = [];
        for (serializerIgnore in meta.extract(":serializerIgnore")) {
            for (param in serializerIgnore.params) {
                switch (param.expr) {
                    case EConst(CIdent(s)):
                        for (f in s.split(",")) {
                            f = f.trim();
                            if (!ignoreFields.contains(f)) {
                                ignoreFields.push(f);
                            }
                        }
                    case _:    
                }
            }
        }
        config.ignore = config.ignore.concat(ignoreFields);


        return config;
    }

    private static function addQuotes(f:Expr):Expr {
        return switch (f.expr) {
            case EConst(CIdent(s)): macro $v{s};
            case _:                 ExprTools.map(f, addQuotes);
        }
    }

    private static function parseSerializerSettings(s:String) {
        var settings:Dynamic = {};
        return settings;
    }
}