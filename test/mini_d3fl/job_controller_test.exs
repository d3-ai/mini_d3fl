defmodule MiniD3fl.JobControllerTest do
  use ExUnit.Case
  doctest MiniD3fl.JobController
  alias MiniD3fl.JobController
  alias MiniD3fl.JobController.EventQueue
  alias MiniD3fl.JobController.EventQueue.Event

  setup do
    # キューの初期化
    queue = EventQueue.init_queue()

    # コマンドを挿入
    queue = EventQueue.insert_command(queue,%Event{time: 5, event_name: :train, args: %{}})
    queue = EventQueue.insert_command(queue,%Event{time: 3, event_name: :send, args: %{}})
    queue = EventQueue.insert_command(queue,%Event{time: 7, event_name: :train, args: %{}})

    job_controller_id = 0
    {:ok, pid} = JobController.start_link(
      %{job_controller_id: job_controller_id,
      init_event_queue: queue})

    %{job_controller_id: job_controller_id}
  end

  test "should have correct time", %{job_controller_id: job_controller_id} do
    JobController.event_execute(job_controller_id)
  end
end
