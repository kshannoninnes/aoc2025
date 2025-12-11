defmodule Day10 do
  import Bitwise

  def part1(input) do
    regex =
      &Regex.scan(~r/^\s*(\[[.#]+\])\s+((?:\(\d+(?:,\d+)*\)\s+)+)\s*(\{\d+(?:,\d+)*\})\s*$/, &1)

    machines =
      input
      |> String.split("\n")
      |> Enum.flat_map(regex)

      # Drop the "full string" match, we're only interested in the captures
      |> Enum.map(&Enum.drop(&1, 1))

      # Ignore the joltages part, irrelevent for part 1
      # Convert the light patterns and buttons into integer masks to enable bitwise operations
      |> Enum.map(fn [lights, buttons, _] ->
        light_mask = pattern_to_integer_mask(lights)
        button_mask = buttons_to_integer_masks(buttons, String.length(lights) - 2)

        {light_mask, button_mask}
      end)

    machines
    |> Enum.map(fn {goal, buttons} ->
      find_light_pattern_path(MapSet.new(), MapSet.new(buttons), goal, buttons)
    end)
    |> Enum.sum()
  end

  # The following 3 functions simply convert the string representations
  # of light patterns and buttons to integers to use as masks for bitwise
  # operations. Nothing particularly fancy involved.

  defp pattern_to_integer_mask(lights) do
    lights
    |> String.slice(1..-2//1)
    |> String.graphemes()
    |> Enum.reduce(0, fn c, acc ->
      acc <<< 1 ||| if c == "#", do: 1, else: 0
    end)
  end

  defp buttons_to_integer_masks(string_of_buttons, binary_width) do
    string_of_buttons
    |> String.split()
    |> Enum.map(fn button_str ->
      button_to_integer_mask(button_str, binary_width)
    end)
  end

  defp button_to_integer_mask(button_str, binary_width) do
    indices =
      button_str
      |> String.trim_leading("(")
      |> String.trim_trailing(")")
      |> String.split(",", trim: true)
      |> Enum.map(&String.to_integer/1)

    Enum.reduce(indices, 0, fn index, mask ->
      bitpos = binary_width - 1 - index
      mask ||| 1 <<< bitpos
    end)
  end

  # Custom BFS over a simplistic state machine
  # A button operation is essentially an XOR of the current state and the button mask
  #
  # First we mark that we've visited the current to_visit states, then
  # we apply the button operations to each to_visit state, then use these
  # new visited/to_visit sets to recurse to the next level of the tree, until
  # we find our goal. This is guaranteed to get us the shortest path in the
  # fewest possible steps.
  #
  # For example:
  #   Goal        = [..#.] -> binary 0010 -> integer 2
  #   Some Button = (1,3)  -> binary 0101 -> integer 5
  #   Some State  = [....] -> binary 0000 -> integer 0
  #   0 XOR 5     = integer 5 -> binary 0101 -> [.#.#]
  #
  #   5 != 2 therefore recurse with 5 as one of the new states
  defp find_light_pattern_path(visited, current_states, goal, buttons, depth \\ 1) do
    if goal in current_states do
      depth
    else
      new_visited = MapSet.union(visited, current_states)

      new_states =
        for button <- buttons, state <- current_states do
          bxor(button, state)
        end
        |> Enum.reject(&MapSet.member?(new_visited, &1))
        |> MapSet.new()

      find_light_pattern_path(new_visited, new_states, goal, buttons, depth + 1)
    end
  end
end
