defmodule Feature.SessionMethods do

  @doc """
  Retourne une nouvelle session

  Utiliser la méthode générale start_session()

  @param {Keyword} params 
    params[:window_size] = [width: <width>, height: <height>]
  """
  def start_session(params \\ []) do
    {:ok, sess} = Wallaby.start_session()
    sess
  end

  def end_session(sujet) do
    session = session_from(sujet)
    Wallaby.end_session(session) 
  end

  # Comme on peut envoyer indifféremment aux fonctions l'user ou
  # la session, on doit traiter session pour en avoir vraiment une
  # 
  # 
  # 
  @doc """
  Donc mettre en début de toutes les méthodes :

    def mafonction(session, ...) do
      session = session_from(session)
  """
  def session_from(session) do
    if Map.has_key?(session, :session) do
      session.session # quand user
    else
      session
    end
  end


end