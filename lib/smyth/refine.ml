open Lang

let filter (ws : worlds) : worlds =
  List.filter (fun (_env, ex) -> ex <> ExTop) ws

let refine _delta sigma ((gamma, goal_type, goal_dec), worlds) =
  let open Option2.Syntax in
  let* _ =
    Option2.guard (Option.is_none goal_dec)
  in
  let
    filtered_worlds =
      filter worlds
  in
    match goal_type with
      (* Refine-Fix *)

      | TArr (tau1, tau2) ->
          let hole_name =
            Fresh.gen_hole ()
          in
          let f_name =
            Term_gen.fresh_ident
              gamma
              Term_gen.function_char
          in
          let x_name =
            Term_gen.fresh_ident
              gamma
              Term_gen.variable_char
          in
          let+ refined_worlds =
            filtered_worlds
              |> List.map
                   ( fun (env, io_ex) ->
                       match io_ex with
                         | ExInputOutput (v, ex) ->
                             Some
                               ( Env.concat_res
                                   [ ( x_name
                                     , Res.from_value v
                                     )
                                   ; ( f_name
                                     , RFix
                                         ( env
                                         , Some f_name
                                         , PatParam (PVar x_name)
                                         , EHole hole_name
                                         )
                                     )
                                   ]
                                   env
                               , ex
                               )

                         | _ ->
                             None
                   )
              |> Option2.sequence
          in
          let new_goal =
            ( hole_name
            , ( ( Type_ctx.concat_type
                    [ (f_name, (TArr (tau1, tau2), Rec f_name))
                    ; (x_name, (tau1, Arg f_name))
                    ]
                    gamma
                , tau2
                , None
                )
              , refined_worlds
              )
            )
          in
          let exp =
            EFix
              ( Some f_name
              , PatParam (PVar x_name)
              , EHole hole_name
              )
          in
            (exp, [new_goal])

      (* Refine-Tuple *)

      | TTuple taus ->
          let* refined_worldss =
            filtered_worlds
              |> List.map
                   ( fun (env, tuple_ex) ->
                       match tuple_ex with
                         | ExTuple exs ->
                             Some (List.map (fun ex -> (env, ex)) exs)

                         | _ ->
                             None
                   )
              |> Option2.sequence
              |> Option2.map List2.transpose
          in
            if List.length refined_worldss <> List.length taus then
              None
            else
              let new_goals =
                List.map2
                  ( fun tau refined_worlds ->
                      ( Fresh.gen_hole ()
                      , ((gamma, tau, None), refined_worlds)
                      )
                  )
                  taus
                  refined_worldss
              in
              let exp =
                ETuple
                  ( List.map
                      (fun (hole_name, _) -> EHole hole_name)
                      new_goals
                  )
              in
                Some (exp, new_goals)

      (* Refine-Ctor *)

      | TData (datatype_name, datatype_args) ->
          let* (datatype_params, datatype_ctors) =
            List.assoc_opt datatype_name sigma
          in
          let* (ctor_name, refined_worlds) =
            filtered_worlds
              |> List.map
                   ( fun (env, ctor_ex) ->
                       match ctor_ex with
                         | ExCtor (ctor_name, arg_ex) ->
                             Some (ctor_name, (env, arg_ex))

                         | _ ->
                             None
                   )
              |> Option2.sequence
              |> Option2.and_then
                   ( List.split
                       >> Pair2.map_fst List2.collapse_equal
                       >> Option2.sequence_fst
                   )
          in
          let+ arg_type =
            List.assoc_opt ctor_name datatype_ctors
              |> Option.map
                   ( Type.substitute_many
                       ~bindings:
                         ( List.combine
                             datatype_params
                             datatype_args
                         )
                   )
          in
          let hole_name =
            Fresh.gen_hole ()
          in
          let new_goal =
            ( hole_name
            , ((gamma, arg_type, None), refined_worlds)
            )
          in
          let exp =
            ECtor
              ( ctor_name
              , datatype_args
              , EHole hole_name
              )
          in
            (exp, [new_goal])

      (* Refine-TAbs *)

      (* Not really necessary, for now *)
      | TForall (_, _) ->
          None

      (* Cannot refine a type variable *)

      | TVar _ ->
          None

let eval_resume_coerce : env -> hole_filling -> exp -> value option =
  fun env hf exp ->
    match Eval.eval env exp with
      | Ok (r, []) ->
          begin match Eval.resume hf r with
            | Ok (r', []) ->
                Res.to_value r'

            | _ ->
                None
          end

      | _ ->
          None

let refine_app :
 hole_ctx ->
 datatype_ctx ->
 hole_filling ->
 synthesis_goal ->
 (exp * fill_goal list) Nondet.t =
  fun _delta _sigma hf ((_gamma, goal_type, goal_dec), worlds) ->
    let open Nondet.Syntax in
    let* _ =
      Nondet.guard (Option.is_none goal_dec)
    in
    let
      filtered_worlds =
        filter worlds
    in
    let tau1 =
      TData ("NatList", [])
    in
    let tau2 =
      TData ("NatList", [])
    in
    let tau_final =
      TArr (tau1, TArr (tau2, goal_type))
    in
    let arg1 =
      EProj (2, 1, EVar "y1")
    in
    let arg2 =
      EApp (false, EVar "concat", EAExp (EProj (2, 2, EVar "y1")))
    in
    let+ final_worlds =
      filtered_worlds
        |> List.map
             ( fun (env, ex) ->
                 let open! Option2.Syntax in
                 let* v1 =
                   eval_resume_coerce env hf arg1
                 in
                 let+ v2 =
                   eval_resume_coerce env hf arg2
                 in
                 ( env
                 , ExInputOutput
                     ( v1
                     , ExInputOutput
                         ( v2
                         , ex
                         )
                     )
                 )
             )
        |> Option2.sequence
        |> Nondet.lift_option
    in
    let hole_name =
      Fresh.gen_hole ()
    in
    let new_goal =
      ( hole_name
      , ((Type_ctx.empty, tau_final, None), final_worlds)
      )
    in
    let exp =
      EApp
        ( false
        , EApp
            ( false
            , EHole hole_name
            , EAExp arg1
            )
        , EAExp arg2
        )
    in
    (exp, [new_goal])
