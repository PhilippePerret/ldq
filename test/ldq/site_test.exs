defmodule LdQ.SiteTest do
  use LdQ.DataCase

  alias LdQ.Site

  describe "pages" do
    alias LdQ.Site.Page

    import LdQ.SiteFixtures

    @invalid_attrs %{status: nil, template: nil, slug: nil, publised_at: nil}

    test "list_pages/0 returns all pages" do
      page = page_fixture()
      assert Site.list_pages() == [page]
    end

    test "get_page!/1 returns the page with given id" do
      page = page_fixture()
      assert Site.get_page!(page.id) == page
    end

    test "create_page/1 with valid data creates a page" do
      valid_attrs = %{status: 42, template: "some template", slug: "some slug", publised_at: ~N[2025-04-13 06:02:00]}

      assert {:ok, %Page{} = page} = Site.create_page(valid_attrs)
      assert page.status == 42
      assert page.template == "some template"
      assert page.slug == "some slug"
      assert page.publised_at == ~N[2025-04-13 06:02:00]
    end

    test "create_page/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Site.create_page(@invalid_attrs)
    end

    test "update_page/2 with valid data updates the page" do
      page = page_fixture()
      update_attrs = %{status: 43, template: "some updated template", slug: "some updated slug", publised_at: ~N[2025-04-14 06:02:00]}

      assert {:ok, %Page{} = page} = Site.update_page(page, update_attrs)
      assert page.status == 43
      assert page.template == "some updated template"
      assert page.slug == "some updated slug"
      assert page.publised_at == ~N[2025-04-14 06:02:00]
    end

    test "update_page/2 with invalid data returns error changeset" do
      page = page_fixture()
      assert {:error, %Ecto.Changeset{}} = Site.update_page(page, @invalid_attrs)
      assert page == Site.get_page!(page.id)
    end

    test "delete_page/1 deletes the page" do
      page = page_fixture()
      assert {:ok, %Page{}} = Site.delete_page(page)
      assert_raise Ecto.NoResultsError, fn -> Site.get_page!(page.id) end
    end

    test "change_page/1 returns a page changeset" do
      page = page_fixture()
      assert %Ecto.Changeset{} = Site.change_page(page)
    end
  end

  describe "page_locales" do
    alias LdQ.Site.PageLocale

    import LdQ.SiteFixtures

    @invalid_attrs %{status: nil, title: nil, image: nil, locale: nil, raw_content: nil, content: nil, summary: nil, meta_title: nil, meta_description: nil}

    test "list_page_locales/0 returns all page_locales" do
      page_locale = page_locale_fixture()
      assert Site.list_page_locales() == [page_locale]
    end

    test "get_page_locale!/1 returns the page_locale with given id" do
      page_locale = page_locale_fixture()
      assert Site.get_page_locale!(page_locale.id) == page_locale
    end

    test "create_page_locale/1 with valid data creates a page_locale" do
      valid_attrs = %{status: 42, title: "some title", image: "some image", locale: "some locale", raw_content: "some raw_content", content: "some content", summary: "some summary", meta_title: "some meta_title", meta_description: "some meta_description"}

      assert {:ok, %PageLocale{} = page_locale} = Site.create_page_locale(valid_attrs)
      assert page_locale.status == 42
      assert page_locale.title == "some title"
      assert page_locale.image == "some image"
      assert page_locale.locale == "some locale"
      assert page_locale.raw_content == "some raw_content"
      assert page_locale.content == "some content"
      assert page_locale.summary == "some summary"
      assert page_locale.meta_title == "some meta_title"
      assert page_locale.meta_description == "some meta_description"
    end

    test "create_page_locale/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Site.create_page_locale(@invalid_attrs)
    end

    test "update_page_locale/2 with valid data updates the page_locale" do
      page_locale = page_locale_fixture()
      update_attrs = %{status: 43, title: "some updated title", image: "some updated image", locale: "some updated locale", raw_content: "some updated raw_content", content: "some updated content", summary: "some updated summary", meta_title: "some updated meta_title", meta_description: "some updated meta_description"}

      assert {:ok, %PageLocale{} = page_locale} = Site.update_page_locale(page_locale, update_attrs)
      assert page_locale.status == 43
      assert page_locale.title == "some updated title"
      assert page_locale.image == "some updated image"
      assert page_locale.locale == "some updated locale"
      assert page_locale.raw_content == "some updated raw_content"
      assert page_locale.content == "some updated content"
      assert page_locale.summary == "some updated summary"
      assert page_locale.meta_title == "some updated meta_title"
      assert page_locale.meta_description == "some updated meta_description"
    end

    test "update_page_locale/2 with invalid data returns error changeset" do
      page_locale = page_locale_fixture()
      assert {:error, %Ecto.Changeset{}} = Site.update_page_locale(page_locale, @invalid_attrs)
      assert page_locale == Site.get_page_locale!(page_locale.id)
    end

    test "delete_page_locale/1 deletes the page_locale" do
      page_locale = page_locale_fixture()
      assert {:ok, %PageLocale{}} = Site.delete_page_locale(page_locale)
      assert_raise Ecto.NoResultsError, fn -> Site.get_page_locale!(page_locale.id) end
    end

    test "change_page_locale/1 returns a page_locale changeset" do
      page_locale = page_locale_fixture()
      assert %Ecto.Changeset{} = Site.change_page_locale(page_locale)
    end
  end
end
