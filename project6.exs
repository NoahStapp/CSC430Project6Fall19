defmodule NumC do
    @enforce_keys [:n]
    defstruct [:n]
end

defmodule BinopC do
    @enforce_keys [:op, :l, :r]
    defstruct [:op, :l, :r]
end

defmodule ExprC do
    @type exprC :: NumC | BinopC
end
    
defmodule Interpreter do
    @spec interp(ExprC) :: integer()
    def interp(expression) do
        case expression do
            %NumC{} -> expression.n
            %BinopC{op: op, l: l, r: r} -> IO.puts getOp(op).(interp(l), interp(r))
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
    def main do
        Interpreter.interp(%BinopC{op: :+, l: %NumC{n: 1}, r: %NumC{n: 2}})
        Interpreter.interp(%BinopC{op: :-, l: %NumC{n: 1}, r: %NumC{n: 2}})
        Interpreter.interp(%BinopC{op: :*, l: %NumC{n: 2}, r: %NumC{n: 2}})
        Interpreter.interp(%BinopC{op: :/, l: %NumC{n: 6}, r: %NumC{n: 2}})
    end
end

Main.main