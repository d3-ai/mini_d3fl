defmodule MiniD3fl.JobController.EventQueueTest do
  use ExUnit.Case
  doctest MiniD3fl.JobController.EventQueue
  alias MiniD3fl.JobController.EventQueue
  alias MiniD3fl.JobController.EventQueue.Event

  test "should pop from EventQueue with proper order" do
    # キューの初期化
    queue = EventQueue.init_queue()

    # コマンドを挿入
    queue = EventQueue.insert_command(queue, %Event{time: 5, event_name: :train, args: "Train A"})
    queue = EventQueue.insert_command(queue, %Event{time: 3, event_name: :send, args: "Send B"})
    queue = EventQueue.insert_command(queue, %Event{time: 7, event_name: :train, args: "Train C"})

    # 時刻順にコマンドを取り出し
    {:ok, command, queue} = EventQueue.pop_command(queue)
    assert command == %Event{time: 3, event_name: :send, args: "Send B"}

    {:ok, command, queue} = EventQueue.pop_command(queue)
    assert command == %Event{time: 5, event_name: :train, args: "Train A"}

    {:ok, command, queue} = EventQueue.pop_command(queue)
    assert command == %Event{time: 7, event_name: :train, args: "Train C"}

    assert queue == {0, nil}
  end
end
