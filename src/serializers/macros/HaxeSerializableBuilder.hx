package serializers.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

class HaxeSerializableBuilder {
    public static macro function build():Array<Field> {
        var hasSuper:Bool = Context.getLocalClass().get().superClass != null;

        var fields = Context.getBuildFields();
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
                        exprs.push(macro var serializer = new haxe.Serializer());
                        exprs.push(macro serializer.useCache = true);
                        exprs.push(macro serializer.serialize(this));
                        exprs.push(macro return serializer.toString());
                    case _:    
                }
            }
            case _:
        }

        switch (unserializeFn.kind) {
            case FFun(f): {
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        if (hasSuper) {
                            exprs.push(macro super.unserialize(data));
                        }
                        exprs.push(macro if (!(data is String)) { // if the response isnt a string, lets turn it into one
                            data = Std.string(data);
                        });
                        exprs.push(macro var unserializer = new haxe.Unserializer(data));
                        exprs.push(macro var parsedData = unserializer.unserialize());

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

        return fields;
    }
}