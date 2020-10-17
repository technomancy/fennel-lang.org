package.preload["fnlfmt"] = package.preload["fnlfmt"] or function(...)
  local view = require("fennelview")
  local function identify_line(line, pos, stack)
    local closers = {[")"] = "(", ["\""] = "\"", ["]"] = "[", ["}"] = "{"}
    local char = line:sub(pos, pos)
    local looking_for = stack[#stack]
    local continue = nil
    local function _0_()
      return identify_line(line, (pos - 1), stack)
    end
    continue = _0_
    if (0 == pos) then
      return nil
    elseif (line:sub((pos - 1), (pos - 1)) == "\\") then
      return continue()
    elseif (looking_for == char) then
      table.remove(stack)
      return continue()
    elseif (closers[char] and (looking_for ~= "\"")) then
      table.insert(stack, closers[char])
      return continue()
    elseif looking_for then
      return continue()
    elseif (("[" == char) or ("{" == char)) then
      return "table", pos
    elseif ("(" == char) then
      return "call", pos, line
    elseif "else" then
      return continue()
    end
  end
  local function symbol_at(line, pos)
    return line:sub(pos):match("[^%s]+")
  end
  local body_specials = {["\206\187"] = true, ["do"] = true, ["eval-compiler"] = true, ["for"] = true, ["while"] = true, ["with-open"] = true, doto = true, each = true, fn = true, lambda = true, let = true, macro = true, match = true, when = true}
  local function remove_comment(line, in_string_3f, pos)
    if (#line < pos) then
      return line
    elseif (line:sub(pos, pos) == "\"") then
      return remove_comment(line, not in_string_3f, (pos + 1))
    elseif ((line:sub(pos, pos) == ";") and not in_string_3f) then
      return line:sub(1, (pos - 1))
    else
      return remove_comment(line, in_string_3f, (pos + 1))
    end
  end
  local function identify_indent_type(lines, last, stack)
    local line = remove_comment((lines[last] or ""), false, 1)
    local _0_0, _1_0, _2_0 = identify_line(line, #line, stack)
    if ((_0_0 == "table") and (nil ~= _1_0)) then
      local pos = _1_0
      return "table", pos
    elseif ((_0_0 == "call") and (nil ~= _1_0) and (_2_0 == line)) then
      local pos = _1_0
      local function_name = symbol_at(line, (pos + 1))
      if body_specials[function_name] then
        return "body-special", (pos - 1)
      else
        return "call", (pos - 1), function_name
      end
    else
      local _3_
      do
        local _ = _0_0
        _3_ = (true and (1 < last))
      end
      if _3_ then
        local _ = _0_0
        return identify_indent_type(lines, (last - 1), stack)
      end
    end
  end
  local function indentation(lines, prev_line_num)
    local _0_0, _1_0, _2_0 = identify_indent_type(lines, prev_line_num, {})
    if ((_0_0 == "table") and (nil ~= _1_0)) then
      local opening = _1_0
      return opening
    elseif ((_0_0 == "body-special") and (nil ~= _1_0)) then
      local prev_indent = _1_0
      return (prev_indent + 2)
    elseif ((_0_0 == "call") and (nil ~= _1_0) and (nil ~= _2_0)) then
      local prev_indent = _1_0
      local function_name = _2_0
      return (prev_indent + #function_name + 2)
    else
      local _ = _0_0
      return 0
    end
  end
  local function indent_line(line, lines, prev_line_num)
    local without_indentation = line:match("[^%s]+.*")
    if without_indentation then
      return ((" "):rep(indentation(lines, prev_line_num)) .. without_indentation)
    else
      return ""
    end
  end
  local function indent(code)
    local lines = {}
    for line in code:gmatch("([^\n]*)\n") do
      table.insert(lines, indent_line(line, lines, #lines))
    end
    return table.concat(lines, "\n")
  end
  local newline = nil
  local function _0_()
    return "\n"
  end
  newline = setmetatable({}, {__fennelview = _0_})
  local function nospace_concat(tbl, sep, start, _end)
    local out = ""
    for i = start, _end do
      local val = tbl[i]
      if ((i == start) or (val == "\n")) then
        out = (out .. val)
      else
        out = (out .. " " .. val)
      end
    end
    return out
  end
  local nil_sym = nil
  local function _1_()
    return "nil"
  end
  nil_sym = setmetatable({}, {__fennelview = _1_})
  local function view_list(open, close, self, tostring2)
    local safe, max = {}, 0
    for k in pairs(self) do
      if ((type(k) == "number") and (k > max)) then
        max = k
      end
    end
    do
      local ts = (tostring2 or tostring)
      for i = 1, max, 1 do
        local function _2_()
          if (self[i] == nil) then
            return nil_sym
          else
            return self[i]
          end
        end
        safe[i] = ts(_2_())
      end
    end
    return (open .. nospace_concat(safe, " ", 1, max) .. close)
  end
  local list_mt = nil
  local function _2_(...)
    return view_list("(", ")", ...)
  end
  list_mt = {__fennelview = _2_}
  local function walk_tree(root, f, iterator)
    local function walk(iterfn, parent, idx, node)
      if f(idx, node, parent) then
        for k, v in iterfn(node) do
          walk(iterfn, node, k, v)
        end
        return nil
      end
    end
    walk((iterator or pairs), nil, nil, root)
    return root
  end
  local function step_for(_3_0)
    local _4_ = _3_0
    local callee = _4_[1]
    if ({match = true})[tostring(callee)] then
      return -2
    else
      return -1
    end
  end
  local function end_for(node)
    if (tostring(node[1]) == "match") then
      return (#node - 1)
    else
      return #node
    end
  end
  local function anonymous_fn_3f(_4_0)
    local _5_ = _4_0
    local callee = _5_[1]
    local name_org_arglist = _5_[2]
    local _7_
    do
      local _6_0 = getmetatable(name_org_arglist)
      if ((type(_6_0) == "table") and (nil ~= _6_0[1])) then
        local which = _6_0[1]
        _7_ = (which == "SYMBOL")
      else
      _7_ = nil
      end
    end
    return (("fn" == tostring(callee)) and not _7_)
  end
  local function start_for(form)
    if anonymous_fn_3f(form) then
      return 3
    else
      return ({["do"] = 2, ["for"] = 3, ["if"] = 3, ["while"] = 3, each = 3, fn = 4, let = 3, match = 3, when = 3})[tostring(form[1])]
    end
  end
  local function add_newlines(idx, node, parent)
    if ("table" == type(node)) then
      do
        local mt = (getmetatable(node) or {})
        local _5_0 = mt
        if ((type(_5_0) == "table") and (_5_0[1] == "LIST")) then
          setmetatable(node, list_mt)
          if start_for(node) then
            for i = end_for(node), start_for(node), step_for(node) do
              table.insert(node, i, newline)
            end
          end
        elseif ((type(_5_0) == "table") and (nil ~= _5_0.sequence)) then
          local sequence = _5_0.sequence
          if ("let" == tostring(parent[1])) then
            local function _6_(...)
              return view_list("[", "]", ...)
            end
            mt.__fennelview = _6_
            for i = (#node - 1), 2, -2 do
              table.insert(node, i, newline)
            end
          end
        end
      end
      return true
    end
  end
  local function fnlfmt(ast, options)
    return indent((view(walk_tree(ast, add_newlines), {["empty-as-square"] = true, ["table-edges"] = false}) .. "\n\n"))
  end
  return {fnlfmt = fnlfmt, indentation = indentation}
end
package.preload["letter"] = package.preload["letter"] or function(...)
  local fennel = require("fennel")
  local function walk_tree(root, f, custom_iterator)
    local function walk(iterfn, parent, idx, node)
      if f(idx, node, parent) then
        for k, v in iterfn(node) do
          walk(iterfn, node, k, v)
        end
        return nil
      end
    end
    walk((custom_iterator or pairs), nil, nil, root)
    return root
  end
  local function locals_to_bindings(node, bindings)
    local maybe_local = node[3]
    if (("table" == type(maybe_local)) and ("local" == tostring(maybe_local[1]))) then
      table.remove(node, 3)
      table.insert(bindings, maybe_local[2])
      table.insert(bindings, maybe_local[3])
      return locals_to_bindings(node, bindings)
    end
  end
  local function move_body(fn_node, do_node, do_loc)
    for i = #fn_node, do_loc, -1 do
      table.insert(do_node, 2, table.remove(fn_node, i))
    end
    return nil
  end
  local function transform_do(node)
    local bindings = {}
    table.insert(node, 2, bindings)
    node[1] = fennel.sym("let")
    return locals_to_bindings(node, bindings)
  end
  local function transform_fn(node)
    local has_name_3f = fennel["sym?"](node[2])
    local do_loc = nil
    if has_name_3f then
      do_loc = 4
    else
      do_loc = 3
    end
    local do_node = fennel.list(fennel.sym("do"))
    move_body(node, do_node, do_loc)
    return table.insert(node, do_loc, do_node)
  end
  local function do_local_node_3f(node)
    return (("table" == type(node)) and ("do" == tostring(node[1])) and ("table" == type(node[2])) and ("local" == tostring(node[2][1])))
  end
  local function fn_local_node_3f(node)
    return (("table" == type(node)) and ("fn" == tostring(node[1])) and ((("table" == type(node[3])) and ("local" == tostring(node[3][1]))) or (("table" == type(node[4])) and ("local" == tostring(node[4][1])))))
  end
  local function letter(idx, node)
    if do_local_node_3f(node) then
      transform_do(node)
    end
    if fn_local_node_3f(node) then
      transform_fn(node)
    end
    return ("table" == type(node))
  end
  local function reverse_ipairs(t)
    local function iter(t0, i)
      local i0 = (i - 1)
      local v = t0[i0]
      if (v ~= nil) then
        return i0, v
      end
    end
    return iter, t, (#t + 1)
  end
  local function compile(ast)
    return walk_tree(ast, letter, reverse_ipairs)
  end
  return compile
end
package.preload["fennelview"] = package.preload["fennelview"] or function(...)
  local function view_quote(str)
    return ("\"" .. str:gsub("\"", "\\\"") .. "\"")
  end
  local short_control_char_escapes = {["\11"] = "\\v", ["\12"] = "\\f", ["\13"] = "\\r", ["\7"] = "\\a", ["\8"] = "\\b", ["\9"] = "\\t", ["\n"] = "\\n"}
  local long_control_char_escapes = nil
  do
    local long = {}
    for i = 0, 31 do
      local ch = string.char(i)
      if not short_control_char_escapes[ch] then
        short_control_char_escapes[ch] = ("\\" .. i)
        long[ch] = ("\\%03d"):format(i)
      end
    end
    long_control_char_escapes = long
  end
  local function escape(str)
    return str:gsub("\\", "\\\\"):gsub("(%c)%f[0-9]", long_control_char_escapes):gsub("%c", short_control_char_escapes)
  end
  local function sequence_key_3f(k, len)
    return ((type(k) == "number") and (1 <= k) and (k <= len) and (math.floor(k) == k))
  end
  local type_order = {["function"] = 5, boolean = 2, number = 1, string = 3, table = 4, thread = 7, userdata = 6}
  local function sort_keys(a, b)
    local ta = type(a)
    local tb = type(b)
    if ((ta == tb) and (ta ~= "boolean") and ((ta == "string") or (ta == "number"))) then
      return (a < b)
    else
      local dta = type_order[a]
      local dtb = type_order[b]
      if (dta and dtb) then
        return (dta < dtb)
      elseif dta then
        return true
      elseif dtb then
        return false
      elseif "else" then
        return (ta < tb)
      end
    end
  end
  local function get_sequence_length(t)
    local len = 1
    for i in ipairs(t) do
      len = i
    end
    return len
  end
  local function get_nonsequential_keys(t)
    local keys = {}
    local sequence_length = get_sequence_length(t)
    for k in pairs(t) do
      if not sequence_key_3f(k, sequence_length) then
        table.insert(keys, k)
      end
    end
    table.sort(keys, sort_keys)
    return keys, sequence_length
  end
  local function count_table_appearances(t, appearances)
    if (type(t) == "table") then
      if not appearances[t] then
        appearances[t] = 1
        for k, v in pairs(t) do
          count_table_appearances(k, appearances)
          count_table_appearances(v, appearances)
        end
      end
    else
      if (t and (t == t)) then
        appearances[t] = ((appearances[t] or 0) + 1)
      end
    end
    return appearances
  end
  local put_value = nil
  local function puts(self, ...)
    for _, v in ipairs({...}) do
      table.insert(self.buffer, v)
    end
    return nil
  end
  local function tabify(self)
    return puts(self, "\n", (self.indent):rep(self.level))
  end
  local function already_visited_3f(self, v)
    return (self.ids[v] ~= nil)
  end
  local function get_id(self, v)
    local id = self.ids[v]
    if not id then
      local tv = type(v)
      id = ((self["max-ids"][tv] or 0) + 1)
      self["max-ids"][tv] = id
      self.ids[v] = id
    end
    return tostring(id)
  end
  local function put_sequential_table(self, t, len)
    puts(self, "[")
    self.level = (self.level + 1)
    for i = 1, len do
      local _0_ = (1 + len)
      if ((1 < i) and (i < _0_)) then
        puts(self, " ")
      end
      put_value(self, t[i])
    end
    self.level = (self.level - 1)
    return puts(self, "]")
  end
  local function put_key(self, k)
    if ((type(k) == "string") and k:find("^[-%w?\\^_!$%&*+./@:|<=>]+$")) then
      return puts(self, ":", k)
    else
      return put_value(self, k)
    end
  end
  local function put_kv_table(self, t, ordered_keys)
    puts(self, "{")
    self.level = (self.level + 1)
    for i, k in ipairs(ordered_keys) do
      if (self["table-edges"] or (i ~= 1)) then
        tabify(self)
      end
      put_key(self, k)
      puts(self, " ")
      put_value(self, t[k])
    end
    for i, v in ipairs(t) do
      tabify(self)
      put_key(self, i)
      puts(self, " ")
      put_value(self, v)
    end
    self.level = (self.level - 1)
    if self["table-edges"] then
      tabify(self)
    end
    return puts(self, "}")
  end
  local function put_table(self, t)
    local metamethod = nil
    local function _1_()
      local _0_0 = t
      if _0_0 then
        local _2_0 = getmetatable(_0_0)
        if _2_0 then
          return _2_0.__fennelview
        else
          return _2_0
        end
      else
        return _0_0
      end
    end
    metamethod = (self["metamethod?"] and _1_())
    if (already_visited_3f(self, t) and self["detect-cycles?"]) then
      return puts(self, "#<table ", get_id(self, t), ">")
    elseif (self.level >= self.depth) then
      return puts(self, "{...}")
    elseif metamethod then
      return puts(self, metamethod(t, self.fennelview))
    elseif "else" then
      local non_seq_keys, len = get_nonsequential_keys(t)
      local id = get_id(self, t)
      if ((1 < (self.appearances[t] or 0)) and self["detect-cycles?"]) then
        return puts(self, "#<table", id, ">")
      elseif ((#non_seq_keys == 0) and (#t == 0)) then
        local function _2_()
          if self["empty-as-square"] then
            return "[]"
          else
            return "{}"
          end
        end
        return puts(self, _2_())
      elseif (#non_seq_keys == 0) then
        return put_sequential_table(self, t, len)
      elseif "else" then
        return put_kv_table(self, t, non_seq_keys)
      end
    end
  end
  local function _0_(self, v)
    local tv = type(v)
    if (tv == "string") then
      return puts(self, view_quote(escape(v)))
    elseif ((tv == "number") or (tv == "boolean") or (tv == "nil")) then
      return puts(self, tostring(v))
    elseif (tv == "table") then
      return put_table(self, v)
    elseif "else" then
      return puts(self, "#<", tostring(v), ">")
    end
  end
  put_value = _0_
  local function one_line(str)
    local ret = str:gsub("\n", " "):gsub("%[ ", "["):gsub(" %]", "]"):gsub("%{ ", "{"):gsub(" %}", "}"):gsub("%( ", "("):gsub(" %)", ")")
    return ret
  end
  local function fennelview(x, options)
    local options0 = (options or {})
    local inspector = nil
    local function _1_(_241)
      return fennelview(_241, options0)
    end
    local function _2_()
      if options0["one-line"] then
        return ""
      else
        return "  "
      end
    end
    inspector = {["detect-cycles?"] = not (false == options0["detect-cycles?"]), ["empty-as-square"] = options0["empty-as-square"], ["max-ids"] = {}, ["metamethod?"] = not (false == options0["metamethod?"]), ["table-edges"] = (options0["table-edges"] ~= false), appearances = count_table_appearances(x, {}), buffer = {}, depth = (options0.depth or 128), fennelview = _1_, ids = {}, indent = (options0.indent or _2_()), level = 0}
    put_value(inspector, x)
    local str = table.concat(inspector.buffer)
    if options0["one-line"] then
      return one_line(str)
    else
      return str
    end
  end
  return fennelview
end
package.preload["anticompiler"] = package.preload["anticompiler"] or function(...)
  local _0_ = require("fennel")
  local list = _0_["list"]
  local sym = _0_["sym"]
  local view = require("fennelview")
  local function map(tbl, f, with_last_3f)
    local len = #tbl
    local out = {}
    for i, v in ipairs(tbl) do
      table.insert(out, f(v, (with_last_3f and (i == len))))
    end
    return out
  end
  local function p(x)
    return print(view(x))
  end
  local function make_scope(parent)
    return setmetatable({}, {__index = parent})
  end
  local function add_to_scope(scope, kind, names, ast)
    for _, name in ipairs(names) do
      scope[tostring(name)] = {ast = ast, kind = kind}
    end
    return nil
  end
  local function _function(compile, scope, _1_0)
    local _2_ = _1_0
    local body = _2_["body"]
    local params = _2_["params"]
    local vararg = _2_["vararg"]
    local params0 = nil
    local function _3_(...)
      return compile(scope, ...)
    end
    params0 = map(params, _3_)
    local subscope = nil
    do
      local _4_0 = make_scope(scope)
      add_to_scope(_4_0, "param", params0)
      subscope = _4_0
    end
    local function _5_(...)
      return compile(subscope, ...)
    end
    return list(sym("fn"), params0, unpack(map(body, _5_, true)))
  end
  local function declare_function(compile, scope, ast)
    if (ast.locald or ("MemberExpression" == ast.id.kind)) then
      local _2_0 = _function(compile, scope, ast)
      table.insert(_2_0, 2, compile(scope, ast.id))
      return _2_0
    else
      return list(sym("set-forcibly!"), compile(scope, ast.id), _function(compile, scope, ast))
    end
  end
  local function local_declaration(compile, scope, _2_0)
    local _3_ = _2_0
    local expressions = _3_["expressions"]
    local names = _3_["names"]
    local _4_ = #names
    if (((#expressions == _4_) and (_4_ == 1)) and ("FunctionExpression" == expressions[1].kind)) then
      add_to_scope(scope, "function", {names[1].name})
      local function _6_()
        local _5_0 = expressions[1]
        _5_0["id"] = names[1]
        _5_0["locald"] = true
        return _5_0
      end
      return declare_function(compile, scope, _6_())
    else
      local local_sym = sym("local")
      local function _5_(_241)
        return _241.name
      end
      add_to_scope(scope, "local", map(names, _5_), local_sym)
      local _6_
      if (1 == #names) then
        _6_ = sym(names[1].name)
      else
        local function _7_(...)
          return compile(scope, ...)
        end
        _6_ = list(unpack(map(names, _7_)))
      end
      local function _8_()
        if (1 == #expressions) then
          return compile(scope, expressions[1])
        elseif (0 == #expressions) then
          return sym("nil")
        else
          local function _8_(...)
            return compile(scope, ...)
          end
          return list(sym("values"), unpack(map(expressions, _8_)))
        end
      end
      return list(local_sym, _6_, _8_())
    end
  end
  local function vals(compile, scope, _3_0)
    local _4_ = _3_0
    local arguments = _4_["arguments"]
    if (1 == #arguments) then
      return compile(scope, arguments[1])
    elseif (0 == #arguments) then
      return sym("nil")
    else
      local function _5_(...)
        return compile(scope, ...)
      end
      return list(sym("values"), unpack(map(arguments, _5_)))
    end
  end
  local function any_complex_expressions_3f(args, i)
    local a = args[i]
    if (nil == a) then
      return false
    elseif not ((a.kind == "Identifier") or (a.kind == "Literal")) then
      return true
    else
      return any_complex_expressions_3f(args, (i + 1))
    end
  end
  local function early_return_complex(compile, scope, args)
    local binding_names = {}
    local bindings = {}
    for i, a in ipairs(args) do
      table.insert(binding_names, ("___antifnl_rtn_" .. i .. "___"))
      table.insert(bindings, sym(binding_names[i]))
      table.insert(bindings, a)
    end
    return list(sym("let"), bindings, list(sym("lua"), ("return " .. table.concat(binding_names, ", "))))
  end
  local function early_return(compile, scope, _4_0)
    local _5_ = _4_0
    local arguments = _5_["arguments"]
    local args = nil
    local function _6_(...)
      return compile(scope, ...)
    end
    args = map(arguments, _6_)
    if any_complex_expressions_3f(arguments, 1) then
      return early_return_complex(compile, scope, args)
    else
      return list(sym("lua"), ("return " .. table.concat(map(args, view), ", ")))
    end
  end
  local function binary(compile, scope, _5_0, ast)
    local _6_ = _5_0
    local left = _6_["left"]
    local operator = _6_["operator"]
    local right = _6_["right"]
    local operators = {["#"] = "length", ["=="] = "=", ["~"] = "bnot", ["~="] = "not="}
    return list(sym((operators[operator] or operator)), compile(scope, left), compile(scope, right))
  end
  local function unary(compile, scope, _6_0, ast)
    local _7_ = _6_0
    local argument = _7_["argument"]
    local operator = _7_["operator"]
    return list(sym(operator), compile(scope, argument))
  end
  local function call(compile, scope, _7_0)
    local _8_ = _7_0
    local arguments = _8_["arguments"]
    local callee = _8_["callee"]
    local function _9_(...)
      return compile(scope, ...)
    end
    return list(compile(scope, callee), unpack(map(arguments, _9_)))
  end
  local function send(compile, scope, _8_0)
    local _9_ = _8_0
    local arguments = _9_["arguments"]
    local method = _9_["method"]
    local receiver = _9_["receiver"]
    local function _10_(...)
      return compile(scope, ...)
    end
    return list(sym(":"), compile(scope, receiver), method.name, unpack(map(arguments, _10_)))
  end
  local function any_computed_3f(ast)
    local function _9_()
      if (ast.object.kind == "MemberExpression") then
        return any_computed_3f(ast.object)
      else
        return true
      end
    end
    return (ast.computed or (ast.object and (ast.object.kind ~= "Identifier") and _9_()))
  end
  local function member(compile, scope, ast)
    if any_computed_3f(ast) then
      local function _9_()
        if ast.computed then
          return compile(scope, ast.property)
        else
          return view(compile(scope, ast.property))
        end
      end
      return list(sym("."), compile(scope, ast.object), _9_())
    else
      return sym((tostring(compile(scope, ast.object)) .. "." .. ast.property.name))
    end
  end
  local function if_2a(compile, scope, _9_0, tail_3f)
    local _10_ = _9_0
    local alternate = _10_["alternate"]
    local cons = _10_["cons"]
    local tests = _10_["tests"]
    for _, v in ipairs(cons) do
      if (0 == #v) then
        table.insert(v, sym("nil"))
      end
    end
    local subscope = make_scope(scope)
    if (not alternate and (1 == #tests)) then
      local function _11_(...)
        return compile(subscope, ...)
      end
      return list(sym("when"), compile(scope, tests[1]), unpack(map(cons[1], _11_, tail_3f)))
    else
      local out = list(sym("if"))
      for i, test in ipairs(tests) do
        table.insert(out, compile(scope, test))
        local c = cons[i]
        local function _11_()
          if (1 == #c) then
            return compile(subscope, c[1], tail_3f)
          else
            local function _11_(...)
              return compile(subscope, ...)
            end
            return list(sym("do"), unpack(map(c, _11_, tail_3f)))
          end
        end
        table.insert(out, _11_())
      end
      if alternate then
        local function _11_()
          if (1 == #alternate) then
            return compile(subscope, alternate[1], tail_3f)
          else
            local function _11_(...)
              return compile(subscope, ...)
            end
            return list(sym("do"), unpack(map(alternate, _11_, tail_3f)))
          end
        end
        table.insert(out, _11_())
      end
      return out
    end
  end
  local function concat(compile, scope, _10_0)
    local _11_ = _10_0
    local terms = _11_["terms"]
    local function _12_(...)
      return compile(scope, ...)
    end
    return list(sym(".."), unpack(map(terms, _12_)))
  end
  local function each_2a(compile, scope, _11_0)
    local _12_ = _11_0
    local body = _12_["body"]
    local explist = _12_["explist"]
    local namelist = _12_["namelist"]
    local subscope = make_scope(scope)
    local binding = nil
    local function _13_(...)
      return compile(scope, ...)
    end
    binding = map(namelist.names, _13_)
    add_to_scope(subscope, "param", binding)
    local function _14_(...)
      return compile(scope, ...)
    end
    for _, form in ipairs(map(explist, _14_)) do
      table.insert(binding, form)
    end
    local function _14_(...)
      return compile(subscope, ...)
    end
    return list(sym("each"), binding, unpack(map(body, _14_)))
  end
  local function tset_2a(compile, scope, left, right_out, ast)
    if (1 < #left) then
      error(("Unsupported form; tset cannot set multiple values on line " .. (ast.line or "?")))
    end
    local _13_
    if (not left[1].computed and (left[1].property.kind == "Identifier")) then
      _13_ = left[1].property.name
    else
      _13_ = compile(scope, left[1].property)
    end
    return list(sym("tset"), compile(scope, left[1].object), _13_, right_out)
  end
  local function varize_local_21(scope, name)
    scope[name].ast[1] = "var"
    return true
  end
  local function setter_for(scope, names)
    local kinds = nil
    local function _12_(_241)
      local _13_0 = (scope[_241] or _241)
      if ((type(_13_0) == "table") and (nil ~= _13_0.kind)) then
        local kind = _13_0.kind
        return kind
      else
        local _ = _13_0
        return "global"
      end
    end
    kinds = map(names, _12_)
    local _13_0, _14_0, _15_0 = kinds
    local _16_
    do
      local _ = _13_0
      _16_ = (true and (1 < #kinds))
    end
    if _16_ then
      local _ = _13_0
      return "set-forcibly!"
    elseif ((type(_13_0) == "table") and (_13_0[1] == "local")) then
      local function _17_(...)
        return varize_local_21(scope, ...)
      end
      map(names, _17_)
      return "set"
    elseif ((type(_13_0) == "table") and (_13_0[1] == "MemberExpression")) then
      return "set"
    elseif ((type(_13_0) == "table") and (_13_0[1] == "function")) then
      return "set-forcibly!"
    elseif ((type(_13_0) == "table") and (_13_0[1] == "param")) then
      return "set-forcibly!"
    else
      local _ = _13_0
      return "global"
    end
  end
  local function assignment(compile, scope, ast)
    local _12_ = ast
    local left = _12_["left"]
    local right = _12_["right"]
    local right_out = nil
    if (1 == #right) then
      right_out = compile(scope, right[1])
    elseif (0 == #right) then
      right_out = sym("nil")
    else
      local function _13_(...)
        return compile(scope, ...)
      end
      right_out = list(sym("values"), unpack(map(right, _13_)))
    end
    if any_computed_3f(left[1]) then
      return tset_2a(compile, scope, left, right_out, ast)
    else
      local setter = nil
      local function _14_(_241)
        return (_241.name or _241)
      end
      setter = setter_for(scope, map(left, _14_))
      local _15_
      if (1 == #left) then
        _15_ = compile(scope, left[1])
      else
        local function _16_(...)
          return compile(scope, ...)
        end
        _15_ = list(unpack(map(left, _16_)))
      end
      return list(sym(setter), _15_, right_out)
    end
  end
  local function while_2a(compile, scope, _12_0)
    local _13_ = _12_0
    local body = _13_["body"]
    local test = _13_["test"]
    local subscope = make_scope(scope)
    local function _14_(...)
      return compile(subscope, ...)
    end
    return list(sym("while"), compile(scope, test), unpack(map(body, _14_)))
  end
  local function repeat_2a(compile, scope, _13_0)
    local _14_ = _13_0
    local body = _14_["body"]
    local test = _14_["test"]
    local function _16_()
      local _15_0 = nil
      local function _16_(...)
        return compile(scope, ...)
      end
      _15_0 = map(body, _16_)
      table.insert(_15_0, list(sym("when"), compile(scope, test), list(sym("lua"), "break")))
      return _15_0
    end
    return list(sym("while"), true, unpack(_16_()))
  end
  local function for_2a(compile, scope, _14_0)
    local _15_ = _14_0
    local body = _15_["body"]
    local init = _15_["init"]
    local last = _15_["last"]
    local step = _15_["step"]
    local i = compile(scope, init.id)
    local subscope = make_scope(scope)
    add_to_scope(subscope, "param", {i})
    local function _16_(...)
      return compile(subscope, ...)
    end
    return list(sym("for"), {i, compile(scope, init.value), compile(scope, last), (step and (step ~= 1) and compile(scope, step))}, unpack(map(body, _16_)))
  end
  local function table_2a(compile, scope, _15_0)
    local _16_ = _15_0
    local keyvals = _16_["keyvals"]
    local out = {}
    for i, _17_0 in pairs(keyvals) do
      local _18_ = _17_0
      local v = _18_[1]
      local k = _18_[2]
      if k then
        out[compile(scope, k)] = compile(scope, v)
      else
        out[i] = compile(scope, v)
      end
    end
    return out
  end
  local function do_2a(compile, scope, _16_0, tail_3f)
    local _17_ = _16_0
    local body = _17_["body"]
    local subscope = make_scope(scope)
    local function _18_(...)
      return compile(subscope, ...)
    end
    return list(sym("do"), unpack(map(body, _18_, tail_3f)))
  end
  local function _break(compile, scope, ast)
    return list(sym("lua"), "break")
  end
  local function unsupported(ast)
    if os.getenv("DEBUG") then
      p(ast)
    end
    return error((ast.kind .. " is not supported on line " .. (ast.line or "?")))
  end
  local function compile(scope, ast, tail_3f)
    if os.getenv("DEBUG") then
      print(ast.kind)
    end
    local _18_0 = ast.kind
    if (_18_0 == "Chunk") then
      local scope0 = make_scope(nil)
      local function _19_(...)
        return compile(scope0, ...)
      end
      return map(ast.body, _19_, true)
    elseif (_18_0 == "LocalDeclaration") then
      return local_declaration(compile, scope, ast)
    elseif (_18_0 == "FunctionDeclaration") then
      return declare_function(compile, scope, ast)
    elseif (_18_0 == "FunctionExpression") then
      return _function(compile, scope, ast)
    elseif (_18_0 == "BinaryExpression") then
      return binary(compile, scope, ast)
    elseif (_18_0 == "ConcatenateExpression") then
      return concat(compile, scope, ast)
    elseif (_18_0 == "CallExpression") then
      return call(compile, scope, ast)
    elseif (_18_0 == "LogicalExpression") then
      return binary(compile, scope, ast)
    elseif (_18_0 == "AssignmentExpression") then
      return assignment(compile, scope, ast)
    elseif (_18_0 == "SendExpression") then
      return send(compile, scope, ast)
    elseif (_18_0 == "MemberExpression") then
      return member(compile, scope, ast)
    elseif (_18_0 == "UnaryExpression") then
      return unary(compile, scope, ast)
    elseif (_18_0 == "ExpressionValue") then
      return compile(scope, ast.value)
    elseif (_18_0 == "ExpressionStatement") then
      return compile(scope, ast.expression)
    elseif (_18_0 == "IfStatement") then
      return if_2a(compile, scope, ast, tail_3f)
    elseif (_18_0 == "DoStatement") then
      return do_2a(compile, scope, ast, tail_3f)
    elseif (_18_0 == "ForInStatement") then
      return each_2a(compile, scope, ast)
    elseif (_18_0 == "WhileStatement") then
      return while_2a(compile, scope, ast)
    elseif (_18_0 == "RepeatStatement") then
      return repeat_2a(compile, scope, ast)
    elseif (_18_0 == "ForStatement") then
      return for_2a(compile, scope, ast)
    elseif (_18_0 == "BreakStatement") then
      return _break(compile, scope, ast)
    elseif (_18_0 == "ReturnStatement") then
      if tail_3f then
        return vals(compile, scope, ast)
      else
        return early_return(compile, scope, ast)
      end
    elseif (_18_0 == "Identifier") then
      return sym(ast.name)
    elseif (_18_0 == "Table") then
      return table_2a(compile, scope, ast)
    elseif (_18_0 == "Literal") then
      if (nil == ast.value) then
        return sym("nil")
      else
        return ast.value
      end
    elseif (_18_0 == "Vararg") then
      return sym("...")
    elseif (_18_0 == nil) then
      return sym("nil")
    else
      local _ = _18_0
      return unsupported(ast)
    end
  end
  return compile
end
package.preload["lang.reader"] = package.preload["lang.reader"] or function(...)
  local strsub = string.sub
  local function new_string_reader(src)
    local pos = 1
    local function reader()
      local chunk = strsub(src, pos, ((pos + 4096) - 32))
      pos = (pos + #chunk)
      return (((#chunk > 0) and chunk) or nil)
    end
    return reader
  end
  local function new_file_reader(filename)
    local f = nil
    if filename then
      f = assert(io.open(filename, "r"), ("cannot open file " .. filename))
    else
      f = io.stdin
    end
    local function reader()
      return f:read((4096 - 32))
    end
    return reader
  end
  return {file = new_file_reader, string = new_string_reader}
end
package.preload["lang.id_generator"] = package.preload["lang.id_generator"] or function(...)
  local function unique_name(variables, name)
    if (variables:lookup(name) ~= nil) then
      local prefix, index = string.match(name, "^(.+)(%d+)$")
      if not prefix then
        prefix, index = name, 1
      else
        index = (tonumber(index) + 1)
      end
      local test_name = (prefix .. tostring(index))
      while (variables:lookup(test_name) ~= nil) do
        index = (index + 1)
        test_name = (prefix .. tostring(index))
      end
      return test_name
    else
      return name
    end
  end
  local function pseudo(name)
    return ("@" .. name)
  end
  local function pseudo_match(pseudo_name)
    return string.match(pseudo_name, "^@(.+)$")
  end
  local function genid(variables, name)
    local pname = pseudo((name or "_"))
    local uname = unique_name(variables, pname)
    return variables:declare(uname)
  end
  local function normalize(variables, raw_name)
    local name = pseudo_match(raw_name)
    local uname = unique_name(variables, name)
    return uname
  end
  local function close_gen_variables(variables)
    local vars = variables.current.vars
    for i = 1, #vars, 1 do
      local id = vars[i]
      if pseudo_match(id.name) then
        id.name = normalize(variables, id.name)
      end
    end
    return nil
  end
  return {close_gen_variables = close_gen_variables, genid = genid}
end
package.preload["lang.lua_ast"] = package.preload["lang.lua_ast"] or function(...)
  local id_generator = require("lang.id_generator")
  local function build(kind, node)
    node.kind = kind
    return node
  end
  local function ident(ast, name, line, field)
    return build("Identifier", {line = line, name = ast.mangle(name, field)})
  end
  local function does_multi_return(expr)
    local k = expr.kind
    return (((k == "CallExpression") or (k == "SendExpression")) or (k == "Vararg"))
  end
  local AST = {}
  local function func_decl(id, body, params, vararg, locald, firstline, lastline)
    return build("FunctionDeclaration", {body = body, firstline = firstline, id = id, lastline = lastline, line = firstline, locald = locald, params = params, vararg = vararg})
  end
  local function func_expr(body, params, vararg, firstline, lastline)
    return build("FunctionExpression", {body = body, firstline = firstline, lastline = lastline, params = params, vararg = vararg})
  end
  AST.expr_function = function(ast, args, body, proto)
    return func_expr(body, args, proto.varargs, proto.firstline, proto.lastline)
  end
  AST.local_function_decl = function(ast, name, args, body, proto)
    local id = ast:var_declare(name)
    return func_decl(id, body, args, proto.varargs, true, proto.firstline, proto.lastline)
  end
  AST.function_decl = function(ast, path, args, body, proto)
    return func_decl(path, body, args, proto.varargs, false, proto.firstline, proto.lastline)
  end
  AST.func_parameters_decl = function(ast, args, vararg)
    local params = {}
    for i = 1, #args, 1 do
      params[i] = ast:var_declare(args[i])
    end
    if vararg then
      params[(#params + 1)] = ast:expr_vararg()
    end
    return params
  end
  AST.chunk = function(ast, body, chunkname, firstline, lastline)
    return build("Chunk", {body = body, chunkname = chunkname, firstline = firstline, lastline = lastline})
  end
  AST.local_decl = function(ast, vlist, exps, line)
    local ids = {}
    for k = 1, #vlist, 1 do
      ids[k] = ast:var_declare(vlist[k])
    end
    return build("LocalDeclaration", {expressions = exps, line = line, names = ids})
  end
  AST.assignment_expr = function(ast, vars, exps, line)
    return build("AssignmentExpression", {left = vars, line = line, right = exps})
  end
  AST.expr_index = function(ast, v, index, line)
    return build("MemberExpression", {computed = true, line = line, object = v, property = index})
  end
  AST.expr_property = function(ast, v, prop, line)
    local index = ident(ast, prop, line, true)
    return build("MemberExpression", {computed = false, line = line, object = v, property = index})
  end
  AST.literal = function(ast, val)
    return build("Literal", {value = val})
  end
  AST.expr_vararg = function(ast)
    return build("Vararg", {})
  end
  AST.expr_brackets = function(ast, expr)
    expr.bracketed = true
    return expr
  end
  AST.set_expr_last = function(ast, expr)
    if (expr.bracketed and does_multi_return(expr)) then
      expr.bracketed = nil
      return build("ExpressionValue", {value = expr})
    else
      return expr
    end
  end
  AST.expr_table = function(ast, keyvals, line)
    return build("Table", {keyvals = keyvals, line = line})
  end
  AST.expr_unop = function(ast, op, v, line)
    return build("UnaryExpression", {argument = v, line = line, operator = op})
  end
  local function concat_append(ts, node)
    local n = #ts
    if (node.kind == "ConcatenateExpression") then
      for k = 1, #node.terms, 1 do
        ts[(n + k)] = node.terms[k]
      end
      return nil
    else
      ts[(n + 1)] = node
      return nil
    end
  end
  AST.expr_binop = function(ast, op, expa, expb, line)
    local binop_body = ((op ~= "..") and {left = expa, line = line, operator = op, right = expb})
    if binop_body then
      if ((op == "and") or (op == "or")) then
        return build("LogicalExpression", binop_body)
      else
        return build("BinaryExpression", binop_body)
      end
    else
      local terms = {}
      concat_append(terms, expa)
      concat_append(terms, expb)
      return build("ConcatenateExpression", {line = expa.line, terms = terms})
    end
  end
  AST.identifier = function(ast, name)
    return ident(ast, name)
  end
  AST.expr_method_call = function(ast, v, key, args, line)
    local m = ident(ast, key, nil, true)
    return build("SendExpression", {arguments = args, line = line, method = m, receiver = v})
  end
  AST.expr_function_call = function(ast, v, args, line)
    return build("CallExpression", {arguments = args, callee = v, line = line})
  end
  AST.return_stmt = function(ast, exps, line)
    return build("ReturnStatement", {arguments = exps, line = line})
  end
  AST.break_stmt = function(ast, line)
    return build("BreakStatement", {line = line})
  end
  AST.label_stmt = function(ast, name, line)
    return build("LabelStatement", {label = name, line = line})
  end
  AST.new_statement_expr = function(ast, expr, line)
    return build("ExpressionStatement", {expression = expr, line = line})
  end
  AST.if_stmt = function(ast, tests, cons, else_branch, line)
    return build("IfStatement", {alternate = else_branch, cons = cons, line = line, tests = tests})
  end
  AST.do_stmt = function(ast, body, line, lastline)
    return build("DoStatement", {body = body, lastline = lastline, line = line})
  end
  AST.while_stmt = function(ast, test, body, line, lastline)
    return build("WhileStatement", {body = body, lastline = lastline, line = line, test = test})
  end
  AST.repeat_stmt = function(ast, test, body, line, lastline)
    return build("RepeatStatement", {body = body, lastline = lastline, line = line, test = test})
  end
  AST.for_stmt = function(ast, ___var___, init, last, step, body, line, lastline)
    local for_init = build("ForInit", {id = ___var___, line = line, value = init})
    return build("ForStatement", {body = body, init = for_init, last = last, lastline = lastline, line = line, step = step})
  end
  AST.for_iter_stmt = function(ast, vars, exps, body, line, lastline)
    local names = build("ForNames", {line = line, names = vars})
    return build("ForInStatement", {body = body, explist = exps, lastline = lastline, line = line, namelist = names})
  end
  AST.goto_stmt = function(ast, name, line)
    return build("GotoStatement", {label = name, line = line})
  end
  AST.var_declare = function(ast, name)
    local id = ident(ast, name)
    do end (ast.variables):declare(name)
    return id
  end
  AST.genid = function(ast, name)
    return id_generator.genid(ast.variables, name)
  end
  AST.fscope_begin = function(ast)
    return (ast.variables):scope_enter()
  end
  AST.fscope_end = function(ast)
    id_generator.close_gen_variables(ast.variables)
    return (ast.variables):scope_exit()
  end
  local ASTClass = {__index = AST}
  local function new_scope(parent_scope)
    return {parent = parent_scope, vars = {}}
  end
  local function new_variables_registry(create, ___match___)
    local function declare(self, name)
      local vars = self.current.vars
      local entry = create(name)
      vars[(#vars + 1)] = entry
      return entry
    end
    local function scope_enter(self)
      self.current = new_scope(self.current)
      return nil
    end
    local function scope_exit(self)
      self.current = self.current.parent
      return nil
    end
    local function lookup(self, name)
      local scope = self.current
      while scope do
        for i = 1, #scope.vars, 1 do
          if ___match___(scope.vars[i], name) then
            return scope
          end
        end
        scope = scope.parent
      end
      return nil
    end
    return {declare = declare, lookup = lookup, scope_enter = scope_enter, scope_exit = scope_exit}
  end
  local function default_mangle(name)
    return name
  end
  local function new_ast(mangle)
    local function match_id_name(id, name)
      return (id.name == name)
    end
    local ast = {mangle = (mangle or default_mangle)}
    local function create(...)
      return ident(ast, ...)
    end
    ast.variables = new_variables_registry(create, match_id_name)
    return setmetatable(ast, ASTClass)
  end
  return {New = new_ast}
end
package.preload["lang.operator"] = package.preload["lang.operator"] or function(...)
  local binop = {["%"] = ((7 * 256) + 7), ["*"] = ((7 * 256) + 7), ["+"] = ((6 * 256) + 6), ["-"] = ((6 * 256) + 6), [".."] = ((5 * 256) + 4), ["/"] = ((7 * 256) + 7), ["<"] = ((3 * 256) + 3), ["<="] = ((3 * 256) + 3), ["=="] = ((3 * 256) + 3), [">"] = ((3 * 256) + 3), [">="] = ((3 * 256) + 3), ["^"] = ((10 * 256) + 9), ["and"] = ((2 * 256) + 2), ["or"] = ((1 * 256) + 1), ["~="] = ((3 * 256) + 3)}
  local unary_priority = 8
  local ident_priority = 16
  local function is_binop(op)
    return binop[op]
  end
  local function left_priority(op)
    return bit.rshift(binop[op], 8)
  end
  local function right_priority(op)
    return bit.band(binop[op], 255)
  end
  return {ident_priority = ident_priority, is_binop = is_binop, left_priority = left_priority, right_priority = right_priority, unary_priority = unary_priority}
end
package.preload["lang.parser"] = package.preload["lang.parser"] or function(...)
  local operator = require("lang.operator")
  local LJ_52 = false
  local End_of_block = {TK_else = true, TK_elseif = true, TK_end = true, TK_eof = true, TK_until = true}
  local function err_syntax(ls, em)
    return ls:error(ls.token, em)
  end
  local function err_token(ls, token)
    return ls:error(ls.token, "'%s' expected", ls.token2str(token))
  end
  local function checkcond(ls, cond, em)
    if not cond then
      return err_syntax(ls, em)
    end
  end
  local function lex_opt(ls, tok)
    if (ls.token == tok) then
      ls:next()
      return true
    end
    return false
  end
  local function lex_check(ls, tok)
    if (ls.token ~= tok) then
      err_token(ls, tok)
    end
    return ls:next()
  end
  local function lex_match(ls, what, who, line)
    if not lex_opt(ls, what) then
      if (line == ls.linenumber) then
        return err_token(ls, what)
      else
        local token2str = ls.token2str
        return ls:error(ls.token, "%s expected (to close %s at line %d)", token2str(what), token2str(who), line)
      end
    end
  end
  local function lex_str(ls)
    if ((ls.token ~= "TK_name") and (LJ_52 or (ls.token ~= "TK_goto"))) then
      err_token(ls, "TK_name")
    end
    local s = ls.tokenval
    ls:next()
    return s
  end
  local expr_primary, expr, expr_unop, expr_binop, expr_simple = nil
  local expr_list, expr_table = nil
  local parse_body, parse_block, parse_args = nil
  local function var_lookup(ast, ls)
    local name = lex_str(ls)
    return ast:identifier(name)
  end
  local function expr_field(ast, ls, v)
    ls:next()
    local key = lex_str(ls)
    return ast:expr_property(v, key)
  end
  local function expr_bracket(ast, ls)
    ls:next()
    local v = expr(ast, ls)
    lex_check(ls, "]")
    return v
  end
  local function _0_(ast, ls)
    local line = ls.linenumber
    local kvs = {}
    lex_check(ls, "{")
    while (ls.token ~= "}") do
      local key = nil
      if (ls.token == "[") then
        key = expr_bracket(ast, ls)
        lex_check(ls, "=")
      elseif (((ls.token == "TK_name") or (not LJ_52 and (ls.token == "TK_goto"))) and (ls:lookahead() == "=")) then
        local name = lex_str(ls)
        key = ast:literal(name)
        lex_check(ls, "=")
      end
      local val = expr(ast, ls)
      kvs[(#kvs + 1)] = {val, key}
      if (not lex_opt(ls, ",") and not lex_opt(ls, ";")) then
        break
      end
    end
    lex_match(ls, "}", "{", line)
    return ast:expr_table(kvs, line)
  end
  expr_table = _0_
  local function _1_(ast, ls)
    local tk, val = ls.token, ls.tokenval
    local e = nil
    if (tk == "TK_number") then
      e = ast:literal(val)
    elseif (tk == "TK_string") then
      e = ast:literal(val)
    elseif (tk == "TK_nil") then
      e = ast:literal(nil)
    elseif (tk == "TK_true") then
      e = ast:literal(true)
    elseif (tk == "TK_false") then
      e = ast:literal(false)
    elseif (tk == "TK_dots") then
      if not ls.fs.varargs then
        err_syntax(ls, "cannot use \"...\" outside a vararg function")
      end
      e = ast:expr_vararg()
    elseif (tk == "{") then
      local ___antifnl_rtn_1___ = expr_table(ast, ls)
      return ___antifnl_rtn_1___
    elseif (tk == "TK_function") then
      ls:next()
      local args, body, proto = parse_body(ast, ls, ls.linenumber, false)
      local ___antifnl_rtn_1___ = ast:expr_function(args, body, proto)
      return ___antifnl_rtn_1___
    else
      local ___antifnl_rtn_1___ = expr_primary(ast, ls)
      return ___antifnl_rtn_1___
    end
    ls:next()
    return e
  end
  expr_simple = _1_
  local function _2_(ast, ls)
    local exps = {}
    exps[1] = expr(ast, ls)
    while lex_opt(ls, ",") do
      exps[(#exps + 1)] = expr(ast, ls)
    end
    local n = #exps
    if (n > 0) then
      exps[n] = ast:set_expr_last(exps[n])
    end
    return exps
  end
  expr_list = _2_
  local function _3_(ast, ls)
    local tk = ls.token
    if (((tk == "TK_not") or (tk == "-")) or (tk == "#")) then
      local line = ls.linenumber
      ls:next()
      local v = expr_binop(ast, ls, operator.unary_priority)
      return ast:expr_unop(ls.token2str(tk), v, line)
    else
      return expr_simple(ast, ls)
    end
  end
  expr_unop = _3_
  local function _4_(ast, ls, limit)
    local v = expr_unop(ast, ls)
    local op = ls.token2str(ls.token)
    while (operator.is_binop(op) and (operator.left_priority(op) > limit)) do
      local line = ls.linenumber
      ls:next()
      local v2, nextop = expr_binop(ast, ls, operator.right_priority(op))
      v = ast:expr_binop(op, v, v2, line)
      op = nextop
    end
    return v, op
  end
  expr_binop = _4_
  local function _5_(ast, ls)
    return expr_binop(ast, ls, 0)
  end
  expr = _5_
  local function _6_(ast, ls)
    local v, vk = nil
    if (ls.token == "(") then
      local line = ls.linenumber
      ls:next()
      vk, v = "expr", ast:expr_brackets(expr(ast, ls))
      lex_match(ls, ")", "(", line)
    elseif ((ls.token == "TK_name") or (not LJ_52 and (ls.token == "TK_goto"))) then
      vk, v = "var", var_lookup(ast, ls)
    else
      err_syntax(ls, "unexpected symbol")
    end
    while true do
      local line = ls.linenumber
      if (ls.token == ".") then
        vk, v = "indexed", expr_field(ast, ls, v)
      elseif (ls.token == "[") then
        local key = expr_bracket(ast, ls)
        vk, v = "indexed", ast:expr_index(v, key)
      elseif (ls.token == ":") then
        ls:next()
        local key = lex_str(ls)
        local args = parse_args(ast, ls)
        vk, v = "call", ast:expr_method_call(v, key, args, line)
      elseif (((ls.token == "(") or (ls.token == "TK_string")) or (ls.token == "{")) then
        local args = parse_args(ast, ls)
        vk, v = "call", ast:expr_function_call(v, args, line)
      else
        break
      end
    end
    return v, vk
  end
  expr_primary = _6_
  local function parse_return(ast, ls, line)
    ls:next()
    ls.fs.has_return = true
    local exps = nil
    if (End_of_block[ls.token] or (ls.token == ";")) then
      exps = {}
    else
      exps = expr_list(ast, ls)
    end
    return ast:return_stmt(exps, line)
  end
  local function parse_for_num(ast, ls, varname, line)
    lex_check(ls, "=")
    local init = expr(ast, ls)
    lex_check(ls, ",")
    local last = expr(ast, ls)
    local step = nil
    if lex_opt(ls, ",") then
      step = expr(ast, ls)
    else
      step = ast:literal(1)
    end
    lex_check(ls, "TK_do")
    local body = parse_block(ast, ls, line)
    local ___var___ = ast:identifier(varname)
    return ast:for_stmt(___var___, init, last, step, body, line, ls.linenumber)
  end
  local function parse_for_iter(ast, ls, indexname)
    local vars = {ast:identifier(indexname)}
    while lex_opt(ls, ",") do
      vars[(#vars + 1)] = ast:identifier(lex_str(ls))
    end
    lex_check(ls, "TK_in")
    local line = ls.linenumber
    local exps = expr_list(ast, ls)
    lex_check(ls, "TK_do")
    local body = parse_block(ast, ls, line)
    return ast:for_iter_stmt(vars, exps, body, line, ls.linenumber)
  end
  local function parse_for(ast, ls, line)
    ls:next()
    local varname = lex_str(ls)
    local stmt = nil
    if (ls.token == "=") then
      stmt = parse_for_num(ast, ls, varname, line)
    elseif ((ls.token == ",") or (ls.token == "TK_in")) then
      stmt = parse_for_iter(ast, ls, varname)
    else
      err_syntax(ls, "'=' or 'in' expected")
    end
    lex_match(ls, "TK_end", "TK_for", line)
    return stmt
  end
  local function parse_repeat(ast, ls, line)
    ast:fscope_begin()
    ls:next()
    local body = parse_block(ast, ls)
    local lastline = ls.linenumber
    lex_match(ls, "TK_until", "TK_repeat", line)
    local cond = expr(ast, ls)
    ast:fscope_end()
    return ast:repeat_stmt(cond, body, line, lastline)
  end
  local function _7_(ast, ls)
    local line = ls.linenumber
    local args = nil
    if (ls.token == "(") then
      if (not LJ_52 and (line ~= ls.lastline)) then
        err_syntax(ls, "ambiguous syntax (function call x new statement)")
      end
      ls:next()
      if (ls.token ~= ")") then
        args = expr_list(ast, ls)
      else
        args = {}
      end
      lex_match(ls, ")", "(", line)
    elseif (ls.token == "{") then
      local a = expr_table(ast, ls)
      args = {a}
    elseif (ls.token == "TK_string") then
      local a = ls.tokenval
      ls:next()
      args = {ast:literal(a)}
    else
      err_syntax(ls, "function arguments expected")
    end
    return args
  end
  parse_args = _7_
  local function parse_assignment(ast, ls, vlist, ___var___, vk)
    local line = ls.linenumber
    checkcond(ls, ((vk == "var") or (vk == "indexed")), "syntax error")
    vlist[(#vlist + 1)] = ___var___
    if lex_opt(ls, ",") then
      local n_var, n_vk = expr_primary(ast, ls)
      return parse_assignment(ast, ls, vlist, n_var, n_vk)
    else
      lex_check(ls, "=")
      local exps = expr_list(ast, ls)
      return ast:assignment_expr(vlist, exps, line)
    end
  end
  local function parse_call_assign(ast, ls)
    local ___var___, vk = expr_primary(ast, ls)
    if (vk == "call") then
      return ast:new_statement_expr(___var___, ls.linenumber)
    else
      local vlist = {}
      return parse_assignment(ast, ls, vlist, ___var___, vk)
    end
  end
  local function parse_local(ast, ls)
    local line = ls.linenumber
    if lex_opt(ls, "TK_function") then
      local name = lex_str(ls)
      local args, body, proto = parse_body(ast, ls, line, false)
      return ast:local_function_decl(name, args, body, proto)
    else
      local vl = {}
      local function collect_lhs()
        vl[(#vl + 1)] = lex_str(ls)
        if lex_opt(ls, ",") then
          return collect_lhs()
        end
      end
      collect_lhs()
      local exps = nil
      if lex_opt(ls, "=") then
        exps = expr_list(ast, ls)
      else
        exps = {}
      end
      return ast:local_decl(vl, exps, line)
    end
  end
  local function parse_func(ast, ls, line)
    local needself = false
    ls:next()
    local v = var_lookup(ast, ls)
    while (ls.token == ".") do
      v = expr_field(ast, ls, v)
    end
    if (ls.token == ":") then
      needself = true
      v = expr_field(ast, ls, v)
    end
    local args, body, proto = parse_body(ast, ls, line, needself)
    return ast:function_decl(v, args, body, proto)
  end
  local function parse_while(ast, ls, line)
    ls:next()
    local cond = expr(ast, ls)
    ast:fscope_begin()
    lex_check(ls, "TK_do")
    local body = parse_block(ast, ls)
    local lastline = ls.linenumber
    lex_match(ls, "TK_end", "TK_while", line)
    ast:fscope_end()
    return ast:while_stmt(cond, body, line, lastline)
  end
  local function parse_then(ast, ls, tests, line)
    ls:next()
    tests[(#tests + 1)] = expr(ast, ls)
    lex_check(ls, "TK_then")
    return parse_block(ast, ls, line)
  end
  local function parse_if(ast, ls, line)
    local tests, blocks = {}, {}
    blocks[1] = parse_then(ast, ls, tests, line)
    while (ls.token == "TK_elseif") do
      blocks[(#blocks + 1)] = parse_then(ast, ls, tests, ls.linenumber)
    end
    local else_branch = nil
    if (ls.token == "TK_else") then
      local eline = ls.linenumber
      ls:next()
      else_branch = parse_block(ast, ls, eline)
    end
    lex_match(ls, "TK_end", "TK_if", line)
    return ast:if_stmt(tests, blocks, else_branch, line)
  end
  local function parse_label(ast, ls)
    ls:next()
    local name = lex_str(ls)
    lex_check(ls, "TK_label")
    while true do
      if (ls.token == "TK_label") then
        parse_label(ast, ls)
      elseif (LJ_52 and (ls.token == ";")) then
        ls:next()
      else
        break
      end
    end
    return ast:label_stmt(name, ls.linenumber)
  end
  local function parse_goto(ast, ls)
    local line = ls.linenumber
    local name = lex_str(ls)
    return ast:goto_stmt(name, line)
  end
  local function parse_stmt(ast, ls)
    local line = ls.linenumber
    local stmt = nil
    if (ls.token == "TK_if") then
      stmt = parse_if(ast, ls, line)
    elseif (ls.token == "TK_while") then
      stmt = parse_while(ast, ls, line)
    elseif (ls.token == "TK_do") then
      ls:next()
      local body = parse_block(ast, ls)
      local lastline = ls.linenumber
      lex_match(ls, "TK_end", "TK_do", line)
      stmt = ast:do_stmt(body, line, lastline)
    elseif (ls.token == "TK_for") then
      stmt = parse_for(ast, ls, line)
    elseif (ls.token == "TK_repeat") then
      stmt = parse_repeat(ast, ls, line)
    elseif (ls.token == "TK_function") then
      stmt = parse_func(ast, ls, line)
    elseif (ls.token == "TK_local") then
      ls:next()
      stmt = parse_local(ast, ls, line)
    elseif (ls.token == "TK_return") then
      stmt = parse_return(ast, ls, line)
      return stmt, true
    elseif (ls.token == "TK_break") then
      ls:next()
      stmt = ast:break_stmt(line)
      local ___antifnl_rtn_1___ = stmt
      local ___antifnl_rtn_2___ = not LJ_52
      return ___antifnl_rtn_1___, ___antifnl_rtn_2___
    elseif (LJ_52 and (ls.token == ";")) then
      ls:next()
      local ___antifnl_rtn_1___ = parse_stmt(ast, ls)
      return ___antifnl_rtn_1___
    elseif (ls.token == "TK_label") then
      stmt = parse_label(ast, ls)
    elseif (ls.token == "TK_goto") then
      if (LJ_52 or (ls:lookahead() == "TK_name")) then
        ls:next()
        stmt = parse_goto(ast, ls)
      end
    end
    if not stmt then
      stmt = parse_call_assign(ast, ls)
    end
    return stmt, false
  end
  local function parse_params(ast, ls, needself)
    lex_check(ls, "(")
    local args = {}
    local vararg = false
    if needself then
      args[1] = "self"
    end
    if (ls.token ~= ")") then
      local function tk_args()
        if ((ls.token == "TK_name") or (not LJ_52 and (ls.token == "TK_goto"))) then
          local name = lex_str(ls)
          args[(#args + 1)] = name
          if lex_opt(ls, ",") then
            return tk_args()
          end
        elseif (ls.token == "TK_dots") then
          ls:next()
          vararg = true
          return nil
        else
          err_syntax(ls, "<name> or \"...\" expected")
          if lex_opt(ls, ",") then
            return tk_args()
          end
        end
      end
      tk_args()
    end
    lex_check(ls, ")")
    return args, vararg
  end
  local function new_proto(ls, varargs)
    return {varargs = varargs}
  end
  local function parse_block_stmts(ast, ls)
    local firstline = ls.linenumber
    local stmt, islast = nil, false
    local body = {}
    while (not islast and not End_of_block[ls.token]) do
      stmt, islast = parse_stmt(ast, ls)
      body[(#body + 1)] = stmt
      lex_opt(ls, ";")
    end
    return body, firstline, ls.linenumber
  end
  local function parse_chunk(ast, ls)
    local body, firstline, lastline = parse_block_stmts(ast, ls)
    return ast:chunk(body, ls.chunkname, 0, lastline)
  end
  local function _8_(ast, ls, line, needself)
    local pfs = ls.fs
    ls.fs = new_proto(ls, false)
    ast:fscope_begin()
    ls.fs.firstline = line
    local args, vararg = parse_params(ast, ls, needself)
    local params = ast:func_parameters_decl(args, vararg)
    ls.fs.varargs = vararg
    local body = parse_block(ast, ls)
    ast:fscope_end()
    local proto = ls.fs
    if (ls.token ~= "TK_end") then
      lex_match(ls, "TK_end", "TK_function", line)
    end
    ls.fs.lastline = ls.linenumber
    ls:next()
    ls.fs = pfs
    return params, body, proto
  end
  parse_body = _8_
  local function _9_(ast, ls, firstline)
    ast:fscope_begin()
    local body = parse_block_stmts(ast, ls)
    body.firstline, body.lastline = firstline, ls.linenumber
    ast:fscope_end()
    return body
  end
  parse_block = _9_
  local function parse(ast, ls)
    ls:next()
    ls.fs = new_proto(ls, true)
    ast:fscope_begin()
    local chunk = parse_chunk(ast, ls)
    ast:fscope_end()
    if (ls.token ~= "TK_eof") then
      err_token(ls, "TK_eof")
    end
    return chunk
  end
  return parse
end
package.preload["lang.lexer"] = package.preload["lang.lexer"] or function(...)
  local ffi = require("ffi")
  local ___band___ = bit.band
  local strsub, strbyte, strchar = string.sub, string.byte, string.char
  local ASCII_0, ASCII_9 = 48, 57
  local ASCII_a, ASCII_f, ASCII_z = 97, 102, 122
  local ASCII_A, ASCII_Z = 65, 90
  local END_OF_STREAM = ( - 1)
  local Reserved_keyword = {["and"] = 1, ["break"] = 2, ["do"] = 3, ["else"] = 4, ["elseif"] = 5, ["end"] = 6, ["false"] = 7, ["for"] = 8, ["function"] = 9, ["goto"] = 10, ["if"] = 11, ["in"] = 12, ["local"] = 13, ["nil"] = 14, ["not"] = 15, ["or"] = 16, ["repeat"] = 17, ["return"] = 18, ["then"] = 19, ["true"] = 20, ["until"] = 21, ["while"] = 22}
  local uint64, int64 = ffi.typeof("uint64_t"), ffi.typeof("int64_t")
  local complex = ffi.typeof("complex")
  local Token_symbol = {TK_concat = "..", TK_eof = "<eof>", TK_eq = "==", TK_ge = ">=", TK_le = "<=", TK_ne = "~="}
  local function token2str(tok)
    if string.match(tok, "^TK_") then
      return (Token_symbol[tok] or string.sub(tok, 4))
    else
      return tok
    end
  end
  local function error_lex(chunkname, tok, line, em, ...)
    local emfmt = string.format(em, ...)
    local msg = string.format("%s:%d: %s", chunkname, line, emfmt)
    if tok then
      msg = string.format("%s near '%s'", msg, tok)
    end
    return error(("LLT-ERROR" .. msg), 0)
  end
  local function lex_error(ls, token, em, ...)
    local tok = nil
    if (((token == "TK_name") or (token == "TK_string")) or (token == "TK_number")) then
      tok = ls.save_buf
    elseif token then
      tok = token2str(token)
    end
    return error_lex(ls.chunkname, tok, ls.linenumber, em, ...)
  end
  local function char_isident(c)
    if (type(c) == "string") then
      local b = strbyte(c)
      if ((b >= ASCII_0) and (b <= ASCII_9)) then
        return true
      elseif ((b >= ASCII_a) and (b <= ASCII_z)) then
        return true
      elseif ((b >= ASCII_A) and (b <= ASCII_Z)) then
        return true
      else
        local ___antifnl_rtn_1___ = (c == "_")
        return ___antifnl_rtn_1___
      end
    end
    return false
  end
  local function char_isdigit(c)
    if (type(c) == "string") then
      local b = strbyte(c)
      local ___antifnl_rtn_1___ = ((b >= ASCII_0) and (b <= ASCII_9))
      return ___antifnl_rtn_1___
    end
    return false
  end
  local function char_isspace(c)
    local b = strbyte(c)
    return (((b >= 9) and (b <= 13)) or (b == 32))
  end
  local function byte(ls, n)
    local k = (ls.p + n)
    return strsub(ls.data, k, k)
  end
  local function pop(ls)
    local k = ls.p
    local c = strsub(ls.data, k, k)
    ls.p = (k + 1)
    ls.n = (ls.n - 1)
    return c
  end
  local function fillbuf(ls)
    local data = ls:read_func()
    if not data then
      return END_OF_STREAM
    end
    ls.data, ls.n, ls.p = data, #data, 1
    return pop(ls)
  end
  local function nextchar(ls)
    local c = (((ls.n > 0) and pop(ls)) or fillbuf(ls))
    ls.current = c
    return c
  end
  local function curr_is_newline(ls)
    local c = ls.current
    return ((c == "\n") or (c == "\13"))
  end
  local function resetbuf(ls)
    ls.save_buf = ""
    return nil
  end
  local function resetbuf_tospace(ls)
    ls.space_buf = (ls.space_buf .. ls.save_buf)
    ls.save_buf = ""
    return nil
  end
  local function spaceadd(ls, str)
    ls.space_buf = (ls.space_buf .. str)
    return nil
  end
  local function save(ls, c)
    ls.save_buf = (ls.save_buf .. c)
    return nil
  end
  local function savespace_and_next(ls)
    ls.space_buf = (ls.space_buf .. ls.current)
    return nextchar(ls)
  end
  local function save_and_next(ls)
    ls.save_buf = (ls.save_buf .. ls.current)
    return nextchar(ls)
  end
  local function get_string(ls, init_skip, end_skip)
    return strsub(ls.save_buf, (init_skip + 1), ( - (end_skip + 1)))
  end
  local function get_space_string(ls)
    local s = ls.space_buf
    ls.space_buf = ""
    return s
  end
  local function inclinenumber(ls)
    local old = ls.current
    savespace_and_next(ls)
    if (curr_is_newline(ls) and (ls.current ~= old)) then
      savespace_and_next(ls)
    end
    ls.linenumber = (ls.linenumber + 1)
    return nil
  end
  local function skip_sep(ls)
    local count = 0
    local s = ls.current
    assert(((s == "[") or (s == "]")))
    save_and_next(ls)
    while (ls.current == "=") do
      save_and_next(ls)
      count = (count + 1)
    end
    return (((ls.current == s) and count) or (( - count) - 1))
  end
  local function build_64int(str)
    local u = str[(#str - 2)]
    local x = (((u == 117) and uint64(0)) or int64(0))
    local i = 1
    while ((str[i] >= ASCII_0) and (str[i] <= ASCII_9)) do
      x = ((10 * x) + (str[i] - ASCII_0))
      i = (i + 1)
    end
    return x
  end
  local function byte_to_hexdigit(b)
    if ((b >= ASCII_0) and (b <= ASCII_9)) then
      return (b - ASCII_0)
    elseif ((b >= ASCII_a) and (b <= ASCII_f)) then
      return (10 + (b - ASCII_a))
    else
      return ( - 1)
    end
  end
  local function build_64hex(str)
    local u = str[(#str - 2)]
    local x = (((u == 117) and uint64(0)) or int64(0))
    local i = 3
    while str[i] do
      local n = byte_to_hexdigit(str[i])
      if (n < 0) then
        break
      end
      x = ((16 * x) + n)
      i = (i + 1)
    end
    return x
  end
  local function strnumdump(str)
    local t = {}
    for i = 1, #str, 1 do
      local c = strsub(str, i, i)
      if char_isident(c) then
        t[i] = strbyte(c)
      else
        return nil
      end
    end
    return t
  end
  local function lex_number(ls)
    local lower = string.lower
    local xp = "e"
    local c = ls.current
    if (c == "0") then
      save_and_next(ls)
      local xc = ls.current
      if ((xc == "x") or (xc == "X")) then
        xp = "p"
      end
    end
    while ((char_isident(ls.current) or (ls.current == ".")) or (((ls.current == "-") or (ls.current == "+")) and (lower(c) == xp))) do
      c = lower(ls.current)
      save(ls, c)
      nextchar(ls)
    end
    local str = ls.save_buf
    local x = nil
    if (strsub(str, ( - 1), ( - 1)) == "i") then
      local img = tonumber(strsub(str, 1, ( - 2)))
      if img then
        x = complex(0, img)
      end
    elseif (strsub(str, ( - 2), ( - 1)) == "ll") then
      local t = strnumdump(str)
      if t then
        x = (((xp == "e") and build_64int(t)) or build_64hex(t))
      end
    else
      x = tonumber(str)
    end
    if x then
      return x
    else
      return lex_error(ls, "TK_number", "malformed number")
    end
  end
  local function read_long_string(ls, sep, ret_value)
    save_and_next(ls)
    if curr_is_newline(ls) then
      inclinenumber(ls)
    end
    while true do
      local c = ls.current
      if (c == END_OF_STREAM) then
        lex_error(ls, "TK_eof", ((ret_value and "unfinished long string") or "unfinished long comment"))
      elseif (c == "]") then
        if (skip_sep(ls) == sep) then
          save_and_next(ls)
          break
        end
      elseif ((c == "\n") or (c == "\13")) then
        save(ls, "\n")
        inclinenumber(ls)
        if not ret_value then
          resetbuf(ls)
        end
      else
        if ret_value then
          save_and_next(ls)
        else
          nextchar(ls)
        end
      end
    end
    if ret_value then
      return get_string(ls, (2 + sep), (2 + sep))
    end
  end
  local Escapes = {a = "\7", b = "\8", f = "\12", n = "\n", r = "\13", t = "\9", v = "\11"}
  local function hex_char(c)
    if string.match(c, "^%x") then
      local b = ___band___(strbyte(c), 15)
      if not char_isdigit(c) then
        b = (b + 9)
      end
      return b
    end
  end
  local function read_escape_char(ls)
    local c = nextchar(ls)
    local esc = Escapes[c]
    if esc then
      save(ls, esc)
      return nextchar(ls)
    elseif (c == "x") then
      local ch1 = hex_char(nextchar(ls))
      local hc = nil
      if ch1 then
        local ch2 = hex_char(nextchar(ls))
        if ch2 then
          hc = strchar(((ch1 * 16) + ch2))
        end
      end
      if not hc then
        lex_error(ls, "TK_string", "invalid escape sequence")
      end
      save(ls, hc)
      return nextchar(ls)
    elseif (c == "z") then
      nextchar(ls)
      while char_isspace(ls.current) do
        if curr_is_newline(ls) then
          inclinenumber(ls)
        else
          nextchar(ls)
        end
      end
      return nil
    elseif ((c == "\n") or (c == "\13")) then
      save(ls, "\n")
      return inclinenumber(ls)
    elseif (((c == "\\") or (c == "\"")) or (c == "'")) then
      save(ls, c)
      return nextchar(ls)
    elseif (c ~= END_OF_STREAM) then
      if not char_isdigit(c) then
        lex_error(ls, "TK_string", "invalid escape sequence")
      end
      local bc = ___band___(strbyte(c), 15)
      if char_isdigit(nextchar(ls)) then
        bc = ((bc * 10) + ___band___(strbyte(ls.current), 15))
        if char_isdigit(nextchar(ls)) then
          bc = ((bc * 10) + ___band___(strbyte(ls.current), 15))
          if (bc > 255) then
            lex_error(ls, "TK_string", "invalid escape sequence")
          end
          nextchar(ls)
        end
      end
      return save(ls, strchar(bc))
    end
  end
  local function read_string(ls, delim)
    save_and_next(ls)
    while (ls.current ~= delim) do
      local c = ls.current
      if (c == END_OF_STREAM) then
        lex_error(ls, "TK_eof", "unfinished string")
      elseif ((c == "\n") or (c == "\13")) then
        lex_error(ls, "TK_string", "unfinished string")
      elseif (c == "\\") then
        read_escape_char(ls)
      else
        save_and_next(ls)
      end
    end
    save_and_next(ls)
    return get_string(ls, 1, 1)
  end
  local function skip_line(ls)
    while (not curr_is_newline(ls) and (ls.current ~= END_OF_STREAM)) do
      savespace_and_next(ls)
    end
    return nil
  end
  local function llex(ls)
    resetbuf(ls)
    while true do
      local current = ls.current
      if char_isident(current) then
        if char_isdigit(current) then
          local ___antifnl_rtn_1___ = "TK_number"
          local ___antifnl_rtn_2___ = lex_number(ls)
          return ___antifnl_rtn_1___, ___antifnl_rtn_2___
        end
        local function sn()
          save_and_next(ls)
          if char_isident(ls.current) then
            return sn()
          end
        end
        sn()
        local s = get_string(ls, 0, 0)
        local reserved = Reserved_keyword[s]
        if reserved then
          local ___antifnl_rtn_1___ = ("TK_" .. s)
          return ___antifnl_rtn_1___
        else
          return "TK_name", s
        end
      end
      if ((current == "\n") or (current == "\13")) then
        inclinenumber(ls)
      elseif ((((current == " ") or (current == "\9")) or (current == "\8")) or (current == "\12")) then
        savespace_and_next(ls)
      elseif (current == "-") then
        nextchar(ls)
        if (ls.current ~= "-") then
          return "-"
        end
        nextchar(ls)
        spaceadd(ls, "--")
        if (ls.current == "[") then
          local sep = skip_sep(ls)
          resetbuf_tospace(ls)
          if (sep >= 0) then
            read_long_string(ls, sep, false)
            resetbuf_tospace(ls)
          else
            skip_line(ls)
          end
        else
          skip_line(ls)
        end
      elseif (current == "[") then
        local sep = skip_sep(ls)
        if (sep >= 0) then
          local str = read_long_string(ls, sep, true)
          return "TK_string", str
        elseif (sep == ( - 1)) then
          return "["
        else
          lex_error(ls, "TK_string", "delimiter error")
        end
      elseif (current == "=") then
        nextchar(ls)
        if (ls.current ~= "=") then
          return "="
        else
          nextchar(ls)
          return "TK_eq"
        end
      elseif (current == "<") then
        nextchar(ls)
        if (ls.current ~= "=") then
          return "<"
        else
          nextchar(ls)
          return "TK_le"
        end
      elseif (current == ">") then
        nextchar(ls)
        if (ls.current ~= "=") then
          return ">"
        else
          nextchar(ls)
          return "TK_ge"
        end
      elseif (current == "~") then
        nextchar(ls)
        if (ls.current ~= "=") then
          return "~"
        else
          nextchar(ls)
          return "TK_ne"
        end
      elseif (current == ":") then
        nextchar(ls)
        if (ls.current ~= ":") then
          return ":"
        else
          nextchar(ls)
          return "TK_label"
        end
      elseif ((current == "\"") or (current == "'")) then
        local str = read_string(ls, current)
        return "TK_string", str
      elseif (current == ".") then
        save_and_next(ls)
        if (ls.current == ".") then
          nextchar(ls)
          if (ls.current == ".") then
            nextchar(ls)
            return "TK_dots"
          end
          return "TK_concat"
        elseif not char_isdigit(ls.current) then
          return "."
        else
          local ___antifnl_rtn_1___ = "TK_number"
          local ___antifnl_rtn_2___ = lex_number(ls)
          return ___antifnl_rtn_1___, ___antifnl_rtn_2___
        end
      elseif (current == END_OF_STREAM) then
        return "TK_eof"
      else
        nextchar(ls)
        return current
      end
    end
    return nil
  end
  local Lexer = {error = lex_error, token2str = token2str}
  Lexer.next = function(ls)
    ls.lastline = ls.linenumber
    if (ls.tklookahead == "TK_eof") then
      ls.token, ls.tokenval = llex(ls)
      ls.space = get_space_string(ls)
      return nil
    else
      ls.token, ls.tokenval = ls.tklookahead, ls.tklookaheadval
      ls.space = ls.spaceahead
      ls.tklookahead = "TK_eof"
      return nil
    end
  end
  Lexer.lookahead = function(ls)
    assert((ls.tklookahead == "TK_eof"))
    ls.tklookahead, ls.tklookaheadval = llex(ls)
    ls.spaceahead = get_space_string(ls)
    return ls.tklookahead
  end
  local Lexer_class = {__index = Lexer}
  local function lex_setup(read_func, chunkname)
    local header = false
    local ls = {chunkname = chunkname, lastline = 1, linenumber = 1, n = 0, read_func = read_func, space_buf = "", tklookahead = "TK_eof"}
    nextchar(ls)
    if ((((ls.current == "\239") and (ls.n >= 2)) and (byte(ls, 0) == "\187")) and (byte(ls, 1) == "\191")) then
      ls.n = (ls.n - 2)
      ls.p = (ls.p + 2)
      nextchar(ls)
      header = true
    end
    if (ls.current == "#") then
      local function nc()
        nextchar(ls)
        if (ls.current == END_OF_STREAM) then
          return ls
        end
        if curr_is_newline(ls) then
          return nc()
        end
      end
      nc()
      inclinenumber(ls)
      header = true
    end
    return setmetatable(ls, Lexer_class)
  end
  return lex_setup
end
local fennel = nil
package.preload["fennel"] = package.preload["fennel"] or function(...)
  package.preload["fennel.repl"] = package.preload["fennel.repl"] or function(...)
    local utils = require("fennel.utils")
    local parser = require("fennel.parser")
    local compiler = require("fennel.compiler")
    local specials = require("fennel.specials")
    local function default_read_chunk(parser_state)
      local function _0_()
        if (0 < parser_state["stack-size"]) then
          return ".."
        else
          return ">> "
        end
      end
      io.write(_0_())
      io.flush()
      local input = io.read()
      return (input and (input .. "\n"))
    end
    local function default_on_values(xs)
      io.write(table.concat(xs, "\9"))
      return io.write("\n")
    end
    local function default_on_error(errtype, err, lua_source)
      local function _1_()
        local _0_0 = errtype
        if (_0_0 == "Lua Compile") then
          return ("Bad code generated - likely a bug with the compiler:\n" .. "--- Generated Lua Start ---\n" .. lua_source .. "--- Generated Lua End ---\n")
        elseif (_0_0 == "Runtime") then
          return (compiler.traceback(err, 4) .. "\n")
        else
          local _ = _0_0
          return ("%s error: %s\n"):format(errtype, tostring(err))
        end
      end
      return io.write(_1_())
    end
    local save_source = table.concat({"local ___i___ = 1", "while true do", " local name, value = debug.getlocal(1, ___i___)", " if(name and name ~= \"___i___\") then", " ___replLocals___[name] = value", " ___i___ = ___i___ + 1", " else break end end"}, "\n")
    local function splice_save_locals(env, lua_source)
      env.___replLocals___ = (env.___replLocals___ or {})
      local spliced_source = {}
      local bind = "local %s = ___replLocals___['%s']"
      for line in lua_source:gmatch("([^\n]+)\n?") do
        table.insert(spliced_source, line)
      end
      for name in pairs(env.___replLocals___) do
        table.insert(spliced_source, 1, bind:format(name, name))
      end
      if ((1 < #spliced_source) and (spliced_source[#spliced_source]):match("^ *return .*$")) then
        table.insert(spliced_source, #spliced_source, save_source)
      end
      return table.concat(spliced_source, "\n")
    end
    local function completer(env, scope, text)
      local matches = {}
      local input_fragment = text:gsub(".*[%s)(]+", "")
      local function add_partials(input, tbl, prefix)
        for k in utils.allpairs(tbl) do
          local k0 = nil
          if ((tbl == env) or (tbl == env.___replLocals___)) then
            k0 = scope.unmanglings[k]
          else
            k0 = k
          end
          if ((#matches < 2000) and (type(k0) == "string") and (input == k0:sub(0, #input))) then
            table.insert(matches, (prefix .. k0))
          end
        end
        return nil
      end
      local function add_matches(input, tbl, prefix)
        local prefix0 = nil
        if prefix then
          prefix0 = (prefix .. ".")
        else
          prefix0 = ""
        end
        if not input:find("%.") then
          return add_partials(input, tbl, prefix0)
        else
          local head, tail = input:match("^([^.]+)%.(.*)")
          local raw_head = nil
          if ((tbl == env) or (tbl == env.___replLocals___)) then
            raw_head = scope.manglings[head]
          else
            raw_head = head
          end
          if (type(tbl[raw_head]) == "table") then
            return add_matches(tail, tbl[raw_head], (prefix0 .. head))
          end
        end
      end
      add_matches(input_fragment, (scope.specials or {}))
      add_matches(input_fragment, (scope.macros or {}))
      add_matches(input_fragment, (env.___replLocals___ or {}))
      add_matches(input_fragment, env)
      add_matches(input_fragment, (env._ENV or env._G or {}))
      return matches
    end
    local function repl(options)
      local old_root_options = utils.root.options
      local env = nil
      if options.env then
        env = utils["wrap-env"](options.env)
      else
        env = setmetatable({}, {__index = (_G._ENV or _G)})
      end
      local save_locals_3f = ((options.saveLocals ~= false) and env.debug and env.debug.getlocal)
      local opts = {}
      local _ = nil
      for k, v in pairs(options) do
        opts[k] = v
      end
      _ = nil
      local read_chunk = (opts.readChunk or default_read_chunk)
      local on_values = (opts.onValues or default_on_values)
      local on_error = (opts.onError or default_on_error)
      local pp = (opts.pp or tostring)
      local byte_stream, clear_stream = parser.granulate(read_chunk)
      local chars = {}
      local read, reset = nil, nil
      local function _1_(parser_state)
        local c = byte_stream(parser_state)
        chars[(#chars + 1)] = c
        return c
      end
      read, reset = parser.parser(_1_)
      local scope = compiler["make-scope"]()
      opts.useMetadata = (options.useMetadata ~= false)
      if (opts.allowedGlobals == nil) then
        opts.allowedGlobals = specials["current-global-names"](opts.env)
      end
      if opts.registerCompleter then
        local function _3_(...)
          return completer(env, scope, ...)
        end
        opts.registerCompleter(_3_)
      end
      local function loop()
        for k in pairs(chars) do
          chars[k] = nil
        end
        local ok, parse_ok_3f, x = pcall(read)
        local src_string = string.char((_G.unpack or table.unpack)(chars))
        utils.root.options = opts
        if not ok then
          on_error("Parse", parse_ok_3f)
          clear_stream()
          reset()
          return loop()
        else
          if parse_ok_3f then
            do
              local _4_0, _5_0 = pcall(compiler.compile, x, {["assert-compile"] = opts["assert-compile"], ["parse-error"] = opts["parse-error"], correlate = opts.correlate, moduleName = opts.moduleName, scope = scope, source = src_string, useMetadata = opts.useMetadata})
              if ((_4_0 == false) and (nil ~= _5_0)) then
                local msg = _5_0
                clear_stream()
                on_error("Compile", msg)
              elseif ((_4_0 == true) and (nil ~= _5_0)) then
                local source = _5_0
                local source0 = nil
                if save_locals_3f then
                  source0 = splice_save_locals(env, source)
                else
                  source0 = source
                end
                local lua_ok_3f, loader = pcall(specials["load-code"], source0, env)
                if not lua_ok_3f then
                  clear_stream()
                  on_error("Lua Compile", loader, source0)
                else
                  local _7_0, _8_0 = nil, nil
                  local function _9_()
                    return {loader()}
                  end
                  local function _10_(...)
                    return on_error("Runtime", ...)
                  end
                  _7_0, _8_0 = xpcall(_9_, _10_)
                  if ((_7_0 == true) and (nil ~= _8_0)) then
                    local ret = _8_0
                    env._ = ret[1]
                    env.__ = ret
                    on_values(utils.map(ret, pp))
                  end
                end
              end
            end
            utils.root.options = old_root_options
            return loop()
          end
        end
      end
      return loop()
    end
    return repl
  end
  package.preload["fennel.specials"] = package.preload["fennel.specials"] or function(...)
    local utils = require("fennel.utils")
    local parser = require("fennel.parser")
    local compiler = require("fennel.compiler")
    local unpack = (_G.unpack or table.unpack)
    local SPECIALS = compiler.scopes.global.specials
    local function wrap_env(env)
      local function _0_(_, key)
        if (type(key) == "string") then
          return env[compiler["global-unmangling"](key)]
        else
          return env[key]
        end
      end
      local function _1_(_, key, value)
        if (type(key) == "string") then
          env[compiler["global-unmangling"](key)] = value
          return nil
        else
          env[key] = value
          return nil
        end
      end
      local function _2_()
        local function putenv(k, v)
          local _3_
          if (type(k) == "string") then
            _3_ = compiler["global-unmangling"](k)
          else
            _3_ = k
          end
          return _3_, v
        end
        return next, utils.kvmap(env, putenv), nil
      end
      return setmetatable({}, {__index = _0_, __newindex = _1_, __pairs = _2_})
    end
    local function current_global_names(env)
      return utils.kvmap((env or _G), compiler["global-unmangling"])
    end
    local function load_code(code, environment, filename)
      local environment0 = ((environment or _ENV) or _G)
      if (_G.setfenv and _G.loadstring) then
        local f = assert(_G.loadstring(code, filename))
        _G.setfenv(f, environment0)
        return f
      else
        return assert(load(code, filename, "t", environment0))
      end
    end
    local function doc_2a(tgt, name)
      if not tgt then
        return (name .. " not found")
      else
        local docstring = (((compiler.metadata):get(tgt, "fnl/docstring") or "#<undocumented>")):gsub("\n$", ""):gsub("\n", "\n  ")
        if (type(tgt) == "function") then
          local arglist = table.concat(((compiler.metadata):get(tgt, "fnl/arglist") or {"#<unknown-arguments>"}), " ")
          local _0_
          if (#arglist > 0) then
            _0_ = " "
          else
            _0_ = ""
          end
          return string.format("(%s%s%s)\n  %s", name, _0_, arglist, docstring)
        else
          return string.format("%s\n  %s", name, docstring)
        end
      end
    end
    local function doc_special(name, arglist, docstring)
      compiler.metadata[SPECIALS[name]] = {["fnl/arglist"] = arglist, ["fnl/docstring"] = docstring}
      return nil
    end
    local function compile_do(ast, scope, parent, start)
      local start0 = (start or 2)
      local len = #ast
      local sub_scope = compiler["make-scope"](scope)
      for i = start0, len do
        compiler.compile1(ast[i], sub_scope, parent, {nval = 0})
      end
      return nil
    end
    SPECIALS["do"] = function(ast, scope, parent, opts, start, chunk, sub_scope, pre_syms)
      local start0 = (start or 2)
      local sub_scope0 = (sub_scope or compiler["make-scope"](scope))
      local chunk0 = (chunk or {})
      local len = #ast
      local retexprs = {returned = true}
      local function compile_body(outer_target, outer_tail, outer_retexprs)
        if (len < start0) then
          compiler.compile1(nil, sub_scope0, chunk0, {tail = outer_tail, target = outer_target})
        else
          for i = start0, len do
            local subopts = {nval = (((i ~= len) and 0) or opts.nval), tail = (((i == len) and outer_tail) or nil), target = (((i == len) and outer_target) or nil)}
            local _ = utils["propagate-options"](opts, subopts)
            local subexprs = compiler.compile1(ast[i], sub_scope0, chunk0, subopts)
            if (i ~= len) then
              compiler["keep-side-effects"](subexprs, parent, nil, ast[i])
            end
          end
        end
        compiler.emit(parent, chunk0, ast)
        compiler.emit(parent, "end", ast)
        return (outer_retexprs or retexprs)
      end
      if (opts.target or (opts.nval == 0) or opts.tail) then
        compiler.emit(parent, "do", ast)
        return compile_body(opts.target, opts.tail)
      elseif opts.nval then
        local syms = {}
        for i = 1, opts.nval, 1 do
          local s = ((pre_syms and pre_syms[i]) or compiler.gensym(scope))
          syms[i] = s
          retexprs[i] = utils.expr(s, "sym")
        end
        local outer_target = table.concat(syms, ", ")
        compiler.emit(parent, string.format("local %s", outer_target), ast)
        compiler.emit(parent, "do", ast)
        return compile_body(outer_target, opts.tail)
      else
        local fname = compiler.gensym(scope)
        local fargs = nil
        if scope.vararg then
          fargs = "..."
        else
          fargs = ""
        end
        compiler.emit(parent, string.format("local function %s(%s)", fname, fargs), ast)
        return compile_body(nil, true, utils.expr((fname .. "(" .. fargs .. ")"), "statement"))
      end
    end
    doc_special("do", {"..."}, "Evaluate multiple forms; return last value.")
    SPECIALS.values = function(ast, scope, parent)
      local len = #ast
      local exprs = {}
      for i = 2, len do
        local subexprs = compiler.compile1(ast[i], scope, parent, {nval = ((i ~= len) and 1)})
        exprs[(#exprs + 1)] = subexprs[1]
        if (i == len) then
          for j = 2, #subexprs, 1 do
            exprs[(#exprs + 1)] = subexprs[j]
          end
        end
      end
      return exprs
    end
    doc_special("values", {"..."}, "Return multiple values from a function. Must be in tail position.")
    SPECIALS.fn = function(ast, scope, parent)
      local index, fn_name, is_local_fn, docstring = 2, utils["sym?"](ast[2])
      local f_scope = nil
      do
        local _0_0 = compiler["make-scope"](scope)
        _0_0["vararg"] = false
        f_scope = _0_0
      end
      local f_chunk = {}
      local multi = (fn_name and utils["multi-sym?"](fn_name[1]))
      compiler.assert((not multi or not multi["multi-sym-method-call"]), ("unexpected multi symbol " .. tostring(fn_name)), ast[index])
      if (fn_name and (fn_name[1] ~= "nil")) then
        is_local_fn = not multi
        if is_local_fn then
          fn_name = compiler["declare-local"](fn_name, {}, scope, ast)
        else
          fn_name = compiler["symbol-to-expression"](fn_name, scope)[1]
        end
        index = (index + 1)
      else
        is_local_fn = true
        fn_name = compiler.gensym(scope)
      end
      do
        local arg_list = nil
        local function _2_()
          if (type(ast[index]) == "table") then
            return ast[index]
          else
            return ast
          end
        end
        arg_list = compiler.assert(utils["table?"](ast[index]), "expected parameters", _2_())
        local function get_arg_name(i, name)
          if utils["varg?"](name) then
            compiler.assert((i == #arg_list), "expected vararg as last parameter", ast[2])
            f_scope.vararg = true
            return "..."
          elseif (utils["sym?"](name) and (utils.deref(name) ~= "nil") and not utils["multi-sym?"](utils.deref(name))) then
            return compiler["declare-local"](name, {}, f_scope, ast)
          elseif utils["table?"](name) then
            local raw = utils.sym(compiler.gensym(scope))
            local declared = compiler["declare-local"](raw, {}, f_scope, ast)
            compiler.destructure(name, raw, ast, f_scope, f_chunk, {declaration = true, nomulti = true})
            return declared
          else
            return compiler.assert(false, ("expected symbol for function parameter: %s"):format(tostring(name)), ast[2])
          end
        end
        local arg_name_list = utils.kvmap(arg_list, get_arg_name)
        if ((type(ast[(index + 1)]) == "string") and ((index + 1) < #ast)) then
          index = (index + 1)
          docstring = ast[index]
        end
        for i = (index + 1), #ast, 1 do
          compiler.compile1(ast[i], f_scope, f_chunk, {nval = (((i ~= #ast) and 0) or nil), tail = (i == #ast)})
        end
        if is_local_fn then
          compiler.emit(parent, ("local function %s(%s)"):format(fn_name, table.concat(arg_name_list, ", ")), ast)
        else
          compiler.emit(parent, ("%s = function(%s)"):format(fn_name, table.concat(arg_name_list, ", ")), ast)
        end
        compiler.emit(parent, f_chunk, ast)
        compiler.emit(parent, "end", ast)
        if utils.root.options.useMetadata then
          local args = nil
          local function _5_(v)
            if utils["table?"](v) then
              return "\"#<table>\""
            else
              return ("\"%s\""):format(tostring(v))
            end
          end
          args = utils.map(arg_list, _5_)
          local meta_fields = {"\"fnl/arglist\"", ("{" .. table.concat(args, ", ") .. "}")}
          if docstring then
            table.insert(meta_fields, "\"fnl/docstring\"")
            table.insert(meta_fields, ("\"" .. docstring:gsub("%s+$", ""):gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\"", "\\\"") .. "\""))
          end
          local meta_str = ("require(\"%s\").metadata"):format((utils.root.options.moduleName or "fennel"))
          compiler.emit(parent, ("pcall(function() %s:setall(%s, %s) end)"):format(meta_str, fn_name, table.concat(meta_fields, ", ")))
        end
      end
      return utils.expr(fn_name, "sym")
    end
    doc_special("fn", {"name?", "args", "docstring?", "..."}, "Function syntax. May optionally include a name and docstring.\nIf a name is provided, the function will be bound in the current scope.\nWhen called with the wrong number of args, excess args will be discarded\nand lacking args will be nil, use lambda for arity-checked functions.")
    SPECIALS.lua = function(ast, _, parent)
      compiler.assert(((#ast == 2) or (#ast == 3)), "expected 1 or 2 arguments", ast)
      if (ast[2] ~= nil) then
        table.insert(parent, {ast = ast, leaf = tostring(ast[2])})
      end
      if (#ast == 3) then
        return tostring(ast[3])
      end
    end
    SPECIALS.doc = function(ast, scope, parent)
      assert(utils.root.options.useMetadata, "can't look up doc with metadata disabled.")
      compiler.assert((#ast == 2), "expected one argument", ast)
      local target = utils.deref(ast[2])
      local special_or_macro = (scope.specials[target] or scope.macros[target])
      if special_or_macro then
        return ("print([[%s]])"):format(doc_2a(special_or_macro, target))
      else
        local value = tostring(compiler.compile1(ast[2], scope, parent, {nval = 1})[1])
        return ("print(require('%s').doc(%s, '%s'))"):format((utils.root.options.moduleName or "fennel"), value, tostring(ast[2]))
      end
    end
    doc_special("doc", {"x"}, "Print the docstring and arglist for a function, macro, or special form.")
    local function dot(ast, scope, parent)
      compiler.assert((1 < #ast), "expected table argument", ast)
      local len = #ast
      local lhs = compiler.compile1(ast[2], scope, parent, {nval = 1})
      if (len == 2) then
        return tostring(lhs[1])
      else
        local indices = {}
        for i = 3, len, 1 do
          local index = ast[i]
          if ((type(index) == "string") and utils["valid-lua-identifier?"](index)) then
            table.insert(indices, ("." .. index))
          else
            local _0_ = compiler.compile1(index, scope, parent, {nval = 1})
            local index0 = _0_[1]
            table.insert(indices, ("[" .. tostring(index0) .. "]"))
          end
        end
        if utils["table?"](ast[2]) then
          return ("(" .. tostring(lhs[1]) .. ")" .. table.concat(indices))
        else
          return (tostring(lhs[1]) .. table.concat(indices))
        end
      end
    end
    SPECIALS["."] = dot
    doc_special(".", {"tbl", "key1", "..."}, "Look up key1 in tbl table. If more args are provided, do a nested lookup.")
    SPECIALS.global = function(ast, scope, parent)
      compiler.assert((#ast == 3), "expected name and value", ast)
      compiler.destructure(ast[2], ast[3], ast, scope, parent, {forceglobal = true, nomulti = true})
      return nil
    end
    doc_special("global", {"name", "val"}, "Set name as a global with val.")
    SPECIALS.set = function(ast, scope, parent)
      compiler.assert((#ast == 3), "expected name and value", ast)
      compiler.destructure(ast[2], ast[3], ast, scope, parent, {noundef = true})
      return nil
    end
    doc_special("set", {"name", "val"}, "Set a local variable to a new value. Only works on locals using var.")
    local function set_forcibly_21_2a(ast, scope, parent)
      compiler.assert((#ast == 3), "expected name and value", ast)
      compiler.destructure(ast[2], ast[3], ast, scope, parent, {forceset = true})
      return nil
    end
    SPECIALS["set-forcibly!"] = set_forcibly_21_2a
    local function local_2a(ast, scope, parent)
      compiler.assert((#ast == 3), "expected name and value", ast)
      compiler.destructure(ast[2], ast[3], ast, scope, parent, {declaration = true, nomulti = true})
      return nil
    end
    SPECIALS["local"] = local_2a
    doc_special("local", {"name", "val"}, "Introduce new top-level immutable local.")
    SPECIALS.var = function(ast, scope, parent)
      compiler.assert((#ast == 3), "expected name and value", ast)
      compiler.destructure(ast[2], ast[3], ast, scope, parent, {declaration = true, isvar = true, nomulti = true})
      return nil
    end
    doc_special("var", {"name", "val"}, "Introduce new mutable local.")
    SPECIALS.let = function(ast, scope, parent, opts)
      local bindings = ast[2]
      local pre_syms = {}
      compiler.assert((utils["list?"](bindings) or utils["table?"](bindings)), "expected binding table", ast)
      compiler.assert(((#bindings % 2) == 0), "expected even number of name/value bindings", ast[2])
      compiler.assert((#ast >= 3), "expected body expression", ast[1])
      for _ = 1, (opts.nval or 0), 1 do
        table.insert(pre_syms, compiler.gensym(scope))
      end
      local sub_scope = compiler["make-scope"](scope)
      local sub_chunk = {}
      for i = 1, #bindings, 2 do
        compiler.destructure(bindings[i], bindings[(i + 1)], ast, sub_scope, sub_chunk, {declaration = true, nomulti = true})
      end
      return SPECIALS["do"](ast, scope, parent, opts, 3, sub_chunk, sub_scope, pre_syms)
    end
    doc_special("let", {"[name1 val1 ... nameN valN]", "..."}, "Introduces a new scope in which a given set of local bindings are used.")
    SPECIALS.tset = function(ast, scope, parent)
      compiler.assert((#ast > 3), "expected table, key, and value arguments", ast)
      local root = compiler.compile1(ast[2], scope, parent, {nval = 1})[1]
      local keys = {}
      for i = 3, (#ast - 1), 1 do
        local key = compiler.compile1(ast[i], scope, parent, {nval = 1})[1]
        keys[(#keys + 1)] = tostring(key)
      end
      local value = compiler.compile1(ast[#ast], scope, parent, {nval = 1})[1]
      local rootstr = tostring(root)
      local fmtstr = nil
      if rootstr:match("^{") then
        fmtstr = "do end (%s)[%s] = %s"
      else
        fmtstr = "%s[%s] = %s"
      end
      return compiler.emit(parent, fmtstr:format(tostring(root), table.concat(keys, "]["), tostring(value)), ast)
    end
    doc_special("tset", {"tbl", "key1", "...", "keyN", "val"}, "Set the value of a table field. Can take additional keys to set\nnested values, but all parents must contain an existing table.")
    local function if_2a(ast, scope, parent, opts)
      local do_scope = compiler["make-scope"](scope)
      local branches = {}
      local has_else = ((#ast > 3) and ((#ast % 2) == 0))
      local else_branch = nil
      local wrapper, inner_tail, inner_target, target_exprs = nil
      if (opts.tail or opts.target or opts.nval) then
        if (opts.nval and (opts.nval ~= 0) and not opts.target) then
          local accum = {}
          target_exprs = {}
          for i = 1, opts.nval, 1 do
            local s = compiler.gensym(scope)
            accum[i] = s
            target_exprs[i] = utils.expr(s, "sym")
          end
          wrapper, inner_tail, inner_target = "target", opts.tail, table.concat(accum, ", ")
        else
          wrapper, inner_tail, inner_target = "none", opts.tail, opts.target
        end
      else
        wrapper, inner_tail, inner_target = "iife", true, nil
      end
      local body_opts = {nval = opts.nval, tail = inner_tail, target = inner_target}
      local function compile_body(i)
        local chunk = {}
        local cscope = compiler["make-scope"](do_scope)
        compiler["keep-side-effects"](compiler.compile1(ast[i], cscope, chunk, body_opts), chunk, nil, ast[i])
        return {chunk = chunk, scope = cscope}
      end
      for i = 2, (#ast - 1), 2 do
        local condchunk = {}
        local res = compiler.compile1(ast[i], do_scope, condchunk, {nval = 1})
        local cond = res[1]
        local branch = compile_body((i + 1))
        branch.cond = cond
        branch.condchunk = condchunk
        branch.nested = ((i ~= 2) and (next(condchunk, nil) == nil))
        table.insert(branches, branch)
      end
      if has_else then
        else_branch = compile_body(#ast)
      end
      local s = compiler.gensym(scope)
      local buffer = {}
      local last_buffer = buffer
      for i = 1, #branches do
        local branch = branches[i]
        local fstr = nil
        if not branch.nested then
          fstr = "if %s then"
        else
          fstr = "elseif %s then"
        end
        local cond = tostring(branch.cond)
        local cond_line = nil
        if ((cond == "true") and branch.nested and (i == #branches)) then
          cond_line = "else"
        else
          cond_line = fstr:format(cond)
        end
        if branch.nested then
          compiler.emit(last_buffer, branch.condchunk, ast)
        else
          for _, v in ipairs(branch.condchunk) do
            compiler.emit(last_buffer, v, ast)
          end
        end
        compiler.emit(last_buffer, cond_line, ast)
        compiler.emit(last_buffer, branch.chunk, ast)
        if (i == #branches) then
          if has_else then
            compiler.emit(last_buffer, "else", ast)
            compiler.emit(last_buffer, else_branch.chunk, ast)
          elseif (inner_target and (cond_line ~= "else")) then
            compiler.emit(last_buffer, "else", ast)
            compiler.emit(last_buffer, ("%s = nil"):format(inner_target), ast)
          end
          compiler.emit(last_buffer, "end", ast)
        elseif not branches[(i + 1)].nested then
          local next_buffer = {}
          compiler.emit(last_buffer, "else", ast)
          compiler.emit(last_buffer, next_buffer, ast)
          compiler.emit(last_buffer, "end", ast)
          last_buffer = next_buffer
        end
      end
      if (wrapper == "iife") then
        local iifeargs = ((scope.vararg and "...") or "")
        compiler.emit(parent, ("local function %s(%s)"):format(tostring(s), iifeargs), ast)
        compiler.emit(parent, buffer, ast)
        compiler.emit(parent, "end", ast)
        return utils.expr(("%s(%s)"):format(tostring(s), iifeargs), "statement")
      elseif (wrapper == "none") then
        for i = 1, #buffer, 1 do
          compiler.emit(parent, buffer[i], ast)
        end
        return {returned = true}
      else
        compiler.emit(parent, ("local %s"):format(inner_target), ast)
        for i = 1, #buffer, 1 do
          compiler.emit(parent, buffer[i], ast)
        end
        return target_exprs
      end
    end
    SPECIALS["if"] = if_2a
    doc_special("if", {"cond1", "body1", "...", "condN", "bodyN"}, "Conditional form.\nTakes any number of condition/body pairs and evaluates the first body where\nthe condition evaluates to truthy. Similar to cond in other lisps.")
    SPECIALS.each = function(ast, scope, parent)
      compiler.assert((#ast >= 3), "expected body expression", ast[1])
      local binding = compiler.assert(utils["table?"](ast[2]), "expected binding table", ast)
      local iter = table.remove(binding, #binding)
      local destructures = {}
      local new_manglings = {}
      local sub_scope = compiler["make-scope"](scope)
      local function destructure_binding(v)
        if utils["sym?"](v) then
          return compiler["declare-local"](v, {}, sub_scope, ast, new_manglings)
        else
          local raw = utils.sym(compiler.gensym(sub_scope))
          destructures[raw] = v
          return compiler["declare-local"](raw, {}, sub_scope, ast)
        end
      end
      local bind_vars = utils.map(binding, destructure_binding)
      local vals = compiler.compile1(iter, sub_scope, parent)
      local val_names = utils.map(vals, tostring)
      local chunk = {}
      compiler.emit(parent, ("for %s in %s do"):format(table.concat(bind_vars, ", "), table.concat(val_names, ", ")), ast)
      for raw, args in utils.stablepairs(destructures) do
        compiler.destructure(args, raw, ast, sub_scope, chunk, {declaration = true, nomulti = true})
      end
      compiler["apply-manglings"](sub_scope, new_manglings, ast)
      compile_do(ast, sub_scope, chunk, 3)
      compiler.emit(parent, chunk, ast)
      return compiler.emit(parent, "end", ast)
    end
    doc_special("each", {"[key value (iterator)]", "..."}, "Runs the body once for each set of values provided by the given iterator.\nMost commonly used with ipairs for sequential tables or pairs for  undefined\norder, but can be used with any iterator.")
    local function while_2a(ast, scope, parent)
      local len1 = #parent
      local condition = compiler.compile1(ast[2], scope, parent, {nval = 1})[1]
      local len2 = #parent
      local sub_chunk = {}
      if (len1 ~= len2) then
        for i = (len1 + 1), len2, 1 do
          sub_chunk[(#sub_chunk + 1)] = parent[i]
          parent[i] = nil
        end
        compiler.emit(parent, "while true do", ast)
        compiler.emit(sub_chunk, ("if not %s then break end"):format(condition[1]), ast)
      else
        compiler.emit(parent, ("while " .. tostring(condition) .. " do"), ast)
      end
      compile_do(ast, compiler["make-scope"](scope), sub_chunk, 3)
      compiler.emit(parent, sub_chunk, ast)
      return compiler.emit(parent, "end", ast)
    end
    SPECIALS["while"] = while_2a
    doc_special("while", {"condition", "..."}, "The classic while loop. Evaluates body until a condition is non-truthy.")
    local function for_2a(ast, scope, parent)
      local ranges = compiler.assert(utils["table?"](ast[2]), "expected binding table", ast)
      local binding_sym = table.remove(ast[2], 1)
      local sub_scope = compiler["make-scope"](scope)
      local range_args = {}
      local chunk = {}
      compiler.assert(utils["sym?"](binding_sym), ("unable to bind %s %s"):format(type(binding_sym), tostring(binding_sym)), ast[2])
      compiler.assert((#ast >= 3), "expected body expression", ast[1])
      for i = 1, math.min(#ranges, 3), 1 do
        range_args[i] = tostring(compiler.compile1(ranges[i], sub_scope, parent, {nval = 1})[1])
      end
      compiler.emit(parent, ("for %s = %s do"):format(compiler["declare-local"](binding_sym, {}, sub_scope, ast), table.concat(range_args, ", ")), ast)
      compile_do(ast, sub_scope, chunk, 3)
      compiler.emit(parent, chunk, ast)
      return compiler.emit(parent, "end", ast)
    end
    SPECIALS["for"] = for_2a
    doc_special("for", {"[index start stop step?]", "..."}, "Numeric loop construct.\nEvaluates body once for each value between start and stop (inclusive).")
    local function native_method_call(ast, scope, parent, target, args)
      local _0_ = ast
      local _ = _0_[1]
      local _0 = _0_[2]
      local method_string = _0_[3]
      local call_string = nil
      if ((target.type == "literal") or (target.type == "expression")) then
        call_string = "(%s):%s(%s)"
      else
        call_string = "%s:%s(%s)"
      end
      return utils.expr(string.format(call_string, tostring(target), method_string, table.concat(args, ", ")), "statement")
    end
    local function nonnative_method_call(ast, scope, parent, target, args)
      local method_string = tostring(compiler.compile1(ast[3], scope, parent, {nval = 1})[1])
      table.insert(args, tostring(target))
      return utils.expr(string.format("%s[%s](%s)", tostring(target), method_string, tostring(target), table.concat(args, ", ")), "statement")
    end
    local function double_eval_protected_method_call(ast, scope, parent, target, args)
      local method_string = tostring(compiler.compile1(ast[3], scope, parent, {nval = 1})[1])
      local call = "(function(tgt, m, ...) return tgt[m](tgt, ...) end)(%s, %s)"
      table.insert(args, method_string)
      return utils.expr(string.format(call, tostring(target), table.concat(args, ", ")), "statement")
    end
    local function method_call(ast, scope, parent)
      compiler.assert((2 < #ast), "expected at least 2 arguments", ast)
      local _0_ = compiler.compile1(ast[2], scope, parent, {nval = 1})
      local target = _0_[1]
      local args = {}
      for i = 4, #ast do
        local subexprs = nil
        local _1_
        if (i ~= #ast) then
          _1_ = 1
        else
        _1_ = nil
        end
        subexprs = compiler.compile1(ast[i], scope, parent, {nval = _1_})
        utils.map(subexprs, tostring, args)
      end
      if ((type(ast[3]) == "string") and utils["valid-lua-identifier?"](ast[3])) then
        return native_method_call(ast, scope, parent, target, args)
      elseif (target.type == "sym") then
        return nonnative_method_call(ast, scope, parent, target, args)
      else
        return double_eval_protected_method_call(ast, scope, parent, target, args)
      end
    end
    SPECIALS[":"] = method_call
    doc_special(":", {"tbl", "method-name", "..."}, "Call the named method on tbl with the provided args.\nMethod name doesn't have to be known at compile-time; if it is, use\n(tbl:method-name ...) instead.")
    SPECIALS.comment = function(ast, _, parent)
      local els = {}
      for i = 2, #ast, 1 do
        els[(#els + 1)] = tostring(ast[i]):gsub("\n", " ")
      end
      return compiler.emit(parent, ("-- " .. table.concat(els, " ")), ast)
    end
    doc_special("comment", {"..."}, "Comment which will be emitted in Lua output.")
    local function hashfn_max_used(f_scope, i, max)
      local max0 = nil
      if f_scope.symmeta[("$" .. i)].used then
        max0 = i
      else
        max0 = max
      end
      if (i < 9) then
        return hashfn_max_used(f_scope, (i + 1), max0)
      else
        return max0
      end
    end
    SPECIALS.hashfn = function(ast, scope, parent)
      compiler.assert((#ast == 2), "expected one argument", ast)
      local f_scope = nil
      do
        local _0_0 = compiler["make-scope"](scope)
        _0_0["vararg"] = false
        _0_0["hashfn"] = true
        f_scope = _0_0
      end
      local f_chunk = {}
      local name = compiler.gensym(scope)
      local symbol = utils.sym(name)
      local args = {}
      compiler["declare-local"](symbol, {}, scope, ast)
      for i = 1, 9 do
        args[i] = compiler["declare-local"](utils.sym(("$" .. i)), {}, f_scope, ast)
      end
      local function walker(idx, node, parent_node)
        if (utils["sym?"](node) and (utils.deref(node) == "$...")) then
          parent_node[idx] = utils.varg()
          f_scope.vararg = true
          return nil
        else
          return (utils["list?"](node) or utils["table?"](node))
        end
      end
      utils["walk-tree"](ast[2], walker)
      compiler.compile1(ast[2], f_scope, f_chunk, {tail = true})
      local max_used = hashfn_max_used(f_scope, 1, 0)
      if f_scope.vararg then
        compiler.assert((max_used == 0), "$ and $... in hashfn are mutually exclusive", ast)
      end
      local arg_str = nil
      if f_scope.vararg then
        arg_str = utils.deref(utils.varg())
      else
        arg_str = table.concat(args, ", ", 1, max_used)
      end
      compiler.emit(parent, string.format("local function %s(%s)", name, arg_str), ast)
      compiler.emit(parent, f_chunk, ast)
      compiler.emit(parent, "end", ast)
      return utils.expr(name, "sym")
    end
    doc_special("hashfn", {"..."}, "Function literal shorthand; args are either $... OR $1, $2, etc.")
    local function define_arithmetic_special(name, zero_arity, unary_prefix, lua_name)
      do
        local padded_op = (" " .. (lua_name or name) .. " ")
        local function _0_(ast, scope, parent)
          local len = #ast
          if (len == 1) then
            compiler.assert((zero_arity ~= nil), "Expected more than 0 arguments", ast)
            return utils.expr(zero_arity, "literal")
          else
            local operands = {}
            for i = 2, len, 1 do
              local subexprs = nil
              local _1_
              if (i == 1) then
                _1_ = 1
              else
              _1_ = nil
              end
              subexprs = compiler.compile1(ast[i], scope, parent, {nval = _1_})
              utils.map(subexprs, tostring, operands)
            end
            if (#operands == 1) then
              if unary_prefix then
                return ("(" .. unary_prefix .. padded_op .. operands[1] .. ")")
              else
                return operands[1]
              end
            else
              return ("(" .. table.concat(operands, padded_op) .. ")")
            end
          end
        end
        SPECIALS[name] = _0_
      end
      return doc_special(name, {"a", "b", "..."}, "Arithmetic operator; works the same as Lua but accepts more arguments.")
    end
    define_arithmetic_special("+", "0")
    define_arithmetic_special("..", "''")
    define_arithmetic_special("^")
    define_arithmetic_special("-", nil, "")
    define_arithmetic_special("*", "1")
    define_arithmetic_special("%")
    define_arithmetic_special("/", nil, "1")
    define_arithmetic_special("//", nil, "1")
    define_arithmetic_special("lshift", nil, "1", "<<")
    define_arithmetic_special("rshift", nil, "1", ">>")
    define_arithmetic_special("band", "0", "0", "&")
    define_arithmetic_special("bor", "0", "0", "|")
    define_arithmetic_special("bxor", "0", "0", "~")
    doc_special("lshift", {"x", "n"}, "Bitwise logical left shift of x by n bits; only works in Lua 5.3+.")
    doc_special("rshift", {"x", "n"}, "Bitwise logical right shift of x by n bits; only works in Lua 5.3+.")
    doc_special("band", {"x1", "x2"}, "Bitwise AND of arguments; only works in Lua 5.3+.")
    doc_special("bor", {"x1", "x2"}, "Bitwise OR of arguments; only works in Lua 5.3+.")
    doc_special("bxor", {"x1", "x2"}, "Bitwise XOR of arguments; only works in Lua 5.3+.")
    define_arithmetic_special("or", "false")
    define_arithmetic_special("and", "true")
    doc_special("and", {"a", "b", "..."}, "Boolean operator; works the same as Lua but accepts more arguments.")
    doc_special("or", {"a", "b", "..."}, "Boolean operator; works the same as Lua but accepts more arguments.")
    doc_special("..", {"a", "b", "..."}, "String concatenation operator; works the same as Lua but accepts more arguments.")
    local function native_comparator(op, _0_0, scope, parent)
      local _1_ = _0_0
      local _ = _1_[1]
      local lhs_ast = _1_[2]
      local rhs_ast = _1_[3]
      local _2_ = compiler.compile1(lhs_ast, scope, parent, {nval = 1})
      local lhs = _2_[1]
      local _3_ = compiler.compile1(rhs_ast, scope, parent, {nval = 1})
      local rhs = _3_[1]
      return string.format("(%s %s %s)", tostring(lhs), op, tostring(rhs))
    end
    local function double_eval_protected_comparator(op, chain_op, ast, scope, parent)
      local arglist = {}
      local comparisons = {}
      local vals = {}
      local chain = string.format(" %s ", (chain_op or "and"))
      for i = 2, #ast do
        table.insert(arglist, tostring(compiler.gensym(scope)))
        table.insert(vals, tostring(compiler.compile1(ast[i], scope, parent, {nval = 1})[1]))
      end
      for i = 1, (#arglist - 1) do
        table.insert(comparisons, string.format("(%s %s %s)", arglist[i], op, arglist[(i + 1)]))
      end
      return string.format("(function(%s) return %s end)(%s)", table.concat(arglist, ","), table.concat(comparisons, chain), table.concat(vals, ","))
    end
    local function define_comparator_special(name, lua_op, chain_op)
      do
        local op = (lua_op or name)
        local function opfn(ast, scope, parent)
          compiler.assert((2 < #ast), "expected at least two arguments", ast)
          if (3 == #ast) then
            return native_comparator(op, ast, scope, parent)
          else
            return double_eval_protected_comparator(op, chain_op, ast, scope, parent)
          end
        end
        SPECIALS[name] = opfn
      end
      return doc_special(name, {"a", "b", "..."}, "Comparison operator; works the same as Lua but accepts more arguments.")
    end
    define_comparator_special(">")
    define_comparator_special("<")
    define_comparator_special(">=")
    define_comparator_special("<=")
    define_comparator_special("=", "==")
    define_comparator_special("not=", "~=", "or")
    SPECIALS["~="] = SPECIALS["not="]
    local function define_unary_special(op, realop)
      local function opfn(ast, scope, parent)
        compiler.assert((#ast == 2), "expected one argument", ast)
        local tail = compiler.compile1(ast[2], scope, parent, {nval = 1})
        return ((realop or op) .. tostring(tail[1]))
      end
      SPECIALS[op] = opfn
      return nil
    end
    define_unary_special("not", "not ")
    doc_special("not", {"x"}, "Logical operator; works the same as Lua.")
    define_unary_special("bnot", "~")
    doc_special("bnot", {"x"}, "Bitwise negation; only works in Lua 5.3+.")
    define_unary_special("length", "#")
    doc_special("length", {"x"}, "Returns the length of a table or string.")
    SPECIALS["#"] = SPECIALS.length
    SPECIALS.quote = function(ast, scope, parent)
      compiler.assert((#ast == 2), "expected one argument")
      local runtime, this_scope = true, scope
      while this_scope do
        this_scope = this_scope.parent
        if (this_scope == compiler.scopes.compiler) then
          runtime = false
        end
      end
      return compiler["do-quote"](ast[2], scope, parent, runtime)
    end
    doc_special("quote", {"x"}, "Quasiquote the following form. Only works in macro/compiler scope.")
    local function make_compiler_env(ast, scope, parent)
      local function _1_()
        return compiler.scopes.macro
      end
      local function _2_(symbol)
        compiler.assert(compiler.scopes.macro, "must call from macro", ast)
        return compiler.scopes.macro.manglings[tostring(symbol)]
      end
      local function _3_()
        return utils.sym(compiler.gensym((compiler.scopes.macro or scope)))
      end
      local function _4_(form)
        compiler.assert(compiler.scopes.macro, "must call from macro", ast)
        return compiler.macroexpand(form, compiler.scopes.macro)
      end
      return setmetatable({["get-scope"] = _1_, ["in-scope?"] = _2_, ["list?"] = utils["list?"], ["multi-sym?"] = utils["multi-sym?"], ["sequence?"] = utils["sequence?"], ["sym?"] = utils["sym?"], ["table?"] = utils["table?"], ["varg?"] = utils["varg?"], _AST = ast, _CHUNK = parent, _IS_COMPILER = true, _SCOPE = scope, _SPECIALS = compiler.scopes.global.specials, _VARARG = utils.varg(), fennel = utils["fennel-module"], gensym = _3_, list = utils.list, macroexpand = _4_, sequence = utils.sequence, sym = utils.sym, unpack = unpack}, {__index = (_ENV or _G)})
    end
    local cfg = string.gmatch(package.config, "([^\n]+)")
    local dirsep, pathsep, pathmark = (cfg() or "/"), (cfg() or ";"), (cfg() or "?")
    local pkg_config = {dirsep = dirsep, pathmark = pathmark, pathsep = pathsep}
    local function escapepat(str)
      return string.gsub(str, "[^%w]", "%%%1")
    end
    local function search_module(modulename, pathstring)
      local pathsepesc = escapepat(pkg_config.pathsep)
      local pattern = ("([^%s]*)%s"):format(pathsepesc, pathsepesc)
      local no_dot_module = modulename:gsub("%.", pkg_config.dirsep)
      local fullpath = ((pathstring or utils["fennel-module"].path) .. pkg_config.pathsep)
      local function try_path(path)
        local filename = path:gsub(escapepat(pkg_config.pathmark), no_dot_module)
        local filename2 = path:gsub(escapepat(pkg_config.pathmark), modulename)
        local _1_0 = (io.open(filename) or io.open(filename2))
        if (nil ~= _1_0) then
          local file = _1_0
          file:close()
          return filename
        end
      end
      local function find_in_path(start)
        local _1_0 = fullpath:match(pattern, start)
        if (nil ~= _1_0) then
          local path = _1_0
          return (try_path(path) or find_in_path((start + #path + 1)))
        end
      end
      return find_in_path(1)
    end
    local function make_searcher(options)
      local opts = utils.copy(utils.root.options)
      for k, v in pairs((options or {})) do
        opts[k] = v
      end
      local function _1_(module_name)
        local filename = search_module(module_name)
        if filename then
          local function _2_(mod_name)
            return utils["fennel-module"].dofile(filename, opts, mod_name)
          end
          return _2_
        end
      end
      return _1_
    end
    local function macro_globals(env, globals)
      local allowed = current_global_names(env)
      for _, k in pairs((globals or {})) do
        table.insert(allowed, k)
      end
      return allowed
    end
    local function add_macros(macros_2a, ast, scope)
      compiler.assert(utils["table?"](macros_2a), "expected macros to be table", ast)
      for k, v in pairs(macros_2a) do
        compiler.assert((type(v) == "function"), "expected each macro to be function", ast)
        scope.macros[k] = v
      end
      return nil
    end
    local function load_macros(modname, ast, scope, parent)
      local filename = compiler.assert(search_module(modname), (modname .. " module not found."), ast)
      local env = make_compiler_env(ast, scope, parent)
      local globals = macro_globals(env, current_global_names())
      return utils["fennel-module"].dofile(filename, {allowedGlobals = globals, env = env, scope = compiler.scopes.compiler, useMetadata = utils.root.options.useMetadata})
    end
    local macro_loaded = {}
    SPECIALS["require-macros"] = function(ast, scope, parent)
      compiler.assert((#ast == 2), "Expected one module name argument", ast)
      local modname = ast[2]
      if not macro_loaded[modname] then
        macro_loaded[modname] = load_macros(modname, ast, scope, parent)
      end
      return add_macros(macro_loaded[modname], ast, scope, parent)
    end
    doc_special("require-macros", {"macro-module-name"}, "Load given module and use its contents as macro definitions in current scope.\nMacro module should return a table of macro functions with string keys.\nConsider using import-macros instead as it is more flexible.")
    local function emit_fennel(src, path, opts, sub_chunk)
      local subscope = compiler["make-scope"](utils.root.scope.parent)
      local forms = {}
      if utils.root.options.requireAsInclude then
        subscope.specials.require = compiler["require-include"]
      end
      for _, val in parser.parser(parser["string-stream"](src), path) do
        table.insert(forms, val)
      end
      for i = 1, #forms do
        local subopts = nil
        if (i == #forms) then
          subopts = {nval = 1, tail = true}
        else
          subopts = {nval = 0}
        end
        utils["propagate-options"](opts, subopts)
        compiler.compile1(forms[i], subscope, sub_chunk, subopts)
      end
      return nil
    end
    local function include_path(ast, opts, path, mod, fennel_3f)
      utils.root.scope.includes[mod] = "fnl/loading"
      local src = nil
      do
        local f = assert(io.open(path))
        local function close_handlers_0_(ok_0_, ...)
          f:close()
          if ok_0_ then
            return ...
          else
            return error(..., 0)
          end
        end
        local function _1_()
          return f:read("*all"):gsub("[\13\n]*$", "")
        end
        src = close_handlers_0_(xpcall(_1_, (package.loaded.fennel or debug).traceback))
      end
      local ret = utils.expr(("require(\"" .. mod .. "\")"), "statement")
      local target = ("package.preload[%q]"):format(mod)
      local preload_str = (target .. " = " .. target .. " or function(...)")
      local temp_chunk, sub_chunk = {}, {}
      compiler.emit(temp_chunk, preload_str, ast)
      compiler.emit(temp_chunk, sub_chunk)
      compiler.emit(temp_chunk, "end", ast)
      for i, v in ipairs(temp_chunk) do
        table.insert(utils.root.chunk, i, v)
      end
      if fennel_3f then
        emit_fennel(src, path, opts, sub_chunk)
      else
        compiler.emit(sub_chunk, src, ast)
      end
      utils.root.scope.includes[mod] = ret
      return ret
    end
    local function include_circular_fallback(mod, modexpr, fallback, ast)
      if (utils.root.scope.includes[mod] == "fnl/loading") then
        compiler.assert(fallback, "circular include detected", ast)
        return fallback(modexpr)
      end
    end
    SPECIALS.include = function(ast, scope, parent, opts)
      compiler.assert((#ast == 2), "expected one argument", ast)
      local modexpr = compiler.compile1(ast[2], scope, parent, {nval = 1})[1]
      if ((modexpr.type ~= "literal") or ((modexpr[1]):byte() ~= 34)) then
        if opts.fallback then
          return opts.fallback(modexpr)
        else
          return compiler.assert(false, "module name must be string literal", ast)
        end
      else
        local mod = load_code(("return " .. modexpr[1]))()
        local function _2_()
          local _1_0 = search_module(mod)
          if (nil ~= _1_0) then
            local fennel_path = _1_0
            return include_path(ast, opts, fennel_path, mod, true)
          else
            local _ = _1_0
            local lua_path = search_module(mod, package.path)
            if lua_path then
              return include_path(ast, opts, lua_path, mod, false)
            elseif opts.fallback then
              return opts.fallback(modexpr)
            else
              return compiler.assert(false, ("module not found " .. mod), ast)
            end
          end
        end
        return (include_circular_fallback(mod, modexpr, opts.fallback, ast) or utils.root.scope.includes[mod] or _2_())
      end
    end
    doc_special("include", {"module-name-literal"}, "Like require but load the target module during compilation and embed it in the\nLua output. The module must be a string literal and resolvable at compile time.")
    local function eval_compiler_2a(ast, scope, parent)
      local scope0 = compiler["make-scope"](compiler.scopes.compiler)
      local luasrc = compiler.compile(ast, {scope = scope0, useMetadata = utils.root.options.useMetadata})
      local loader = load_code(luasrc, wrap_env(make_compiler_env(ast, scope0, parent)))
      return loader()
    end
    SPECIALS.macros = function(ast, scope, parent)
      compiler.assert((#ast == 2), "Expected one table argument", ast)
      return add_macros(eval_compiler_2a(ast[2], scope, parent), ast, scope, parent)
    end
    doc_special("macros", {"{:macro-name-1 (fn [...] ...) ... :macro-name-N macro-body-N}"}, "Define all functions in the given table as macros local to the current scope.")
    SPECIALS["eval-compiler"] = function(ast, scope, parent)
      local old_first = ast[1]
      ast[1] = utils.sym("do")
      local val = eval_compiler_2a(ast, scope, parent)
      ast[1] = old_first
      return val
    end
    doc_special("eval-compiler", {"..."}, "Evaluate the body at compile-time. Use the macro system instead if possible.")
    return {["current-global-names"] = current_global_names, ["load-code"] = load_code, ["macro-loaded"] = macro_loaded, ["make-compiler-env"] = make_compiler_env, ["make-searcher"] = make_searcher, ["search-module"] = search_module, ["wrap-env"] = wrap_env, doc = doc_2a}
  end
  package.preload["fennel.compiler"] = package.preload["fennel.compiler"] or function(...)
    local utils = require("fennel.utils")
    local parser = require("fennel.parser")
    local friend = require("fennel.friend")
    local unpack = (_G.unpack or table.unpack)
    local scopes = {}
    local function make_scope(parent)
      local parent0 = (parent or scopes.global)
      local _0_
      if parent0 then
        _0_ = ((parent0.depth or 0) + 1)
      else
        _0_ = 0
      end
      return {autogensyms = {}, depth = _0_, hashfn = (parent0 and parent0.hashfn), includes = setmetatable({}, {__index = (parent0 and parent0.includes)}), macros = setmetatable({}, {__index = (parent0 and parent0.macros)}), manglings = setmetatable({}, {__index = (parent0 and parent0.manglings)}), parent = parent0, refedglobals = setmetatable({}, {__index = (parent0 and parent0.refedglobals)}), specials = setmetatable({}, {__index = (parent0 and parent0.specials)}), symmeta = setmetatable({}, {__index = (parent0 and parent0.symmeta)}), unmanglings = setmetatable({}, {__index = (parent0 and parent0.unmanglings)}), vararg = (parent0 and parent0.vararg)}
    end
    local function assert_compile(condition, msg, ast)
      if not condition then
        local _0_ = (utils.root.options or {})
        local source = _0_["source"]
        local unfriendly = _0_["unfriendly"]
        utils.root.reset()
        if unfriendly then
          local m = getmetatable(ast)
          local filename = ((m and m.filename) or ast.filename or "unknown")
          local line = ((m and m.line) or ast.line or "?")
          local target = nil
          local function _1_()
            if utils["sym?"](ast[1]) then
              return utils.deref(ast[1])
            else
              return (ast[1] or "()")
            end
          end
          target = tostring(_1_())
          error(string.format("Compile error in '%s' %s:%s: %s", target, filename, line, msg), 0)
        else
          friend["assert-compile"](condition, msg, ast, source)
        end
      end
      return condition
    end
    scopes.global = make_scope()
    scopes.global.vararg = true
    scopes.compiler = make_scope(scopes.global)
    scopes.macro = scopes.global
    local serialize_subst = {["\11"] = "\\v", ["\12"] = "\\f", ["\7"] = "\\a", ["\8"] = "\\b", ["\9"] = "\\t", ["\n"] = "n"}
    local function serialize_string(str)
      local function _0_(_241)
        return ("\\" .. _241:byte())
      end
      return string.gsub(string.gsub(string.format("%q", str), ".", serialize_subst), "[\128-\255]", _0_)
    end
    local function global_mangling(str)
      if utils["valid-lua-identifier?"](str) then
        return str
      else
        local function _0_(_241)
          return string.format("_%02x", _241:byte())
        end
        return ("__fnl_global__" .. str:gsub("[^%w]", _0_))
      end
    end
    local function global_unmangling(identifier)
      local _0_0 = string.match(identifier, "^__fnl_global__(.*)$")
      if (nil ~= _0_0) then
        local rest = _0_0
        local _1_0 = nil
        local function _2_(_241)
          return string.char(tonumber(_241:sub(2), 16))
        end
        _1_0 = string.gsub(rest, "_[%da-f][%da-f]", _2_)
        return _1_0
      else
        local _ = _0_0
        return identifier
      end
    end
    local allowed_globals = nil
    local function global_allowed(name)
      local found_3f = not allowed_globals
      if not allowed_globals then
        return true
      else
        return utils["member?"](name, allowed_globals)
      end
    end
    local function unique_mangling(original, mangling, scope, append)
      if scope.unmanglings[mangling] then
        return unique_mangling(original, (original .. append), scope, (append + 1))
      else
        return mangling
      end
    end
    local function local_mangling(str, scope, ast, temp_manglings)
      assert_compile(not utils["multi-sym?"](str), ("unexpected multi symbol " .. str), ast)
      local append = 0
      local raw = nil
      if (utils["lua-keywords"][str] or str:match("^%d")) then
        raw = ("_" .. str)
      else
        raw = str
      end
      local mangling = nil
      local function _1_(_241)
        return string.format("_%02x", _241:byte())
      end
      mangling = string.gsub(string.gsub(raw, "-", "_"), "[^%w_]", _1_)
      local unique = unique_mangling(mangling, mangling, scope, 0)
      scope.unmanglings[unique] = str
      do
        local manglings = (temp_manglings or scope.manglings)
        manglings[str] = unique
      end
      return unique
    end
    local function apply_manglings(scope, new_manglings, ast)
      for raw, mangled in pairs(new_manglings) do
        assert_compile(not scope.refedglobals[mangled], ("use of global " .. raw .. " is aliased by a local"), ast)
        scope.manglings[raw] = mangled
      end
      return nil
    end
    local function combine_parts(parts, scope)
      local ret = (scope.manglings[parts[1]] or global_mangling(parts[1]))
      for i = 2, #parts, 1 do
        if utils["valid-lua-identifier?"](parts[i]) then
          if (parts["multi-sym-method-call"] and (i == #parts)) then
            ret = (ret .. ":" .. parts[i])
          else
            ret = (ret .. "." .. parts[i])
          end
        else
          ret = (ret .. "[" .. serialize_string(parts[i]) .. "]")
        end
      end
      return ret
    end
    local function gensym(scope, base)
      local append, mangling = 0, ((base or "") .. "_0_")
      while scope.unmanglings[mangling] do
        mangling = ((base or "") .. "_" .. append .. "_")
        append = (append + 1)
      end
      scope.unmanglings[mangling] = true
      return mangling
    end
    local function autogensym(base, scope)
      local _0_0 = utils["multi-sym?"](base)
      if (nil ~= _0_0) then
        local parts = _0_0
        parts[1] = autogensym(parts[1], scope)
        return table.concat(parts, ((parts["multi-sym-method-call"] and ":") or "."))
      else
        local _ = _0_0
        local function _1_()
          local mangling = gensym(scope, base:sub(1, ( - 2)))
          scope.autogensyms[base] = mangling
          return mangling
        end
        return (scope.autogensyms[base] or _1_())
      end
    end
    local function check_binding_valid(symbol, scope, ast)
      local name = utils.deref(symbol)
      assert_compile(not (scope.specials[name] or scope.macros[name]), ("local %s was overshadowed by a special form or macro"):format(name), ast)
      return assert_compile(not utils["quoted?"](symbol), string.format("macro tried to bind %s without gensym", name), symbol)
    end
    local function declare_local(symbol, meta, scope, ast, temp_manglings)
      check_binding_valid(symbol, scope, ast)
      local name = utils.deref(symbol)
      assert_compile(not utils["multi-sym?"](name), ("unexpected multi symbol " .. name), ast)
      scope.symmeta[name] = meta
      return local_mangling(name, scope, ast, temp_manglings)
    end
    local function hashfn_arg_name(name, multi_sym_parts, scope)
      if not scope.hashfn then
        return nil
      elseif (name == "$") then
        return "$1"
      elseif multi_sym_parts then
        if (multi_sym_parts and (multi_sym_parts[1] == "$")) then
          multi_sym_parts[1] = "$1"
        end
        return table.concat(multi_sym_parts, ".")
      end
    end
    local function symbol_to_expression(symbol, scope, reference_3f)
      local name = symbol[1]
      local multi_sym_parts = utils["multi-sym?"](name)
      local name0 = (hashfn_arg_name(name, multi_sym_parts, scope) or name)
      local parts = (multi_sym_parts or {name0})
      local etype = (((#parts > 1) and "expression") or "sym")
      local local_3f = scope.manglings[parts[1]]
      if (local_3f and scope.symmeta[parts[1]]) then
        scope.symmeta[parts[1]]["used"] = true
      end
      assert_compile((not reference_3f or local_3f or global_allowed(parts[1])), ("unknown global in strict mode: " .. parts[1]), symbol)
      if (allowed_globals and not local_3f) then
        utils.root.scope.refedglobals[parts[1]] = true
      end
      return utils.expr(combine_parts(parts, scope), etype)
    end
    local function emit(chunk, out, ast)
      if (type(out) == "table") then
        return table.insert(chunk, out)
      else
        return table.insert(chunk, {ast = ast, leaf = out})
      end
    end
    local function peephole(chunk)
      if chunk.leaf then
        return chunk
      elseif ((#chunk >= 3) and (chunk[(#chunk - 2)].leaf == "do") and not chunk[(#chunk - 1)].leaf and (chunk[#chunk].leaf == "end")) then
        local kid = peephole(chunk[(#chunk - 1)])
        local new_chunk = {ast = chunk.ast}
        for i = 1, (#chunk - 3), 1 do
          table.insert(new_chunk, peephole(chunk[i]))
        end
        for i = 1, #kid, 1 do
          table.insert(new_chunk, kid[i])
        end
        return new_chunk
      else
        return utils.map(chunk, peephole)
      end
    end
    local function flatten_chunk_correlated(main_chunk)
      local function flatten(chunk, out, last_line, file)
        local last_line0 = last_line
        if chunk.leaf then
          out[last_line0] = ((out[last_line0] or "") .. " " .. chunk.leaf)
        else
          for _, subchunk in ipairs(chunk) do
            if (subchunk.leaf or (#subchunk > 0)) then
              if (subchunk.ast and (file == subchunk.ast.file)) then
                last_line0 = math.max(last_line0, (subchunk.ast.line or 0))
              end
              last_line0 = flatten(subchunk, out, last_line0, file)
            end
          end
        end
        return last_line0
      end
      local out = {}
      local last = flatten(main_chunk, out, 1, main_chunk.file)
      for i = 1, last do
        if (out[i] == nil) then
          out[i] = ""
        end
      end
      return table.concat(out, "\n")
    end
    local function flatten_chunk(sm, chunk, tab, depth)
      if chunk.leaf then
        local code = chunk.leaf
        local info = chunk.ast
        if sm then
          sm[(#sm + 1)] = ((info and info.line) or ( - 1))
        end
        return code
      else
        local tab0 = nil
        do
          local _0_0 = tab
          if (_0_0 == true) then
            tab0 = "  "
          elseif (_0_0 == false) then
            tab0 = ""
          elseif (_0_0 == tab) then
            tab0 = tab
          elseif (_0_0 == nil) then
            tab0 = ""
          else
          tab0 = nil
          end
        end
        local function parter(c)
          if (c.leaf or (#c > 0)) then
            local sub = flatten_chunk(sm, c, tab0, (depth + 1))
            if (depth > 0) then
              return (tab0 .. sub:gsub("\n", ("\n" .. tab0)))
            else
              return sub
            end
          end
        end
        return table.concat(utils.map(chunk, parter), "\n")
      end
    end
    local fennel_sourcemap = {}
    local function make_short_src(source)
      local source0 = source:gsub("\n", " ")
      if (#source0 <= 49) then
        return ("[fennel \"" .. source0 .. "\"]")
      else
        return ("[fennel \"" .. source0:sub(1, 46) .. "...\"]")
      end
    end
    local function flatten(chunk, options)
      local chunk0 = peephole(chunk)
      if options.correlate then
        return flatten_chunk_correlated(chunk0), {}
      else
        local sm = {}
        local ret = flatten_chunk(sm, chunk0, options.indent, 0)
        if sm then
          sm.short_src = (options.filename or ret)
          if options.filename then
            sm.key = ("@" .. options.filename)
          else
            sm.key = ret
          end
          fennel_sourcemap[sm.key] = sm
        end
        return ret, sm
      end
    end
    local function make_metadata()
      local function _0_(self, tgt, key)
        if self[tgt] then
          return self[tgt][key]
        end
      end
      local function _1_(self, tgt, key, value)
        self[tgt] = (self[tgt] or {})
        self[tgt][key] = value
        return tgt
      end
      local function _2_(self, tgt, ...)
        local kv_len = select("#", ...)
        local kvs = {...}
        if ((kv_len % 2) ~= 0) then
          error("metadata:setall() expected even number of k/v pairs")
        end
        self[tgt] = (self[tgt] or {})
        for i = 1, kv_len, 2 do
          self[tgt][kvs[i]] = kvs[(i + 1)]
        end
        return tgt
      end
      return setmetatable({}, {__index = {get = _0_, set = _1_, setall = _2_}, __mode = "k"})
    end
    local function exprs1(exprs)
      return table.concat(utils.map(exprs, 1), ", ")
    end
    local function keep_side_effects(exprs, chunk, start, ast)
      local start0 = (start or 1)
      for j = start0, #exprs, 1 do
        local se = exprs[j]
        if ((se.type == "expression") and (se[1] ~= "nil")) then
          emit(chunk, string.format("do local _ = %s end", tostring(se)), ast)
        elseif (se.type == "statement") then
          local code = tostring(se)
          emit(chunk, (((code:byte() == 40) and ("do end " .. code)) or code), ast)
        end
      end
      return nil
    end
    local function handle_compile_opts(exprs, parent, opts, ast)
      if opts.nval then
        local n = opts.nval
        local len = #exprs
        if (n ~= len) then
          if (len > n) then
            keep_side_effects(exprs, parent, (n + 1), ast)
            for i = (n + 1), len, 1 do
              exprs[i] = nil
            end
          else
            for i = (#exprs + 1), n, 1 do
              exprs[i] = utils.expr("nil", "literal")
            end
          end
        end
      end
      if opts.tail then
        emit(parent, string.format("return %s", exprs1(exprs)), ast)
      end
      if opts.target then
        local result = exprs1(exprs)
        local function _2_()
          if (result == "") then
            return "nil"
          else
            return result
          end
        end
        emit(parent, string.format("%s = %s", opts.target, _2_()), ast)
      end
      if (opts.tail or opts.target) then
        return {returned = true}
      else
        local _3_0 = exprs
        _3_0["returned"] = true
        return _3_0
      end
    end
    local function find_macro(ast, scope, multi_sym_parts)
      local function find_in_table(t, i)
        if (i <= #multi_sym_parts) then
          return find_in_table((utils["table?"](t) and t[multi_sym_parts[i]]), (i + 1))
        else
          return t
        end
      end
      local macro_2a = (utils["sym?"](ast[1]) and scope.macros[utils.deref(ast[1])])
      if (not macro_2a and multi_sym_parts) then
        local nested_macro = find_in_table(scope.macros, 1)
        assert_compile((not scope.macros[multi_sym_parts[1]] or (type(nested_macro) == "function")), "macro not found in imported macro module", ast)
        return nested_macro
      else
        return macro_2a
      end
    end
    local function macroexpand_2a(ast, scope, once)
      if not utils["list?"](ast) then
        return ast
      else
        local macro_2a = find_macro(ast, scope, utils["multi-sym?"](ast[1]))
        if not macro_2a then
          return ast
        else
          local old_scope = scopes.macro
          local _ = nil
          scopes.macro = scope
          _ = nil
          local ok, transformed = pcall(macro_2a, unpack(ast, 2))
          scopes.macro = old_scope
          assert_compile(ok, transformed, ast)
          if (once or not transformed) then
            return transformed
          else
            return macroexpand_2a(transformed, scope)
          end
        end
      end
    end
    local function compile_special(ast, scope, parent, opts, special)
      local exprs = (special(ast, scope, parent, opts) or utils.expr("nil", "literal"))
      local exprs0 = nil
      if (type(exprs) == "string") then
        exprs0 = utils.expr(exprs, "expression")
      else
        exprs0 = exprs
      end
      local exprs2 = nil
      if utils["expr?"](exprs0) then
        exprs2 = {exprs0}
      else
        exprs2 = exprs0
      end
      if not exprs2.returned then
        return handle_compile_opts(exprs2, parent, opts, ast)
      elseif (opts.tail or opts.target) then
        return {returned = true}
      else
        return exprs2
      end
    end
    local function compile_call(ast, scope, parent, opts, compile1)
      local len = #ast
      local first = ast[1]
      local multi_sym_parts = utils["multi-sym?"](first)
      local special = (utils["sym?"](first) and scope.specials[utils.deref(first)])
      assert_compile((len > 0), "expected a function, macro, or special to call", ast)
      if special then
        return compile_special(ast, scope, parent, opts, special)
      elseif (multi_sym_parts and multi_sym_parts["multi-sym-method-call"]) then
        local table_with_method = table.concat({unpack(multi_sym_parts, 1, (#multi_sym_parts - 1))}, ".")
        local method_to_call = multi_sym_parts[#multi_sym_parts]
        local new_ast = utils.list(utils.sym(":", scope), utils.sym(table_with_method, scope), method_to_call)
        for i = 2, len, 1 do
          new_ast[(#new_ast + 1)] = ast[i]
        end
        return compile1(new_ast, scope, parent, opts)
      else
        local fargs = {}
        local fcallee = compile1(ast[1], scope, parent, {nval = 1})[1]
        assert_compile((fcallee.type ~= "literal"), ("cannot call literal value " .. tostring(first)), ast)
        for i = 2, len, 1 do
          local subexprs = compile1(ast[i], scope, parent, {nval = (((i ~= len) and 1) or nil)})
          fargs[(#fargs + 1)] = (subexprs[1] or utils.expr("nil", "literal"))
          if (i == len) then
            for j = 2, #subexprs, 1 do
              fargs[(#fargs + 1)] = subexprs[j]
            end
          else
            keep_side_effects(subexprs, parent, 2, ast[i])
          end
        end
        local call = string.format("%s(%s)", tostring(fcallee), exprs1(fargs))
        return handle_compile_opts({utils.expr(call, "statement")}, parent, opts, ast)
      end
    end
    local function compile_varg(ast, scope, parent, opts)
      assert_compile(scope.vararg, "unexpected vararg", ast)
      return handle_compile_opts({utils.expr("...", "varg")}, parent, opts, ast)
    end
    local function compile_sym(ast, scope, parent, opts)
      local multi_sym_parts = utils["multi-sym?"](ast)
      assert_compile(not (multi_sym_parts and multi_sym_parts["multi-sym-method-call"]), "multisym method calls may only be in call position", ast)
      local e = nil
      if (ast[1] == "nil") then
        e = utils.expr("nil", "literal")
      else
        e = symbol_to_expression(ast, scope, true)
      end
      return handle_compile_opts({e}, parent, opts, ast)
    end
    local function compile_scalar(ast, scope, parent, opts)
      local serialize = nil
      do
        local _0_0 = type(ast)
        if (_0_0 == "nil") then
          serialize = tostring
        elseif (_0_0 == "boolean") then
          serialize = tostring
        elseif (_0_0 == "string") then
          serialize = serialize_string
        elseif (_0_0 == "number") then
          local function _1_(...)
            return string.format("%.17g", ...)
          end
          serialize = _1_
        else
        serialize = nil
        end
      end
      return handle_compile_opts({utils.expr(serialize(ast), "literal")}, parent, opts)
    end
    local function compile_table(ast, scope, parent, opts, compile1)
      local buffer = {}
      for i = 1, #ast, 1 do
        local nval = ((i ~= #ast) and 1)
        buffer[(#buffer + 1)] = exprs1(compile1(ast[i], scope, parent, {nval = nval}))
      end
      local function write_other_values(k)
        if ((type(k) ~= "number") or (math.floor(k) ~= k) or (k < 1) or (k > #ast)) then
          if ((type(k) == "string") and utils["valid-lua-identifier?"](k)) then
            return {k, k}
          else
            local _0_ = compile1(k, scope, parent, {nval = 1})
            local compiled = _0_[1]
            local kstr = ("[" .. tostring(compiled) .. "]")
            return {kstr, k}
          end
        end
      end
      do
        local keys = nil
        do
          local _0_0 = utils.kvmap(ast, write_other_values)
          local function _1_(a, b)
            return (a[1] < b[1])
          end
          table.sort(_0_0, _1_)
          keys = _0_0
        end
        local function _1_(k)
          local v = tostring(compile1(ast[k[2]], scope, parent, {nval = 1})[1])
          return string.format("%s = %s", k[1], v)
        end
        utils.map(keys, _1_, buffer)
      end
      return handle_compile_opts({utils.expr(("{" .. table.concat(buffer, ", ") .. "}"), "expression")}, parent, opts, ast)
    end
    local function compile1(ast, scope, parent, opts)
      local opts0 = (opts or {})
      local ast0 = macroexpand_2a(ast, scope)
      if utils["list?"](ast0) then
        return compile_call(ast0, scope, parent, opts0, compile1)
      elseif utils["varg?"](ast0) then
        return compile_varg(ast0, scope, parent, opts0)
      elseif utils["sym?"](ast0) then
        return compile_sym(ast0, scope, parent, opts0)
      elseif (type(ast0) == "table") then
        return compile_table(ast0, scope, parent, opts0, compile1)
      elseif ((type(ast0) == "nil") or (type(ast0) == "boolean") or (type(ast0) == "number") or (type(ast0) == "string")) then
        return compile_scalar(ast0, scope, parent, opts0)
      else
        return assert_compile(false, ("could not compile value of type " .. type(ast0)), ast0)
      end
    end
    local function destructure(to, from, ast, scope, parent, opts)
      local opts0 = (opts or {})
      local _0_ = opts0
      local declaration = _0_["declaration"]
      local forceglobal = _0_["forceglobal"]
      local forceset = _0_["forceset"]
      local isvar = _0_["isvar"]
      local nomulti = _0_["nomulti"]
      local noundef = _0_["noundef"]
      local setter = nil
      if declaration then
        setter = "local %s = %s"
      else
        setter = "%s = %s"
      end
      local new_manglings = {}
      local function getname(symbol, up1)
        local raw = symbol[1]
        assert_compile(not (nomulti and utils["multi-sym?"](raw)), ("unexpected multi symbol " .. raw), up1)
        if declaration then
          return declare_local(symbol, {var = isvar}, scope, symbol, new_manglings)
        else
          local parts = (utils["multi-sym?"](raw) or {raw})
          local meta = scope.symmeta[parts[1]]
          if ((#parts == 1) and not forceset) then
            assert_compile(not (forceglobal and meta), string.format("global %s conflicts with local", tostring(symbol)), symbol)
            assert_compile(not (meta and not meta.var), ("expected var " .. raw), symbol)
            assert_compile((meta or not noundef), ("expected local " .. parts[1]), symbol)
          end
          if forceglobal then
            assert_compile(not scope.symmeta[scope.unmanglings[raw]], ("global " .. raw .. " conflicts with local"), symbol)
            scope.manglings[raw] = global_mangling(raw)
            scope.unmanglings[global_mangling(raw)] = raw
            if allowed_globals then
              table.insert(allowed_globals, raw)
            end
          end
          return symbol_to_expression(symbol, scope)[1]
        end
      end
      local function compile_top_target(lvalues)
        local inits = nil
        local function _2_(_241)
          if scope.manglings[_241] then
            return _241
          else
            return "nil"
          end
        end
        inits = utils.map(lvalues, _2_)
        local init = table.concat(inits, ", ")
        local lvalue = table.concat(lvalues, ", ")
        local plen, plast = #parent, parent[#parent]
        local ret = compile1(from, scope, parent, {target = lvalue})
        if declaration then
          for pi = plen, #parent do
            if (parent[pi] == plast) then
              plen = pi
            end
          end
          if ((#parent == (plen + 1)) and parent[#parent].leaf) then
            parent[#parent]["leaf"] = ("local " .. parent[#parent].leaf)
          else
            table.insert(parent, (plen + 1), {ast = ast, leaf = ("local " .. lvalue .. " = " .. init)})
          end
        end
        return ret
      end
      local function destructure1(left, rightexprs, up1, top)
        if (utils["sym?"](left) and (left[1] ~= "nil")) then
          local lname = getname(left, up1)
          check_binding_valid(left, scope, left)
          if top then
            compile_top_target({lname})
          else
            emit(parent, setter:format(lname, exprs1(rightexprs)), left)
          end
        elseif utils["table?"](left) then
          local s = gensym(scope)
          local right = nil
          if top then
            right = exprs1(compile1(from, scope, parent))
          else
            right = exprs1(rightexprs)
          end
          if (right == "") then
            right = "nil"
          end
          emit(parent, string.format("local %s = %s", s, right), left)
          for k, v in utils.stablepairs(left) do
            if (utils["sym?"](left[k]) and (left[k][1] == "&")) then
              assert_compile(((type(k) == "number") and not left[(k + 2)]), "expected rest argument before last parameter", left)
              local unpack_str = "{(table.unpack or unpack)(%s, %s)}"
              local formatted = string.format(unpack_str, s, k)
              local subexpr = utils.expr(formatted, "expression")
              destructure1(left[(k + 1)], {subexpr}, left)
              return
            else
              if (utils["sym?"](k) and (tostring(k) == ":") and utils["sym?"](v)) then
                k = tostring(v)
              end
              if (type(k) ~= "number") then
                k = serialize_string(k)
              end
              local subexpr = utils.expr(string.format("%s[%s]", s, k), "expression")
              destructure1(v, {subexpr}, left)
            end
          end
        elseif utils["list?"](left) then
          local left_names, tables = {}, {}
          for i, name in ipairs(left) do
            local symname = nil
            if utils["sym?"](name) then
              symname = getname(name, up1)
            else
              symname = gensym(scope)
              tables[i] = {name, utils.expr(symname, "sym")}
            end
            table.insert(left_names, symname)
          end
          if top then
            compile_top_target(left_names)
          else
            local lvalue = table.concat(left_names, ", ")
            local setting = setter:format(lvalue, exprs1(rightexprs))
            emit(parent, setting, left)
          end
          for _, pair in utils.stablepairs(tables) do
            destructure1(pair[1], {pair[2]}, left)
          end
        else
          assert_compile(false, string.format("unable to bind %s %s", type(left), tostring(left)), (((type(up1[2]) == "table") and up1[2]) or up1))
        end
        if top then
          return {returned = true}
        end
      end
      local ret = destructure1(to, nil, ast, true)
      apply_manglings(scope, new_manglings, ast)
      return ret
    end
    local function require_include(ast, scope, parent, opts)
      opts.fallback = function(e)
        return utils.expr(string.format("require(%s)", tostring(e)), "statement")
      end
      return scopes.global.specials.include(ast, scope, parent, opts)
    end
    local function compile_stream(strm, options)
      local opts = utils.copy(options)
      local old_globals = allowed_globals
      local scope = (opts.scope or make_scope(scopes.global))
      local vals = {}
      local chunk = {}
      local _0_ = utils.root
      _0_["set-reset"](_0_)
      allowed_globals = opts.allowedGlobals
      if (opts.indent == nil) then
        opts.indent = "  "
      end
      if opts.requireAsInclude then
        scope.specials.require = require_include
      end
      utils.root.chunk, utils.root.scope, utils.root.options = chunk, scope, opts
      for ok, val in parser.parser(strm, opts.filename, opts) do
        vals[(#vals + 1)] = val
      end
      for i = 1, #vals, 1 do
        local exprs = compile1(vals[i], scope, chunk, {nval = (((i < #vals) and 0) or nil), tail = (i == #vals)})
        keep_side_effects(exprs, chunk, nil, vals[i])
      end
      allowed_globals = old_globals
      utils.root.reset()
      return flatten(chunk, opts)
    end
    local function compile_string(str, opts)
      return compile_stream(parser["string-stream"](str), (opts or {}))
    end
    local function compile(ast, opts)
      local opts0 = utils.copy(opts)
      local old_globals = allowed_globals
      local chunk = {}
      local scope = (opts0.scope or make_scope(scopes.global))
      local _0_ = utils.root
      _0_["set-reset"](_0_)
      allowed_globals = opts0.allowedGlobals
      if (opts0.indent == nil) then
        opts0.indent = "  "
      end
      if opts0.requireAsInclude then
        scope.specials.require = require_include
      end
      utils.root.chunk, utils.root.scope, utils.root.options = chunk, scope, opts0
      local exprs = compile1(ast, scope, chunk, {tail = true})
      keep_side_effects(exprs, chunk, nil, ast)
      allowed_globals = old_globals
      utils.root.reset()
      return flatten(chunk, opts0)
    end
    local function traceback_frame(info)
      if ((info.what == "C") and info.name) then
        return string.format("  [C]: in function '%s'", info.name)
      elseif (info.what == "C") then
        return "  [C]: in ?"
      else
        local remap = fennel_sourcemap[info.source]
        if (remap and remap[info.currentline]) then
          info["short-src"] = remap["short-src"]
          info.currentline = remap[info.currentline]
        end
        if (info.what == "Lua") then
          local function _1_()
            if info.name then
              return ("'" .. info.name .. "'")
            else
              return "?"
            end
          end
          return string.format("  %s:%d: in function %s", info.short_src, info.currentline, _1_())
        elseif (info["short-src"] == "(tail call)") then
          return "  (tail call)"
        else
          return string.format("  %s:%d: in main chunk", info.short_src, info.currentline)
        end
      end
    end
    local function traceback(msg, start)
      local msg0 = (msg or "")
      if ((msg0:find("^Compile error") or msg0:find("^Parse error")) and not utils["debug-on?"]("trace")) then
        return msg0
      else
        local lines = {}
        if (msg0:find("^Compile error") or msg0:find("^Parse error")) then
          table.insert(lines, msg0)
        else
          local newmsg = msg0:gsub("^[^:]*:%d+:%s+", "runtime error: ")
          table.insert(lines, newmsg)
        end
        table.insert(lines, "stack traceback:")
        local done_3f, level = false, (start or 2)
        while not done_3f do
          do
            local _1_0 = debug.getinfo(level, "Sln")
            if (_1_0 == nil) then
              done_3f = true
            elseif (nil ~= _1_0) then
              local info = _1_0
              table.insert(lines, traceback_frame(info))
            end
          end
          level = (level + 1)
        end
        return table.concat(lines, "\n")
      end
    end
    local function entry_transform(fk, fv)
      local function _0_(k, v)
        if (type(k) == "number") then
          return k, fv(v)
        else
          return fk(k), fv(v)
        end
      end
      return _0_
    end
    local function no()
      return nil
    end
    local function mixed_concat(t, joiner)
      local seen = {}
      local ret, s = "", ""
      for k, v in ipairs(t) do
        table.insert(seen, k)
        ret = (ret .. s .. v)
        s = joiner
      end
      for k, v in utils.stablepairs(t) do
        if not seen[k] then
          ret = (ret .. s .. "[" .. k .. "]" .. "=" .. v)
          s = joiner
        end
      end
      return ret
    end
    local function do_quote(form, scope, parent, runtime_3f)
      local function q(x)
        return do_quote(x, scope, parent, runtime_3f)
      end
      if utils["varg?"](form) then
        assert_compile(not runtime_3f, "quoted ... may only be used at compile time", form)
        return "_VARARG"
      elseif utils["sym?"](form) then
        local filename = nil
        if form.filename then
          filename = string.format("%q", form.filename)
        else
          filename = "nil"
        end
        local symstr = utils.deref(form)
        assert_compile(not runtime_3f, "symbols may only be used at compile time", form)
        if (symstr:find("#$") or symstr:find("#[:.]")) then
          return string.format("sym('%s', nil, {filename=%s, line=%s})", autogensym(symstr, scope), filename, (form.line or "nil"))
        else
          return string.format("sym('%s', nil, {quoted=true, filename=%s, line=%s})", symstr, filename, (form.line or "nil"))
        end
      elseif (utils["list?"](form) and utils["sym?"](form[1]) and (utils.deref(form[1]) == "unquote")) then
        local payload = form[2]
        local res = unpack(compile1(payload, scope, parent))
        return res[1]
      elseif utils["list?"](form) then
        local mapped = utils.kvmap(form, entry_transform(no, q))
        local filename = nil
        if form.filename then
          filename = string.format("%q", form.filename)
        else
          filename = "nil"
        end
        assert_compile(not runtime_3f, "lists may only be used at compile time", form)
        return string.format(("setmetatable({filename=%s, line=%s, bytestart=%s, %s}" .. ", getmetatable(list()))"), filename, (form.line or "nil"), (form.bytestart or "nil"), mixed_concat(mapped, ", "))
      elseif (type(form) == "table") then
        local mapped = utils.kvmap(form, entry_transform(q, q))
        local source = getmetatable(form)
        local filename = nil
        if source.filename then
          filename = string.format("%q", source.filename)
        else
          filename = "nil"
        end
        local function _1_()
          if source then
            return source.line
          else
            return "nil"
          end
        end
        return string.format("setmetatable({%s}, {filename=%s, line=%s})", mixed_concat(mapped, ", "), filename, _1_())
      elseif (type(form) == "string") then
        return serialize_string(form)
      else
        return tostring(form)
      end
    end
    return {["apply-manglings"] = apply_manglings, ["compile-stream"] = compile_stream, ["compile-string"] = compile_string, ["declare-local"] = declare_local, ["do-quote"] = do_quote, ["global-mangling"] = global_mangling, ["global-unmangling"] = global_unmangling, ["keep-side-effects"] = keep_side_effects, ["make-scope"] = make_scope, ["require-include"] = require_include, ["symbol-to-expression"] = symbol_to_expression, assert = assert_compile, autogensym = autogensym, compile = compile, compile1 = compile1, destructure = destructure, emit = emit, gensym = gensym, macroexpand = macroexpand_2a, metadata = make_metadata(), scopes = scopes, traceback = traceback}
  end
  package.preload["fennel.friend"] = package.preload["fennel.friend"] or function(...)
    local function ast_source(ast)
      local m = getmetatable(ast)
      if (m and m.line and m) then
        return m
      else
        return ast
      end
    end
    local suggestions = {["$ and $... in hashfn are mutually exclusive"] = {"modifying the hashfn so it only contains $... or $, $1, $2, $3, etc"}, ["can't start multisym segment with a digit"] = {"removing the digit", "adding a non-digit before the digit"}, ["cannot call literal value"] = {"checking for typos", "checking for a missing function name"}, ["could not compile value of type "] = {"debugging the macro you're calling not to return a coroutine or userdata"}, ["could not read number (.*)"] = {"removing the non-digit character", "beginning the identifier with a non-digit if it is not meant to be a number"}, ["expected a function.* to call"] = {"removing the empty parentheses", "using square brackets if you want an empty table"}, ["expected binding table"] = {"placing a table here in square brackets containing identifiers to bind"}, ["expected body expression"] = {"putting some code in the body of this form after the bindings"}, ["expected each macro to be function"] = {"ensuring that the value for each key in your macros table contains a function", "avoid defining nested macro tables"}, ["expected even number of name/value bindings"] = {"finding where the identifier or value is missing"}, ["expected even number of values in table literal"] = {"removing a key", "adding a value"}, ["expected local"] = {"looking for a typo", "looking for a local which is used out of its scope"}, ["expected macros to be table"] = {"ensuring your macro definitions return a table"}, ["expected parameters"] = {"adding function parameters as a list of identifiers in brackets"}, ["expected rest argument before last parameter"] = {"moving & to right before the final identifier when destructuring"}, ["expected symbol for function parameter: (.*)"] = {"changing %s to an identifier instead of a literal value"}, ["expected var (.*)"] = {"declaring %s using var instead of let/local", "introducing a new local instead of changing the value of %s"}, ["expected vararg as last parameter"] = {"moving the \"...\" to the end of the parameter list"}, ["expected whitespace before opening delimiter"] = {"adding whitespace"}, ["global (.*) conflicts with local"] = {"renaming local %s"}, ["illegal character: (.)"] = {"deleting or replacing %s", "avoiding reserved characters like \", \\, ', ~, ;, @, `, and comma"}, ["local (.*) was overshadowed by a special form or macro"] = {"renaming local %s"}, ["macro not found in macro module"] = {"checking the keys of the imported macro module's returned table"}, ["macro tried to bind (.*) without gensym"] = {"changing to %s# when introducing identifiers inside macros"}, ["malformed multisym"] = {"ensuring each period or colon is not followed by another period or colon"}, ["may only be used at compile time"] = {"moving this to inside a macro if you need to manipulate symbols/lists", "using square brackets instead of parens to construct a table"}, ["method must be last component"] = {"using a period instead of a colon for field access", "removing segments after the colon", "making the method call, then looking up the field on the result"}, ["mismatched closing delimiter (.), expected (.)"] = {"replacing %s with %s", "deleting %s", "adding matching opening delimiter earlier"}, ["multisym method calls may only be in call position"] = {"using a period instead of a colon to reference a table's fields", "putting parens around this"}, ["unable to bind (.*)"] = {"replacing the %s with an identifier"}, ["unexpected closing delimiter (.)"] = {"deleting %s", "adding matching opening delimiter earlier"}, ["unexpected multi symbol (.*)"] = {"removing periods or colons from %s"}, ["unexpected vararg"] = {"putting \"...\" at the end of the fn parameters if the vararg was intended"}, ["unknown global in strict mode: (.*)"] = {"looking to see if there's a typo", "using the _G table instead, eg. _G.%s if you really want a global", "moving this code to somewhere that %s is in scope", "binding %s as a local in the scope of this code"}, ["unused local (.*)"] = {"fixing a typo so %s is used", "renaming the local to _%s"}, ["use of global (.*) is aliased by a local"] = {"renaming local %s", "refer to the global using _G.%s instead of directly"}}
    local unpack = (_G.unpack or table.unpack)
    local function suggest(msg)
      local suggestion = nil
      for pat, sug in pairs(suggestions) do
        local matches = {msg:match(pat)}
        if (0 < #matches) then
          if ("table" == type(sug)) then
            local out = {}
            for _, s in ipairs(sug) do
              table.insert(out, s:format(unpack(matches)))
            end
            suggestion = out
          else
            suggestion = sug(matches)
          end
        end
      end
      return suggestion
    end
    local function read_line_from_file(filename, line)
      local bytes = 0
      local f = assert(io.open(filename))
      local _ = nil
      for _0 = 1, (line - 1) do
        bytes = (bytes + 1 + #f:read())
      end
      _ = nil
      local codeline = f:read()
      f:close()
      return codeline, bytes
    end
    local function read_line_from_source(source, line)
      local lines, bytes, codeline = 0, 0
      for this_line, newline in string.gmatch((source .. "\n"), "(.-)(\13?\n)") do
        lines = (lines + 1)
        if (lines == line) then
          codeline = this_line
          break
        end
        bytes = (bytes + #newline + #this_line)
      end
      return codeline, bytes
    end
    local function read_line(filename, line, source)
      if source then
        return read_line_from_source(source, line)
      else
        return read_line_from_file(filename, line)
      end
    end
    local function friendly_msg(msg, _0_0, source)
      local _1_ = _0_0
      local byteend = _1_["byteend"]
      local bytestart = _1_["bytestart"]
      local filename = _1_["filename"]
      local line = _1_["line"]
      local ok, codeline, bol, eol = pcall(read_line, filename, line, source)
      local suggestions0 = suggest(msg)
      local out = {msg, ""}
      if (ok and codeline) then
        table.insert(out, codeline)
      end
      if (ok and codeline and bytestart and byteend) then
        table.insert(out, (string.rep(" ", (bytestart - bol - 1)) .. "^" .. string.rep("^", math.min((byteend - bytestart), ((bol + #codeline) - bytestart)))))
      end
      if (ok and codeline and bytestart and not byteend) then
        table.insert(out, (string.rep("-", (bytestart - bol - 1)) .. "^"))
        table.insert(out, "")
      end
      if suggestions0 then
        for _, suggestion in ipairs(suggestions0) do
          table.insert(out, ("* Try %s."):format(suggestion))
        end
      end
      return table.concat(out, "\n")
    end
    local function assert_compile(condition, msg, ast, source)
      if not condition then
        local _1_ = ast_source(ast)
        local filename = _1_["filename"]
        local line = _1_["line"]
        error(friendly_msg(("Compile error in %s:%s\n  %s"):format((filename or "unknown"), (line or "?"), msg), ast_source(ast), source), 0)
      end
      return condition
    end
    local function parse_error(msg, filename, line, bytestart, source)
      return error(friendly_msg(("Parse error in %s:%s\n  %s"):format(filename, line, msg), {bytestart = bytestart, filename = filename, line = line}, source), 0)
    end
    return {["assert-compile"] = assert_compile, ["parse-error"] = parse_error}
  end
  package.preload["fennel.parser"] = package.preload["fennel.parser"] or function(...)
    local utils = require("fennel.utils")
    local friend = require("fennel.friend")
    local unpack = (_G.unpack or table.unpack)
    local function granulate(getchunk)
      local c, index, done_3f = "", 1, false
      local function _0_(parser_state)
        if not done_3f then
          if (index <= #c) then
            local b = c:byte(index)
            index = (index + 1)
            return b
          else
            c = getchunk(parser_state)
            if (not c or (c == "")) then
              done_3f = true
              return nil
            end
            index = 2
            return c:byte(1)
          end
        end
      end
      local function _1_()
        c = ""
        return nil
      end
      return _0_, _1_
    end
    local function string_stream(str)
      local str0 = str:gsub("^#![^\n]*\n", "")
      local index = 1
      local function _0_()
        local r = str0:byte(index)
        index = (index + 1)
        return r
      end
      return _0_
    end
    local delims = {[123] = 125, [125] = true, [40] = 41, [41] = true, [91] = 93, [93] = true}
    local function whitespace_3f(b)
      return ((b == 32) or ((b >= 9) and (b <= 13)))
    end
    local function symbolchar_3f(b)
      return ((b > 32) and not delims[b] and (b ~= 127) and (b ~= 34) and (b ~= 39) and (b ~= 126) and (b ~= 59) and (b ~= 44) and (b ~= 64) and (b ~= 96))
    end
    local prefixes = {[35] = "hashfn", [39] = "quote", [44] = "unquote", [96] = "quote"}
    local function parser(getbyte, filename, options)
      local stack = {}
      local line = 1
      local byteindex = 0
      local lastb = nil
      local function ungetb(ub)
        if (ub == 10) then
          line = (line - 1)
        end
        byteindex = (byteindex - 1)
        lastb = ub
        return nil
      end
      local function getb()
        local r = nil
        if lastb then
          r, lastb = lastb, nil
        else
          r = getbyte({["stack-size"] = #stack})
        end
        byteindex = (byteindex + 1)
        if (r == 10) then
          line = (line + 1)
        end
        return r
      end
      local function parse_error(msg)
        local _0_ = (utils.root.options or {})
        local source = _0_["source"]
        local unfriendly = _0_["unfriendly"]
        utils.root.reset()
        if unfriendly then
          return error(string.format("Parse error in %s:%s: %s", (filename or "unknown"), (line or "?"), msg), 0)
        else
          return friend["parse-error"](msg, (filename or "unknown"), (line or "?"), byteindex, source)
        end
      end
      local function parse_stream()
        local whitespace_since_dispatch, done_3f, retval = true
        local function dispatch(v)
          if (#stack == 0) then
            retval, done_3f, whitespace_since_dispatch = v, true, false
            return nil
          elseif stack[#stack].prefix then
            local stacktop = stack[#stack]
            stack[#stack] = nil
            return dispatch(utils.list(utils.sym(stacktop.prefix), v))
          else
            whitespace_since_dispatch = false
            return table.insert(stack[#stack], v)
          end
        end
        local function badend()
          local accum = utils.map(stack, "closer")
          return parse_error(string.format("expected closing delimiter%s %s", (((#stack == 1) and "") or "s"), string.char(unpack(accum))))
        end
        while true do
          local b = nil
          while true do
            b = getb()
            if (b and whitespace_3f(b)) then
              whitespace_since_dispatch = true
            end
            if (not b or not whitespace_3f(b)) then
              break
            end
          end
          if not b then
            if (#stack > 0) then
              badend()
            end
            return nil
          end
          if (b == 59) then
            while true do
              b = getb()
              if (not b or (b == 10)) then
                break
              end
            end
          elseif (type(delims[b]) == "number") then
            if not whitespace_since_dispatch then
              parse_error(("expected whitespace before opening delimiter " .. string.char(b)))
            end
            table.insert(stack, setmetatable({bytestart = byteindex, closer = delims[b], filename = filename, line = line}, getmetatable(utils.list())))
          elseif delims[b] then
            local last = stack[#stack]
            if (#stack == 0) then
              parse_error(("unexpected closing delimiter " .. string.char(b)))
            end
            local val = nil
            if (last.closer ~= b) then
              parse_error(("mismatched closing delimiter " .. string.char(b) .. ", expected " .. string.char(last.closer)))
            end
            last.byteend = byteindex
            if (b == 41) then
              val = last
            elseif (b == 93) then
              val = utils.sequence(unpack(last))
              for k, v in pairs(last) do
                getmetatable(val)[k] = v
              end
            else
              if ((#last % 2) ~= 0) then
                byteindex = (byteindex - 1)
                parse_error("expected even number of values in table literal")
              end
              val = {}
              setmetatable(val, last)
              for i = 1, #last, 2 do
                if ((tostring(last[i]) == ":") and utils["sym?"](last[(i + 1)]) and utils["sym?"](last[i])) then
                  last[i] = tostring(last[(i + 1)])
                end
                val[last[i]] = last[(i + 1)]
              end
            end
            stack[#stack] = nil
            dispatch(val)
          elseif (b == 34) then
            local chars = {34}
            local state = "base"
            stack[(#stack + 1)] = {closer = 34}
            while true do
              b = getb()
              chars[(#chars + 1)] = b
              if (state == "base") then
                if (b == 92) then
                  state = "backslash"
                elseif (b == 34) then
                  state = "done"
                end
              else
                state = "base"
              end
              if (not b or (state == "done")) then
                break
              end
            end
            if not b then
              badend()
            end
            stack[#stack] = nil
            local raw = string.char(unpack(chars))
            local formatted = nil
            local function _2_(c)
              return ("\\" .. c:byte())
            end
            formatted = raw:gsub("[\1-\31]", _2_)
            local load_fn = (_G.loadstring or load)(string.format("return %s", formatted))
            dispatch(load_fn())
          elseif prefixes[b] then
            table.insert(stack, {prefix = prefixes[b]})
            local nextb = getb()
            if whitespace_3f(nextb) then
              if (b ~= 35) then
                parse_error("invalid whitespace after quoting prefix")
              end
              stack[#stack] = nil
              dispatch(utils.sym("#"))
            end
            ungetb(nextb)
          elseif (symbolchar_3f(b) or (b == string.byte("~"))) then
            local chars = {}
            local bytestart = byteindex
            while true do
              chars[(#chars + 1)] = b
              b = getb()
              if (not b or not symbolchar_3f(b)) then
                break
              end
            end
            if b then
              ungetb(b)
            end
            local rawstr = string.char(unpack(chars))
            if (rawstr == "true") then
              dispatch(true)
            elseif (rawstr == "false") then
              dispatch(false)
            elseif (rawstr == "...") then
              dispatch(utils.varg())
            elseif rawstr:match("^:.+$") then
              dispatch(rawstr:sub(2))
            elseif (rawstr:match("^~") and (rawstr ~= "~=")) then
              parse_error("illegal character: ~")
            else
              local force_number = rawstr:match("^%d")
              local number_with_stripped_underscores = rawstr:gsub("_", "")
              local x = nil
              if force_number then
                x = (tonumber(number_with_stripped_underscores) or parse_error(("could not read number \"" .. rawstr .. "\"")))
              else
                x = tonumber(number_with_stripped_underscores)
                if not x then
                  if rawstr:match("%.[0-9]") then
                    byteindex = (((byteindex - #rawstr) + rawstr:find("%.[0-9]")) + 1)
                    parse_error(("can't start multisym segment " .. "with a digit: " .. rawstr))
                  elseif (rawstr:match("[%.:][%.:]") and (rawstr ~= "..") and (rawstr ~= "$...")) then
                    byteindex = ((byteindex - #rawstr) + 1 + rawstr:find("[%.:][%.:]"))
                    parse_error(("malformed multisym: " .. rawstr))
                  elseif rawstr:match(":.+[%.:]") then
                    byteindex = ((byteindex - #rawstr) + rawstr:find(":.+[%.:]"))
                    parse_error(("method must be last component " .. "of multisym: " .. rawstr))
                  else
                    x = utils.sym(rawstr, nil, {byteend = byteindex, bytestart = bytestart, filename = filename, line = line})
                  end
                end
              end
              dispatch(x)
            end
          else
            parse_error(("illegal character: " .. string.char(b)))
          end
          if done_3f then
            break
          end
        end
        return true, retval
      end
      local function _0_()
        stack = {}
        return nil
      end
      return parse_stream, _0_
    end
    return {["string-stream"] = string_stream, granulate = granulate, parser = parser}
  end
  local utils = nil
  package.preload["fennel.utils"] = package.preload["fennel.utils"] or function(...)
    local function stablepairs(t)
      local keys = {}
      local succ = {}
      for k in pairs(t) do
        table.insert(keys, k)
      end
      local function _0_(a, b)
        return (tostring(a) < tostring(b))
      end
      table.sort(keys, _0_)
      for i, k in ipairs(keys) do
        succ[k] = keys[(i + 1)]
      end
      local function stablenext(tbl, idx)
        if (idx == nil) then
          return keys[1], tbl[keys[1]]
        else
          return succ[idx], tbl[succ[idx]]
        end
      end
      return stablenext, t, nil
    end
    local function map(t, f, out)
      local out0 = (out or {})
      local f0 = nil
      if (type(f) == "function") then
        f0 = f
      else
        local s = f
        local function _0_(x)
          return x[s]
        end
        f0 = _0_
      end
      for _, x in ipairs(t) do
        local _1_0 = f0(x)
        if (nil ~= _1_0) then
          local v = _1_0
          table.insert(out0, v)
        end
      end
      return out0
    end
    local function kvmap(t, f, out)
      local out0 = (out or {})
      local f0 = nil
      if (type(f) == "function") then
        f0 = f
      else
        local s = f
        local function _0_(x)
          return x[s]
        end
        f0 = _0_
      end
      for k, x in stablepairs(t) do
        local korv, v = f0(k, x)
        if (korv and not v) then
          table.insert(out0, korv)
        end
        if (korv and v) then
          out0[korv] = v
        end
      end
      return out0
    end
    local function copy(from)
      local to = {}
      for k, v in pairs((from or {})) do
        to[k] = v
      end
      return to
    end
    local function member_3f(x, tbl, n)
      local _0_0 = tbl[(n or 1)]
      if (_0_0 == x) then
        return true
      elseif (_0_0 == nil) then
        return false
      else
        local _ = _0_0
        return member_3f(x, tbl, ((n or 1) + 1))
      end
    end
    local function allpairs(tbl)
      assert((type(tbl) == "table"), "allpairs expects a table")
      local t = tbl
      local seen = {}
      local function allpairs_next(_, state)
        local next_state, value = next(t, state)
        if seen[next_state] then
          return allpairs_next(nil, next_state)
        elseif next_state then
          seen[next_state] = true
          return next_state, value
        else
          local meta = getmetatable(t)
          if (meta and meta.__index) then
            t = meta.__index
            return allpairs_next(t)
          end
        end
      end
      return allpairs_next
    end
    local function deref(self)
      return self[1]
    end
    local nil_sym = nil
    local function list__3estring(self, tostring2)
      local safe, max = {}, 0
      for k in pairs(self) do
        if ((type(k) == "number") and (k > max)) then
          max = k
        end
      end
      for i = 1, max, 1 do
        safe[i] = (((self[i] == nil) and nil_sym) or self[i])
      end
      return ("(" .. table.concat(map(safe, (tostring2 or tostring)), " ", 1, max) .. ")")
    end
    local symbol_mt = {"SYMBOL", __fennelview = deref, __tostring = deref}
    local expr_mt = {"EXPR", __tostring = deref}
    local list_mt = {"LIST", __fennelview = list__3estring, __tostring = list__3estring}
    local sequence_marker = {"SEQUENCE"}
    local vararg = setmetatable({"..."}, {"VARARG", __fennelview = deref, __tostring = deref})
    local getenv = nil
    local function _0_()
      return nil
    end
    getenv = ((os and os.getenv) or _0_)
    local function debug_on_3f(flag)
      local level = (getenv("FENNEL_DEBUG") or "")
      return ((level == "all") or level:find(flag))
    end
    local function list(...)
      return setmetatable({...}, list_mt)
    end
    local function sym(str, scope, source)
      local s = {str, scope = scope}
      for k, v in pairs((source or {})) do
        if (type(k) == "string") then
          s[k] = v
        end
      end
      return setmetatable(s, symbol_mt)
    end
    nil_sym = sym("nil")
    local function sequence(...)
      return setmetatable({...}, {sequence = sequence_marker})
    end
    local function expr(strcode, etype)
      return setmetatable({strcode, type = etype}, expr_mt)
    end
    local function varg()
      return vararg
    end
    local function expr_3f(x)
      return ((type(x) == "table") and (getmetatable(x) == expr_mt) and x)
    end
    local function varg_3f(x)
      return ((x == vararg) and x)
    end
    local function list_3f(x)
      return ((type(x) == "table") and (getmetatable(x) == list_mt) and x)
    end
    local function sym_3f(x)
      return ((type(x) == "table") and (getmetatable(x) == symbol_mt) and x)
    end
    local function table_3f(x)
      return ((type(x) == "table") and (x ~= vararg) and (getmetatable(x) ~= list_mt) and (getmetatable(x) ~= symbol_mt) and x)
    end
    local function sequence_3f(x)
      local mt = ((type(x) == "table") and getmetatable(x))
      return (mt and (mt.sequence == sequence_marker) and x)
    end
    local function multi_sym_3f(str)
      if sym_3f(str) then
        return multi_sym_3f(tostring(str))
      elseif (type(str) ~= "string") then
        return false
      else
        local parts = {}
        for part in str:gmatch("[^%.%:]+[%.%:]?") do
          local last_char = part:sub(( - 1))
          if (last_char == ":") then
            parts["multi-sym-method-call"] = true
          end
          if ((last_char == ":") or (last_char == ".")) then
            parts[(#parts + 1)] = part:sub(1, ( - 2))
          else
            parts[(#parts + 1)] = part
          end
        end
        return ((#parts > 0) and (str:match("%.") or str:match(":")) and not str:match("%.%.") and (str:byte() ~= string.byte(".")) and (str:byte(( - 1)) ~= string.byte(".")) and parts)
      end
    end
    local function quoted_3f(symbol)
      return symbol.quoted
    end
    local function walk_tree(root, f, custom_iterator)
      local function walk(iterfn, parent, idx, node)
        if f(idx, node, parent) then
          for k, v in iterfn(node) do
            walk(iterfn, node, k, v)
          end
          return nil
        end
      end
      walk((custom_iterator or pairs), nil, nil, root)
      return root
    end
    local lua_keywords = {"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while", "goto"}
    for i, v in ipairs(lua_keywords) do
      lua_keywords[v] = i
    end
    local function valid_lua_identifier_3f(str)
      return (str:match("^[%a_][%w_]*$") and not lua_keywords[str])
    end
    local propagated_options = {"allowedGlobals", "indent", "correlate", "useMetadata", "env"}
    local function propagate_options(options, subopts)
      for _, name in ipairs(propagated_options) do
        subopts[name] = options[name]
      end
      return subopts
    end
    local root = nil
    local function _1_()
    end
    root = {chunk = nil, options = nil, reset = _1_, scope = nil}
    root["set-reset"] = function(new_root)
      root.reset = function()
        root.chunk, root.scope, root.options, root.reset = new_root.chunk, new_root.scope, new_root.options, new_root.reset
        return nil
      end
      return root.reset
    end
    return {["debug-on?"] = debug_on_3f, ["expr?"] = expr_3f, ["list?"] = list_3f, ["lua-keywords"] = lua_keywords, ["member?"] = member_3f, ["multi-sym?"] = multi_sym_3f, ["propagate-options"] = propagate_options, ["quoted?"] = quoted_3f, ["sequence?"] = sequence_3f, ["sym?"] = sym_3f, ["table?"] = table_3f, ["valid-lua-identifier?"] = valid_lua_identifier_3f, ["varg?"] = varg_3f, ["walk-tree"] = walk_tree, allpairs = allpairs, copy = copy, deref = deref, expr = expr, kvmap = kvmap, list = list, map = map, path = table.concat({"./?.fnl", "./?/init.fnl", getenv("FENNEL_PATH")}, ";"), root = root, sequence = sequence, stablepairs = stablepairs, sym = sym, varg = varg}
  end
  utils = require("fennel.utils")
  local parser = require("fennel.parser")
  local compiler = require("fennel.compiler")
  local specials = require("fennel.specials")
  local repl = require("fennel.repl")
  local function eval(str, options, ...)
    local opts = utils.copy(options)
    local _ = nil
    if ((opts.allowedGlobals == nil) and not getmetatable(opts.env)) then
      opts.allowedGlobals = specials["current-global-names"](opts.env)
      _ = nil
    else
    _ = nil
    end
    local env = (opts.env and specials["wrap-env"](opts.env))
    local lua_source = compiler["compile-string"](str, opts)
    local loader = nil
    local function _1_(...)
      if opts.filename then
        return ("@" .. opts.filename)
      else
        return str
      end
    end
    loader = specials["load-code"](lua_source, env, _1_(...))
    opts.filename = nil
    return loader(...)
  end
  local function dofile_2a(filename, options, ...)
    local opts = utils.copy(options)
    local f = assert(io.open(filename, "rb"))
    local source = f:read("*all")
    f:close()
    opts.filename = filename
    return eval(source, opts, ...)
  end
  local mod = {["compile-stream"] = compiler["compile-stream"], ["compile-string"] = compiler["compile-string"], ["list?"] = utils["list?"], ["load-code"] = specials["load-code"], ["macro-loaded"] = specials["macro-loaded"], ["make-searcher"] = specials["make-searcher"], ["search-module"] = specials["search-module"], ["string-stream"] = parser["string-stream"], ["sym?"] = utils["sym?"], compile = compiler.compile, compile1 = compiler.compile1, compileStream = compiler["compile-stream"], compileString = compiler["compile-string"], doc = specials.doc, dofile = dofile_2a, eval = eval, gensym = compiler.gensym, granulate = parser.granulate, list = utils.list, loadCode = specials["load-code"], macroLoaded = specials["macro-loaded"], makeSearcher = specials["make-searcher"], make_searcher = specials["make-searcher"], mangle = compiler["global-mangling"], metadata = compiler.metadata, parser = parser.parser, path = utils.path, repl = repl, scope = compiler["make-scope"], searchModule = specials["search-module"], searcher = specials["make-searcher"](), stringStream = parser["string-stream"], sym = utils.sym, traceback = compiler.traceback, unmangle = compiler["global-unmangling"], varg = utils.varg, version = "0.5.1-dev"}
  utils["fennel-module"] = mod
  do
    local builtin_macros = [===[;; The code for these macros is somewhat idiosyncratic because it cannot use any
    ;; macros which have not yet been defined.
    
    (fn -> [val ...]
      "Thread-first macro.
    Take the first value and splice it into the second form as its first argument.
    The value of the second form is spliced into the first arg of the third, etc."
      (var x val)
      (each [_ e (ipairs [...])]
        (let [elt (if (list? e) e (list e))]
          (table.insert elt 2 x)
          (set x elt)))
      x)
    
    (fn ->> [val ...]
      "Thread-last macro.
    Same as ->, except splices the value into the last position of each form
    rather than the first."
      (var x val)
      (each [_ e (pairs [...])]
        (let [elt (if (list? e) e (list e))]
          (table.insert elt x)
          (set x elt)))
      x)
    
    (fn -?> [val ...]
      "Nil-safe thread-first macro.
    Same as -> except will short-circuit with nil when it encounters a nil value."
      (if (= 0 (select "#" ...))
          val
          (let [els [...]
                e (table.remove els 1)
                el (if (list? e) e (list e))
                tmp (gensym)]
            (table.insert el 2 tmp)
            `(let [,tmp ,val]
               (if ,tmp
                   (-?> ,el ,(unpack els))
                   ,tmp)))))
    
    (fn -?>> [val ...]
      "Nil-safe thread-last macro.
    Same as ->> except will short-circuit with nil when it encounters a nil value."
      (if (= 0 (select "#" ...))
          val
          (let [els [...]
                e (table.remove els 1)
                el (if (list? e) e (list e))
                tmp (gensym)]
            (table.insert el tmp)
            `(let [,tmp ,val]
               (if ,tmp
                   (-?>> ,el ,(unpack els))
                   ,tmp)))))
    
    (fn doto [val ...]
      "Evaluates val and splices it into the first argument of subsequent forms."
      (let [name (gensym)
            form `(let [,name ,val])]
        (each [_ elt (pairs [...])]
          (table.insert elt 2 name)
          (table.insert form elt))
        (table.insert form name)
        form))
    
    (fn when [condition body1 ...]
      "Evaluate body for side-effects only when condition is truthy."
      (assert body1 "expected body")
      `(if ,condition
           (do ,body1 ,...)))
    
    (fn with-open [closable-bindings ...]
      "Like `let`, but invokes (v:close) on each binding after evaluating the body.
    The body is evaluated inside `xpcall` so that bound values will be closed upon
    encountering an error before propagating it."
      (let [bodyfn    `(fn [] ,...)
            closer `(fn close-handlers# [ok# ...] (if ok# ...
                                                      (error ... 0)))
            traceback `(. (or package.loaded.fennel debug) :traceback)]
        (for [i 1 (# closable-bindings) 2]
          (assert (sym? (. closable-bindings i))
                  "with-open only allows symbols in bindings")
          (table.insert closer 4 `(: ,(. closable-bindings i) :close)))
        `(let ,closable-bindings ,closer
              (close-handlers# (xpcall ,bodyfn ,traceback)))))
    
    (fn partial [f ...]
      "Returns a function with all arguments partially applied to f."
      (let [body (list f ...)]
        (table.insert body _VARARG)
        `(fn [,_VARARG] ,body)))
    
    (fn pick-args [n f]
      "Creates a function of arity n that applies its arguments to f.
    
    For example,
      (pick-args 2 func)
    expands to
      (fn [_0_ _1_] (func _0_ _1_))"
      (assert (and (= (type n) :number) (= n (math.floor n)) (>= n 0))
              "Expected n to be an integer literal >= 0.")
      (let [bindings []]
        (for [i 1 n] (tset bindings i (gensym)))
        `(fn ,bindings (,f ,(unpack bindings)))))
    
    (fn pick-values [n ...]
      "Like the `values` special, but emits exactly n values.
    
    For example,
      (pick-values 2 ...)
    expands to
      (let [(_0_ _1_) ...]
        (values _0_ _1_))"
      (assert (and (= :number (type n)) (>= n 0) (= n (math.floor n)))
              "Expected n to be an integer >= 0")
      (let [let-syms   (list)
            let-values (if (= 1 (select :# ...)) ... `(values ,...))]
        (for [i 1 n] (table.insert let-syms (gensym)))
        (if (= n 0) `(values)
            `(let [,let-syms ,let-values] (values ,(unpack let-syms))))))
    
    (fn lambda [...]
      "Function literal with arity checking.
    Will throw an exception if a declared argument is passed in as nil, unless
    that argument name begins with ?."
      (let [args [...]
            has-internal-name? (sym? (. args 1))
            arglist (if has-internal-name? (. args 2) (. args 1))
            docstring-position (if has-internal-name? 3 2)
            has-docstring? (and (> (# args) docstring-position)
                                (= :string (type (. args docstring-position))))
            arity-check-position (- 4 (if has-internal-name? 0 1)
                                    (if has-docstring? 0 1))
            empty-body? (< (# args) arity-check-position)]
        (fn check! [a]
          (if (table? a)
              (each [_ a (pairs a)]
                (check! a))
              (and (not (string.match (tostring a) "^?"))
                   (not= (tostring a) "&")
                   (not= (tostring a) "..."))
              (table.insert args arity-check-position
                            `(assert (not= nil ,a)
                                     (string.format "Missing argument %s on %s:%s"
                                                    ,(tostring a)
                                                    ,(or a.filename "unknown")
                                                    ,(or a.line "?"))))))
        (assert (= :table (type arglist)) "expected arg list")
        (each [_ a (ipairs arglist)]
          (check! a))
        (if empty-body?
            (table.insert args (sym :nil)))
        `(fn ,(unpack args))))
    
    (fn macro [name ...]
      "Define a single macro."
      (assert (sym? name) "expected symbol for macro name")
      (local args [...])
      `(macros { ,(tostring name) (fn ,name ,(unpack args))}))
    
    (fn macrodebug [form return?]
      "Print the resulting form after performing macroexpansion.
    With a second argument, returns expanded form as a string instead of printing."
      (let [(ok view) (pcall require :fennelview)
            handle (if return? `do `print)]
        `(,handle ,((if ok view tostring) (macroexpand form _SCOPE)))))
    
    (fn import-macros [binding1 module-name1 ...]
      "Binds a table of macros from each macro module according to a binding form.
    Each binding form can be either a symbol or a k/v destructuring table.
    Example:
      (import-macros mymacros                 :my-macros    ; bind to symbol
                     {:macro1 alias : macro2} :proj.macros) ; import by name"
      (assert (and binding1 module-name1 (= 0 (% (select :# ...) 2)))
              "expected even number of binding/modulename pairs")
      (for [i 1 (select :# binding1 module-name1 ...) 2]
        (local (binding modname) (select i binding1 module-name1 ...))
        ;; generate a subscope of current scope, use require-macros
        ;; to bring in macro module. after that, we just copy the
        ;; macros from subscope to scope.
        (local scope (get-scope))
        (local subscope (fennel.scope scope))
        (fennel.compile-string (string.format "(require-macros %q)"
                                             modname)
                              {:scope subscope})
        (if (sym? binding)
            ;; bind whole table of macros to table bound to symbol
            (do (tset scope.macros (. binding 1) {})
                (each [k v (pairs subscope.macros)]
                  (tset (. scope.macros (. binding 1)) k v)))
    
            ;; 1-level table destructuring for importing individual macros
            (table? binding)
            (each [macro-name [import-key] (pairs binding)]
              (assert (= :function (type (. subscope.macros macro-name)))
                      (.. "macro " macro-name " not found in module " modname))
              (tset scope.macros import-key (. subscope.macros macro-name)))))
      nil)
    
    ;;; Pattern matching
    
    (fn match-pattern [vals pattern unifications]
      "Takes the AST of values and a single pattern and returns a condition
    to determine if it matches as well as a list of bindings to
    introduce for the duration of the body if it does match."
      ;; we have to assume we're matching against multiple values here until we
      ;; know we're either in a multi-valued clause (in which case we know the #
      ;; of vals) or we're not, in which case we only care about the first one.
      (let [[val] vals]
        (if (or (and (sym? pattern) ; unification with outer locals (or nil)
                     (not= :_ (tostring pattern)) ; never unify _
                     (or (in-scope? pattern)
                         (= :nil (tostring pattern))))
                (and (multi-sym? pattern)
                     (in-scope? (. (multi-sym? pattern) 1))))
            (values `(= ,val ,pattern) [])
            ;; unify a local we've seen already
            (and (sym? pattern)
                 (. unifications (tostring pattern)))
            (values `(= ,(. unifications (tostring pattern)) ,val) [])
            ;; bind a fresh local
            (sym? pattern)
            (let [wildcard? (= (tostring pattern) "_")]
              (if (not wildcard?) (tset unifications (tostring pattern) val))
              (values (if (or wildcard? (string.find (tostring pattern) "^?"))
                          true `(not= ,(sym :nil) ,val))
                      [pattern val]))
            ;; guard clause
            (and (list? pattern) (sym? (. pattern 2)) (= :? (tostring (. pattern 2))))
            (let [(pcondition bindings) (match-pattern vals (. pattern 1)
                                                       unifications)
                  condition `(and ,pcondition)]
              (for [i 3 (# pattern)] ; splice in guard clauses
                (table.insert condition (. pattern i)))
              (values `(let ,bindings ,condition) bindings))
    
            ;; multi-valued patterns (represented as lists)
            (list? pattern)
            (let [condition `(and)
                  bindings []]
              (each [i pat (ipairs pattern)]
                (let [(subcondition subbindings) (match-pattern [(. vals i)] pat
                                                                unifications)]
                  (table.insert condition subcondition)
                  (each [_ b (ipairs subbindings)]
                    (table.insert bindings b))))
              (values condition bindings))
            ;; table patterns
            (= (type pattern) :table)
            (let [condition `(and (= (type ,val) :table))
                  bindings []]
              (each [k pat (pairs pattern)]
                (if (and (sym? pat) (= "&" (tostring pat)))
                    (do (assert (not (. pattern (+ k 2)))
                                "expected rest argument before last parameter")
                        (table.insert bindings (. pattern (+ k 1)))
                        (table.insert bindings [`(select ,k ((or _G.unpack
                                                                 table.unpack)
                                                             ,val))]))
                    (and (= :number (type k))
                         (= "&" (tostring (. pattern (- k 1)))))
                    nil ; don't process the pattern right after &; already got it
                    (let [subval `(. ,val ,k)
                          (subcondition subbindings) (match-pattern [subval] pat
                                                                    unifications)]
                      (table.insert condition subcondition)
                      (each [_ b (ipairs subbindings)]
                        (table.insert bindings b)))))
              (values condition bindings))
            ;; literal value
            (values `(= ,val ,pattern) []))))
    
    (fn match-condition [vals clauses]
      "Construct the actual `if` AST for the given match values and clauses."
      (if (not= 0 (% (length clauses) 2)) ; treat odd final clause as default
          (table.insert clauses (length clauses) (sym :_)))
      (let [out `(if)]
        (for [i 1 (length clauses) 2]
          (let [pattern (. clauses i)
                body (. clauses (+ i 1))
                (condition bindings) (match-pattern vals pattern {})]
            (table.insert out condition)
            (table.insert out `(let ,bindings ,body))))
        out))
    
    (fn match-val-syms [clauses]
      "How many multi-valued clauses are there? return a list of that many gensyms."
      (let [syms (list (gensym))]
        (for [i 1 (length clauses) 2]
          (if (list? (. clauses i))
              (each [valnum (ipairs (. clauses i))]
                (if (not (. syms valnum))
                    (tset syms valnum (gensym))))))
        syms))
    
    (fn match [val ...]
      "Perform pattern matching on val. See reference for details."
      (let [clauses [...]
            vals (match-val-syms clauses)]
        ;; protect against multiple evaluation of the value, bind against as
        ;; many values as we ever match against in the clauses.
        (list `let [vals val]
              (match-condition vals clauses))))
    
    {: -> : ->> : -?> : -?>>
     : doto : when : with-open
     : partial : lambda
     : pick-args : pick-values
     : macro : macrodebug : import-macros
     : match}
    ]===]
    local module_name = "fennel.macros"
    local _ = nil
    local function _0_()
      return mod
    end
    package.preload[module_name] = _0_
    _ = nil
    local env = specials["make-compiler-env"](nil, compiler.scopes.compiler, {})
    local built_ins = eval(builtin_macros, {allowedGlobals = false, env = env, filename = "src/fennel/macros.fnl", moduleName = module_name, scope = compiler.scopes.compiler, useMetadata = true})
    for k, v in pairs(built_ins) do
      compiler.scopes.global.macros[k] = v
    end
    compiler.scopes.global.macros["\206\187"] = compiler.scopes.global.macros.lambda
    package.preload[module_name] = nil
  end
  return mod
end
fennel = require("fennel")
local searcher = fennel.makeSearcher({correlate = true})
if os.getenv("FNL") then
  table.insert((package.loaders or package.searchers), 1, searcher)
else
  table.insert((package.loaders or package.searchers), searcher)
end
local lex_setup = require("lang.lexer")
local parse = require("lang.parser")
local lua_ast = require("lang.lua_ast")
local reader = require("lang.reader")
local compiler = require("anticompiler")
local letter = require("letter")
local fnlfmt = require("fnlfmt")
local reserved_fennel = {band = true, bnot = true, bor = true, bxor = true, doc = true, doto = true, each = true, fn = true, global = true, hashfn = true, lambda = true, let = true, lshift = true, lua = true, macro = true, macrodebug = true, macroexpand = true, macros = true, match = true, partial = true, rshift = true, set = true, tset = true, values = true, var = true, when = true}
local function uncamelize(name)
  local function splicedash(pre, cap)
    return (pre .. "-" .. cap:lower())
  end
  return name:gsub("([a-z0-9])([A-Z])", splicedash)
end
local function mangle(name, field)
  if (not field and reserved_fennel[name]) then
    name = ("___" .. name .. "___")
  end
  return ((field and name) or uncamelize(name):gsub("([a-z0-9])_", "%1-"))
end
local function compile(rdr, filename)
  local ls = lex_setup(rdr, filename)
  local ast_builder = lua_ast.New(mangle)
  local ast_tree = parse(ast_builder, ls)
  return letter(compiler(nil, ast_tree))
end
if ((debug and debug.getinfo) and (debug.getinfo(3) == nil)) then
  local filename = arg[1]
  local f = (filename and io.open(filename))
  if f then
    f:close()
    for _, code in ipairs(compile(reader.file(filename), filename)) do
      print(fnlfmt.fnlfmt(code))
    end
    return nil
  else
    print(("Usage: %s LUA_FILENAME"):format(arg[0]))
    print("Compiles LUA_FILENAME to Fennel and prints output.")
    return os.exit(1)
  end
else
  local function _1_(str, source)
    local out = {}
    for _, code in ipairs(compile(reader.string(str), (source or "*source"))) do
      table.insert(out, fnlfmt.fnlfmt(code))
    end
    return table.concat(out, "\n")
  end
  return _1_
end