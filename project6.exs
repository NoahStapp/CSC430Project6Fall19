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
    
defmodule Interpreter do
    @spec interp(ExprC) :: Value
    def interp(expression) do
        case expression do
            %NumC{} -> %NumV{n: expression.n}
            %StringC{} -> %StringV{s: expression.s}
            %BinopC{op: op, l: l, r: r} -> %NumV{n: getOp(op).(interp(l).n, interp(r).n)}
            _ -> throw "Invalid expression"
        end
    end

    def getOp(op) do
        case op do
            :+ -> &myPlus/2
            :- -> &mySub/2
            :* -> &myMult/2
            :/ -> &myDiv/2
        end
    end

    def myPlus(l, r) do
        l + r
    end

    def mySub(l, r) do
        l - r
    end

    def myMult(l, r) do
        l * r
    end

    def myDiv(l, r) do
        l / r
    end
end

defmodule Main do
    use ExUnit.Case

    test "numC" do
        assert Interpreter.interp(%NumC{n: 1}) == %NumV{n: 1}
    end

    test "stringC" do
        assert Interpreter.interp(%StringC{s: "Test"}) == %StringV{s: "Test"}
    end

    test "+ binop" do
        assert Interpreter.interp(%BinopC{op: :+, l: %NumC{n: 1}, r: %NumC{n: 2}}) == %NumV{n: 3}
    end

    test "- binop" do
        Interpreter.interp(%BinopC{op: :-, l: %NumC{n: 1}, r: %NumC{n: 2}}) == %NumV{n: -1}
    end

    test "* binop" do
        Interpreter.interp(%BinopC{op: :*, l: %NumC{n: 2}, r: %NumC{n: 2}}) == %NumV{n: -4}
    end

    test "/ binop" do
        Interpreter.interp(%BinopC{op: :/, l: %NumC{n: 6}, r: %NumC{n: 2}}) == %NumV{n: 3}
    end
end