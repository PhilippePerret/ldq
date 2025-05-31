defmodule LdQ.Core.TriggerDaemon do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    schedule_work()
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    LdQ.Core.Trigger.fetch_and_execute()
    
    # On programme le prochain traitement
    schedule_work()

    {:noreply, state}
  end

  defp schedule_work do
    # Le processus est lancé toutes les heures
    Process.send_after(self(), :work, 1 * 60 * 60 * 1000)
  end
end