(* Code generation: translate takes a semantically checked AST and
produces LLVM IR

LLVM tutorial: Make sure to read the OCaml version of the tutorial

http://llvm.org/docs/tutorial/index.html

Detailed documentation on the OCaml LLVM library:

http://llvm.moe/
http://llvm.moe/ocaml/
*)

module L = Llvm
module A = Ast

module StringMap = Map.Make(String)
module String = String


let translate (globals, functions) =
  let context = L.global_context () in
  let the_module = L.create_module context "Genesis" in
    ignore(L.set_data_layout "e-m:o-i64:64-f80:128-n8:16:32:64-S128" the_module); (* sets data layout to match machine *)
  let i64_t = L.i64_type context in
  let i32_t = L.i32_type  context in
  let i8_t  = L.i8_type   context in
  let i1_t  = L.i1_type   context in
  let flt_t =  L.double_type context in
  let pointer_t = L.pointer_type in
  let void_t = L.void_type context in

(*   let ut_hash_handle_t = L.named_struct_type context "UT_hash_handle" in 
  let ut_hash_table_t = L.named_struct_type context "UT_hash_table" in
  let ut_hash_bucket_t = L.named_struct_type context "UT_hash_bucket" in
    L.struct_set_body ut_hash_handle_t [|L.pointer_type ut_hash_table_t; L.pointer_type i8_t; L.pointer_type i8_t; L.pointer_type ut_hash_handle_t; L.pointer_type ut_hash_handle_t; L.pointer_type i8_t; i32_t; i32_t|] false; 
    L.struct_set_body ut_hash_table_t  [|L.pointer_type ut_hash_bucket_t; i32_t; i32_t; i32_t; L.pointer_type ut_hash_handle_t; i64_t; i32_t; i32_t; i32_t; i32_t; i32_t|] false;
    L.struct_set_body ut_hash_bucket_t [|L.pointer_type ut_hash_handle_t; i32_t; i32_t|] false;
 *)
  let color_t = L.named_struct_type context "color" in
    L.struct_set_body color_t [| i32_t ; i32_t ; i32_t |] false; (* need to change here if source file changes *)
  let col_ptr_t = L.pointer_type color_t in

  let cluster_t = i32_t in
(*   let position_t = L.named_struct_type context "position" in
    L.struct_set_body position_t [| i32_t ; i32_t |] false;

  let cluster_t = L.named_struct_type context "cluster" in
    L.struct_set_body cluster_t [| position_t ; color_t ; i32_t ; i32_t ; L.pointer_type i8_t ; L.pointer_type cluster_t ; ut_hash_handle_t|] false;
  let board_t = L.named_struct_type context "board" in
    L.struct_set_body board_t [| L.pointer_type i8_t ; color_t ; i32_t ; i32_t ; L.pointer_type cluster_t ; ut_hash_handle_t |] false;
 *)
  let rec ltype_of_typ = function
      A.Int -> i32_t
    | A.Float -> flt_t
    | A.String -> pointer_t i8_t
    | A.Bool -> i1_t
    | A.Void -> void_t 
    | A.Color -> col_ptr_t
    | A.Cluster -> cluster_t
(*
    | A.Struct -> pointer_t void_t
*)
    | A.ArrayType(t) -> pointer_t (ltype_of_typ t)

  in

  (* Declare each global variable; remember its value in a map *)
  let global_vars =
    let global_var m (t, n) =
      let init = L.const_int (ltype_of_typ t) 0
      in StringMap.add n (L.define_global n init the_module) m in
    List.fold_left global_var StringMap.empty globals in


  (* Declare printf(), which the print built-in function will call *)
  let printf_t = L.var_arg_function_type i32_t [| L.pointer_type i8_t |] in
  let printf_func = L.declare_function "printf" printf_t the_module in

  (* Declare the built-in printbig() function *)
  let printbig_t = L.function_type i32_t [| i32_t |] in
  let printbig_func = L.declare_function "printbig" printbig_t the_module in

  (* Declare function for making a new board *)
  (*   let initScreen_t = L.function_type i32_t [| i32_t; i32_t ; color_t |] in
  let initScreen = L.declare_function "initScreen" initScreen_t the_module in *)

  let initScreen_t = L.function_type i32_t [| L.pointer_type color_t; i32_t; i32_t |] in
  let initScreen_func = L.declare_function "initScreen" initScreen_t the_module in

  (*let add_cluster_t = L.function_type (L.void_type context) [| L.pointer_type gb_t] in
  let add_cluster = L.declare_function "addCluster" add_cluster_t the_module in*)

  let startGame_t = L.function_type void_t [| L.pointer_type color_t; i32_t; i32_t |] in
  let startGame_func = L.declare_function "startGame" startGame_t the_module in

  let isKeyDown_t = L.function_type i1_t [| pointer_t i8_t |] in
  let isKeyDown_func = L.declare_function "isKeyDown" isKeyDown_t the_module in

  let isKeyUp_t = L.function_type i1_t [| pointer_t i8_t |] in
  let isKeyUp_func = L.declare_function "isKeyUp" isKeyUp_t the_module in

  let isKeyHeld_t = L.function_type i1_t [| pointer_t i8_t |] in
  let isKeyHeld_func = L.declare_function "isKeyHeld" isKeyHeld_t the_module in

  let newCluster_t = L.function_type i32_t [|i32_t; i32_t; i32_t; i32_t; i32_t; i32_t; col_ptr_t |] in
  let newCluster_func = L.declare_function "newCluster" newCluster_t the_module in

  let randomInt_t = L.function_type i32_t [|i32_t|] in
  let randomInt_func = L.declare_function "randomInt" randomInt_t the_module in

  let getX_t = L.function_type i32_t [|i32_t|] in
  let getX_func = L.declare_function "getX" getX_t the_module in

  let getY_t = L.function_type i32_t [|i32_t|] in
  let getY_func = L.declare_function "getY" getY_t the_module in

  let getDX_t = L.function_type i32_t [|i32_t|] in
  let getDX_func = L.declare_function "getDX" getDX_t the_module in

  let getDY_t = L.function_type i32_t [|i32_t|] in
  let getDY_func = L.declare_function "getDY" getDY_t the_module in

  let getHeight_t = L.function_type i32_t [|i32_t|] in
  let getHeight_func = L.declare_function "getHeight" getHeight_t the_module in

  let getWidth_t = L.function_type i32_t [|i32_t|] in
  let getWidth_func = L.declare_function "getWidth" getWidth_t the_module in

  let getColor_t = L.function_type col_ptr_t [|i32_t|] in
  let getColor_func = L.declare_function "getColor" getColor_t the_module in

  let setX_t = L.function_type i32_t [|i32_t; i32_t|] in
  let setX_func = L.declare_function "setX" setX_t the_module in

  let setY_t = L.function_type void_t [|i32_t; i32_t|] in
  let setY_func = L.declare_function "setY" setY_t the_module in

  let setDX_t = L.function_type void_t [|i32_t; i32_t|] in
  let setDX_func = L.declare_function "setDX" setDX_t the_module in

  let setDY_t = L.function_type void_t [|i32_t; i32_t|] in
  let setDY_func = L.declare_function "setDY" setDY_t the_module in

  let setHeight_t = L.function_type void_t [|i32_t; i32_t|] in
  let setHeight_func = L.declare_function "setHeight" setHeight_t the_module in

  let setWidth_t = L.function_type void_t [|i32_t; i32_t|] in
  let setWidth_func = L.declare_function "setWidth" setWidth_t the_module in

  let setColor_t = L.function_type void_t [|i32_t; col_ptr_t|] in
  let setColor_func = L.declare_function "setColor" setColor_t the_module in

  (* Define each function (arguments and return type) so we can call it *)
  let function_decls =
    let function_decl m fdecl =
      let name = fdecl.A.fname
      and formal_types =
  Array.of_list (List.map (fun (t,_) -> ltype_of_typ t) fdecl.A.formals)
      in let ftype = L.function_type (ltype_of_typ fdecl.A.typ) formal_types in
      StringMap.add name (L.define_function name ftype the_module, fdecl) m in
    List.fold_left function_decl StringMap.empty functions in

  (* Cast int to float *)
  let make_float var builder =
    if L.type_of var = flt_t then
      var 
    else if L.type_of var = i32_t || L.type_of var = i64_t then
      L.build_sitofp var flt_t "" builder
    else if L.type_of var = (pointer_t flt_t) then
      L.build_load var "" builder
    else
      raise (Failure ("Unknown cast to float"))
    in

  (* Cast float to int, don't modify bools *)
  let make_int var builder = 
    if L.type_of var = i32_t || L.type_of var = i64_t || 
       L.type_of var = i8_t  || L.type_of var = i1_t then
      var
    else if L.type_of var = flt_t then
      L.build_fptosi var i32_t "" builder
    else if L.type_of var = (pointer_t i32_t) || L.type_of var = (pointer_t i64_t) then
      L.build_load var "" builder 
    else
      raise (Failure ("Unknown cast to int"))
    in
  
  (* Fill in the body of the given function *)
  let build_function_body fdecl =
    let (the_function, _) = StringMap.find fdecl.A.fname function_decls in
    let builder = L.builder_at_end context (L.entry_block the_function) in

    let int_format_str = L.build_global_stringptr "%d\n" "fmt" builder in
    let float_format_str = L.build_global_stringptr "%lf\n" "fmt" builder in
    let string_format_str = L.build_global_stringptr "%s\n" "fmt" builder in
    
    (* Construct the function's "locals": formal arguments and locally
       declared variables.  Allocate each on the stack, initialize their
       value, if appropriate, and remember their values in the "locals" map *)

    let local_vars =
      let add_formal m (t, n) p = L.set_value_name n p;
      let local = L.build_alloca (ltype_of_typ t) n builder in
        ignore (L.build_store p local builder);
    StringMap.add n local m in


      let add_local m (t, n) =
        let local_var = L.build_alloca (ltype_of_typ t) n builder
        in StringMap.add n local_var m in

      let formals = List.fold_left2 add_formal StringMap.empty fdecl.A.formals
          (Array.to_list (L.params the_function)) in
      List.fold_left add_local formals fdecl.A.locals in

    (* Return the value (usually a memory address) for a variable or formal argument *)
    let lookup n = try StringMap.find n local_vars
      with Not_found -> StringMap.find n global_vars
    in

    (* Get array value of name at index i *)
    let get_array_element name i builder = 
      let arr = L.build_load (lookup name) "" builder in
      let ptr = L.build_gep arr [| i |] "" builder in
      L.build_load ptr "" builder
    in

    (* Set array element of name at index i to val *)
    let set_array_element name i v builder = 
      let arr = L.build_load (lookup name) "" builder in
      let ptr = L.build_gep arr [| i |] "" builder in
      L.build_store v ptr builder
    in

    (* Initializes array of typ of size len *)
    let init_array name typ len builder =
      let malloc = L.build_array_malloc (ltype_of_typ typ) len "" builder in
      L.build_store malloc (lookup name) builder
    in

    (* Construct code for an expression; return its value *)
    let rec expr builder = function
        A.Literal i -> L.const_int i32_t i
      | A.StringLit s -> L.build_global_stringptr s "tmp" builder
      | A.FloatLit fl -> L.const_float flt_t fl
      | A.BoolLit b -> L.const_int i1_t (if b then 1 else 0)
      | A.ColorLit (r, g, b) -> 
        let ctmp = L.build_alloca color_t "color_tmp" builder in
(*           ignore(L.set_alignment 4 ctmp); *)
        let cptr = L.build_alloca (L.pointer_type color_t) "clr_ptr" builder in
(*           ignore(L.set_alignment 8 cptr); *)
        let e1 = expr builder r 
        and e2 = expr builder g 
        and e3 = expr builder b in

        let rtmp = L.build_struct_gep ctmp 0 "r" builder in 
          ignore (L.build_store e1 rtmp builder);
        let gtmp = L.build_struct_gep ctmp 1 "g" builder in 
          ignore (L.build_store e2 gtmp builder);
        let btmp = L.build_struct_gep ctmp 2 "b" builder in 
          ignore (L.build_store e3 btmp builder);
(*         let rtmp = L.build_in_bounds_gep ctmp [| L.const_int i32_t 0 ; L.const_int i32_t 0|] "r" builder in
        let rstr = L.build_store e1 rtmp builder in
(*           ignore(L.set_alignment 4 rstr); *)
        let gtmp = L.build_in_bounds_gep ctmp [| L.const_int i32_t 0; L.const_int i32_t 1|] "g" builder in
        let gstr = L.build_store e2 rtmp builder in 
(*           ignore(L.set_alignment 4 gstr); *)
        let btmp = L.build_in_bounds_gep ctmp [| L.const_int i32_t 0; L.const_int i32_t 2|] "b" builder in
        let  bstr = L.build_store e3 rtmp builder in
(*           ignore(L.set_alignment 4 bstr); *) *)
        let colstr = L.build_store ctmp cptr builder in
(*           ignore(L.set_alignment 8 colstr); *)
        let colld = L.build_load cptr "" builder in
(*           ignore(L.set_alignment 8 colld); *)
        colld
      | A.ClusterLit (l, w, x, y, dx, dy, c)->
        let xPos = expr builder x in
        let yPos = expr builder y in
        let xVel = expr builder dx in
        let yVel = expr builder dy in 
        let len = expr builder l in
        let wid = expr builder w in
        let color = expr builder c in

        L.build_call newCluster_func [| len; wid; xPos; yPos; xVel; yVel; color|] "newClust" builder
(*         let name = expr builder c in
        let clustPtr = L.build_malloc cluster_t ("clustPtr") builder in
        let posPtr = L.build_struct_gep clustPtr 0 ("posPtr") builder in
        let colorPtr = L.build_struct_gep clustPtr 1 ("colorPtr") builder in
        let heightPtr = L.build_struct_gep clustPtr 2 ("heightPtr") builder in
        let widthPtr = L.build_struct_gep clustPtr 3 ("widthPtr") builder in
        let name_ptr = L.build_struct_gep clustPtr 4 ("name ptr") builder in
        let next_ptr = L.build_struct_gep clustPtr 5 ("nextPtr") builder in
        let handle_ptr = L.build_struct_gep clustPtr 6 ("handle_ptr") builder in
        clustPtr *)
        
      | A.Noexpr -> L.const_int i32_t 0
      | A.Id s -> L.build_load (lookup s) s builder
      | A.Property s -> L.const_int i32_t 0
      | A.PropertyAccess(c, p) ->
        let cluster = expr builder c in
        (match p with
        | "x" -> L.build_call getX_func [|cluster|] "xVal" builder
        | "y" -> L.build_call getY_func [|cluster|] "yVal" builder
        | "dx" -> L.build_call getDX_func [|cluster|] "dxVal" builder
        | "dy" -> L.build_call getDY_func [|cluster|] "dyVal" builder  
        | "height" -> L.build_call getHeight_func [|cluster|] "hVal" builder
        | "width" -> L.build_call getWidth_func [|cluster|] "wVal" builder              
        | "color" -> L.build_call getColor_func [|cluster|] "colVal" builder              
        | _ -> raise (Failure ("Property does not exist"))
        )
      | A.PropertyAssign(c, p, e) ->
        let cluster = expr builder c in
        let e' = expr builder e in
        (match p with
        | "x" -> L.build_call setX_func [|cluster; e'|] "" builder
        | "y" -> L.build_call setY_func [|cluster; e'|] "" builder
        | "dx" -> L.build_call setDX_func [|cluster; e'|] "" builder
        | "dy" -> L.build_call setDY_func [|cluster; e'|] "" builder  
        | "height" -> L.build_call setHeight_func [|cluster; e'|] "" builder
        | "width" -> L.build_call setWidth_func [|cluster; e'|] "" builder              
        | "color" -> L.build_call setColor_func [|cluster; e'|] "" builder              
        | _ -> raise (Failure ("Property does not exist"))
        )
      | A.ArrayAccess(s, e) -> get_array_element s (expr builder e) builder
      | A.ArrayInit(s, typ, e) -> let len = (expr builder e) in 
          init_array s typ len builder
      | A.ArrayAssign(s, lhs, rhs) -> 
          set_array_element s (expr builder lhs) (expr builder rhs) builder
      | A.Binop (e1, op, e2) ->
    let e1' = expr builder e1
    and e2' = expr builder e2 in
    if (L.type_of e1' = i32_t && L.type_of e2' = i32_t) then
      (match op with
          A.Add     -> L.build_add
        | A.Sub     -> L.build_sub
        | A.Mult    -> L.build_mul
        | A.Div     -> L.build_sdiv
        | A.And     -> L.build_and
        | A.Or      -> L.build_or
        | A.Equal   -> L.build_icmp L.Icmp.Eq
        | A.Neq     -> L.build_icmp L.Icmp.Ne
        | A.Less    -> L.build_icmp L.Icmp.Slt
        | A.Leq     -> L.build_icmp L.Icmp.Sle
        | A.Greater -> L.build_icmp L.Icmp.Sgt
        | A.Geq     -> L.build_icmp L.Icmp.Sge
      ) e1' e2' "tmp" builder
    else if (L.type_of e1' = flt_t || L.type_of e2' = flt_t) then
      (match op with
          A.Add     -> L.build_fadd
        | A.Sub     -> L.build_fsub
        | A.Mult    -> L.build_fmul
        | A.Div     -> L.build_fdiv
        | A.Equal   -> L.build_fcmp L.Fcmp.Oeq
        | A.Neq     -> L.build_fcmp L.Fcmp.One
        | A.Less    -> L.build_fcmp L.Fcmp.Olt
        | A.Leq     -> L.build_fcmp L.Fcmp.Ole
        | A.Greater -> L.build_fcmp L.Fcmp.Ogt
        | A.Geq     -> L.build_fcmp L.Fcmp.Oge
        | _         -> raise (Failure ("incompatible operator-operand for number")) (* Should never be reached *)
      ) (make_float e1' builder) (make_float e2' builder) "tmp" builder
    else 
      (match op with
          A.And     -> L.build_and
        | A.Or      -> L.build_or
        | _         -> raise (Failure ("incompatible operator-operand")) (* Should never be reached *)
      ) e1' e2' "tmp" builder

    | A.Unop(op, e) ->
    let e' = expr builder e in

    (match op with
        A.Neg     -> L.build_neg
      | A.Not     -> L.build_not) e' "tmp" builder

      | A.Assign (s, e) -> let e' = expr builder e in
        if L.type_of (lookup s) = (L.pointer_type i32_t) then
          ignore (L.build_store (make_int e' builder) (lookup s) builder) (* Handle float to int downcast *)
        else if L.type_of (lookup s) = (L.pointer_type flt_t) then
          ignore (L.build_store (make_float e' builder) (lookup s) builder) (* Handle int to float upcast *)
        else
          ignore (L.build_store e' (lookup s) builder) (* Normal assignment for everything else *)
        ; e' (* Fixes bug in test-func2 *)

      | A.Call ("printfl", [e]) -> 
          L.build_call printf_func [| float_format_str ; make_float (expr builder e) builder |]
          "printf" builder 
      | A.Call ("print", [e]) | A.Call ("printb", [e]) ->
          L.build_call printf_func [| int_format_str ; make_int (expr builder e) builder |]
          "printf" builder
      | A.Call ("printbig", [e]) ->
          L.build_call printbig_func [| (expr builder e) |] "printbig" builder
(* external function -- for testing *)
      | A.Call ("initScreen", [w; h; c]) -> 
          let width = expr builder w 
          and height = expr builder h
          and color = expr builder c in
(*             ignore(L.set_alignment 8 color);
 *)(*           and clr_ptr = L.build_alloca (L.pointer_type color_t) "colorptr" builder in
          ignore(L.build_store color clr_ptr builder) ; *)
          L.build_call initScreen_func [| color; width; height |] "initScreen" builder
      | A.Call ("startGame", [w; h; c]) -> 
          let width = expr builder w 
          and height = expr builder h
          and color = expr builder c in
(*             ignore(L.set_alignment 8 color);
 *)(*           and clr_ptr = L.build_alloca (L.pointer_type color_t) "colorptr" builder in
          ignore(L.build_store color clr_ptr builder) ; *)
          L.build_call startGame_func [| color; width; height |] "" builder  
      | A.Call ("keyDown", [s]) ->
          let keyName = expr builder s in
          L.build_call isKeyDown_func [|keyName|] "keyD" builder
      | A.Call ("keyUp", [s]) ->
          let keyName = expr builder s in
          L.build_call isKeyUp_func [|keyName|] "keyU" builder
      | A.Call ("keyHeld", [s]) ->
          let keyName = expr builder s in
          L.build_call isKeyHeld_func [|keyName|] "keyH" builder
      | A.Call ("random", [e]) ->
          let maxInt = expr builder e in
          L.build_call randomInt_func [|maxInt|] "randInt" builder
      | A.Call ("prints", [e]) ->
          L.build_call printf_func [| string_format_str ; (expr builder e) |] "printf" builder
      | A.Call (f, act) ->
          let (fdef, fdecl) = StringMap.find f function_decls in
          let actuals = List.rev (List.map (expr builder) (List.rev act)) in
          let result = (match fdecl.A.typ with A.Void -> ""
        | _ -> f ^ "_result") in
          L.build_call fdef (Array.of_list actuals) result builder
    in

    (* Invoke "f builder" if the current block doesn't already
       have a terminal (e.g., a branch). *)
    let add_terminal builder f =
      match L.block_terminator (L.insertion_block builder) with
  Some _ -> ()
      | None -> ignore (f builder) in
  
    (* Build the code for the given statement; return the builder for
       the statement's successor *)
    let rec stmt builder = function
  A.Block sl -> List.fold_left stmt builder sl
      | A.Expr e -> ignore (expr builder e); builder
      | A.Return e -> ignore (match fdecl.A.typ with
    A.Void -> L.build_ret_void builder
  | _ -> L.build_ret (expr builder e) builder); builder
      | A.If (predicate, then_stmt, else_stmt) ->
         let bool_val = expr builder predicate in
   let merge_bb = L.append_block context "merge" the_function in

   let then_bb = L.append_block context "then" the_function in
   add_terminal (stmt (L.builder_at_end context then_bb) then_stmt)
     (L.build_br merge_bb);

   let else_bb = L.append_block context "else" the_function in
   add_terminal (stmt (L.builder_at_end context else_bb) else_stmt)
     (L.build_br merge_bb);

   ignore (L.build_cond_br bool_val then_bb else_bb builder);
   L.builder_at_end context merge_bb

      | A.While (predicate, body) ->
    let pred_bb = L.append_block context "while" the_function in
    ignore (L.build_br pred_bb builder);

    let body_bb = L.append_block context "while_body" the_function in
    add_terminal (stmt (L.builder_at_end context body_bb) body)
      (L.build_br pred_bb);

    let pred_builder = L.builder_at_end context pred_bb in
    let bool_val = expr pred_builder predicate in

    let merge_bb = L.append_block context "merge" the_function in
    ignore (L.build_cond_br bool_val body_bb merge_bb pred_builder);
    L.builder_at_end context merge_bb

      | A.For (e1, e2, e3, body) -> stmt builder
      ( A.Block [A.Expr e1 ; A.While (e2, A.Block [body ; A.Expr e3]) ] )
    in

    (* Build the code for each statement in the function *)
    let builder = stmt builder (A.Block fdecl.A.body) in

    (* Add a return if the last block falls off the end *)
    add_terminal builder (match fdecl.A.typ with
        A.Void -> L.build_ret_void
      | t -> L.build_ret (L.const_int (ltype_of_typ t) 0))
  in

  List.iter build_function_body functions;
  the_module
