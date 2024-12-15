defmodule MiniD3fl.JobControllerTest do
  use ExUnit.Case
  doctest MiniD3fl.JobController
  alias MiniD3fl.JobController
  alias MiniD3fl.JobController.EventQueue
  alias MiniD3fl.JobController.EventQueue.Event

  def setup() do
    # キューの初期化
    queue = EventQueue.init_queue()

    # コマンドを挿入
    queue = EventQueue.insert_command(queue,%Event{time: 5, event_name: :train, args: %{}})
    queue = EventQueue.insert_command(queue,%Event{time: 3, event_name: :send, args: %{}})
    queue = EventQueue.insert_command(queue,%Event{time: 7, event_name: :train, args: %{}})

    job_controller_id = 0
    {:ok, _pid} = JobController.start_link(
      %{job_controller_id: job_controller_id,
      init_event_queue: queue})
    %{job_controller_id: job_controller_id, queue: queue}
  end

  setup do
    setup()
  end

  test "should have correct time", %{job_controller_id: job_controller_id, queue: _queue} do
    {:ok, event} = JobController.get_event(job_controller_id)
    assert event == %Event{time: 3, event_name: :send, args: %{}}

    {:ok, event} = JobController.get_event(job_controller_id)
    assert event == %Event{time: 5, event_name: :train, args: %{}}

    {:ok, event} = JobController.get_event(job_controller_id)
    assert event == %Event{time: 7, event_name: :train, args: %{}}
  end
end
