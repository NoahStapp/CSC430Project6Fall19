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
            t: %BoolV{b: true},
            f: %BoolV{b: false}
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
                fd = interp(expression.test, env)
                case fd do
                    %BoolV{} -> test = fd.b
                            case test do
                                true -> interp(expression.then, env)
                                false -> interp(expression.else, env)
                            end
                end
            %AppC{} -> 
                fd = interp(expression.fun, env)
                case fd do
                    %PrimV{} -> fd.op.(Enum.map(expression.args, fn arg -> interp(arg, env) end))
                end
            _ -> throw "Invalid expression"
        end
    end

    @spec myPlus(list(Value)) :: Value
    def myPlus(args) do   
        if length(args) == 2 do         
            %NumV{n: List.first(args).n + List.last(args).n}
        end
    end

    @spec mySub(list(Value)) :: Value
    def mySub(args) do   
        if length(args) == 2 do         
            %NumV{n: List.first(args).n - List.last(args).n}
        end
    end

    @spec myMult(list(Value)) :: Value
    def myMult(args) do   
        if length(args) == 2 do         
            %NumV{n: List.first(args).n * List.last(args).n}
        end
    end

    @spec myDiv(list(Value)) :: Value
    def myDiv(args) do   
        if length(args) == 2 and List.last(args).n != 0 do         
            %NumV{n: List.first(args).n / List.last(args).n}
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

    test "IfC" do
        assert Interpreter.interp(%IfC{test: %IdC{s: :t}, then: %NumC{n: 1}, else: %NumC{n: 2}},
         Env.createEnv()) == %NumV{n: 1}
        assert Interpreter.interp(%IfC{test: %IdC{s: :f}, then: %NumC{n: 1}, else: %NumC{n: 2}},
         Env.createEnv()) == %NumV{n: 2}
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
end