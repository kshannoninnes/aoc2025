defmodule Day6 do
  def part1(input) do
    lines =
      input
      |> String.split("\n", trim: true)

    {operators, operands} = List.pop_at(lines, -1)

    operators = String.split(operators)

    operands =
      operands
      |> Enum.map(&String.split/1)
      |> Enum.map(&to_int_list/1)
      |> Enum.zip_with(fn a -> a end)

    solve_the_math(operators, operands)
  end

  def part2(input) do
    lines =
      input
      |> String.split("\n", trim: true)

    {operators, operands} = List.pop_at(lines, -1)

    operators = String.split(operators)

    operands =
      operands
      |> transpose_digits()
      |> group_by_expression()
      |> Enum.map(&to_int_list/1)

    solve_the_math(operators, operands)
  end

  defp solve_the_math(operators, operands) do
    operators

    # Pair each operator with its corresponding list of operands.
    #
    # Example:
    #  operators: ["*", "+"]
    #  operands:  [[123, 45, 6], [328, 64, 98]]
    #  result:    [{"*", [123, 45, 6]}, {"+", [328, 64, 98]}]
    |> Enum.zip(operands)
    |> Enum.reduce(0, fn expression, total -> total + eval(expression) end)
  end

  # Pattern match on each expression to determine which operation to perform
  defp eval({"*", operands}), do: Enum.reduce(operands, 1, &*/2)
  defp eval({"+", operands}), do: Enum.sum(operands)

  defp to_int_list(string_list) do
    Enum.map(string_list, &String.to_integer/1)
  end

  # Transpose digits from row major to column major
  #
  # Example:
  #  before: ["123", " 45", "  6"]
  #  after:  ["1", "24", "356"]
  defp transpose_digits(lines) do
    lines
    |> Enum.map(&String.graphemes/1)
    |> Enum.zip()
    |> Enum.map(fn tuple ->
      tuple
      |> Tuple.to_list()
      |> Enum.join()
      |> String.trim()
    end)
  end

  # Group transposed columns into expressions, splitting wherever a blank column appears.
  #
  # nums follows the pattern:
  #   [expr1, "", expr2, "", ...]
  #
  # Blank entries act as separators between expressions.
  #
  # Example:
  #   before: ["1", "24", "356", "", "369", "248", "8"]
  #   after:  [["1", "24", "356"], ["369", "248", "8"]]
  defp group_by_expression(nums) do
    nums
    |> Enum.chunk_by(fn str -> str == "" end)
    |> Enum.take_every(2)
  end
end
