package serializers.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

class HaxeSerializableBuilder {
    public static macro function build():Array<Field> {
        var fields = Context.getBuildFields();
        SerializableBuilder.findOrAddConstructor(fields);

        var toStringFn = SerializableBuilder.findOrAddToString(fields);
        var fromStringFn = SerializableBuilder.findOrAddFromString(fields);
        
        var localClass = Context.getLocalClass();
        var parts = localClass.toString().split(".");
        var s = parts.pop();

        var type = TPath({
            pack: parts,
            name: s
        });

        switch (toStringFn.kind) {
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

        switch (fromStringFn.kind) {
            case FFun(f): {
                switch (f.expr.expr) {
                    case EBlock(exprs):
                        exprs.push(macro if (!(data is String)) { // if the response isnt a string, lets turn it into one
                            data = Std.string(data);
                        });
                        exprs.push(macro var unserializer = new haxe.Unserializer(data));
                        exprs.push(macro var parsedData = unserializer.unserialize());

                        for (field in fields) {
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