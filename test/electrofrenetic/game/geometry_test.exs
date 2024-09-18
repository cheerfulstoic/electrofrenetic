defmodule Electrofrenetic.Game.GeometryTest do
  alias Electrofrenetic.Game.Geometry

  use ExUnit.Case

  @pi :math.pi()

  # describe ".cap_difference" do
  #   test "returns the difference when the amount is within the range" do
  #     assert_in_delta Geometry.cap_difference(-6.283184), 0.0, 0.0001
  #
  #     assert_in_delta Geometry.cap_difference(-5.7), -0.58318, 0.0001
  #
  #     assert_in_delta Geometry.cap_difference(-3.15), -3.1331, 0.0001
  #
  #     assert Geometry.cap_difference(-3.1415) == -3.1415
  #     assert Geometry.cap_difference(-1.0) == -1.0
  #     assert Geometry.cap_difference(-0.5) == -0.5
  #
  #     assert Geometry.cap_difference(0.0) == 0.0
  #     assert Geometry.cap_difference(0.5) == 0.5
  #     assert Geometry.cap_difference(1.0) == 1.0
  #     assert Geometry.cap_difference(3.1415) == 3.1415
  #     assert_in_delta Geometry.cap_difference(3.15), 3.1331, 0.0001
  #
  #     assert_in_delta Geometry.cap_difference(5.7), 0.58318, 0.0001
  #
  #     assert_in_delta Geometry.cap_difference(6.283184), 0.0, 0.0001
  #   end
  # end
  #
  describe ".target_angle" do
    test "less than 180 degrees" do
      assert Geometry.target_angle({1, 1}, 0.0, {2, 1}) == 0.0
      assert Geometry.target_angle({1, 1}, @pi / 2, {1, 2}) == 0.0

      assert_in_delta Geometry.target_angle({1, 1}, @pi / 4, {1, 2}), @pi / 4, 0.0001
      assert_in_delta Geometry.target_angle({1, 1}, 3 / 4 * @pi, {1, 2}), -@pi / 4, 0.0001
    end

    test "180 degrees" do
      assert Geometry.target_angle({1, 1}, 0.0, {0, 1}) == @pi
      assert Geometry.target_angle({1, 1}, @pi / 2, {1, 0}) == @pi
      assert Geometry.target_angle({1, 1}, @pi / 4, {0, 0}) == @pi
      assert Geometry.target_angle({1, 1}, 3 / 4 * @pi, {2, 0}) == @pi
    end

    test "Negative angles" do
      assert Geometry.target_angle({1, 1}, 0.0, {2, 0}) == -@pi / 4
      assert Geometry.target_angle({1, 1}, 0.0, {1, 0}) == -@pi / 2
      assert Geometry.target_angle({1, 1}, 0.0, {0, 0}) == -3 / 4 * @pi
    end
  end

  describe ".distance" do
    test "returns the distance between two points" do
      assert Geometry.distance({0, 0}, {0, 0}) == 0.0

      # negative numbers
      assert Geometry.distance({-2, -3}, {-2, -3}) == 0.0

      assert_in_delta Geometry.distance({0, 0}, {-1, 0}), 1.0, 0.0001
      assert_in_delta Geometry.distance({0, 0}, {0, -1}), 1.0, 0.0001
      assert_in_delta Geometry.distance({0, 0}, {-1, -1}), 1.4142, 0.0001
      assert_in_delta Geometry.distance({0, 0}, {-1, -2}), 2.2360, 0.0001
      assert_in_delta Geometry.distance({0, 0}, {-2, -1}), 2.2360, 0.0001
      assert_in_delta Geometry.distance({0, 0}, {-2, -2}), 2.8284, 0.0001

      # positive numbers
      assert Geometry.distance({2, 3}, {2, 3}) == 0.0

      assert_in_delta Geometry.distance({0, 0}, {1, 0}), 1.0, 0.0001
      assert_in_delta Geometry.distance({0, 0}, {0, 1}), 1.0, 0.0001
      assert_in_delta Geometry.distance({0, 0}, {1, 1}), 1.4142, 0.0001
      assert_in_delta Geometry.distance({0, 0}, {1, 2}), 2.2360, 0.0001
      assert_in_delta Geometry.distance({0, 0}, {2, 1}), 2.2360, 0.0001
      assert_in_delta Geometry.distance({0, 0}, {2, 2}), 2.8284, 0.0001
    end
  end

  describe ".target_direction" do
    test "returns the direction from the source to the target" do
      # assert_in_delta Geometry.target_direction({0, 0}, {0, 0}), 0.0, 0.0001

      assert_in_delta Geometry.target_direction({0, 0}, {1, 0}), 0.0, 0.0001
      assert_in_delta Geometry.target_direction({0, 0}, {0, 1}), @pi / 2, 0.0001
      assert_in_delta Geometry.target_direction({0, 0}, {-1, 0}), @pi, 0.0001
      assert_in_delta Geometry.target_direction({0, 0}, {0, -1}), 3 / 2 * @pi, 0.0001
    end
  end
end
