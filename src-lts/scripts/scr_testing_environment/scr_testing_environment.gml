
//# feather use syntax-errors

test_add(function () : Test("env-tokenise") constructor {
    var env = new CatspeakEnvironment();
    var buff = __catspeak_create_buffer_from_string(@'hello.world');
    var lexer = env.tokenise(buff);
    assertEq(CatspeakToken.IDENT, lexer.next());
    assertEq("hello", lexer.getLexeme());
    assertEq(CatspeakToken.DOT, lexer.next());
    assertEq(".", lexer.getLexeme());
    assertEq(CatspeakToken.IDENT, lexer.next());
    assertEq("world", lexer.getLexeme());
    assertEq(CatspeakToken.EOF, lexer.next());
    buffer_delete(buff);
});

test_add(function () : Test("env-tokenise-2") constructor {
    var env = new CatspeakEnvironment();
    var buff = __catspeak_create_buffer_from_string(@'hello.world');
    var lexer = env.tokenise(buff, 3, 5);
    assertEq(CatspeakToken.IDENT, lexer.next());
    assertEq("lo", lexer.getLexeme());
    assertEq(CatspeakToken.DOT, lexer.next());
    assertEq(".", lexer.getLexeme());
    assertEq(CatspeakToken.IDENT, lexer.next());
    assertEq("wo", lexer.getLexeme());
    assertEq(CatspeakToken.EOF, lexer.next());
    buffer_delete(buff);
});

test_add(function () : Test("env-tokenise-keywords") constructor {
    var env = new CatspeakEnvironment();
    env.renameKeyword("while", "world");
    var buff = __catspeak_create_buffer_from_string(@'hello.world');
    var lexer = env.tokenise(buff);
    assertEq(CatspeakToken.IDENT, lexer.next());
    assertEq("hello", lexer.getLexeme());
    assertEq(CatspeakToken.DOT, lexer.next());
    assertEq(".", lexer.getLexeme());
    assertEq(CatspeakToken.WHILE, lexer.next());
    assertEq("world", lexer.getLexeme());
    assertEq(CatspeakToken.EOF, lexer.next());
    buffer_delete(buff);
});

test_add(function () : Test("env-self-inst") constructor {
    var env = new CatspeakEnvironment();
    var ir = env.parseString(@'self');
    var gmlFunc = env.compileGML(ir);
    var inst = instance_create_depth(0, 0, 0, obj_unit_test_inst);
    gmlFunc.setSelf(inst);
    assertEq(catspeak_special_to_struct(inst), gmlFunc());
    instance_destroy(inst);
});

test_add(function () : Test("env-global-shared") constructor {
    var env = new CatspeakEnvironment();
    var fA = env.compileGML(env.parseString(@'globalvar = 1;'));
    var fB = env.compileGML(env.parseString(@'globalvar'));
    var s = { };
    fA.setGlobals(s);
    fB.setGlobals(s);
    fA();
    assertEq(1, fB());
});

test_add(function () : Test("env-global-shared-2") constructor {
    var env = new CatspeakEnvironment();
    env.enableSharedGlobal(true);
    var fA = env.compileGML(env.parseString(@'globalvar = 1;'));
    var fB = env.compileGML(env.parseString(@'globalvar'));
    fA();
    assertEq(1, fB());
});

test_add(function () : Test("env-delete-keyword") constructor {
    var env = new CatspeakEnvironment();
    env.removeKeyword("fun");
    var buff = __catspeak_create_buffer_from_string("fun");
    var lexer = env.tokenise(buff);
    assertEq(CatspeakToken.IDENT, lexer.next());
    assertEq("fun", lexer.getLexeme());
    assertEq("fun", lexer.getValue());
    buffer_delete(buff);
});

test_add(function () : Test("env-struct-not-terminated") constructor {
    var env = new CatspeakEnvironment();
    var ir = env.parseString(@'
        return {
            foo: "bar",
            a_number: 0,
            a_string: "Hello World!"
        }
    ');
    var func = env.compileGML(ir);
    var result = func();
    assertEq(result, { foo : "bar", a_number : 0, a_string : "Hello World!" });
});

test_add(function () : Test("env-function-brace-style") constructor {
    var env = new CatspeakEnvironment();
    var fA = env.compileGML(env.parseString(@'
        main = fun()
        {
            return "hi"
        }
    '));
    var fB = env.compileGML(env.parseString(@'
        main = fun() {
            return "hi"
        }
    '));
    fA();
    fB();
    assertEq(fA.getGlobals().main(), fB.getGlobals().main());
    assertEq("hi", fA.getGlobals().main());
    assertEq("hi", fB.getGlobals().main());
});

//test_add(function () : Test("env-use-test") constructor {
//    msg = "start";
//    var env = new CatspeakEnvironment();
//    env.addMethod("thing", function () {
//        msg = "inside";
//        return function () { msg = "end" };
//    });
//    env.addMethod("get_msg", function () {
//        return msg;
//    });
//    var fA = env.compileGML(env.parseString(@'
//        let a = get_msg();
//        let b;
//        use thing {
//            b = get_msg();
//        }
//        let c = get_msg();
//        [a, b, c]
//    '));
//    assertEq(["start", "inside", "end"], fA());
//});

test_add(function () : Test("env-function-set-self") constructor {
    var env = new CatspeakEnvironment();
    var f = env.compileGML(env.parseString(@'
        return fun { self };
    '));
    var fun = f();
    var result = catspeak_execute_ext(fun, { hi : "hi" });
    assertTypeof(result, "struct");
    assertEq("hi", result.hi);
});

test_add(function () : Test("env-function-method") constructor {
    var env = new CatspeakEnvironment();
    var f = env.compile(env.parseString(@'
        return fun { self };
    '));
    var fun = catspeak_method({ bye : "bye" }, f());
    var result = catspeak_execute_ext(fun, { bye : "sike!" });
    assertTypeof(result, "struct");
    assertEq("bye", result.bye);
});

test_add(function () : Test("env-function-method-2") constructor {
    var env = new CatspeakEnvironment();
    var f = env.compile(env.parseString(@'
        return fun { self };
    '));
    var fun = catspeak_method({ bye : "bye" }, f());
    var result = fun();
    assertTypeof(result, "struct");
    assertEq("bye", result.bye);
});

function EngineFunctionMethodCallTest__Construct() constructor {
    // this is part of the below test, but needs to live in global scope
    // otherwise the name will be mangled
    str = "";
    static add = function(_str) {
        str += string(_str);
    }
}

test_add(function () : Test("env-function-method-call") constructor {
    var env = new CatspeakEnvironment();
    env.getInterface().exposeFunction("Construct", function() {
        return new EngineFunctionMethodCallTest__Construct();
    });
    var f = env.compileGML(env.parseString(@'
        let _inst = Construct();
        _inst.add("Woo!");
        _inst.add("Yeehaw!");
        _inst
    '));
    var inst = f();
    assertEq("EngineFunctionMethodCallTest__Construct", instanceof(inst));
    assertEq("Woo!Yeehaw!", inst.str);
});

test_add(function () : Test("env-function-constructor-call") constructor {
    var env = new CatspeakEnvironment();
    env.getInterface().exposeFunction(
        "Construct", EngineFunctionMethodCallTest__Construct
    );
    var f = env.compileGML(env.parseString(@'
        let _inst = new Construct();
        _inst.add("Woo!");
        _inst.add("Yeehaw!");
        _inst
    '));
    var inst = f();
    assertEq("EngineFunctionMethodCallTest__Construct", instanceof(inst));
    assertEq("Woo!Yeehaw!", inst.str);
});

test_add(function () : Test("env-function-constructor-call-implicit") constructor {
    var env = new CatspeakEnvironment();
    env.getInterface().exposeFunction(
        "Construct", EngineFunctionMethodCallTest__Construct
    );
    var f = env.compileGML(env.parseString(@'
        let _inst = new Construct;
        _inst.add("Woo!");
        _inst.add("Yeehaw!");
        _inst
    '));
    var inst = f();
    assertEq("EngineFunctionMethodCallTest__Construct", instanceof(inst));
    assertEq("Woo!Yeehaw!", inst.str);
});

test_add(function () : Test("env-function-constructor-call-implicit-index") constructor {
    var env = new CatspeakEnvironment();
    env.getInterface().exposeConstant(
        "ctx", { C : method(undefined, EngineFunctionMethodCallTest__Construct) }
    );
    var f = env.compileGML(env.parseString(@'
        let _inst = new ctx.C;
        _inst.add("Woo!");
        _inst.add("Yeehaw!");
        _inst
    '));
    var inst = f();
    assertEq("EngineFunctionMethodCallTest__Construct", instanceof(inst));
    assertEq("Woo!Yeehaw!", inst.str);
});

test_add(function () : Test("global-custom-presets") constructor {
    catspeak_preset_add("test-preset", function (ffi) {
        ffi.exposeFunction("double", function (n) { return 2 * n });
    });
    var env = new CatspeakEnvironment();
    env.applyPreset("test-preset");
    var f = env.compileGML(env.parseString(@'
        return double(103);
    '));
    assertEq(2 * 103, f());
});

test_add(function () : Test("env-properties") constructor {
    var env = new CatspeakEnvironment();
    env.interface.exposeDynamicConstant("some_property", function () { return 620 });
    var f = env.compileGML(env.parseString(@'
        return some_property + 2 * some_property
    '));
    assertEq(620 + 2 * 620, f());
});

test_add(function () : Test("env-misc-counter") constructor {
    var env = new CatspeakEnvironment();
    var f = env.compileGML(env.parseString(@'
        count = 1
        let counter = fun {
            let res = count
            count *= 2
            return res
        }

        let a = counter()
        let b = counter()
        let c = counter()
        return { a, b, c }
    '));
    var result = f();
    assertEq(1, result.a);
    assertEq(2, result.b);
    assertEq(4, result.c);
});

test_add(function () : Test("env-misc-get-set") constructor {
    var env = new CatspeakEnvironment();
    var f = env.compileGML(env.parseString(@'
        value = 0
        let double = fun (x) {
            if x == undefined { value } else { value = 2 * x }
        }

        double(8)
        let a = double()

        double(double() + 6)
        let b = double() + double()

        return [a, b]
    '));
    var result = f();
    assertEq(2 * 8, result[0]);
    assertEq(2 * (2 * 8 + 6) + 2 * (2 * 8 + 6), result[1]);
});

test_add(function () : Test("env-pipe-left") constructor {
    var env = new CatspeakEnvironment();
    var f = env.compileGML(env.parseString(@'
        let f = fun (x) { return x * 2 }
        f <| 7
    '));
    assertEq(7 * 2, f());
});

test_add(function () : Test("env-pipe-right") constructor {
    var env = new CatspeakEnvironment();
    var f = env.compileGML(env.parseString(@'
        let f = fun (x) { return x + "world" }
        "hello" |> f
    '));
    assertEq("helloworld", f());
});

test_add(function () : Test("env-gm-asset") constructor {
    var env = new CatspeakEnvironment();
    var ffi = env.getInterface();
    ffi.exposeFunction("font_exists", font_exists);
    ffi.exposeAsset("fnt_testing");
    var ir = env.parseString(@'
        return font_exists(fnt_testing);
    ');
    var func = env.compileGML(ir);
    var result = func();
    assertEq(true, result);
});

test_add(function () : Test("env-gml-function") constructor {
    var env = new CatspeakEnvironment();
    var ffi = env.getInterface();
    ffi.exposeFunctionByName("is_string");
    var ir = env.parseString(@'
        return is_string("Hello World!");
    ');
    var func = env.compileGML(ir);
    var result = func();
    assertEq(true, result);
});

test_add(function () : Test("env-gml-function-2") constructor {
    var env = new CatspeakEnvironment();
    var ffi = env.getInterface();
    ffi.exposeFunctionByName(is_string);
    var ir = env.parseString(@'
        return is_string("Hello World!");
    ');
    var func = env.compileGML(ir);
    var result = func();
    assertEq(true, result);
});

test_add(function () : Test("env-gml-function-3") constructor {
    var env = new CatspeakEnvironment();
    var ffi = env.getInterface();
    ffi.exposeFunctionByPrefix("is_");
    var ir = env.parseString(@'
        return is_string("Hello World!");
    ');
    var func = env.compileGML(ir);
    var result = func();
    assertEq(true, result);
});

test_add(function () : Test("env-gml-function-by-substring") constructor {
    var env = new CatspeakEnvironment();
    var ffi = env.getInterface();
    ffi.exposeFunctionByPrefix("test_array");
    var ir = env.parseString(@'
        let array = [2, 2, 4];
        return test_array_sum(array);
    ');
    var func = env.compileGML(ir);
    var result = func();
    assertEq(8, result);
});

test_add(function () : Test("env-gml-function-by-substring-exist") constructor {
    var env = new CatspeakEnvironment();
    var ffi = env.getInterface();
    ffi.exposeFunctionByPrefix("test_array");
    var ir = env.parseString(@'
        return [
            test_array_sum,
            test_array_min,
            test_array_max,
            test_array_mean,
            test_array_median,
        ];
    ');
    var func = env.compileGML(ir);
    var result = func();
    assertNeq(undefined, result[0]);
    assertNeq(undefined, result[1]);
    assertNeq(undefined, result[2]);
    assertNeq(undefined, result[3]);
    assertNeq(undefined, result[4]);
    assert(is_method(result[0]));
    assert(is_method(result[1]));
    assert(is_method(result[2]));
    assert(is_method(result[3]));
    assert(is_method(result[4]));
});

test_add(function () : Test("env-gml-function-by-substring-not-exist") constructor {
    var env = new CatspeakEnvironment();
    var ffi = env.getInterface();
    ffi.exposeFunctionByPrefix("test_array");
    var ir = env.parseString(@'
        return test_struct_create;
    ');
    var func = env.compileGML(ir);
    var result = func();
    assertEq(undefined, result);
    assert(!is_method(result));
});

test_add(function () : Test("env-object-index") constructor {
    try {
        instance_create_depth(0, 0, 0, obj_unit_test_obj);
    } catch (e) {
        fail(e.message);
    }
});

test_add(function () : Test("env-else-if") constructor {
    var env = new CatspeakEnvironment();
    try {
        var ir = env.parseString(@'
            a = 1
            if (a == 1) {

            } else if (a == 2) {

            }
        ');
        env.compileGML(ir);
    } catch (e) {
        fail(e.message);
    }
});

test_add_force(function () : Test(
    "engine-else-if-multiple-statements"
) constructor {
    var engine = new CatspeakEnvironment();
    var ir = engine.parseString(@'
        a = 1
        if (a == 4) or (a == 3) {
            "bad"
        } else if (a == 1) {
            "good"
        } else {
            "also bad"
        }
    ');
    var _func = engine.compileGML(ir);
    var result = _func();
    assertEq("good", result);
});

test_add_force(function () : Test(
    "dynamic-constants"
) constructor {
    var engine = new CatspeakEnvironment();
    engine.getInterface().exposeDynamicConstant("room_width", function() { return room_width; });
    engine.getInterface().exposeFunction("room_width_function", function() { return room_width; });
    var ir = engine.parseString(@'
        return (room_width == room_width_function());
    ');
    var _func = engine.compileGML(ir);
    var result = _func();
    assertEq(true, result);
});

test_add(function() : Test("match-1") constructor {
    var engine = new CatspeakEnvironment();
    var ir = engine.parseString(@'
        let a = 2
        
        match a {
            case 1 { 69 }
            case 2 { 42 }
            case 3 { 3.14 }
            else { 0 }
        }
    ');
    var _func = engine.compileGML(ir);
    var result = _func();
    assertEq(42, result);
});

test_add(function() : Test("match-2") constructor {
    var engine = new CatspeakEnvironment();
    var ir = engine.parseString(@'
        let a = 2
        
        match a {
            else { 0 }
            case 1 { 69 }
            case 2 { 42 }
            case 3 { 3.14 }
        }
    ');
    var _func = engine.compileGML(ir);
    var result = _func();
    assertEq(0, result);
});

test_add(function() : Test("match-3") constructor {
    var engine = new CatspeakEnvironment();
    var ir = engine.parseString(@'
        let a = 4
        
        match a {
            case 1 { 69 }
            case 2 { 42 }
            case 3 { 3.14 }
        }
    ');
    var _func = engine.compileGML(ir);
    var result = _func();
    assertEq(undefined, result);
});

test_add(function() : Test("match-4") constructor {
    var engine = new CatspeakEnvironment();
    var ir = engine.parseString(@'
        let a = 0
        match a {}
    ');
    var _func = engine.compileGML(ir);
    var result = _func();
    assertEq(undefined, result);
});

test_add(function() : Test("match-5") constructor {
    var engine = new CatspeakEnvironment();
    var ir = engine.parseString(@'
        counter = 2;
        
        increment = fun {
            counter += 1
            counter
        }
        
        match increment() {
            case 1 { 0}
            case 2 {0 }
            case 3 { 1 }
            else { 2 }
        }
    ');
    var _func = engine.compileGML(ir);
    var result = _func();
    assertEq(1, result);
});

test_add(function() : Test("match-local") constructor {
    var engine = new CatspeakEnvironment();
    var ir = engine.parseString(@'
        let a = 1;
        match a {
            else {
                let b = 2;
                a + b
            }
        }
    ');
    var _func = engine.compileGML(ir);
    assertEq(1 + 2, _func());
});

test_add(function() : Test("match-local-scope") constructor {
    var engine = new CatspeakEnvironment();
    var ir = engine.parseString(@'
        match "anything" {
            else {
                let b = "hi";
            }
        }
        b
    ');
    var _func = engine.compileGML(ir);
    assertEq(undefined, _func());
});

test_add(function() : Test("expr-xor-false") constructor {
    var engine = new CatspeakEnvironment();
    var ir = engine.parseString(@'15 xor 12');
    var _func = engine.compileGML(ir);
    assertEq(false, _func());
});

test_add(function() : Test("expr-xor-true") constructor {
    var engine = new CatspeakEnvironment();
    var ir = engine.parseString(@'-15 xor 12');
    var _func = engine.compileGML(ir);
    assertEq(true, _func());
});

test_add(function() : Test("with-struct") constructor {
    var engine = new CatspeakEnvironment();
    var ir = engine.parseString(@'
        with { a : 1 } {
            return self;
        }
    ');
    var _func = engine.compileGML(ir);
    var result = _func();
    assertTypeof(result, "struct");
    assertEq(1, result.a);
});

test_add(function() : Test("with-noone") constructor {
    var engine = new CatspeakEnvironment();
    var ir = engine.parseString(@'
        let success = true;
        with -4 {
            success = false;
        }
        return success;
    ');
    var _func = engine.compileGML(ir);
    assertEq(true, _func());
});

test_add(function() : Test("with-inst") constructor {
    var env = new CatspeakEnvironment();
    env.interface.exposeAsset("obj_unit_test_inst");
    env.interface.exposeFunctionByName(array_push);
    var ir = env.parseString(@'
        let arr = [];
        let n = 0;
        with obj_unit_test_inst {
            array_push(arr, self);
            n += 1;
        }
        return { arr, n };
    ');
    var inst1 = instance_create_depth(0, 0, 0, obj_unit_test_inst);
    var inst2 = instance_create_depth(0, 0, 0, obj_unit_test_inst);
    var gmlFunc = env.compile(ir);
    var result = gmlFunc();
    assertTypeof(result, "struct");
    assertTypeof(result.arr, "array");
    assertEq(result.n, array_length(result.arr));
    assertEq(2, result.n);
    var inst1Self, inst2Self;
    with (inst1) { inst1Self = self }
    with (inst2) { inst2Self = self }
    assertEq(inst1Self, result.arr[0]);
    assertEq(inst2Self, result.arr[1]);
    instance_destroy(inst1);
    instance_destroy(inst2);
});

// TODO :: i dont really want tests to last longer than a frame or two, so this shoould really
//         be turned into a benchmark instead
test_add(function() : Test("method-scope-vs-undefined") constructor {
    var env = new CatspeakEnvironment();
    var func = function(value) {
        return value * 32;
    }
    env.interface.exposeFunction("func", func);
    env.interface.exposeMethod("funcM", func);
    
    var ir = env.parseString(@'
        func(0.5);
    ');
    
    var gmlFuncA = env.compile(ir);
	
    ir = env.parseString(@'
        funcM(0.5);
    ');
    
    var gmlFuncB = env.compile(ir);
    
    var t = get_timer();
    repeat(100000) {
        gmlFuncA();	
    }
    show_debug_message("gmlFuncA (func) Time taken: " + string((get_timer() - t) / 1000) + "ms");
    
    t = get_timer();
    repeat(100000) {
        gmlFuncB();	
    }
    show_debug_message("gmlFuncB (funcM) Time taken: " + string((get_timer() - t) / 1000) + "ms");
});


test_add(function() : Test("method-scope-vs-undefined-with-method") constructor {
    var env = new CatspeakEnvironment();
    var func = function(value) {
        return value * 32;
    }
    
    var ir = env.parseString(@'
        self.func(0.5);
    ');
    
    var compiledFunc = env.compile(ir);
	
	var structA = {func: method(undefined, func)};
	var structB = {func: func};
    
    var t = get_timer();
	repeat(100000) {
		catspeak_execute_ext(compiledFunc, structA);
	}
    show_debug_message("structA (func) Time taken: " + string((get_timer() - t) / 1000) + "ms");
    
    t = get_timer();
	repeat(100000) {
		catspeak_execute_ext(compiledFunc, structB);
	}
    show_debug_message("structB (funcM) Time taken: " + string((get_timer() - t) / 1000) + "ms");
});