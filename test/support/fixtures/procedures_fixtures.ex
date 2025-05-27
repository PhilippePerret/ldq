defmodule LdQ.ProcedureFixture do

  alias LdQ.ComptesFixtures, as: FCompt

  def create_procedure(params \\ []) do
    params = get_or_put(params, :owner, FCompt.make_simple_user())
    params = get_or_put(params, :submitter, FCompt.make_simple_user())
    params = get_or_put(params, :submitter, FCompt.make_membre())
    params = get_or_put(params, :submitter, FCompt.make_writer())
    params = get_or_put(params, :current_step, params[:current]||params[:step])
    params = get_or_put(params, :next_step, params[:next]||params[:step])
    params = get_or_put(params, :proc_dim, params[:dim]||params[:proc_id]||"unknown-proc")

    # TODO
    # Plus tard il sera possible de déterminer des étapes en chargeant
    # le module d'après son :proc_dim (et en appelant module.steps)

    attrs = %{
      proc_dim: params[:proc_dim],
      submitter_id: params[:submitter_id] || params[:submitter].id,
      owner_type: Keyword.get(params, :owner_type, "user"),
      owner_id:   Keyword.get(params, :owner_id, params[:owner].id),
      current_step: params[:current_step],
      next_step: params[:next_step],
      steps_done: params[:steps_done] || [],
      data: Keyword.get(params, :data, %{})
    }
    LdQ.ProcedureMethods.create_procedure(attrs)
  end

  def get_or_put(kw, prop, def) do
    if is_nil(Keyword.get(kw, prop, nil)) do
      Keyword.put(kw, prop, def)
    else
      kw
    end
  end


end