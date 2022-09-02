
var buff = catspeak_create_buffer_from_string(@'
    let a = 1
    a = 2 = 1
');
var lex = new CatspeakLexer(buff);
var comp = new CatspeakCompiler(lex);

comp.emitProgram(-1);
var disasm = comp.ir.disassembly();
show_message(disasm);
clipboard_set_text(disasm);