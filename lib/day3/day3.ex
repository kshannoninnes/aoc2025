defmodule Day3 do
  def part1(input) do
    input
    |> String.split("\n")
    |> Enum.map(fn row -> solve(row, 2) end)
    |> Enum.sum()
  end

  def part2(input) do
    input
    |> String.split("\n")
    |> Enum.map(fn row -> solve(row, 12) end)
    |> Enum.sum()
  end

  def solve(line, num_digits) do
    line
    |> String.graphemes()
    |> Enum.map(&String.to_integer/1)
    |> max_from_subsequence(num_digits, [])
    |> Integer.undigits() # Convert list of digits into a single whole number
  end

  defp max_from_subsequence(_digits, 0, acc) do
    Enum.reverse(acc)
  end

  defp max_from_subsequence(digits, num_digits, acc) do
    max_pos = length(digits) - num_digits

    {max_digit, max_index} =
      digits
      |> Enum.take(max_pos + 1)             # Get the sublist starting from max_pos + 1
      |> Enum.with_index()                  # Include the index of each digit as a {digit, index} tuple
      |> Enum.max_by(fn {d, _i} -> d end)   # Get the max digit from this sublist

    # split the current list into a new list starting after max_index
    {_, new_list} = Enum.split(digits, max_index + 1)

    # Run the algorithm again using:
    # the new list starting after max_digit
    # a num_digits - 1 to account for us choosing a max_digit
    # and the current running list of digits we've chosen
    max_from_subsequence(new_list, num_digits - 1, [max_digit | acc])
  end
end
