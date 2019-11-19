# hello_world.exs
defmodule Parser do
  def parse(val, a, b) do
    case val do
        :+ -> "%AppC{fun: %IdC{s: #{val}}, args: [%NumC{n: #{a}, %NumC{n: #{b}]}"
        :- -> "%AppC{fun: %IdC{s: #{val}}, args: [%NumC{n: #{a}, %NumC{n: #{b}]}"
        :/ -> "%AppC{fun: %IdC{s: #{val}}, args: [%NumC{n: #{a}, %NumC{n: #{b}]}"
        :* -> "%AppC{fun: %IdC{s: #{val}}, args: [%NumC{n: #{a}, %NumC{n: #{b}]}"
        :lam -> "%LamC {#{a}} #{b}"
        end
  end
  def parse(:-, a, b) do
   "%AppC{fun: %IdC{s: :-}, args: [%NumC{n: #{a}, %NumC{n: #{b}]}"
  end
  def parse(:/, a, b) do
   "%AppC{fun: %IdC{s: :/}, args: [%NumC{n: #{a}, %NumC{n: #{b}]}"
  end
  def parse(:*, a, b) do
   "%AppC{fun: %IdC{s: :*}, args: [%NumC{n: #{a}, %NumC{n: #{b}]}"
  end
  def parse(:lam, a, b) do
   "%AppC{fun: %IdC{s: :*}, args: [%NumC{n: #{a}, %NumC{n: #{b}]}"
  end
  def parse(:if, a, b, c) do
   "if {fun: %IdC{s: :*}, args: [%NumC{n: #{a}, %NumC{n: #{b}]}"
  end
  def say_hello(:jane), do: "Hi there, Jane!"
  def say_hello(name) do # name is a variable that gets assigned
    "Whatever, #{name}."
  end

end