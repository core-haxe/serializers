package serializers.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

class JsonSerializableBuilder {
    public static macro function build():Array<Field> {
        var fields = Context.getBuildFields();

        addFields(fields);

        return fields;
    }

    private static function addFields(fields:Array<Field>) {
        Sys.println("serializers > adding json serialization to " + Context.getLocalClass().toString());

        var config = SerializableBuilder.getConfig(Context.getLocalClass().get());
        var fieldNames:Array<String> = []; // just hold onto these so we can easily check if ignore list contains something that doesnt exist
        for (f in fields) {
            fieldNames.push(f.name);
            if (config.ignore.contains(f.name)) {
                f.meta.push({name: ":jignored", pos: Context.currentPos()}); // json2object specific metadata
            }
        }
        for (ignore in config.ignore) {
            if (!fieldNames.contains(ignore)) {
                Context.warning('serializer settings reference a field to ignore that doesnt exist: ${ignore}', Context.currentPos());
            }
        }

        var hasSuper:Bool = Context.getLocalClass().get().superClass != null;
        SerializableBuilder.findOrAddConstructor(fields, hasSuper);

        var serializeFn = SerializableBuilder.findOrAddSerialize(fields, hasSuper);
        var unserializeImplFn = findOrAddUnserializeImpl(fields, hasSuper);
        var unserializeFn = SerializableBuilder.findOrAddUnserialize(fields, hasSuper);
        
        var localClass = Context.getLocalClass();
        var parts = localClass.toString().split(".");
        var s = parts.pop();

        var type = TPath({
            pack: parts,
            name: s
        });

        switch (serializeFn.kind) {
            case FFun(f): {
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        exprs.push(macro var o = this);
                        exprs.push(macro var writer = new json2object.JsonWriter<$type>());
                        exprs.push(macro var data = writer.write(o));
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
                            exprs.push(macro super.unserializeImpl(data));
                        }

                        exprs.push(macro var parser = new json2object.JsonParser<$type>());
                        exprs.push(macro var parsedData = parser.fromJson(data));

                        for (field in fields) {
                            if (field.access.contains(AStatic)) {
                                continue;
                            }
                
                            switch (field.kind) {
                                case FVar(t, e):
                                    var fieldName = field.name;
                                    exprs.push(macro this.$fieldName = parsedData.$fieldName);
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
                            data = haxe.Json.stringify(data);
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
                        exprs.push(macro unserializeImpl(data));
                    case _:    
                }
            }
            case _:
        }
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
                kind: FFun({
                    args:[{name: "data", type: macro: String}],
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