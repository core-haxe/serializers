package serializers.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

class HaxeSerializableBuilder {
    public static macro function build():Array<Field> {
        Sys.println("serializers > adding haxe serialization to " + Context.getLocalClass().toString());

        var config = SerializableBuilder.getConfig(Context.getLocalClass().get());
        var fieldNames:Array<String> = []; // just hold onto these so we can easily check if ignore list contains something that doesnt exist
        var fields = Context.getBuildFields();
        for (f in fields) {
            fieldNames.push(f.name);
        }
        for (ignore in config.ignore) {
            if (!fieldNames.contains(ignore)) {
                Context.warning('serializer settings reference a field to ignore that doesnt exist: ${ignore}', Context.currentPos());
            }
        }

        var hasSuper:Bool = Context.getLocalClass().get().superClass != null;
        SerializableBuilder.findOrAddConstructor(fields, hasSuper);

        var serializeFn = SerializableBuilder.findOrAddSerialize(fields, hasSuper);
        var serializeImplFn = findOrAddSerializeImpl(fields, hasSuper);
        var unserializeFn = SerializableBuilder.findOrAddUnserialize(fields, hasSuper);
        var unserializeImplFn = findOrAddUnserializeImpl(fields, hasSuper);
        
        var localClass = Context.getLocalClass();
        var parts = localClass.toString().split(".");
        var s = parts.pop();

        var type = TPath({
            pack: parts,
            name: s
        });

        switch (serializeImplFn.kind) {
            case FFun(f): {
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        if (hasSuper) {
                            exprs.push(macro super.serializeImpl(serializer));
                        }

                        for (f in fields) {
                            if (f.access.contains(AStatic)) {
                                continue;
                            }
                            if (config.ignore.contains(f.name)) {
                                continue;
                            }
                            switch (f.kind) {
                                case FVar(t, e):
                                    var fieldName = f.name;
                                    exprs.push(macro serializer.serialize($i{fieldName}));
                                case _:   
                            }
                        }
                    case _:    
                }
            }
            case _:
        }

        switch (serializeFn.kind) {
            case FFun(f): {
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        exprs.push(macro var serializer = new haxe.Serializer());
                        exprs.push(macro serializer.useCache = true);
                        exprs.push(macro serializeImpl(serializer));
                        exprs.push(macro var data = serializer.toString());
                        if (config.transformers != null) {
                            for (transformer in config.transformers) {
                                var parts = transformer.split(".");
                                var name = parts.pop();
                                var type = {pack: parts, name: name};
                                exprs.push(macro var transformer = new $type());
                                exprs.push(macro data = transformer.transformTo(data));
                            }
                        }
                        exprs.push(macro return data);
                    case _:    
                }
            }
            case _:
        }

        switch (unserializeImplFn.kind) {
            case FFun(f): {
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        if (hasSuper) {
                            exprs.push(macro super.unserializeImpl(unserializer));
                        }

                        for (f in fields) {
                            if (f.access.contains(AStatic)) {
                                continue;
                            }
                            if (config.ignore.contains(f.name)) {
                                continue;
                            }
                            switch (f.kind) {
                                case FVar(t, e):
                                    var fieldName = f.name;
                                    exprs.push(macro $i{fieldName} = unserializer.unserialize());
                                case _:   
                            }
                        }
                    case _:    
                }
            }
            case _:
        }

        switch (unserializeFn.kind) {
            case FFun(f): {
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        exprs.push(macro if (!(data is String)) { // if the response isnt a string, lets turn it into one
                            data = Std.string(data);
                        });
                        if (config.transformers != null) {
                            var copy = config.transformers.copy();
                            copy.reverse();
                            for (transformer in copy) {
                                var parts = transformer.split(".");
                                var name = parts.pop();
                                var type = {pack: parts, name: name};
                                exprs.push(macro var transformer = new $type());
                                exprs.push(macro data = transformer.transformFrom(data));
                            }
                        }
                        exprs.push(macro var unserializer = new haxe.Unserializer(data));
                        exprs.push(macro unserializeImpl(unserializer));
                    case _:    
                }
            }
            case _:
        }

        return fields;
    }

    public static function findOrAddSerializeImpl(fields:Array<Field>, hasSuper:Bool):Field {
        var fn:Field = null;
        for (field in fields) {
            if (field.name == "serializeImpl") {
                fn = field;
            }
        }
        
        var access = [APrivate];
        if (hasSuper) {
            access.push(AOverride);
        }

        if (fn == null) {
            fn = {
                name: "serializeImpl",
                access: access,
                meta: [{name: ":noCompletion", pos: Context.currentPos()}],
                kind: FFun({
                    args:[{name: "serializer", type: macro: haxe.Serializer}],
                    expr: macro {
                    }
                }),
                pos: Context.currentPos()
            }
            fields.push(fn);
        }

        return fn;
    }

    public static function findOrAddUnserializeImpl(fields:Array<Field>, hasSuper:Bool):Field {
        var fn:Field = null;
        for (field in fields) {
            if (field.name == "unserializeImpl") {
                fn = field;
            }
        }
        
        var access = [APrivate];
        if (hasSuper) {
            access.push(AOverride);
        }

        if (fn == null) {
            fn = {
                name: "unserializeImpl",
                access: access,
                meta: [{name: ":noCompletion", pos: Context.currentPos()}],
                kind: FFun({
                    args:[{name: "unserializer", type: macro: haxe.Unserializer}],
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