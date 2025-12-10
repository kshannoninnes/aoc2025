defmodule Day9 do
  def part1(input) do
    coord_list =
      input
      |> String.split("\n", trim: true)
      |> Enum.map(fn row ->
        row
        |> String.split(",", trim: true)
        |> Enum.map(&String.to_integer/1)
        |> List.to_tuple()
      end)

    # Use a reducer that tracks the current max area and the remaining list of candidate corners.
    {max_area, _} =
      Enum.reduce(coord_list, {-1, coord_list}, fn corner, {max_area, [_corner | candidate_corners]} ->
        find_max_rect_from(corner, {max_area, candidate_corners})
      end)

    max_area
  end

  # Empty candidate list, thus we're finished searching. Just return the current state.
  defp find_max_rect_from(_corner, {_area, []} = state), do: state

  # Find the max-area rectangle whose diagonal runs from corner_a to some opposite corner in the remaining candidates.
  defp find_max_rect_from(corner_a, {max_area, remaining_candidates}) do
    # Find the "maximum candidate" by area
    candidate_coords =
      Enum.max_by(remaining_candidates, fn corner_b_candidate ->
        calc_rect_area(corner_a, corner_b_candidate)
      end)

    candidate_area =
      calc_rect_area(corner_a, candidate_coords)

    if candidate_area > max_area do
      {candidate_area, remaining_candidates}
    else
      {max_area, remaining_candidates}
    end
  end

  defp calc_rect_area({x1, y1}, {x2, y2}), do: (abs(x1 - x2) + 1) * (abs(y1 - y2) + 1)

  def part2(input) do
    polygon_points =
      input
      |> String.split("\n", trim: true)
      |> Enum.map(fn row ->
        row
        |> String.split(",", trim: true)
        |> Enum.map(&String.to_integer/1)
        |> List.to_tuple()
      end)

    # Create edges by generating chunks from polygon_points, of size 2
    # eg. [1, 2, 3, 4] becomes [[1, 2], [2, 3], [3, 4]]
    #
    # Providing 'polygon_points' as the third argument ensures chunk_every
    # can generate one last chunk with '4' as the starting point.
    # eg. [[1, 2], [2, 3], [3, 4]] becomes [[1, 2], [2, 3], [3, 4], [4, 1]]
    #
    # This effectively ensures we have a 'closed' polygon for our algorithms
    polygon_edges =
      polygon_points
      |> Enum.chunk_every(2, 1, polygon_points)
      |> Enum.map(&List.to_tuple/1)

    {area, _coords} =
      polygon_points
      |> generate_all_rectangle_corner_pairs()

      # For each rectangle:
      # - Calculate the area
      #   - If its area is smaller than the current valid max, skip it
      #   - Else if the rectangle is partially outside the polygon, keep the current max
      #   - Else we've found a new valid max area rectangle
      |> Enum.reduce({0, nil}, fn {p1, p2} = candidate_coords,
                                  {current_max_area, current_max_coords} ->
        candidate_area = calc_rect_area(p1, p2)

        cond do
          candidate_area <= current_max_area ->
            {current_max_area, current_max_coords}

          true ->
            # Build the edges for this rectangle
            #
            # We need all the edges to ensure we don't have a rectangle where:
            # - The corners exist inside the polygon
            # - The edges partially exist outside of the polygon
            #
            # This can happen when the polygon has a concave section
            # such as a big box shaped 'C' where an edge might start
            # in the top arm and span down, ending in the bottom arm.
            rect_edges = build_rectangle_edges(p1, p2)

            if rectangle_fully_inside?({candidate_coords, rect_edges}, polygon_edges) do
              {candidate_area, candidate_coords}
            else
              {current_max_area, current_max_coords}
            end
        end
      end)

    area
  end

  # Use a for-comprehension to generate all pair combinations of points
  defp generate_all_rectangle_corner_pairs(polygon_points) do
    for {point_a, index} <- Enum.with_index(polygon_points),
        point_b <- Enum.drop(polygon_points, index + 1) do
      {point_a, point_b}
    end
  end

  # A rectangle is valid if:
  # - All 4 corners are considered valid, AND
  # - None of the edges of the rectangle cross any edges of the polygon
  defp rectangle_fully_inside?({corners, rect_edges}, polygon_edges) do
    all_corners_valid?(corners, polygon_edges) and
      not any_edge_crossing?(rect_edges, polygon_edges)
  end

  defp all_corners_valid?({{x1, y1}, {x2, y2}}, polygon_edges) do
    # Work out the four corners of the rectangle. The two given points are opposite
    # corners, so we find the left/right x-values and the bottom/top y-values and
    # build the full set of corners from them.
    left = min(x1, x2)
    right = max(x1, x2)
    bottom = min(y1, y2)
    top = max(y1, y2)

    corner_points = [
      {left, bottom},
      {right, bottom},
      {right, top},
      {left, top}
    ]

    # Check that every corner of the rectangle lies inside (or on an edge of) the polygon.
    Enum.all?(corner_points, fn point ->
      point_inside_polygon?(point, polygon_edges)
    end)
  end

  # The inner Enum.any? checks a single rectangle edge against all polygon edges.
  # The outer Enum.any? repeats this for every rectangle edge and returns true
  # as soon as it finds any intersecting pair.
  defp any_edge_crossing?(rect_edges, polygon_edges) do
    Enum.any?(rect_edges, fn rect_edge ->
      Enum.any?(polygon_edges, fn poly_edge ->
        edges_intersect?(rect_edge, poly_edge)
      end)
    end)
  end

  # This is the point I started needing help and started looking things up.
  # Essentially two edges intersect if edge_a_start and edge_a_end lie on
  # opposite sides of the line defined by edge_b_start and edge_b_end, and
  # vice versa.
  #
  # We determine this by running a small calculation for each point that tells
  # us whether it lies on one side of the edge or the other. If each edge has
  # its two endpoints landing on different sides of the other edge’s line
  # (and none fall exactly on that line), then the edges cross.
  defp edges_intersect?({edge_a_start, edge_a_end}, {edge_b_start, edge_b_end}) do
    edge_b_start_side = determine_side(edge_a_start, edge_a_end, edge_b_start)
    edge_b_end_side = determine_side(edge_a_start, edge_a_end, edge_b_end)
    edge_a_start_side = determine_side(edge_b_start, edge_b_end, edge_a_start)
    edge_a_end_side = determine_side(edge_b_start, edge_b_end, edge_a_end)

    # The start/end of each edge are on opposite sides AND
    #  Neither end of edge_b falls exactly on the line of edge_a AND
    #  Neither end of edge_a falls exactly on the line of edge_b
    edge_b_start_side != edge_b_end_side and edge_a_start_side != edge_a_end_side and
      edge_b_start_side != :collinear and edge_b_end_side != :collinear and
      edge_a_start_side != :collinear and edge_a_end_side != :collinear
  end

  # This function uses a funny bit of math to work out which side of the edge a point is on.
  #
  # Treat the line from point p to point q as a car driving along a straight road.
  # The point r is either:
  # - to the car’s left,
  # - to the car’s right,
  # - or exactly on the road (collinear).
  defp determine_side({px, py}, {qx, qy}, {rx, ry}) do
    side = (qy - py) * (rx - qx) - (qx - px) * (ry - qy)

    cond do
      side > 0 -> :left
      side < 0 -> :right
      true -> :collinear
    end
  end

  # A point is considered inside the polygon if it's on a polygon edge
  # or it is fully inside the closed polygon.
  defp point_inside_polygon?(point, polygon_edges) do
    point_on_edge =
      Enum.any?(polygon_edges, fn {edge_start, edge_end} ->
        point_on_edge?(point, edge_start, edge_end)
      end)

    point_on_edge or point_fully_inside_polygon?(point, polygon_edges)
  end

  # This is also something I needed a LOT of help with.
  #
  # The algorithm for this function is the ray-casting algorithm:
  #   https://rosettacode.org/wiki/Ray-casting_algorithm
  #
  # It works by using math to simulate an infinite horizontal line extending out to
  # the right of a point and counting how many times it crosses an edge. If it's odd,
  # the line originated from inside a the polygon, and if it's even then outside.
  #
  # To simulate this line, we perform two tests for each of the polygon's edges:
  #
  # 1) Check whether point_y is between y1 and y2, the y-values of this edge’s endpoints.
  #    This means one endpoint lies above the point and the other lies below it. If this
  #    is not true, then our horizontal line at point_y can never touch this edge.
  #
  # 2) Work out where this edge would meet that horizontal line: at what x coordinate on
  #    the edge would an intersection occur? If that x coordinate is to the right of the
  #    point’s x (point_x), then this edge is one of the crossings we count for the ray.
  defp point_fully_inside_polygon?({point_x, point_y}, polygon_edges) do
    Enum.reduce(polygon_edges, false, fn {{x1, y1}, {x2, y2}}, inside? ->
      crosses? =
        y1 > point_y != y2 > point_y and
          point_x < (x2 - x1) * (point_y - y1) / (y2 - y1) + x1

      if crosses?, do: not inside?, else: inside?
    end)
  end

  # Generate the edges for a rectangle represented by 2 opposite points
  defp build_rectangle_edges({x1, y1}, {x2, y2}) do
    left = min(x1, x2)
    right = max(x1, x2)
    bottom = min(y1, y2)
    top = max(y1, y2)

    top_left = {left, top}
    top_right = {right, top}
    bottom_right = {right, bottom}
    bottom_left = {left, bottom}

    [
      {top_left, top_right},
      {top_right, bottom_right},
      {bottom_right, bottom_left},
      {bottom_left, top_left}
    ]
  end

  # This function checks whether the point lies somewhere on the infinite line
  # defined by the edge, and if so, whether it also lies between the start and
  # end of the edge.
  defp point_on_edge?({px, py}, {x1, y1}, {x2, y2}) do
    collinear = determine_side({x1, y1}, {x2, y2}, {px, py}) == :collinear

    within_x = px >= min(x1, x2) and px <= max(x1, x2)
    within_y = py >= min(y1, y2) and py <= max(y1, y2)

    collinear and within_x and within_y
  end
end
