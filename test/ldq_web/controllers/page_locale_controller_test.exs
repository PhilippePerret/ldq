defmodule LdQWeb.PageLocaleControllerTest do
  use LdQWeb.ConnCase

  import LdQ.SiteFixtures

  @create_attrs %{status: 42, title: "some title", image: "some image", locale: "some locale", raw_content: "some raw_content", content: "some content", summary: "some summary", meta_title: "some meta_title", meta_description: "some meta_description"}
  @update_attrs %{status: 43, title: "some updated title", image: "some updated image", locale: "some updated locale", raw_content: "some updated raw_content", content: "some updated content", summary: "some updated summary", meta_title: "some updated meta_title", meta_description: "some updated meta_description"}
  @invalid_attrs %{status: nil, title: nil, image: nil, locale: nil, raw_content: nil, content: nil, summary: nil, meta_title: nil, meta_description: nil}

  describe "index" do
    test "lists all page_locales", %{conn: conn} do
      conn = get(conn, ~p"/page_locales")
      assert html_response(conn, 200) =~ "Listing Page locales"
    end
  end

  describe "new page_locale" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/page_locales/new")
      assert html_response(conn, 200) =~ "New Page locale"
    end
  end

  describe "create page_locale" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/page_locales", page_locale: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/page_locales/#{id}"

      conn = get(conn, ~p"/page_locales/#{id}")
      assert html_response(conn, 200) =~ "Page locale #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/page_locales", page_locale: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Page locale"
    end
  end

  describe "edit page_locale" do
    setup [:create_page_locale]

    test "renders form for editing chosen page_locale", %{conn: conn, page_locale: page_locale} do
      conn = get(conn, ~p"/page_locales/#{page_locale}/edit")
      assert html_response(conn, 200) =~ "Edit Page locale"
    end
  end

  describe "update page_locale" do
    setup [:create_page_locale]

    test "redirects when data is valid", %{conn: conn, page_locale: page_locale} do
      conn = put(conn, ~p"/page_locales/#{page_locale}", page_locale: @update_attrs)
      assert redirected_to(conn) == ~p"/page_locales/#{page_locale}"

      conn = get(conn, ~p"/page_locales/#{page_locale}")
      assert html_response(conn, 200) =~ "some updated title"
    end

    test "renders errors when data is invalid", %{conn: conn, page_locale: page_locale} do
      conn = put(conn, ~p"/page_locales/#{page_locale}", page_locale: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Page locale"
    end
  end

  describe "delete page_locale" do
    setup [:create_page_locale]

    test "deletes chosen page_locale", %{conn: conn, page_locale: page_locale} do
      conn = delete(conn, ~p"/page_locales/#{page_locale}")
      assert redirected_to(conn) == ~p"/page_locales"

      assert_error_sent 404, fn ->
        get(conn, ~p"/page_locales/#{page_locale}")
      end
    end
  end

  defp create_page_locale(_) do
    page_locale = page_locale_fixture()
    %{page_locale: page_locale}
  end
end
