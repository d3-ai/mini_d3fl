defmodule MiniD3fl.ComputeNode.AiCoreTest do
  use ExUnit.Case
  use MiniD3fl.Aliases

  test "should train and test for MNIST" do
    {value, _, _} = MiniD3fl.ComputeNode.AiCore.run()
    assert value == :end_train
  end
end
