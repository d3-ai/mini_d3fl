defmodule MiniD3fl.Utils do
  def get_process_name(module, index) do
    :"#{module}_#{index}"
  end

  def get_channel_name(from_id, to_id) do
    :"Channel_#{from_id}_#{to_id}"
  end

end
