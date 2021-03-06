using Gallium
import Base: LineEdit, REPL

function RunLLDBRepl(dbg)
    repl = Base.active_repl
    mirepl = isdefined(repl,:mi) ? repl.mi : repl

    main_mode = mirepl.interface.modes[1]

    # Setup cxx panel
    panel = LineEdit.Prompt("LLDB > ";
        # Copy colors from the prompt object
        prompt_prefix=Base.text_colors[:blue],
        prompt_suffix=main_mode.prompt_suffix,
        on_enter = s->true)

    hp = main_mode.hist
    hp.mode_mapping[:lldb] = panel
    panel.hist = hp

    panel.on_done = REPL.respond(repl,panel; pass_empty = true) do line
        # Rerun the previous command if the line is empty
        if isempty(line)
            :( Gallium.reset_ans(); print(lldb_exec($dbg,($hp).history[end])); Gallium.debugger_ans )
        else
            :( Gallium.reset_ans(); print(lldb_exec($dbg,$line)); Gallium.debugger_ans )
        end
    end


    push!(mirepl.interface.modes,panel)

    const lldb_keymap = Dict{Any,Any}(
        '`' => function (s,args...)
            if isempty(s)
                if !haskey(s.mode_state,panel)
                    s.mode_state[panel] = LineEdit.init_state(repl.t,panel)
                end
                LineEdit.transition(s,panel)
            else
                LineEdit.edit_insert(s,'`')
            end
        end
    )

    search_prompt, skeymap = LineEdit.setup_search_keymap(hp)
    mk = REPL.mode_keymap(main_mode)

    b = Dict{Any,Any}[skeymap, mk, LineEdit.history_keymap, LineEdit.default_keymap, LineEdit.escape_defaults]
    panel.keymap_dict = LineEdit.keymap(b)

    main_mode.keymap_dict = LineEdit.keymap_merge(main_mode.keymap_dict, lldb_keymap);
    nothing
end
