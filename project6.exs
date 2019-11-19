ExUnit.start()

defmodule ExprC do
    @type exprC :: NumC | BinopC | StringC | IdC | AppC | IfC | LamC
end

defmodule NumC do
    @enforce_keys [:n]
    defstruct [:n]

    @type t :: %NumC{n: float}
end

defmodule StringC do
    @enforce_keys [:s]
    defstruct [:s]

    @type t :: %StringC{s: String.t()}
end

defmodule IdC do
    @enforce_keys [:s]
    defstruct [:s]

    @type t :: %IdC{s: atom}
end

defmodule AppC do
    @enforce_keys [:fun, :args]
    defstruct [:fun, :args]

    @type t :: %AppC{fun: ExprC, args: list(atom)}
end

defmodule IfC do
    @enforce_keys [:test, :then, :else]
    defstruct [:test, :then, :else]

     @type t :: %IfC{test: ExprC, then: ExprC, else: ExprC}
end

defmodule LamC do
    @enforce_keys [:params, :body]
    defstruct [:params, :body]

     @type t :: %LamC{params: list(atom), body: ExprC}
end

defmodule Value do
    @type value :: NumV | BoolV | StringV | ClosV | PrimV
end

defmodule NumV do
    @enforce_keys [:n]
    defstruct [:n]

     @type t :: %NumV{n: float}
end

defmodule BoolV do
    @enforce_keys [:b]
    defstruct [:b]

     @type t :: %BoolV{b: boolean}
end

defmodule StringV do
    @enforce_keys [:s]
    defstruct [:s]

     @type t :: %StringV{s: String.t()}
end

defmodule ClosV do
    @enforce_keys [:params, :body, :env]
    defstruct [:params, :body, :env]

     @type t :: %ClosV{params: list(atom), body: ExprC, env: ExprC}
end

defmodule PrimV do
    @enforce_keys [:op]
    defstruct [:op]

     @type t :: %PrimV{op: (list(Value) -> Value)}
end

defmodule BinopC do
    @enforce_keys [:op, :l, :r]
    defstruct [:op, :l, :r]
end

defmodule Env do
    @type env :: %{atom => [Value]}

    @spec createEnv() :: env
    def createEnv() do
        %{
            +: %PrimV{op: &Interpreter.myPlus/1},
            -: %PrimV{op: &Interpreter.mySub/1},
            *: %PrimV{op: &Interpreter.myMult/1},
            /: %PrimV{op: &Interpreter.myDiv/1},
            <=: %PrimV{op: &Interpreter.leq?/1},
            equal?: %PrimV{op: &Interpreter.equ?/1},
            true: %BoolV{b: true},
            false: %BoolV{b: false}
        }
    end
end
    
defmodule Interpreter do
    @spec interp(ExprC, Env) :: Value
    def interp(expression, env) do
        case expression do
            %NumC{} -> %NumV{n: expression.n}
            %StringC{} -> %StringV{s: expression.s}
            %IdC{} -> env[expression.s]
            %LamC{} -> %ClosV{params: expression.params, body: expression.body, env: env}
            %IfC{} -> 
                test = interp(expression.test, env)
                case test do
                    %BoolV{} -> if test.b do
                                    interp(expression.then, env)
                                else
                                    interp(expression.else, env)
                                end
                    _ -> throw "Non-boolean test condition"
                end
            %AppC{} -> 
                fd = interp(expression.fun, env)
                case fd do
                    %PrimV{} -> fd.op.(Enum.map(expression.args, fn arg -> interp(arg, env) end))
                    %ClosV{} ->
                        env2 = evaluate(env, fd.env, fd.params, expression.args)
                        interp(fd.body, env2)
                end
            _ -> throw IO.puts expression
        end
    end

    @spec evaluate(Env, Env, list(atom), list(ExprC)) :: Env
    def evaluate(env, cenv, parms, actual) do
        cond do
            length(parms) == 0 ->
                cond do
                    length(actual) == 0 -> cenv
                    true -> throw "Too many args given"
                end
            length(actual) == 0 -> throw "Not enough args given"
            true ->
                evaluate(env, Map.put(cenv, List.first(parms), interp(List.first(actual), env)), List.delete_at(actual, 0), List.delete_at(parms, 0))
        end
    end

    @spec myPlus(list(Value)) :: Value
    def myPlus(args) do   
        if length(args) == 2 do         
            %NumV{n: List.first(args).n + List.last(args).n}
        else
            throw "Invalid args to +"
        end
    end

    @spec mySub(list(Value)) :: Value
    def mySub(args) do   
        if length(args) == 2 do         
            %NumV{n: List.first(args).n - List.last(args).n}
        else
            throw "Invalid args to -"
        end
    end

    @spec myMult(list(Value)) :: Value
    def myMult(args) do   
        if length(args) == 2 do         
            %NumV{n: List.first(args).n * List.last(args).n}
        else
            throw "Invalid args to *"
        end
    end

    @spec myDiv(list(Value)) :: Value
    def myDiv(args) do   
        if length(args) == 2 and List.last(args).n != 0 do         
            %NumV{n: List.first(args).n / List.last(args).n}
        else
            throw "Invalid args to /"
        end
    end

    @spec leq?(list(Value)) :: Value
    def leq?(args) do
        if length(args) == 2 do
            %BoolV{b: List.first(args).n <= List.last(args).n}
        else
            throw "Invalid args to <="
        end
    end

    @spec equ?(list(Value)) :: Value
    def equ?(args) do
        if length(args) == 2 do
            case List.first(args) do
                %NumV{} -> 
                    case List.last(args) do
                        %NumV{} -> %BoolV{b: List.first(args).n == List.last(args).n}
                        _ -> throw "Invalid equal?"
                    end
                %BoolV{} -> 
                    case List.last(args) do
                        %BoolV{} -> %BoolV{b: List.first(args).b == List.last(args).b}
                        _ -> throw "Invalid equal?"
                    end
                %StringV{} -> 
                    case List.last(args) do
                        %StringV{} -> %BoolV{b: List.first(args).s == List.last(args).s}
                        _ -> throw "Invalid equal?"
                    end
                _ -> %BoolV{b: false}
            end
        else
            throw "Invalid args to equal?"
        end
    end
end

defmodule Main do
    use ExUnit.Case

    test "NumC" do
        assert Interpreter.interp(%NumC{n: 1}, Env.createEnv()) == %NumV{n: 1}
    end

    test "StringC" do
        assert Interpreter.interp(%StringC{s: "Test"}, Env.createEnv()) == %StringV{s: "Test"}
    end

    test "IdC" do
        assert Interpreter.interp(%IdC{s: :test}, %{test: %NumV{n: 1}}) == %NumV{n: 1}

        assert Interpreter.interp(%IdC{s: :+}, Env.createEnv()) 
        == %PrimV{op: &Interpreter.myPlus/1}
    end

    test "LamC" do
        assert Interpreter.interp(%LamC{params: [:x], body: %NumC{n: 1}},
         Env.createEnv()) == 
        %ClosV{params: [:x], body: %NumC{n: 1}, env: Env.createEnv()}
    end

    test "appC - closure" do
        assert Interpreter.interp(%AppC{
            fun: %LamC{params: [:x], body: %AppC{fun: %IdC{s: :*}, args: [%NumC{n: 3}, %IdC{s: :x}]}},
            args: [%NumC{n: 7}]}, Env.createEnv()) == %NumV{n: 21}
    end
    
    test "IfC" do
        assert Interpreter.interp(%IfC{test: %IdC{s: :true}, then: %NumC{n: 1}, else: %NumC{n: 2}},
         Env.createEnv()) == %NumV{n: 1}
        assert Interpreter.interp(%IfC{test: %IdC{s: :false}, then: %NumC{n: 1}, else: %NumC{n: 2}},
         Env.createEnv()) == %NumV{n: 2}
    end
         
    test "nested primops" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :*}, 
        args: [
            %AppC{fun: %IdC{s: :+}, 
                args: [%NumC{n: 1}, %NumC{n: 2}]},
            %AppC{fun: %IdC{s: :+}, 
                args: [%NumC{n: 1}, %NumC{n: 2}]}
        ]}, 
        Env.createEnv()) == %NumV{n: 9}
    end

    test "+" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :+}, 
        args: [%NumC{n: 1}, %NumC{n: 2}]}, 
        Env.createEnv()) == %NumV{n: 3}
    end

    test "-" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :-}, 
        args: [%NumC{n: 1}, %NumC{n: 2}]}, 
        Env.createEnv()) == %NumV{n: -1}
    end

    test "*" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :*}, 
        args: [%NumC{n: 2}, %NumC{n: 2}]}, 
        Env.createEnv()) == %NumV{n: 4}
    end

    test "/" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :/}, 
        args: [%NumC{n: 6}, %NumC{n: 3}]}, 
        Env.createEnv()) == %NumV{n: 2}
    end

    test "<=" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :<=}, 
        args: [%NumC{n: 2}, %NumC{n: 1}]}, 
        Env.createEnv()) == %BoolV{b: false}

        assert Interpreter.interp(%AppC{fun: %IdC{s: :<=}, 
        args: [%NumC{n: 1}, %NumC{n: 2}]}, 
        Env.createEnv()) == %BoolV{b: true}
    end

    test "equal? nums" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :equal?}, 
        args: [%NumC{n: 1}, %NumC{n: 1}]}, 
        Env.createEnv()) == %BoolV{b: true}

        assert Interpreter.interp(%AppC{fun: %IdC{s: :equal?}, 
        args: [%NumC{n: 1}, %NumC{n: 2}]}, 
        Env.createEnv()) == %BoolV{b: false}
    end

    test "equal? bools" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :equal?}, 
        args: [%IdC{s: :true}, %IdC{s: :true}]}, 
        Env.createEnv()) == %BoolV{b: true}

        assert Interpreter.interp(%AppC{fun: %IdC{s: :equal?}, 
        args: [%IdC{s: :true}, %IdC{s: :false}]}, 
        Env.createEnv()) == %BoolV{b: false}
    end

    test "equal? strings" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :equal?}, 
        args: [%StringC{s: "theSame"}, %StringC{s: "theSame"}]}, 
        Env.createEnv()) == %BoolV{b: true}

        assert Interpreter.interp(%AppC{fun: %IdC{s: :equal?}, 
        args: [%StringC{s: "theSame"}, %StringC{s: "different"}]}, 
        Env.createEnv()) == %BoolV{b: false}
    end

    test "equal? else" do
        assert Interpreter.interp(%AppC{fun: %IdC{s: :equal?}, 
        args: [
            %LamC{params: [:x], body: %NumC{n: 1}},
            %LamC{params: [:x], body: %NumC{n: 1}}
        ]}, 
        Env.createEnv()) == %BoolV{b: false}
    end

    test "equal? error" do
        catch_throw Interpreter.interp(%AppC{fun: %IdC{s: :equal?}, 
        args: [
            %NumC{n: 1},
            %LamC{params: [:x], body: %NumC{n: 1}}
        ]}, 
        Env.createEnv())

        catch_throw Interpreter.interp(%AppC{fun: %IdC{s: :equal?}, 
        args: [
            %NumC{n: 1},
            %NumC{n: 1},
            %NumC{n: 1}
        ]}, 
        Env.createEnv())
    end

    test "arthimetic error" do
        catch_throw Interpreter.interp(%AppC{fun: %IdC{s: :+}, 
        args: [
            %NumC{n: 1},
            %NumC{n: 1},
            %NumC{n: 1}
        ]}, 
        Env.createEnv())
    end
end