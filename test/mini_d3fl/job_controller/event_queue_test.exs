defmodule MiniD3fl.JobController.EventQueueTest do
  use ExUnit.Case
  doctest MiniD3fl.JobController.EventQueue
  alias MiniD3fl.JobController.EventQueue

  test "greets the world" do
    # キューの初期化
    queue = EventQueue.init_queue()

    # コマンドを挿入
    queue = EventQueue.insert_command(queue, 5, :train, "Train A")
    queue = EventQueue.insert_command(queue, 3, :send, "Message B")
    queue = EventQueue.insert_command(queue, 7, :train, "Train C")

    # 時刻順にコマンドを取り出し
    {command, queue} = EventQueue.pop_command(queue)
    assert command == {3, :send, "Message B"}

    {command, queue} = EventQueue.pop_command(queue)
    assert command == {5, :train, "Train A"}

    {command, queue} = EventQueue.pop_command(queue)
    assert command == {7, :train, "Train C"}

    assert queue == {0, nil}
  end
end
