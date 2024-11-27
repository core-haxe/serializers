package serializers.macros;

#if macro

import haxe.macro.Type.ClassType;
import haxe.macro.ExprTools;
import haxe.macro.Type.MetaAccess;
import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;

class SerializableBuilder {
    public static function classTypeHasInterface(classType:ClassType, interfaceToCheck:String) {
        for (i in classType.interfaces) {
            if (i.t.toString() == interfaceToCheck) {
                return true;
            }
        }
        return false;
    }

    public static function fieldHasMeta(field:Field, metaName:String):Bool {
        if (field.meta == null) {
            return false;
        }

        for (m in field.meta) {
            if (m.name == metaName || m.name == ":" + metaName) {
                return true;
            }
        }

        return false;
    }
    public static function findOrAddConstructor(fields:Array<Field>, hasSuper:Bool):Field {
        var ctor:Field = null;
        for (field in fields) {
            if (field.name == "new") {
                ctor = field;
            }
        }

        var expr = macro { }
        if (hasSuper) {
            expr = macro {
                super();
            }
        }

        if (Context.getLocalClass().get().isExtern) {
            expr = null;
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

        var expr = macro {}
        if (Context.getLocalClass().get().isExtern) {
            expr = null;
        }

        if (fn == null) {
            fn = {
                name: "serialize",
                access: access,
                kind: FFun({
                    args:[],
                    expr: expr,
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

        var expr = macro {}
        if (Context.getLocalClass().get().isExtern) {
            expr = null;
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
                    expr: expr,
                    ret: macro: Void
                }),
                pos: Context.currentPos()
            }
            fields.push(fn);
        }

        return fn;
    }

    public static function getConfig(classType:ClassType):SerializerConfig {
        var config:SerializerConfig = {
            ignore: [],
            transformers: []
        };

        var ref = classType;
        while (ref != null) {
            var tempConfigs = extractConfigFromMeta(ref.meta);
            for (c in tempConfigs) {
                if (c.transformers == null) {
                    continue;
                }
                for (t in c.transformers) {
                    if (!config.transformers.contains(t)) {
                        config.transformers.push(t);
                    }
                }
            }
            if (ref.superClass == null) {
                break;
            }
            ref = ref.superClass.t.get();
        }

        var meta = classType.meta;
        for (serializer in meta.extract(":serializer")) {
            var s = ExprTools.toString(serializer.params[0]);
            s = s.replace(".", "_");
            var expr = Context.parseInlineString(s, Context.currentPos());
            expr = ExprTools.map(expr, addQuotes);
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

        var fixedTransformers = [];
        for (t in config.transformers) {
            t = t.replace("_", ".");
            if (!fixedTransformers.contains(t)) {
                fixedTransformers.push(t);            
            }
        }
        config.transformers = fixedTransformers;

        return config;
    }

    private static function extractConfigFromMeta(meta:MetaAccess):Array<SerializerConfig> {
        var list = [];
        for (serializer in meta.extract(":serializer")) {
            var s = ExprTools.toString(serializer.params[0]);
            s = s.replace(".", "_");
            var expr = Context.parseInlineString(s, Context.currentPos());
            var expr = ExprTools.map(expr, addQuotes);
            var tempConfig:SerializerConfig = ExprTools.getValue(expr);
            list.push(tempConfig);
        }

        return list;
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

#end