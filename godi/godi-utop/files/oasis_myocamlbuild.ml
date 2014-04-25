(*
 * myocamlbuild.ml
 * ---------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of utop.
 *)

(* OASIS_START *)
(* DO NOT EDIT (digest: 72e933ef97d8f6e337714850d90bdc16) *)
module OASISGettext = struct
(* # 22 "src/oasis\\OASISGettext.ml" *)


  let ns_ str =
    str


  let s_ str =
    str


  let f_ (str: ('a, 'b, 'c, 'd) format4) =
    str


  let fn_ fmt1 fmt2 n =
    if n = 1 then
      fmt1^^""
    else
      fmt2^^""


  let init =
    []


end

module OASISExpr = struct
(* # 22 "src/oasis\\OASISExpr.ml" *)





  open OASISGettext


  type test = string


  type flag = string


  type t =
    | EBool of bool
    | ENot of t
    | EAnd of t * t
    | EOr of t * t
    | EFlag of flag
    | ETest of test * string



  type 'a choices = (t * 'a) list


  let eval var_get t =
    let rec eval' =
      function
        | EBool b ->
            b

        | ENot e ->
            not (eval' e)

        | EAnd (e1, e2) ->
            (eval' e1) && (eval' e2)

        | EOr (e1, e2) ->
            (eval' e1) || (eval' e2)

        | EFlag nm ->
            let v =
              var_get nm
            in
              assert(v = "true" || v = "false");
              (v = "true")

        | ETest (nm, vl) ->
            let v =
              var_get nm
            in
              (v = vl)
    in
      eval' t


  let choose ?printer ?name var_get lst =
    let rec choose_aux =
      function
        | (cond, vl) :: tl ->
            if eval var_get cond then
              vl
            else
              choose_aux tl
        | [] ->
            let str_lst =
              if lst = [] then
                s_ "<empty>"
              else
                String.concat
                  (s_ ", ")
                  (List.map
                     (fun (cond, vl) ->
                        match printer with
                          | Some p -> p vl
                          | None -> s_ "<no printer>")
                     lst)
            in
              match name with
                | Some nm ->
                    failwith
                      (Printf.sprintf
                         (f_ "No result for the choice list '%s': %s")
                         nm str_lst)
                | None ->
                    failwith
                      (Printf.sprintf
                         (f_ "No result for a choice list: %s")
                         str_lst)
    in
      choose_aux (List.rev lst)


end


# 132 "myocamlbuild.ml"
module BaseEnvLight = struct
(* # 22 "src/base\\BaseEnvLight.ml" *)


  module MapString = Map.Make(String)


  type t = string MapString.t


  let default_filename =
    Filename.concat
      (Sys.getcwd ())
      "setup.data"


  let load ?(allow_empty=false) ?(filename=default_filename) () =
    if Sys.file_exists filename then
      begin
        let chn =
          open_in_bin filename
        in
        let st =
          Stream.of_channel chn
        in
        let line =
          ref 1
        in
        let st_line =
          Stream.from
            (fun _ ->
               try
                 match Stream.next st with
                   | '\n' -> incr line; Some '\n'
                   | c -> Some c
               with Stream.Failure -> None)
        in
        let lexer =
          Genlex.make_lexer ["="] st_line
        in
        let rec read_file mp =
          match Stream.npeek 3 lexer with
            | [Genlex.Ident nm; Genlex.Kwd "="; Genlex.String value] ->
                Stream.junk lexer;
                Stream.junk lexer;
                Stream.junk lexer;
                read_file (MapString.add nm value mp)
            | [] ->
                mp
            | _ ->
                failwith
                  (Printf.sprintf
                     "Malformed data file '%s' line %d"
                     filename !line)
        in
        let mp =
          read_file MapString.empty
        in
          close_in chn;
          mp
      end
    else if allow_empty then
      begin
        MapString.empty
      end
    else
      begin
        failwith
          (Printf.sprintf
             "Unable to load environment, the file '%s' doesn't exist."
             filename)
      end


  let rec var_expand str env =
    let buff =
      Buffer.create ((String.length str) * 2)
    in
      Buffer.add_substitute
        buff
        (fun var ->
           try
             var_expand (MapString.find var env) env
           with Not_found ->
             failwith
               (Printf.sprintf
                  "No variable %s defined when trying to expand %S."
                  var
                  str))
        str;
      Buffer.contents buff


  let var_get name env =
    var_expand (MapString.find name env) env


  let var_choose lst env =
    OASISExpr.choose
      (fun nm -> var_get nm env)
      lst
end


# 237 "myocamlbuild.ml"
module MyOCamlbuildFindlib = struct
(* # 22 "src/plugins/ocamlbuild\\MyOCamlbuildFindlib.ml" *)


  (** OCamlbuild extension, copied from
    * http://brion.inria.fr/gallium/index.php/Using_ocamlfind_with_ocamlbuild
    * by N. Pouillard and others
    *
    * Updated on 2009/02/28
    *
    * Modified by Sylvain Le Gall
    *)
  open Ocamlbuild_plugin


  (* these functions are not really officially exported *)
  let run_and_read =
    Ocamlbuild_pack.My_unix.run_and_read


  let blank_sep_strings =
    Ocamlbuild_pack.Lexers.blank_sep_strings


  let exec_from_conf exec =
    let exec =
      let env_filename = Pathname.basename BaseEnvLight.default_filename in
      let env = BaseEnvLight.load ~filename:env_filename ~allow_empty:true () in
      try
        BaseEnvLight.var_get exec env
      with Not_found ->
        Printf.eprintf "W: Cannot get variable %s\n" exec;
        exec
    in
    let fix_win32 str =
      if Sys.os_type = "Win32" then begin
        let buff = Buffer.create (String.length str) in
        (* Adapt for windowsi, ocamlbuild + win32 has a hard time to handle '\\'.
         *)
        String.iter
          (fun c -> Buffer.add_char buff (if c = '\\' then '/' else c))
          str;
        Buffer.contents buff
      end else begin
        str
      end
    in
      fix_win32 exec

  let split s ch =
    let buf = Buffer.create 13 in
    let x = ref [] in
    let flush () =
      x := (Buffer.contents buf) :: !x;
      Buffer.clear buf
    in
      String.iter
        (fun c ->
           if c = ch then
             flush ()
           else
             Buffer.add_char buf c)
        s;
      flush ();
      List.rev !x


  let split_nl s = split s '\n'


  let before_space s =
    try
      String.before s (String.index s ' ')
    with Not_found -> s

  (* ocamlfind command *)
  let ocamlfind x = S[Sh (
    Ocamlbuild_pack.Shell.quote_filename_if_needed
      (exec_from_conf "ocamlfind") ); x]

  (* This lists all supported packages. *)
  let find_packages () =
    List.map before_space (split_nl & run_and_read "ocamlfind list")


  (* Mock to list available syntaxes. *)
  let find_syntaxes () = ["camlp4o"; "camlp4r"]


  let well_known_syntax = [
    "camlp4.quotations.o";
    "camlp4.quotations.r";
    "camlp4.exceptiontracer";
    "camlp4.extend";
    "camlp4.foldgenerator";
    "camlp4.listcomprehension";
    "camlp4.locationstripper";
    "camlp4.macro";
    "camlp4.mapgenerator";
    "camlp4.metagenerator";
    "camlp4.profiler";
    "camlp4.tracer"
  ]


  let dispatch =
    function
      | After_options ->
          (* By using Before_options one let command line options have an higher
           * priority on the contrary using After_options will guarantee to have
           * the higher priority override default commands by ocamlfind ones *)
          Options.ocamlc     := ocamlfind & A"ocamlc";
          Options.ocamlopt   := ocamlfind & A"ocamlopt";
          Options.ocamldep   := ocamlfind & A"ocamldep";
          Options.ocamldoc   := ocamlfind & A"ocamldoc";
          Options.ocamlmktop := ocamlfind & A"ocamlmktop";
          Options.ocamlmklib := ocamlfind & A"ocamlmklib"

      | After_rules ->

          (* When one link an OCaml library/binary/package, one should use
           * -linkpkg *)
          flag ["ocaml"; "link"; "program"] & A"-linkpkg";

          (* For each ocamlfind package one inject the -package option when
           * compiling, computing dependencies, generating documentation and
           * linking. *)
          List.iter
            begin fun pkg ->
              let base_args = [A"-package"; A pkg] in
              (* TODO: consider how to really choose camlp4o or camlp4r. *)
              let syn_args = [A"-syntax"; A "camlp4o"] in
              let args =
              (* Heuristic to identify syntax extensions: whether they end in
                 ".syntax"; some might not.
               *)
                if Filename.check_suffix pkg "syntax" ||
                   List.mem pkg well_known_syntax then
                  syn_args @ base_args
                else
                  base_args
              in
              flag ["ocaml"; "compile";  "pkg_"^pkg] & S args;
              flag ["ocaml"; "ocamldep"; "pkg_"^pkg] & S args;
              flag ["ocaml"; "doc";      "pkg_"^pkg] & S args;
              flag ["ocaml"; "link";     "pkg_"^pkg] & S base_args;
              flag ["ocaml"; "infer_interface"; "pkg_"^pkg] & S args;
            end
            (find_packages ());

          (* Like -package but for extensions syntax. Morover -syntax is useless
           * when linking. *)
          List.iter begin fun syntax ->
          flag ["ocaml"; "compile";  "syntax_"^syntax] & S[A"-syntax"; A syntax];
          flag ["ocaml"; "ocamldep"; "syntax_"^syntax] & S[A"-syntax"; A syntax];
          flag ["ocaml"; "doc";      "syntax_"^syntax] & S[A"-syntax"; A syntax];
          flag ["ocaml"; "infer_interface"; "syntax_"^syntax] &
                S[A"-syntax"; A syntax];
          end (find_syntaxes ());

          (* The default "thread" tag is not compatible with ocamlfind.
           * Indeed, the default rules add the "threads.cma" or "threads.cmxa"
           * options when using this tag. When using the "-linkpkg" option with
           * ocamlfind, this module will then be added twice on the command line.
           *
           * To solve this, one approach is to add the "-thread" option when using
           * the "threads" package using the previous plugin.
           *)
          flag ["ocaml"; "pkg_threads"; "compile"] (S[A "-thread"]);
          flag ["ocaml"; "pkg_threads"; "doc"] (S[A "-I"; A "+threads"]);
          flag ["ocaml"; "pkg_threads"; "link"] (S[A "-thread"]);
          flag ["ocaml"; "pkg_threads"; "infer_interface"] (S[A "-thread"]);
          flag ["ocaml"; "package(threads)"; "compile"] (S[A "-thread"]);
          flag ["ocaml"; "package(threads)"; "doc"] (S[A "-I"; A "+threads"]);
          flag ["ocaml"; "package(threads)"; "link"] (S[A "-thread"]);
          flag ["ocaml"; "package(threads)"; "infer_interface"] (S[A "-thread"]);

      | _ ->
          ()
end

module MyOCamlbuildBase = struct
(* # 22 "src/plugins/ocamlbuild\\MyOCamlbuildBase.ml" *)


  (** Base functions for writing myocamlbuild.ml
      @author Sylvain Le Gall
    *)





  open Ocamlbuild_plugin
  module OC = Ocamlbuild_pack.Ocaml_compiler


  type dir = string
  type file = string
  type name = string
  type tag = string


(* # 62 "src/plugins/ocamlbuild\\MyOCamlbuildBase.ml" *)


  type t =
      {
        lib_ocaml: (name * dir list * string list) list;
        lib_c:     (name * dir * file list) list;
        flags:     (tag list * (spec OASISExpr.choices)) list;
        (* Replace the 'dir: include' from _tags by a precise interdepends in
         * directory.
         *)
        includes:  (dir * dir list) list;
      }


  let env_filename =
    Pathname.basename
      BaseEnvLight.default_filename


  let dispatch_combine lst =
    fun e ->
      List.iter
        (fun dispatch -> dispatch e)
        lst


  let tag_libstubs nm =
    "use_lib"^nm^"_stubs"


  let nm_libstubs nm =
    nm^"_stubs"


  let dispatch t e =
    let env =
      BaseEnvLight.load
        ~filename:env_filename
        ~allow_empty:true
        ()
    in
      match e with
        | Before_options ->
            let no_trailing_dot s =
              if String.length s >= 1 && s.[0] = '.' then
                String.sub s 1 ((String.length s) - 1)
              else
                s
            in
              List.iter
                (fun (opt, var) ->
                   try
                     opt := no_trailing_dot (BaseEnvLight.var_get var env)
                   with Not_found ->
                     Printf.eprintf "W: Cannot get variable %s\n" var)
                [
                  Options.ext_obj, "ext_obj";
                  Options.ext_lib, "ext_lib";
                  Options.ext_dll, "ext_dll";
                ]

        | After_rules ->
            (* Declare OCaml libraries *)
            List.iter
              (function
                 | nm, [], intf_modules ->
                     ocaml_lib nm;
                     let cmis =
                       List.map (fun m -> (String.uncapitalize m) ^ ".cmi")
                                intf_modules in
                     dep ["ocaml"; "link"; "library"; "file:"^nm^".cma"] cmis
                 | nm, dir :: tl, intf_modules ->
                     ocaml_lib ~dir:dir (dir^"/"^nm);
                     List.iter
                       (fun dir ->
                          List.iter
                            (fun str ->
                               flag ["ocaml"; "use_"^nm; str] (S[A"-I"; P dir]))
                            ["compile"; "infer_interface"; "doc"])
                       tl;
                     let cmis =
                       List.map (fun m -> dir^"/"^(String.uncapitalize m)^".cmi")
                                intf_modules in
                     dep ["ocaml"; "link"; "library"; "file:"^dir^"/"^nm^".cma"]
                         cmis)
              t.lib_ocaml;

            (* Declare directories dependencies, replace "include" in _tags. *)
            List.iter
              (fun (dir, include_dirs) ->
                 Pathname.define_context dir include_dirs)
              t.includes;

            (* Declare C libraries *)
            List.iter
              (fun (lib, dir, headers) ->
                   (* Handle C part of library *)
                   flag ["link"; "library"; "ocaml"; "byte"; tag_libstubs lib]
                     (S[A"-dllib"; A("-l"^(nm_libstubs lib)); A"-cclib";
                        A("-l"^(nm_libstubs lib))]);

                   flag ["link"; "library"; "ocaml"; "native"; tag_libstubs lib]
                     (S[A"-cclib"; A("-l"^(nm_libstubs lib))]);

                   flag ["link"; "program"; "ocaml"; "byte"; tag_libstubs lib]
                     (S[A"-dllib"; A("dll"^(nm_libstubs lib))]);

                   (* When ocaml link something that use the C library, then one
                      need that file to be up to date.
                    *)
                   dep ["link"; "ocaml"; "program"; tag_libstubs lib]
                     [dir/"lib"^(nm_libstubs lib)^"."^(!Options.ext_lib)];

                   dep  ["compile"; "ocaml"; "program"; tag_libstubs lib]
                     [dir/"lib"^(nm_libstubs lib)^"."^(!Options.ext_lib)];

                   (* TODO: be more specific about what depends on headers *)
                   (* Depends on .h files *)
                   dep ["compile"; "c"]
                     headers;

                   (* Setup search path for lib *)
                   flag ["link"; "ocaml"; "use_"^lib]
                     (S[A"-I"; P(dir)]);
              )
              t.lib_c;

              (* Add flags *)
              List.iter
              (fun (tags, cond_specs) ->
                 let spec = BaseEnvLight.var_choose cond_specs env in
                 let rec eval_specs =
                   function
                     | S lst -> S (List.map eval_specs lst)
                     | A str -> A (BaseEnvLight.var_expand str env)
                     | spec -> spec
                 in
                   flag tags & (eval_specs spec))
              t.flags
        | _ ->
            ()


  let dispatch_default t =
    dispatch_combine
      [
        dispatch t;
        MyOCamlbuildFindlib.dispatch;
      ]


end


# 596 "myocamlbuild.ml"
open Ocamlbuild_plugin;;
let package_default =
  {
     MyOCamlbuildBase.lib_ocaml =
       [
          ("optcomp", ["syntax"], []);
          ("utop", ["src/lib"], []);
          ("utop-camlp4", ["src/camlp4"], [])
       ];
     lib_c = [];
     flags = [];
     includes = [("src/top", ["src/lib"]); ("src/camlp4", ["src/lib"])]
  }
  ;;

let dispatch_default = MyOCamlbuildBase.dispatch_default package_default;;

# 615 "myocamlbuild.ml"
(* OASIS_STOP *)

let () =
  dispatch
    (fun hook ->
       dispatch_default hook;
       match hook with
         | Before_options ->
             Options.make_links := false

         | After_rules ->
             (* Copy tags from *.byte to *.top *)
             tag_file
               "src/top/uTop_top.top"
               (List.filter
                  (* Remove the "file:..." tag and syntax extensions. *)
                  (fun tag -> not (String.is_prefix "file:" tag) && not (String.is_suffix tag ".syntax"))
                  (Tags.elements (tags_of_pathname "src/top/uTop_top.byte")));

             (* Use -linkpkg for creating toplevels *)
             flag ["ocaml"; "link"; "toplevel"] & A"-linkpkg";

             let env = BaseEnvLight.load () in
             let path = BaseEnvLight.var_get "compiler_libs" env in
             let stdlib = BaseEnvLight.var_get "standard_library" env in

             let findlib_version = BaseEnvLight.var_get "findlib_version" env in
             let findlib_version =
               Scanf.sscanf findlib_version "%d.%d" (Printf.sprintf "findlib_version=(%d, %d)")
             in

             (* Optcomp *)
             let args =
               S[A"-ppopt"; A"syntax/pa_optcomp.cmo";
                 A"-ppopt"; A"-let"; A"-ppopt"; A findlib_version]
             in
             flag ["ocaml"; "compile"; "pa_optcomp"] args;
             flag ["ocaml"; "ocamldep"; "pa_optcomp"] args;
             flag ["ocaml"; "doc"; "pa_optcomp"] args;
             dep ["ocaml"; "ocamldep"; "pa_optcomp"] ["syntax/pa_optcomp.cmo"];

             (* Add directories for compiler-libraries: *)
             let paths = List.filter Sys.file_exists [path; path / "typing"; path / "parsing"; path / "utils"] in
             let paths = List.map (fun path -> S [A "-I"; A path]) paths in
             flag ["ocaml"; "compile"; "use_compiler_libs"] & S paths;
             flag ["ocaml"; "ocamldep"; "use_compiler_libs"] & S paths;
             flag ["ocaml"; "doc"; "use_compiler_libs"] & S paths;

             let paths = [A "-I"; A "+camlp5"] in
             flag ["ocaml"; "compile"; "use_camlp5"] & S paths;
             flag ["ocaml"; "ocamldep"; "use_camlp5"] & S paths;
             flag ["ocaml"; "doc"; "use_camlp5"] & S paths;

             (* Expunge compiler modules *)
             rule "toplevel expunge"
               ~dep:"src/top/uTop_top.top"
               ~prod:"src/top/uTop_top.byte"
               (fun _ _ ->
                  (* Build the list of explicit dependencies. *)
                  let packages =
                    Tags.fold
                      (fun tag packages ->
                         if String.is_prefix "pkg_" tag && not (String.is_suffix tag ".syntax") then
                           String.after tag 4 :: packages
                         else
                           packages)
                      (tags_of_pathname "src/top/uTop_top.byte")
                      []
                  in
                  (* Build the list of dependencies. *)
                  let deps = Findlib.topological_closure (List.rev_map Findlib.query packages) in
                  (* Build the set of locations of dependencies. *)
                  let locs = List.fold_left (fun set pkg -> StringSet.add pkg.Findlib.location set) StringSet.empty deps in
                  (* Directories to search for .cmi: *)
                  let directories = StringSet.add stdlib (StringSet.add (stdlib / "threads") locs) in
                  (* Construct the set of modules to keep by listing
                     .cmi files: *)
                  let modules =
                    StringSet.fold
                      (fun directory set ->
                         List.fold_left
                           (fun set fname ->
                              if Pathname.check_extension fname "cmi" then
                                StringSet.add (module_name_of_pathname fname) set
                              else
                                set)
                           set
                           (Array.to_list (Pathname.readdir directory)))
                      directories StringSet.empty
                  in
                  (* These are not in the stdlib path since 4.00 *)
                  let modules = StringSet.add "Toploop" modules in
                  let modules = StringSet.add "Topmain" modules in
                  Cmd (S [A (stdlib / "expunge");
                          A "src/top/uTop_top.top";
                          A "src/top/uTop_top.byte";
                          A "UTop"; A "UTop_private"; S(List.map (fun x -> A x) (StringSet.elements modules))]));

             rule "full toplevel (not expunged)"
               ~dep:"src/top/uTop_top.top"
               ~prod:"src/top/uTop_top_full.byte"
               (fun _ _ -> cp "src/top/uTop_top.top" "src/top/uTop_top_full.byte")
         | _ ->
             ())
