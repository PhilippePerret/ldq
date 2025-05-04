defmodule Feature.ProcedureTestMeths do
  use LdQWeb.FeatureCase, async: false

  import LdQ.ProcedureMethods

  def has_no_procedure(sujet, proc_id) when is_binary(proc_id) do
    assert(is_nil(get_procedure(proc_id)))
    sujet
  end
  def has_no_procedure(sujet, procedure) do
    has_no_procedure(sujet, procedure.id)
  end
end