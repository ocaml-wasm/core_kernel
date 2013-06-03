open Std_internal
open Container

module Test_generic
         (Elt : sig
            type 'a t
            val of_int : int -> int t
            val to_int : int t -> int
          end)
         (Container : sig
            type 'a t with sexp
            include Generic
              with type 'a t := 'a t
              with type 'a elt := 'a Elt.t
            val of_list : 'a Elt.t list -> 'a t
          end)
  (* This signature constraint reminds us to add unit tests when functions are added to
     [Generic]. *)
  : sig
    type 'a t with sexp
    include Generic with type 'a t := 'a t
  end
  with type 'a t := 'a Container.t
  with type 'a elt := 'a Elt.t
  = struct

    open Container

    let find      = find
    let find_map  = find_map
    let fold      = fold
    let is_empty  = is_empty
    let iter      = iter
    let length    = length
    let mem       = mem
    let sexp_of_t = sexp_of_t
    let t_of_sexp = t_of_sexp
    let to_array  = to_array
    let to_list   = to_list

    TEST_UNIT =
      List.iter [ 0; 1; 2; 3; 4; 8; 1024 ] ~f:(fun n ->
        let list = List.init n ~f:Elt.of_int in
        let c = Container.of_list list in
        let sort l = List.sort l ~cmp:compare in
        let sorts_are_equal l1 l2 = sort l1 = sort l2 in
        assert (n = Container.length c);
        assert ((n = 0) = Container.is_empty c);
        assert (sorts_are_equal list
                  (Container.fold c ~init:[] ~f:(fun ac e -> e :: ac)));
        assert (sorts_are_equal list (Container.to_list c));
        assert (sorts_are_equal list (Array.to_list (Container.to_array c)));
        assert (n > 0 = is_some (Container.find c ~f:(fun e -> Elt.to_int e = 0)));
        assert (n > 0 = is_some (Container.find c ~f:(fun e -> Elt.to_int e = n - 1)));
        assert (is_none (Container.find c ~f:(fun e -> Elt.to_int e = n)));
        assert (n > 0 = Container.mem c (Elt.of_int 0));
        assert (n > 0 = Container.mem c (Elt.of_int (n - 1)));
        assert (not (Container.mem c (Elt.of_int n)));
        assert (n > 0 = is_some (Container.find_map c ~f:(fun e ->
                                   if Elt.to_int e = 0 then Some () else None)));
        assert (n > 0 = is_some (Container.find_map c ~f:(fun e ->
                                   if Elt.to_int e = n - 1 then Some () else None)));
        assert (is_none (Container.find_map c ~f:(fun e ->
                           if Elt.to_int e = n then Some () else None)));
        let r = ref 0 in
        Container.iter c ~f:(fun e -> r := !r + Elt.to_int e);
        assert (!r = List.fold list ~init:0 ~f:(fun n e -> n + Elt.to_int e));
        let c2 = <:of_sexp< int Container.t >> (<:sexp_of< int Container.t >> c) in
        assert (sorts_are_equal list (Container.to_list c2))
      );
    ;;

    let count   = count
    let exists  = exists
    let for_all = for_all

    TEST_UNIT =
      List.iter [ [];
                  [true];
                  [false];
                  [false; false];
                  [true; false];
                  [false; true];
                  [true; true];
                ]
        ~f:(fun bools ->
          let count_should_be =
            List.fold bools ~init:0 ~f:(fun n b -> if b then n + 1 else n)
          in
          let forall_should_be = List.fold bools ~init:true  ~f:(fun ac b -> b && ac) in
          let exists_should_be = List.fold bools ~init:false ~f:(fun ac b -> b || ac) in
          let container =
            Container.of_list
              (List.map bools ~f:(fun b -> Elt.of_int (if b then 1 else 0)))
          in
          let is_one e = Elt.to_int e = 1 in
          assert (forall_should_be = Container.for_all container ~f:is_one);
          assert (exists_should_be = Container.exists  container ~f:is_one);
          assert (count_should_be = Container.count container ~f:is_one);
        )
    ;;

  end

module Test_S1 =
  Test_generic (struct
    type 'a t = 'a
    let of_int = Fn.id
    let to_int = Fn.id
  end)

include (Test_S1 (Array)         : sig end)
include (Test_S1 (Bag)           : sig end)
include (Test_S1 (Doubly_linked) : sig end)
include (Test_S1 (Linked_stack)  : sig end)
include (Test_S1 (List)          : sig end)
include (Test_S1 (Queue)         : sig end)
include (Test_S1 (Core_stack)    : sig end)
