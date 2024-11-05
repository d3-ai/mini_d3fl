defmodule MiniD3fl.Utils do
  @spec get_process_name(String.t(), non_neg_integer()) :: atom()
  def get_process_name(module, id) do
    :"#{module}_#{id}"
  end

  @spec get_process_name(String.t(), non_neg_integer(), non_neg_integer()) :: atom()
  def get_process_name_from_to(module, from_id, to_id) do
    :"#{module}_#{from_id}_#{to_id}"
  end
end
