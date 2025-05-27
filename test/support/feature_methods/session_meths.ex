defmodule Feature.SessionMethods do

  @doc """
  Retourne une nouvelle session

  Utiliser la méthode générale start_session()

  @param {Keyword} params 
    params[:window_size] = [width: <width>, height: <height>]
  """
  def start_session(sujet, params) do
    session = start_session(params)
    Map.merge(sujet, %{
      session: session,
      window_handle: Wallaby.Browser.window_handle(session)
    })
  end
  def start_session(_params) do
    {:ok, sess} = Wallaby.start_session()
    sess
  end

  def move_window(sujet, position) do
    session = session_from(sujet)
    Wallaby.Browser.move_window(session, position[:left], Keyword.get(position, :top, 0))
  end

  def end_session(sujet) do
    session = session_from(sujet)
    Wallaby.end_session(session)
    sujet
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