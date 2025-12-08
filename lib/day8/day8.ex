defmodule Day8 do
  def part1(input) do
    coords_list =
      input
      |> String.split("\n", trim: true)
      |> Enum.map(&to_coordinates/1)

    coords_list
    |> build_all_edges()

    # sort by distance
    |> Enum.sort_by(&elem(&1, 1))

    # take 10 (sample) or 1000 (real) shortest edges
    |> Enum.take(1000)

    # list of MapSet circuits
    |> build_circuits()

    # circuit sizes
    |> Enum.map(&MapSet.size/1)
    |> Enum.sort(:desc)
    |> Enum.take(3)
    |> Enum.product()
  end

  def part2(input) do
    coords_list =
      input
      |> String.split("\n", trim: true)
      |> Enum.map(&to_coordinates/1)

    total_coord_count = length(coords_list)

    edges =
      coords_list
      |> build_all_edges()

      # sort by distance
      |> Enum.sort_by(&elem(&1, 1))

    {_, {{first_coord, second_coord}, _distance}} =
      Enum.reduce_while(edges, {[], nil}, fn edge, {circuits, last_edge} ->
        {{first, second}, _} = edge

        # This coord pair is already connected inside a circuit: skip it.
        if coords_in_same_circuit?(circuits, first, second) do
          {:cont, {circuits, last_edge}}
        else
          updated_circuits = add_edge_to_circuits(circuits, first, second)

          # All coords connected, stop and get last edge for math stuff
          if all_coords_connected?(updated_circuits, total_coord_count) do
            {:halt, {updated_circuits, edge}}
          else
            {:cont, {updated_circuits, edge}}
          end
        end
      end)

    {x1, _y1, _z1} = first_coord
    {x2, _y2, _z2} = second_coord

    x1 * x2
  end


  defp to_coordinates(row) do
    row

    # "x, y, z"
    |> String.split(",", trim: true)
    |> Enum.map(&String.to_integer/1)

    # {x, y, z}
    |> List.to_tuple()
  end

  defp get_distance({x1, y1, z1}, {x2, y2, z2}) do
    ((x1 - x2) ** 2 + (y1 - y2) ** 2 + (z1 - z2) ** 2) ** 0.5
  end

  # Returns a list of {{start, end}, distance}
  defp build_all_edges(coords_list) do
    coords_list
    |> Enum.with_index()
    |> Enum.flat_map(fn {coord_a, idx_a} ->
      coords_list
      |> Enum.drop(idx_a + 1)
      |> Enum.map(fn coord_b ->
        {{coord_a, coord_b}, get_distance(coord_a, coord_b)}
      end)
    end)
  end

  # Reduce edges into a list of circuits (each a MapSet of coordinates).
  defp build_circuits(edges) do
    Enum.reduce(edges, [], fn {{a, b}, _dist}, circuits ->
      add_edge_to_circuits(circuits, a, b)
    end)
  end

  # Add one edge (first, second) into the current list of circuits.
  #
  # Input:
  #   circuits: a list of circuits, where each circuit is a set of coord tuples
  #   first/second: coord tuples to connect
  #
  # Output:
  #   a new list of circuits reflecting the updated connections after linking first and second
  #
  # Examples for each case:
  #
  # 1) Neither coord is in any circuit
  #
  #      circuits = [ [{1,1,1}, {2,2,2}] ]
  #      first    = {10,10,10}
  #      second   = {11,11,11}
  #
  #      return [
  #        [{10,10,10}, {11,11,11}],
  #        [{1,1,1}, {2,2,2}]
  #      ]
  #
  # 2) First coord is in a circuit, second is not
  #
  #      circuits = [ [{1,1,1}, {2,2,2}] ]
  #      first    = {2,2,2}
  #      second   = {3,3,3}
  #
  #      return [
  #        [{1,1,1}, {2,2,2}, {3,3,3}]
  #      ]
  #
  # 3) Second coord is in a circuit, first is not
  #
  #      circuits = [ [{5,5,5}, {6,6,6}] ]
  #      first    = {9,9,9}
  #      second   = {6,6,6}
  #
  #      return [
  #        [{5,5,5}, {6,6,6}, {9,9,9}]
  #      ]
  #
  # 4) Both coords already belong to the same circuit
  #
  #      circuits = [ [{1,1,1}, {2,2,2}, {3,3,3}] ]
  #      first    = {1,1,1}
  #      second   = {3,3,3}
  #
  #      return [
  #        [{1,1,1}, {2,2,2}, {3,3,3}]
  #      ]
  #
  # 5) Coords belong to different circuits, merge them
  #
  #      circuits = [
  #        [{1,1,1}, {2,2,2}],
  #        [{9,9,9}, {8,8,8}]
  #      ]
  #      first    = {2,2,2}
  #      second   = {9,9,9}
  #
  #      return [
  #        [{1,1,1}, {2,2,2}, {9,9,9}, {8,8,8}]
  #      ]
  defp add_edge_to_circuits(circuits, first, second) do
    {found_circuit_a, circuits_with_first} =
      remove_circuit(circuits, first)

    {found_circuit_b, circuits_without_first_or_second} =
      remove_circuit(circuits_with_first, second)

    updated_circuit =
      case {found_circuit_a, found_circuit_b} do
        {nil, nil} ->
          # neither coord in any circuit: start a new circuit
          MapSet.new([first, second])

        {circuit_a, nil} ->
          # only a is in a circuit: add b
          MapSet.put(circuit_a, second)

        {nil, circuit_b} ->
          # only b is in a circuit: add a
          MapSet.put(circuit_b, first)

        {circuit, circuit} ->
          # both already in the same circuit: nothing changes
          circuit

        {circuit_a, circuit_b} ->
          # endpoints in different circuits: merge them
          MapSet.union(circuit_a, circuit_b)
      end

    [updated_circuit | circuits_without_first_or_second]
  end

  # Find and remove the first circuit containing coord
  # If no circuit is found containing coord, return circuits unchanged
  defp remove_circuit(circuits, coord) do
    {circuits_without_coord, circuits_with_coord} =
      Enum.split_with(circuits, fn circuit ->
        not MapSet.member?(circuit, coord)
      end)

    case circuits_with_coord do
      # Found a circuit with coord in it
      # Return a tuple of {found_coord, circuit_with_coord_removed}
      # This effectively removes the coord from the circuit
      [found_coord | circuit_with_coord_removed] ->
        {found_coord, circuits_without_coord ++ circuit_with_coord_removed}

      # No circuits found with coord in them
      # Return circuits unchanged
      [] ->
        {nil, circuits}
    end
  end

  defp coords_in_same_circuit?(circuits, first, second) do
    Enum.any?(circuits, fn circuit ->
      MapSet.member?(circuit, first) and MapSet.member?(circuit, second)
    end)
  end

  defp all_coords_connected?(circuits, total_coord_count) do
    case circuits do
      [single_circuit] ->
        MapSet.size(single_circuit) == total_coord_count

      _ ->
        false
    end
  end
end
