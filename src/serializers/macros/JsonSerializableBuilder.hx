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
        Sys.println(" - adding json serialization to " + Context.getLocalClass().toString());

        var config = SerializableBuilder.getConfig(Context.getLocalClass().get().meta);
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
                        exprs.push(macro return data);
                    case _:    
                }
            }
            case _:
        }

        var superExpr:Expr = null;
        if (hasSuper) {
            superExpr = macro super.unserialize(data);
        }

        switch (unserializeFn.kind) {
            case FFun(f): {
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        if (hasSuper) {
                            exprs.push(macro super.unserialize(data));
                        }
                        exprs.push(macro if (!(data is String)) { // if the response isnt a string, lets turn it into one
                            data = haxe.Json.stringify(data);
                        });

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
    }
}