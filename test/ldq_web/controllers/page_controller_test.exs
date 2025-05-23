defmodule LdQWeb.PageControllerTest do
  use LdQWeb.ConnCase

  import LdQ.SiteFixtures

  @create_attrs %{status: 42, template: "some template", slug: "some slug", published_at: ~N[2025-04-13 06:02:00]}
  @update_attrs %{status: 43, template: "some updated template", slug: "some updated slug", published_at: ~N[2025-04-14 06:02:00]}
  @invalid_attrs %{status: nil, template: nil, slug: nil, published_at: nil}

  describe "index" do
    test "lists all pages", %{conn: conn} do
      conn = get(conn, ~p"/pages")
      assert html_response(conn, 200) =~ "Listing Pages"
    end
  end

  describe "new page" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/pages/new")
      assert html_response(conn, 200) =~ "New Page"
    end
  end

  describe "create page" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/pages", page: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/pages/#{id}"

      conn = get(conn, ~p"/pages/#{id}")
      assert html_response(conn, 200) =~ "Page #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/pages", page: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Page"
    end
  end

  describe "edit page" do
    setup [:create_page]

    test "renders form for editing chosen page", %{conn: conn, page: page} do
      conn = get(conn, ~p"/pages/#{page}/edit")
      assert html_response(conn, 200) =~ "Edit Page"
    end
  end

  describe "update page" do
    setup [:create_page]

    test "redirects when data is valid", %{conn: conn, page: page} do
      conn = put(conn, ~p"/pages/#{page}", page: @update_attrs)
      assert redirected_to(conn) == ~p"/pages/#{page}"

      conn = get(conn, ~p"/pages/#{page}")
      assert html_response(conn, 200) =~ "some updated template"
    end

    test "renders errors when data is invalid", %{conn: conn, page: page} do
      conn = put(conn, ~p"/pages/#{page}", page: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Page"
    end
  end

  describe "delete page" do
    setup [:create_page]

    test "deletes chosen page", %{conn: conn, page: page} do
      conn = delete(conn, ~p"/pages/#{page}")
      assert redirected_to(conn) == ~p"/pages"

      assert_error_sent 404, fn ->
        get(conn, ~p"/pages/#{page}")
      end
    end
  end

  defp create_page(_) do
    page = page_fixture()
    %{page: page}
  end
end
